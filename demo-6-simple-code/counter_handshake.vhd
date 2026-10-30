/*
The main purpose of "counter_handshake" is to help produce the data that we want to write in the PS DDR, which is
starting from 0 and ending at 63 by increasing by 1. The output m_axis_tdata_o gives 0,4,8,12,...,60, which is later
used in ct_ingest.vhd module to crate the streaming data 0,1,2,3,4,5,...,63.
*/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_handshake is

    generic(
    G_DATA_W : natural := 32; -- counter sample width in bits 
    G_MAX_CNT : natural := 64 -- until where the counter will produce data (from 0 to 63)
    );
    
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           write_en : out STD_LOGIC;
           
           max_cnt_i : in std_logic_vector(31 downto 0); --word count from vio
                     
           m_axis_tdata_o : out std_logic_vector(31 downto 0);
           m_axis_tvalid_o : out std_logic;
           m_axis_tready_i : in std_logic
           );
           
end counter_handshake;

architecture Behavioral of counter_handshake is

    type state_type is (ST_IDLE, ST_RUNNING, ST_DONE);
    
    signal state : state_type := ST_IDLE;
    signal cnt_r : unsigned(31 downto 0):= (others => '0');
    
    constant C_BYTES_PER_WORD : natural := G_DATA_W / 8; -- 4 bytes
    
    signal max_cnt_r : unsigned(31 downto 0) := (others => '0');

begin

    m_axis_tdata_o <= std_logic_vector(cnt_r);
    m_axis_tvalid_o <= '1' when state = ST_RUNNING else '0';
    write_en <= '1' when state = ST_RUNNING else '0';
    
    
    p_counter : process(clk)
        variable v_handshake : boolean;
    begin
        if rising_edge(clk) then
            if rst = '0' then -- low-active reset
            state <= ST_IDLE;
            cnt_r <= (others => '0');
        else
            case state is
                
                when ST_IDLE =>
                    cnt_r <= (others => '0');                    
                    if start = '1' and unsigned(max_cnt_i)/= 0 then
                        max_cnt_r <= unsigned(max_cnt_i);
                        state <= ST_RUNNING;
                    end if;
                    
                when ST_RUNNING =>
                    v_handshake := (m_axis_tready_i = '1');
                    if v_handshake then
                        if cnt_r = max_cnt_r - 4 then
                            state <= ST_DONE;
                        else
                            cnt_r <= cnt_r + 4; -- increase by 4 since four 32-bit data are combined together in 128-bit data sent to AXI
                        end if;
                    end if;
                    
                when ST_DONE =>
                    if start = '0' then
                        state <= ST_IDLE;
                    end if;
                    
                when others =>
                    state <= ST_IDLE;
            end case;
         end if;
      end if;
   end process;
end Behavioral;
