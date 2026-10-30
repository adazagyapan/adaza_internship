library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write is
    generic (
        G_WORD_W : natural := 32;    -- counter sample width in bits      
        G_AXI_W  : natural := 128;   -- AXI data width in bits    
        G_ADDR_W : natural := 49    -- AXI address width in bits
    );
    port (
        clk_i       : in  std_logic;
        rst_n_i     : in  std_logic;
  
        -- related with the data, valid signal and ready signal in the counter module 
        s_axis_l0_tdata  : in  std_logic_vector(G_WORD_W-1 downto 0);
        s_axis_l0_tvalid : in  std_logic;
        s_axis_l0_tready : out std_logic;  
     
        start_i : in  std_logic;
        done_o  : out std_logic;  
        err_o : out std_logic; 

        write_base_address_input : in std_logic_vector(48 downto 0); -- base addr
        
        total_bytes_i : in std_logic_vector(31 downto 0);

        ing_awaddr_o  : out std_logic_vector(G_ADDR_W-1 downto 0);
        ing_awlen_o   : out std_logic_vector(7 downto 0);
        ing_awvalid_o : out std_logic; 
        ing_awready_i : in  std_logic;
        ing_wdata_o   : out std_logic_vector(G_AXI_W-1 downto 0);
        ing_wstrb_o   : out std_logic_vector(G_AXI_W/8-1 downto 0);
        ing_wlast_o   : out std_logic;
        ing_wvalid_o  : out std_logic;
        ing_wready_i  : in  std_logic;
        ing_bresp_i   : in  std_logic_vector(1 downto 0);
        ing_bvalid_i  : in std_logic; 
        ing_bready_o  : out std_logic
    );
end entity write;

architecture rtl of write is

    --states
    type StateType is (ST_IDLE,  ST_AW, ST_STREAM, ST_B);
    signal state : StateType := ST_IDLE;
    
    --constants
    constant C_BYTES_PER_BEAT : natural := G_AXI_W / 8; --16
    constant PAGE_SIZE : unsigned(12 downto 0) := to_unsigned(4096,13); --since one page has 4096 bytes (4KB boundary)

    -- control stuff (not position)
    signal start_reg : std_logic := '0'; 
    signal bresp_err_r : std_logic := '0';

    --  positions
    signal addr_r : unsigned(G_ADDR_W-1 downto 0) := unsigned(write_base_address_input);  -- current address, advances in every beat
    signal addr_end : unsigned(G_ADDR_W-1 downto 0) := (others => '0');
    signal burst_end_addr : unsigned(G_ADDR_W-1 downto 0):= (others => '0');
    
    -- combinational stuff derived from addresses
    signal bytes_left : unsigned (G_ADDR_W-1 downto 0); -- addr_end-addr_r (EVERY ADDR IS ONE BYTE)
    signal bytes_to_page_end : unsigned (12 downto 0); -- bytes until the next page, maxc 4096 
    signal burst_bytes : unsigned(12 downto 0); --min(bytes_left, bytes_to_page_end), max 4096 = one full page 
    signal burst_beats : unsigned(8 downto 0); -- burst_bytes/16 because one beat carries 4 words, 1 word is 4 bytes so in total 16 bytes

