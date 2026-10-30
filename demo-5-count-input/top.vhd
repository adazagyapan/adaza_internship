/*
IMPORTANT : 

1- Since PL sends 128 bits data to AXI and each in fact includes four 32-bit data from the counter, the base address for writing the counter data should be
selected at both VITIS IDE and VIO so that it ends with a '0'. For example, 0x07000030, 0x00001260, 0x10006000 are valid base addresses while addresses like
0x10000004, 0x00000068, 0x05001288 should not be selected. 

2- The input base address for PL selected in VITIS IDE (2nd input in VITIS) and the base address selected using VIO must be the same for the expected 
behaviour of the code.

3- In VITIS IDE, the value of the second input address must be greater or equal than the first input address.

4- The input base address for PL selected in VITIS IDE (2nd input in VITIS) cannot exceed 0x7FFF_FF00 since memory location 0x8000_0000 cannot be
accessed since it is used for PL AXI slave ports. Note that 0x8_0000_0000 and further can be used.
*/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is

    generic (
        G_WORD_W : natural := 32;    -- counter sample width in bits
        G_AXI_W  : natural := 128;   -- AXI data width in bits
        G_ADDR_W : natural := 49;    -- AXI address width in bits
        G_BURST : natural := 64      -- AXI burst length
    );

end top;

