-- this will (hopefully) be the AXI read master
-- it will issue bursts to PS DDR thru an HP port, accept return beats, and return data thru the ILA
-- jesus buddha allah help my code

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity read is
    generic (
        G_AXI_W : natural := 128; --data bus width 
        G_ADDR_W : natural := 49; -- hp port address width 
        G_BURST : natural := 16 -- max no. of bursts
    );
    
    port (
        clk_i : in std_logic;
        rst_n_i : in std_logic; 
        
        start_i : in std_logic; 
        done_o : out std_logic; 
        err_o : out std_logic; 
        
        base_address_input : in std_logic_vector(G_ADDR_W-1 downto 0);
        
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
        rdata_full_o : out std_logic_vector(G_AXI_W-1 downto 0); -- last full burst 
        beat_total_o : out std_logic_vector(7 downto 0) --beats received this run
    );
end read;

architecture rtl of read is
    type stateType is (ST_IDLE, ST_AR, ST_R);
    signal state : stateType := ST_IDLE;
    
    constant C_TOTAL_BYTES : unsigned(31 downto 0) := to_unsigned(256, 32); -- ts is loaded to remaining_bytes 
    constant C_BYTES_PER_BEAT : natural := G_AXI_W/8; --16, how many bytes move in one beat. converts byte to beat count 
    
    signal start_reg : std_logic := '0'; -- i'll do start_i='1' and start_reg = '0' so a start signal held high by vio triggers exactly one run
    signal addr_r : unsigned(G_ADDR_W-1 downto 0) := (others => '0'); --current AXI address, incremented by 16 on every beat
    signal beat_cnt_r : natural range 0 to 256 := 0; -- beats within the current burst. one burst has 16 beats, and 16 beats in total send the total 256 bytes. so all this is sent in one single burst and 16 beats in that burst.
    signal beat_total_r : unsigned(7 downto 0) := (others => '0'); -- counts beats across the whole run, but it doesnt rlly matter because we're sending everything in one burst so beat total and beat cnt become the same thing 
    signal burst_len_r : unsigned(8 downto 0) := (others => '0');  -- the no. of beats the burrent burst is issued with 
    signal remaining_bytes : unsigned(31 downto 0) := (others => '0');  -- how many bytes still needed gettinmg 
    signal bytes_transferred : unsigned(31 downto 0); -- burst_len_r * 16, amount to subtract from remaining bytes 
    signal rresp_err_r : std_logic := '0'; -- error yes or no 
    
    signal rdata_cap_r : std_logic_vector(G_AXI_W-1 downto 0) := (others => '0'); -- the most rcent beat's data 
    
    -- paging stuff same as ingest 
    constant PAGE_SIZE : unsigned(12 downto 0) := to_unsigned(4096, 13); -- paging boundary 
    signal offset_in_page : unsigned(11 downto 0); -- low 12 beats of the address, so position within the current page
    signal bytes_to_boundary : unsigned(12 downto 0); -- 4096 minus offset_in_page 
    
    signal available_boundary_beats : unsigned(8 downto 0); -- converts byte quantities into beats, remaining beats till next page 
    signal remaining_beats : unsigned(8 downto 0); -- total remaining beats
    signal calc_burst_beats : unsigned(8 downto 0); --minimum of beats remaining, beats until boundary and G_BURST 
    