begin

    -- the two distances that bound a burst read from the addresses 
    bytes_left <= addr_end - addr_r;
    bytes_to_page_end <= PAGE_SIZE - resize(addr_r(11 downto 0), 13); -- lower 12 bits are the page offset 
    
    -- burst length in bytes = min(bytes_left, bytes_to_page_end)
    -- a page-aligned burst runs the whole 4096-byte page (256 beats in total, AWLEN is 0xFF)
    -- it is only shortened by the boundary near a page edge, or by what is left at the end 
    process(bytes_left, bytes_to_page_end)
        variable m : unsigned(12 downto 0);
    begin
        m := bytes_to_page_end; -- start a the page boundary limit
        if bytes_left < resize(m, bytes_left'length) then
            m := resize(bytes_left, 13);    -- if bytes left is smaller than bytes until the end of page then our burst bytes is just remaining bytes, 
                                            -- this means we will finish writing in one page and we wont skip a page
        end if;
        burst_bytes <= m;    
    end process;
    
    -- beat conversion for the length output 
    burst_beats <= burst_bytes(12 downto 4); -- divide by 16 
    
    -- outputs 
    ing_wstrb_o <= x"FFFF"; -- all 128 bits valid 
    ing_awaddr_o <= std_logic_vector(addr_r); -- current address 
    ing_awlen_o <= std_logic_vector(resize(burst_beats-1, 8)) when state = ST_AW else (others => '0');
    
    ing_awvalid_o <= '1' when state = ST_AW else '0';
    ing_wvalid_o <= '1' when (state = ST_STREAM and s_axis_l0_tvalid = '1') else '0';
    -- last beat of the burst, ts will make addr_r reach burst_end_addr
    ing_wlast_o <= '1' when (state = ST_STREAM and addr_r = burst_end_addr - C_BYTES_PER_BEAT) else '0';
    ing_bready_o <= '1' when state = ST_B else '0';
    s_axis_l0_tready <= ing_wready_i when state = ST_STREAM else '0';
    
    ing_wdata_o <= std_logic_vector(unsigned(s_axis_l0_tdata) + 3) & std_logic_vector(unsigned(s_axis_l0_tdata) + 2) & 
                   std_logic_vector(unsigned(s_axis_l0_tdata) + 1) & std_logic_vector(unsigned(s_axis_l0_tdata) + 0); -- data sent to AXI 
    
    p_fsm : process(clk_i)
        variable v_handshake : boolean;
    begin 
        if rising_edge(clk_i) then 
            if rst_n_i = '0' then 
                state <= ST_IDLE;
                done_o <= '0'; 
                bresp_err_r <= '0';
                addr_r <= unsigned(write_base_address_input);
                addr_end <= (others => '0'); 
                burst_end_addr <= (others => '0');
                start_reg <= '0'; 
            else 
                start_reg <= start_i; 
                
                case state is 
                    
                    when ST_IDLE => -- initial state 
                        if (start_i = '1' and start_reg = '0') then 
                            done_o <= '0';
                            bresp_err_r <= '0'; 
                            addr_r <= unsigned(write_base_address_input); 
                            addr_end <= unsigned(write_base_address_input) + resize(unsigned(total_bytes_i), G_ADDR_W);
                            state <= ST_AW;
                        end if;
                        
                    when ST_AW => --address write state 
                        if ing_awready_i = '1' then -- address write handshake 
                            -- get where the burst ends, addr_r is stable rn so burst_bytes is valid 
                            burst_end_addr <= addr_r + resize(burst_bytes, G_ADDR_W);
                            state <= ST_STREAM; 
                        end if;
                        
                    when ST_STREAM => -- data streams
                        v_handshake := (s_axis_l0_tvalid = '1' and ing_wready_i ='1'); 
                        if v_handshake then 
                            addr_r <= addr_r + C_BYTES_PER_BEAT; 
                            if (addr_r = burst_end_addr - C_BYTES_PER_BEAT) then --last beat of this burst 
                                state <= ST_B; 
                            end if;
                        end if;
                    
                    when ST_B => -- response state 
                        if (ing_bvalid_i = '1') then --write response handshake 
                            if (ing_bresp_i /= "00") then  --non-OKAY response 
                                bresp_err_r <= '1';
                                err_o <= bresp_err_r; 
                                state <= ST_IDLE; 
                            elsif (addr_r = addr_end) then --reached the end, whole transfer done 
                                done_o <= '1'; 
                                err_o <= bresp_err_r; 
                                state <= ST_IDLE; 
                            else 
                                state <= ST_AW; -- more data, issue next burst 
                            end if; 
                        end if; 
                    
                    when others => 
                        state <= ST_IDLE; 
                    
                end case; 
            end if;
        end if;
    end process p_fsm;

end architecture rtl;