architecture Behavioral of top is

    signal awaddr_con_wire : std_logic_vector(G_ADDR_W-1 downto 0);
    signal awlen_con_wire : std_logic_vector(7 downto 0);
    signal awvalid_con_wire : std_logic;
    signal awready_con_wire : std_logic;
    signal wdata_con_wire : std_logic_vector(127 downto 0);
    signal wlast_con_wire : std_logic;
    signal wvalid_con_wire : std_logic;
    signal wready_con_wire : std_logic;
    signal bvalid_con_wire : std_logic;
    signal bresp_con_wire : std_logic_vector(1 downto 0);
    signal bready_con_wire : std_logic;
    
    signal araddr_con_wire : std_logic_vector(G_ADDR_W-1 downto 0);
    signal arlen_con_wire : std_logic_vector(7 downto 0);
    signal arsize_con_wire : std_logic_vector(2 downto 0);
    signal arburst_con_wire : std_logic_vector(1 downto 0);
    signal arcache_con_wire : std_logic_vector(3 downto 0);
    signal arvalid_con_wire : std_logic;
    signal arready_con_wire : std_logic;
    signal rdata_con_wire : std_logic_vector(127 downto 0);
    signal rresp_con_wire : std_logic_vector(1 downto 0);
    signal rlast_con_wire : std_logic;
    signal rvalid_con_wire : std_logic;
    signal rready_con_wire : std_logic;
    
    signal start_read : std_logic;
    signal done_read : std_logic;
    signal err_read : std_logic;
    signal rdata_lo : std_logic_vector(31 downto 0);
    signal beat_total : std_logic_vector(7 downto 0);
    
    signal wstrb_full : std_logic_vector(15 downto 0);

    signal rst_in : std_logic;

    signal vio_rst_n : std_logic_vector(0 downto 0);
    signal vio_start : std_logic_vector(1 downto 0);
    
       
    signal pl_reset : std_logic;
    signal pl_clock : std_logic := '0';
    signal start_write : std_logic; 
    signal done_write : std_logic;

    signal data_streaming : std_logic_vector(G_WORD_W-1 downto 0);
    signal axis_tvalid : std_logic := '1'; 
    signal axis_tready : std_logic;

    signal write_enable : std_logic; -- can be used in order to observe the write_en output of the counter module, has no other role
    
    signal awburst_con_wire : std_logic_vector(1 downto 0);
    signal awsize_con_wire : std_logic_vector(2 downto 0);
    signal awcache_con_wire : std_logic_vector(3 downto 0);
    
    -- demo 4
    signal write_base_address : std_logic_vector(48 downto 0); 
    signal read_base_address: std_logic_vector(48 downto 0);
    
    signal err_write : std_logic;
    
    -- demo 5
    signal word_count : std_logic_vector(23 downto 0);
    signal max_cnt_ext : std_logic_vector(31 downto 0);
    signal total_bytes : std_logic_vector(31 downto 0); --word count * 4 so total number of bytes

    attribute MARK_DEBUG : string; 
    attribute keep : string; 

    --what we want to observe using ILA
    attribute keep of start_write,data_streaming, awaddr_con_wire, awready_con_wire, awvalid_con_wire, wready_con_wire, wvalid_con_wire, 
        wdata_con_wire, wlast_con_wire, bready_con_wire, bvalid_con_wire, bresp_con_wire, done_write, err_write, start_read, araddr_con_wire, arready_con_wire, 
        arvalid_con_wire, rready_con_wire, rvalid_con_wire, rdata_con_wire, rlast_con_wire, rresp_con_wire, done_read, err_read : signal is "true";
    
                        
    attribute MARK_DEBUG of start_write,data_streaming, awaddr_con_wire, awready_con_wire, awvalid_con_wire, wready_con_wire, wvalid_con_wire, 
        wdata_con_wire, wlast_con_wire, bready_con_wire, bvalid_con_wire, bresp_con_wire, done_write, err_write, start_read, araddr_con_wire, arready_con_wire, 
        arvalid_con_wire, rready_con_wire, rvalid_con_wire, rdata_con_wire, rlast_con_wire, rresp_con_wire, done_read, err_read : signal is "true";
     
                                      
    component AXIdesign_wrapper is
        Port(
        pl_clk0_0 : out STD_LOGIC; 
        pl_resetn0_0 : out STD_LOGIC; 
        
        -- write stuff
        S_AXI_HP0_FPD_0_awaddr : in STD_LOGIC_VECTOR ( 48 downto 0 );
        S_AXI_HP0_FPD_0_awvalid : in STD_LOGIC;
        S_AXI_HP0_FPD_0_awready : out STD_LOGIC;
        S_AXI_HP0_FPD_0_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 ); 
        S_AXI_HP0_FPD_0_awlock : in STD_LOGIC;     
        S_AXI_HP0_FPD_0_bready : in STD_LOGIC;
        S_AXI_HP0_FPD_0_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
        S_AXI_HP0_FPD_0_bvalid : out STD_LOGIC;
        S_AXI_HP0_FPD_0_wdata : in STD_LOGIC_VECTOR ( 127 downto 0 ); 
        S_AXI_HP0_FPD_0_wlast : in STD_LOGIC;
        S_AXI_HP0_FPD_0_wready : out STD_LOGIC;
        S_AXI_HP0_FPD_0_wstrb : in STD_LOGIC_VECTOR ( 15 downto 0 );
        S_AXI_HP0_FPD_0_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
        S_AXI_HP0_FPD_0_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
        S_AXI_HP0_FPD_0_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
        S_AXI_HP0_FPD_0_wvalid : in STD_LOGIC;
        
        --read stuff
        S_AXI_HP0_FPD_0_araddr : in STD_LOGIC_VECTOR(48 downto 0);
        S_AXI_HP0_FPD_0_arlen : in STD_LOGIC_VECTOR(7 downto 0);
        S_AXI_HP0_FPD_0_arsize : in STD_LOGIC_VECTOR(2 downto 0);
        S_AXI_HP0_FPD_0_arburst : in STD_LOGIC_VECTOR(1 downto 0);
        S_AXI_HP0_FPD_0_arcache : in STD_LOGIC_VECTOR(3 downto 0);
        S_AXI_HP0_FPD_0_arlock : in STD_LOGIC;
        S_AXI_HP0_FPD_0_arvalid : in STD_LOGIC;
        S_AXI_HP0_FPD_0_arready : out STD_LOGIC;
        S_AXI_HP0_FPD_0_rdata : out std_logic_vector(127 downto 0);
        S_AXI_HP0_FPD_0_rresp : out std_logic_vector(1 downto 0);
        S_AXI_HP0_FPD_0_rlast : out std_logic;
        S_AXI_HP0_FPD_0_rvalid: out std_logic;
        S_AXI_HP0_FPD_0_rready : in std_logic     
        );
    end component AXIdesign_wrapper;
    
    component write is
    Port(
        clk_i       : in  std_logic; 
        rst_n_i     : in  std_logic; 
        
        ing_awaddr_o  : out std_logic_vector(G_ADDR_W-1 downto 0); 
        ing_awlen_o   : out std_logic_vector(7 downto 0); 
        ing_awvalid_o : out std_logic;
        ing_awready_i : in  std_logic;
        ing_wdata_o   : out std_logic_vector(G_AXI_W-1 downto 0); 
        ing_wstrb_o   : out std_logic_vector(G_AXI_W/8-1 downto 0); 
        ing_wlast_o   : out std_logic;
        ing_wvalid_o  : out std_logic;
        ing_wready_i  : in  std_logic;
        ing_bvalid_i  : in  std_logic;
        ing_bresp_i   : in  std_logic_vector(1 downto 0);
        ing_bready_o  : out std_logic;
        
        write_base_address_input : in std_logic_vector(48 downto 0); -- base addr
        
        total_bytes_i : in std_logic_vector(31 downto 0);
        
        start_i : in std_logic;
        done_o : out std_logic;
        err_o : out std_logic;
        s_axis_l0_tdata  : in  std_logic_vector(G_WORD_W-1 downto 0);
        s_axis_l0_tready : out std_logic;
        s_axis_l0_tvalid : in std_logic
        );
        
    end component write;


    component vio_0 is
    Port(
        clk : in std_logic;
        probe_in0 : in std_logic_vector(0 downto 0); --write_done
        probe_in1 : in std_logic_vector(31 downto 0); --wdata_con_wire
        probe_in2 : in std_logic;  --awready_con_wire
        probe_in3 : in std_logic_vector(48 downto 0); --awaddr_con_wire
        probe_in4 : in std_logic_vector(0 downto 0); --done_read
        probe_in5 : in std_logic_vector(0 downto 0); --err_read
        probe_in6 : in std_logic_vector(7 downto 0); --beat_total 
        probe_in7 : in std_logic_vector(31 downto 0); --rdata_lo 
        probe_in8 : in std_logic_vector(0 downto 0); --err_write
        
        
        probe_out0 : out std_logic_vector(0 downto 0); -- rst_n_i
        probe_out1 : out std_logic_vector(1 downto 0);  --start_i
        probe_out2 : out std_logic_vector(48 downto 0); -- write base addr
        probe_out3 : out std_logic_vector(48 downto 0); -- read base addr
        probe_out4 : out std_logic_vector(23 downto 0) -- word count
    );
    end component vio_0;


    component counter_handshake is
        generic(
        G_DATA_W : natural := 32;
        G_ADDR_W : natural := 49;
        G_MAX_CNT : natural := 64
        );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           write_en : out STD_LOGIC;

           m_axis_tdata_o : out std_logic_vector(31 downto 0);
           m_axis_tvalid_o : out std_logic;
           m_axis_tready_i : in std_logic;
           
           max_cnt_i : in std_logic_vector(31 downto 0)
           );
    end component counter_handshake;
    
    component read is
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
            
            read_base_address_input : in std_logic_vector(G_ADDR_W-1 downto 0);
            
            total_bytes_i : in std_logic_vector(31 downto 0);
            
            egr_araddr_o : out std_logic_vector(G_ADDR_W-1 downto 0);
            egr_arlen_o : out std_logic_vector(7 downto 0);
            egr_arvalid_o : out std_logic; 
            egr_arready_i : in std_logic;
            
            egr_rdata_i : in std_logic_vector(G_AXI_W-1 downto 0);
            egr_rresp_i : in std_logic_vector(1 downto 0);
            egr_rvalid_i : in std_logic; 
            egr_rready_o : out std_logic; 
            egr_rlast_i : in std_logic;
            
            rdata_lo_o : out std_logic_vector(31 downto 0); -- last beat so bits 31-0 of the last 4 words read 
            rdata_full_o : out std_logic_vector(G_AXI_W-1 downto 0); -- last full burst 
            beat_total_o : out std_logic_vector(7 downto 0) --beats received this run
        );
    end component read;
    
