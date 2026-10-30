
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- this xounts AXI clock cycles from the rising edge of start_i until done_i is seen 
-- and then gets the total. cycles_o holds the duration of the last completed run. 
-- time = cycles_o / f_clk, throughput = N_bytes/time

entity timer is
    
    generic(
    G_W : natural := 32 --ts is counter width, considering the AXI PL clock it should cover around 4.98e9 cycles
    );
    
    port(
        clk_i : in std_logic;
        rst_n_i : in std_logic;
        start_i : in std_logic;
        done_i : in std_logic;
        cycles_o : out std_logic_vector(G_W-1 downto 0)
    );
    
end timer;

architecture rtl of timer is

    signal cnt : unsigned(G_W-1 downto 0) := (others => '0');
    signal get : unsigned(G_W-1 downto 0) := (others => '0');
    signal running : std_logic := '0';
    signal start_d : std_logic := '0';
    
begin
    cycles_o <= std_logic_vector(get);
    
    process(clk_i)
    begin 
        if rising_edge(clk_i) then
            if rst_n_i = '0' then  
                cnt <= (others => '0');
                get <= (others => '0'); 
                running <= '0';
                start_d <= '0';
            else 
                start_d <= start_i;
                
                if (start_i = '1' and start_d = '0') then --rising edge, so new run 
                    cnt <= (others => '0');
                    running <= '1';
                elsif running = '1' then 
                    if done_i = '1' then 
                        get <= cnt;
                        running <= '0';
                    else 
                        cnt <= cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end rtl;
