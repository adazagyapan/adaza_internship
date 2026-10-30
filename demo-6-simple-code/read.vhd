-- this will (hopefully) be the AXI read master
-- it will issue bursts to PS DDR thru an HP port, accept return beats, and return data thru the ILA
-- jesus buddha allah help my code

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity read is
    generic (
        G_AXI_W : natural := 128; --data bus width 
        G_ADDR_W : natural := 49 -- hp port address width 
    );
    
    port (
        clk_i : in std_logic;
        rst_n_i : in std_logic; 
        
        start_i : in std_logic; 
        done_o : out std_logic; 
        err_o : out std_logic; 
        
        read_base_address_input : in std_logic_vector(G_ADDR_W-1 downto 0);
        
        total_bytes_i : in std_logic_vector(31 downto 0);
        
        -- read address channels 
        egr_araddr_o : out std_logic_vector(G_ADDR_W-1 downto 0);
        egr_arlen_o : out std_logic_vector(7 downto 0);
        egr_arvalid_o : out std_logic; 
        egr_arready_i : in std_logic;
        
        -- read data channels
        egr_rdata_i : in std_logic_vector(G_AXI_W-1 downto 0);
        egr_rresp_i : in std_logic_vector(1 downto 0);
        egr_rvalid_i : in std_logic; 
        egr_rready_o : out std_logic; 
        egr_rlast_i : in std_logic;
        
        -- observation stuff 
        rdata_lo_o : out std_logic_vector(31 downto 0); -- last beat so bits 31-0 of the last 4 words read 
        rdata_full_o : out std_logic_vector(G_AXI_W-1 downto 0); -- last full beat 
        beat_total_o : out std_logic_vector(7 downto 0) --beats received this run
    );
end read;

architecture rtl of read is

    -- states 
    type stateType is (ST_IDLE, ST_AR, ST_R);
    signal state : stateType := ST_IDLE;
    
    -- constants
    constant C_BYTES_PER_BEAT : natural := G_AXI_W/8; --16, how many bytes move in one beat. converts byte to beat count 
    constant PAGE_SIZE : unsigned(12 downto 0) := to_unsigned(4096,13); --4kB page
    
    -- control studd (not position) 
    signal start_reg : std_logic := '0'; 
    signal rresp_err_r : std_logic := '0'; 
    
    -- address and position stuff 
    -- there is no need for burst_end_r here, the slave marks the burst end with RLAST so read never computes it 
    signal addr_r : unsigned(G_ADDR_W-1 downto 0) := (others => '0'); 
    signal addr_end : unsigned(G_ADDR_W-1 downto 0) := (others =>'0');
    
    --observation stuff 
    signal beat_total_r : unsigned(7 downto 0) := (others => '0'); 
    signal rdata_cap_r : std_logic_vector(G_AXI_W-1 downto 0) := (others => '0');
    
    --combinational stuff derived from addresses 
    signal bytes_left : unsigned(G_ADDR_W-1 downto 0); --addr_end - addr_r 
    signal bytes_to_page_end : unsigned(12 downto 0); --bytes until the next 4KB boundary, max 4096 
    signal burst_bytes : unsigned(12 downto 0); --min(bytes_left, bytes_to_page_end), max 4096 = full page 
    signal burst_beats : unsigned(8 downto 0); -- burst bytes / 16 
    
begin
    
    -- the distances that bound the burst calculated from read addresses 
    bytes_left <= addr_end - addr_r; 
    bytes_to_page_end <= PAGE_SIZE - resize(addr_r(11 downto 0), 13); -- low 12 bits are the page offset 
    
    -- burst length in bytes = min(bytes_left, bytes_to_page_end) 
    process(bytes_left, bytes_to_page_end)
        variable m : unsigned(12 downto 0);
    begin 
        m := bytes_to_page_end;
        if bytes_left <= resize(m, bytes_left'length) then 
            m := resize(bytes_left, 13); 
        end if;
        burst_bytes <= m;
    end process;
    
    -- beat conversion for length output 
    burst_beats <= burst_bytes(12 downto 4); --divide by 16 
    
    -- outputs 
    egr_araddr_o <= std_logic_vector(addr_r);
    --ARLEN is 0 outside of ST_AR 
    egr_arlen_o <= std_logic_vector(resize(burst_beats-1, 8)) when state = ST_AR else (others => '0'); 
    egr_arvalid_o <= '1' when state = ST_AR else '0';
    egr_rready_o <= '1' when state = ST_R else '0';
    
    rdata_full_o <= rdata_cap_r;
    rdata_lo_o <= rdata_cap_r(31 downto 0);
    beat_total_o <= std_logic_vector(beat_total_r);
    err_o <= rresp_err_r;
    
    p_fsm : process(clk_i) is 
    begin 
        if rising_edge(clk_i) then 
            if rst_n_i = '0' then 
                state <= ST_IDLE; 
                done_o <= '0';
                rresp_err_r <= '0';
                addr_r <= (others => '0');
                addr_end <= (others => '0'); 
                beat_total_r <= (others => '0'); 
                rdata_cap_r <= (others => '0'); 
                start_reg <= '0';
            else 
                start_reg <= start_i;
                
                case state is 
                
                    when ST_IDLE => 
                        if (start_i = '1' and start_reg = '0') then 
                            done_o <= '0';
                            rresp_err_r <= '0';
                            beat_total_r <= (others => '0');
                            addr_r <= unsigned(read_base_address_input);
                            addr_end <= unsigned(read_base_address_input) + resize(unsigned(total_bytes_i),G_ADDR_W);
                            state <= ST_AR;
                        end if;
                        
                    when ST_AR => 
                        if (egr_arready_i = '1') then -- address read handshake 
                            state <= ST_R;
                        end if;
                        
                    when ST_R => --read beats
                         if (egr_rvalid_i = '1') then 
                            rdata_cap_r <= egr_rdata_i;
                            beat_total_r <= beat_total_r + 1; 
                            addr_r <= addr_r + C_BYTES_PER_BEAT;
                            
                            if (egr_rresp_i /= "00") then 
                                rresp_err_r <= '1'; 
                            end if; 
                            
                            if (egr_rlast_i = '1') then --slave marks ts
                                if (addr_r + C_BYTES_PER_BEAT = addr_end) then 
                                    done_o <= '1';
                                    state <= ST_IDLE;
                                else 
                                    state <= ST_AR; 
                                end if;
                            end if;
                        end if;
                    
                    when others => 
                        state <= ST_IDLE;
                        
                end case; 
            end if; 
        end if; 
    end process p_fsm;
            
end rtl;