begin

pl_reset <= vio_rst_n(0);
rst_in <= pl_reset;
start_write <= vio_start(0);
awburst_con_wire <= "01"; --incrementing burst mode selected
awsize_con_wire <= "100"; --16 bytes selected
awcache_con_wire <= "0011"; --bufferable mode selected, allows interconnect FIFOs to buffer writes for max. throughput

arburst_con_wire <= "01"; -- INCR 
arsize_con_wire <= "100"; --16 bytes per beat 
arcache_con_wire <= "0011"; --bufferable 
start_read <= vio_start(1);

--demo 5 
max_cnt_ext <= std_logic_vector(resize(unsigned(word_count),32));
total_bytes <= std_logic_vector(resize(unsigned(word_count),30)) & "00"; -- word count * 4 

    AXI_inst : AXIdesign_wrapper
        port map (
            pl_clk0_0 => pl_clock,
            pl_resetn0_0 => pl_reset,
            
            S_AXI_HP0_FPD_0_awaddr => awaddr_con_wire,
            S_AXI_HP0_FPD_0_awvalid => awvalid_con_wire,
            S_AXI_HP0_FPD_0_awready => awready_con_wire,            
            S_AXI_HP0_FPD_0_awlen => awlen_con_wire,
            S_AXI_HP0_FPD_0_awlock => '0',
            S_AXI_HP0_FPD_0_bready => bready_con_wire,
            S_AXI_HP0_FPD_0_bresp => bresp_con_wire,
            S_AXI_HP0_FPD_0_bvalid => bvalid_con_wire,
            S_AXI_HP0_FPD_0_wdata => wdata_con_wire,
            S_AXI_HP0_FPD_0_wlast => wlast_con_wire,
            S_AXI_HP0_FPD_0_wready => wready_con_wire,
            S_AXI_HP0_FPD_0_wstrb => wstrb_full,
            S_AXI_HP0_FPD_0_awburst => awburst_con_wire,
            S_AXI_HP0_FPD_0_awsize => awsize_con_wire,
            S_AXI_HP0_FPD_0_awcache => awcache_con_wire,
            S_AXI_HP0_FPD_0_wvalid => wvalid_con_wire,
            
            S_AXI_HP0_FPD_0_araddr => araddr_con_wire,
            S_AXI_HP0_FPD_0_arlen => arlen_con_wire,
            S_AXI_HP0_FPD_0_arsize => arsize_con_wire,
            S_AXI_HP0_FPD_0_arburst => arburst_con_wire,
            S_AXI_HP0_FPD_0_arcache => arcache_con_wire,
            S_AXI_HP0_FPD_0_arlock => '0',
            S_AXI_HP0_FPD_0_arvalid => arvalid_con_wire,
            S_AXI_HP0_FPD_0_arready => arready_con_wire,
            S_AXI_HP0_FPD_0_rdata => rdata_con_wire,
            S_AXI_HP0_FPD_0_rresp => rresp_con_wire,
            S_AXI_HP0_FPD_0_rlast => rlast_con_wire,
            S_AXI_HP0_FPD_0_rvalid => rvalid_con_wire,
            S_AXI_HP0_FPD_0_rready => rready_con_wire
        );

    write_inst : write
        port map (
            clk_i => pl_clock,
            rst_n_i => rst_in,
            
            ing_awaddr_o => awaddr_con_wire,
            ing_awlen_o => awlen_con_wire,
            ing_awvalid_o => awvalid_con_wire,
            ing_awready_i => awready_con_wire,
            ing_wdata_o => wdata_con_wire,
            ing_wstrb_o => wstrb_full,
            ing_wlast_o => wlast_con_wire,
            ing_wvalid_o => wvalid_con_wire,
            ing_wready_i => wready_con_wire,
            ing_bvalid_i => bvalid_con_wire,
            ing_bresp_i => bresp_con_wire,
            ing_bready_o => bready_con_wire,
            
            write_base_address_input => write_base_address, 
            
            total_bytes_i => total_bytes,
            
            start_i => start_write,
            done_o => done_write,
            err_o => err_write,
            s_axis_l0_tdata => data_streaming,
            s_axis_l0_tready => axis_tready ,
            s_axis_l0_tvalid => axis_tvalid
        );
        
    read_inst : read
        generic map (
            G_AXI_W => G_AXI_W,
            G_ADDR_W => G_ADDR_W,
            G_BURST => 16 
        )
        port map(
            clk_i => pl_clock,
            rst_n_i => rst_in,
            start_i => start_read,
            done_o => done_read,
            err_o => err_read,
            
            read_base_address_input => read_base_address,
            
            total_bytes_i => total_bytes,
            
            egr_araddr_o => araddr_con_wire,
            egr_arlen_o => arlen_con_wire,
            egr_arvalid_o => arvalid_con_wire,
            egr_arready_i => arready_con_wire,
            
            egr_rdata_i => rdata_con_wire,
            egr_rresp_i => rresp_con_wire,
            egr_rlast_i => rlast_con_wire,
            egr_rvalid_i => rvalid_con_wire,
            egr_rready_o => rready_con_wire,
            
            rdata_lo_o => rdata_lo,
            rdata_full_o => open,
            beat_total_o => beat_total
        );

    vio_inst : vio_0
        port map(
            clk => pl_clock,
            probe_in0(0) => done_write,
            probe_in1 => wdata_con_wire(31 downto 0),
            probe_in2 => awready_con_wire,
            probe_in3 => awaddr_con_wire,
            probe_in4(0) => done_read,
            probe_in5(0) => err_read,
            probe_in6 => beat_total,
            probe_in7 => rdata_lo,
            probe_in8(0) => err_write,
            
            probe_out0 => vio_rst_n,
            probe_out1 => vio_start,
            probe_out2 => write_base_address,
            probe_out3 => read_base_address,
            probe_out4 => word_count
        );

    counter_handshake_inst : counter_handshake
        port map(
            clk => pl_clock,
            rst => pl_reset,
            start => start_write,
            write_en => write_enable,  
            m_axis_tdata_o => data_streaming, 
            m_axis_tvalid_o => axis_tvalid,
            m_axis_tready_i => axis_tready,
            max_cnt_i => max_cnt_ext
        );        

end Behavioral;
