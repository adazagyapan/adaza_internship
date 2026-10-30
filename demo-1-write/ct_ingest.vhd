/*
The main purpose of "ct_ingest" is to get the data from the counter, put it in the form in which it will be sent to AXI, and to also create the addresses
that will be sent to AXI. Note that the 4KB boundaries are considered.
*/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ct_ingest is
    generic (
        G_WORD_W : natural := 32;    -- counter sample width in bits      
        G_AXI_W  : natural := 128;   -- AXI data width in bits    
        G_ADDR_W : natural := 49;    -- AXI address width in bits
        G_BURST : natural := 16      -- AXI burst length = 64/4 since we combine four 32-bit data into one 128-bit data 
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

        base_address_input : in std_logic_vector(48 downto 0); -- base addr

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
end entity ct_ingest;

architecture rtl of ct_ingest is

    type StateType is (ST_IDLE,  ST_AW, ST_STREAM, ST_B);
    signal state : StateType := ST_IDLE;
    
    constant C_TOTAL_BYTES : unsigned(31 downto 0) := to_unsigned(256,32); --16 * 16
    constant C_BYTES_PER_BEAT : natural := G_AXI_W / 8; --16
    constant PAGE_SIZE : unsigned(12 downto 0) := to_unsigned(4096,13); --since one page has 4096 bytes (4KB boundary)

    signal start_reg : std_logic := '0';   
    signal addr_r : unsigned(G_ADDR_W-1 downto 0) := unsigned(base_address_input); 
    signal beat_cnt_r : natural range 0 to 256 := 0;
    signal burst_len_r : unsigned(8 downto 0) := (others => '0');  
    signal bresp_err_r : std_logic := '0';
     
    signal remaining_bytes : unsigned(31 downto 0);    
    signal bytes_transferred : unsigned(31 downto 0);     
    signal offset_in_page : unsigned(11 downto 0);               -- lowest 12 bits of the input address
    signal bytes_to_boundary : unsigned(12 downto 0);            -- remaining bytes until the end of the page
    signal available_boundary_beats : unsigned(8 downto 0);      -- the number of beats left for the initial page
    signal remaining_beats : unsigned(8 downto 0);               -- the number of beats left to the next page
    signal calc_burst_beats : unsigned(8 downto 0);              -- decided number of beats to use
     

begin

    offset_in_page <= unsigned(addr_r(11 downto 0));                        -- lowest 12 bits of the input address
    bytes_to_boundary <= PAGE_SIZE - offset_in_page;                        -- remaining bytes until the end of the page
    bytes_transferred <= resize(burst_len_r & "0000", 32);                  -- adding "0000" is equal to multiplying by 16 = 128/8 
    available_boundary_beats <= resize(bytes_to_boundary(12 downto 4),9);   -- (12 downto 4) is for dividing by 16. The number of beats left for the initial page
    remaining_beats <= resize(remaining_bytes(12 downto 4), 9);             -- the number of beats left to the next page

    process(available_boundary_beats, remaining_beats)
    begin
        if(remaining_beats <= available_boundary_beats and remaining_beats <= to_unsigned(G_BURST, 9)) then
            calc_burst_beats <= remaining_beats;
        elsif (available_boundary_beats <= to_unsigned(G_BURST, 9)) then
            calc_burst_beats <= available_boundary_beats;
        else
            calc_burst_beats <= to_unsigned(G_BURST, 9);
        end if;
    end process;

    ing_wstrb_o  <= x"FFFF"; --all 128 bits are selected to be valid
    ing_awaddr_o <= std_logic_vector(addr_r);
    ing_awlen_o <= std_logic_vector(resize(calc_burst_beats - 1, 8));
    ing_awvalid_o <= '1' when state = ST_AW else '0';
    ing_wvalid_o    <= '1' when (state = ST_STREAM and s_axis_l0_tvalid = '1') else '0';
    ing_wlast_o <= '1' when (state = ST_STREAM  and beat_cnt_r = to_integer(burst_len_r)-1 ) else '0';
    ing_bready_o <= '1' when state = ST_B else '0';
    s_axis_l0_tready <= ing_wready_i when state = ST_STREAM else '0'; 
    
    ing_wdata_o <= std_logic_vector(unsigned(s_axis_l0_tdata) + 3) & std_logic_vector(unsigned(s_axis_l0_tdata) + 2)&
    std_logic_vector(unsigned(s_axis_l0_tdata) + 1)& std_logic_vector(unsigned(s_axis_l0_tdata) + 0);                    --data sent to AXI

    p_fsm : process(clk_i)
        variable v_handshake : boolean;
    begin 
        if rising_edge(clk_i) then

            if rst_n_i = '0' then
                state <= ST_IDLE;
                done_o <= '0';
                bresp_err_r <= '0';               
                addr_r <= unsigned(base_address_input); 
                beat_cnt_r <= 0;
                start_reg <= '0';                             
                remaining_bytes <= (others => '0');
                burst_len_r <= (others => '0');
            else
                start_reg <= start_i;
                
                case state is
            
                    when ST_IDLE => --initial state
                                                                                       
                        if (start_i = '1' and start_reg = '0') then 
                            done_o <= '0';
                            bresp_err_r <= '0';
                            addr_r <= unsigned(base_address_input); 
                            remaining_bytes <= C_TOTAL_BYTES;
                            beat_cnt_r <= 0;
                            state <= ST_AW;
                         end if;
                         
                     when ST_AW => -- address write state

                         if ing_awready_i = '1' then             -- if address write handshake
                            burst_len_r <= calc_burst_beats;                             
                            beat_cnt_r <= 0;                 
                            state <= ST_STREAM;                                                         
                         end if;
                        
                     when ST_STREAM => --where data streams

                        v_handshake := (s_axis_l0_tvalid = '1' and ing_wready_i = '1');
                        if v_handshake then
                            addr_r <= addr_r + C_BYTES_PER_BEAT;
                            beat_cnt_r <= beat_cnt_r + 1; 

                            if (beat_cnt_r = to_integer(burst_len_r) -1) then  
    
                                if(remaining_bytes > bytes_transferred) then
                                    remaining_bytes <= remaining_bytes - bytes_transferred;
                                else
                                    remaining_bytes <= (others => '0');
                                end if;
                                
                                state <= ST_B;                             
                            end if;
                        end if;
                         
                      when ST_B => --response state

                            if (ing_bvalid_i = '1') then       -- if write response handshake

                                if (ing_bresp_i /= "00") then  -- if ing_bresp_i is not equal to "00"
                                    bresp_err_r <= '1';
                                    state <= ST_IDLE;
   
                                elsif (remaining_bytes = 0) then
                                    done_o <= '1';
                                    state <= ST_IDLE;
   
                                else    
                                    state <= ST_AW;            -- if no error but there are still unsend data
                                end if;    
                            end if;

                        when others =>        
                            state <= ST_IDLE;   
                              
                     end case;
              end if;
           end if;

    end process p_fsm;
end architecture rtl;