begin
    -- paging stuff 
    offset_in_page <= unsigned(addr_r(11 downto 0)); 
    bytes_to_boundary <= PAGE_SIZE - offset_in_page; -- 4096dan 16 16 art?r?lan de?er ç?kart?l?yor, kaç byte kald??? hesaplan?yo  
    bytes_transferred <= resize(burst_len_r & "0000", 32); -- beats * 16 because one beat carries 16 bytes 
    
    available_boundary_beats <= resize(bytes_to_boundary(12 downto 4), 9); --available bytes converted to beats, so divided by 16 
    remaining_beats <= resize(remaining_bytes(12 downto 4), 9); 
    
    -- this changes the burst length so that the burst stops the moment we reach the end of the page or not depending on constant burst length, total remaining beats and remaining beats till the end of page
    process(available_boundary_beats, remaining_beats)
    begin
        if (remaining_beats <= available_boundary_beats and remaining_beats <= to_unsigned(G_BURST, 9)) then 
            calc_burst_beats <= remaining_beats;
        elsif (available_boundary_beats <= to_unsigned(G_BURST, 9)) then 
            calc_burst_beats <= available_boundary_beats;
        else --  
            calc_burst_beats <= to_unsigned(G_BURST, 9);
        end if;
    end process;
    
    -- AXI stuff 
    egr_araddr_o <= std_logic_vector(addr_r); 
    egr_arlen_o <= std_logic_vector(resize(calc_burst_beats-1, 8));
    egr_arvalid_o <= '1' when state = ST_AR else '0'; 
    
    egr_rready_o <= '1' when state = ST_R else '0'; 
    
    rdata_full_o <= rdata_cap_r;
    rdata_lo_o <= rdata_cap_r(31 downto 0); 
    beat_total_o <= std_logic_vector(beat_total_r); 
    err_o <= rresp_err_r;
    
    -- state machine 
    p_fsm : process(clk_i) is 
    begin
        if rising_edge(clk_i) then
            if rst_n_i = '0' then 
                state <= ST_IDLE;
                done_o <= '0';
                rresp_err_r <= '0';
                addr_r <= (others => '0');
                beat_cnt_r <= 0;
                beat_total_r <= (others => '0'); 
                start_reg <= '0'; 
                remaining_bytes <= (others => '0');
                burst_len_r <= (others => '0');
                rdata_cap_r <= (others => '0');
            else 
                start_reg <= start_i;
                
                case state is 
                    when ST_IDLE => 
                        if (start_i = '1' and start_reg = '0') then 
                            done_o <= '0';
                            rresp_err_r <= '0';
                            addr_r <= unsigned(base_address_input);
                            beat_cnt_r <= 0; 
                            beat_total_r <= (others => '0');
                            remaining_bytes <= C_TOTAL_BYTES;
                            state <= ST_AR; 
                        end if; 
                    
                    when ST_AR => 
                        if (egr_arready_i = '1') then 
                            burst_len_r <= calc_burst_beats; -- calc_burst_beats de?i?ecek o yüzden burst len'e assignlad?k
                            beat_cnt_r <= 0;
                            state <= ST_R;
                        end if;
                        
                    when ST_R =>
                        if (egr_rvalid_i = '1') then
                            rdata_cap_r <= egr_rdata_i;
                            beat_cnt_r <= beat_cnt_r + 1; 
                            beat_total_r <= beat_total_r + 1; -- her beat 16 byte yani 4 say?, beati okuyup data cape koyup yeni beate ve yeni adrese geçiyoruz
                            addr_r <= addr_r + C_BYTES_PER_BEAT; --adresi 16 16 art?r?caz
                            
                            if (egr_rresp_i /= "00") then 
                                rresp_err_r <= '1';
                            end if;
                            
                            if (egr_rlast_i = '1') then 
                                if (remaining_bytes > bytes_transferred) then   
                                    remaining_bytes <= remaining_bytes - bytes_transferred; 
                                    state <= ST_AR;
                                else 
                                    remaining_bytes <= (others => '0');
                                    done_o <= '1';
                                    state <= ST_IDLE;
                                end if;
                            end if;
                        end if;
                    
                    when others =>
                        state <= ST_IDLE;
                end case;
            end if;
        end if;
    end process;
end rtl;

--proc emit_probe {core n netbase width} {
 --   set nets {}
  --  for {set i 0} {$i < $width} {incr i} {lappend nets "${netbase}\[$i\]"}
  --  puts "create_debug_port $core probe"
 --   puts "set_property port_width $width \[get_debug_ports $core/probe$n\]"
  --  puts "set_property PROBE_TYPE DATA_AND_TRIGGER \[get_debug_ports $core/probe$n\]"
  --  puts "connect_debug_port $core/probe$n \[get_nets \[list [join $nets " "]\]\]"
--}
--emit_probe u_ila_0 20 araddr_con_wire 49
--emit_probe u_ila_0 21 rdata_con_wire 32