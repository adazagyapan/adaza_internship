--Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
--Date        : Mon Aug 10 11:08:31 2026
--Host        : ETM-LAB running 64-bit major release  (build 9200)
--Command     : generate_target AXIdesign_wrapper.bd
--Design      : AXIdesign_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity AXIdesign_wrapper is
  port (
    S_AXI_HP0_FPD_0_araddr : in STD_LOGIC_VECTOR ( 48 downto 0 );
    S_AXI_HP0_FPD_0_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP0_FPD_0_arlock : in STD_LOGIC;
    S_AXI_HP0_FPD_0_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_arready : out STD_LOGIC;
    S_AXI_HP0_FPD_0_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_aruser : in STD_LOGIC;
    S_AXI_HP0_FPD_0_arvalid : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awaddr : in STD_LOGIC_VECTOR ( 48 downto 0 );
    S_AXI_HP0_FPD_0_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP0_FPD_0_awlock : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_awready : out STD_LOGIC;
    S_AXI_HP0_FPD_0_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_awuser : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awvalid : in STD_LOGIC;
    S_AXI_HP0_FPD_0_bid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_bready : in STD_LOGIC;
    S_AXI_HP0_FPD_0_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_bvalid : out STD_LOGIC;
    S_AXI_HP0_FPD_0_rdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    S_AXI_HP0_FPD_0_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_rlast : out STD_LOGIC;
    S_AXI_HP0_FPD_0_rready : in STD_LOGIC;
    S_AXI_HP0_FPD_0_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_rvalid : out STD_LOGIC;
    S_AXI_HP0_FPD_0_wdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    S_AXI_HP0_FPD_0_wlast : in STD_LOGIC;
    S_AXI_HP0_FPD_0_wready : out STD_LOGIC;
    S_AXI_HP0_FPD_0_wstrb : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXI_HP0_FPD_0_wvalid : in STD_LOGIC;
    pl_clk0_0 : out STD_LOGIC;
    pl_resetn0_0 : out STD_LOGIC
  );
end AXIdesign_wrapper;

architecture STRUCTURE of AXIdesign_wrapper is
  component AXIdesign is
  port (
    pl_resetn0_0 : out STD_LOGIC;
    pl_clk0_0 : out STD_LOGIC;
    S_AXI_HP0_FPD_0_aruser : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awuser : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_awaddr : in STD_LOGIC_VECTOR ( 48 downto 0 );
    S_AXI_HP0_FPD_0_awlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP0_FPD_0_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_awlock : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_awvalid : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awready : out STD_LOGIC;
    S_AXI_HP0_FPD_0_wdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    S_AXI_HP0_FPD_0_wstrb : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXI_HP0_FPD_0_wlast : in STD_LOGIC;
    S_AXI_HP0_FPD_0_wvalid : in STD_LOGIC;
    S_AXI_HP0_FPD_0_wready : out STD_LOGIC;
    S_AXI_HP0_FPD_0_bid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_bvalid : out STD_LOGIC;
    S_AXI_HP0_FPD_0_bready : in STD_LOGIC;
    S_AXI_HP0_FPD_0_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_araddr : in STD_LOGIC_VECTOR ( 48 downto 0 );
    S_AXI_HP0_FPD_0_arlen : in STD_LOGIC_VECTOR ( 7 downto 0 );
    S_AXI_HP0_FPD_0_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_arlock : in STD_LOGIC;
    S_AXI_HP0_FPD_0_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_HP0_FPD_0_arvalid : in STD_LOGIC;
    S_AXI_HP0_FPD_0_arready : out STD_LOGIC;
    S_AXI_HP0_FPD_0_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    S_AXI_HP0_FPD_0_rdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    S_AXI_HP0_FPD_0_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_HP0_FPD_0_rlast : out STD_LOGIC;
    S_AXI_HP0_FPD_0_rvalid : out STD_LOGIC;
    S_AXI_HP0_FPD_0_rready : in STD_LOGIC;
    S_AXI_HP0_FPD_0_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_HP0_FPD_0_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component AXIdesign;
begin
AXIdesign_i: component AXIdesign
     port map (
      S_AXI_HP0_FPD_0_araddr(48 downto 0) => S_AXI_HP0_FPD_0_araddr(48 downto 0),
      S_AXI_HP0_FPD_0_arburst(1 downto 0) => S_AXI_HP0_FPD_0_arburst(1 downto 0),
      S_AXI_HP0_FPD_0_arcache(3 downto 0) => S_AXI_HP0_FPD_0_arcache(3 downto 0),
      S_AXI_HP0_FPD_0_arid(5 downto 0) => S_AXI_HP0_FPD_0_arid(5 downto 0),
      S_AXI_HP0_FPD_0_arlen(7 downto 0) => S_AXI_HP0_FPD_0_arlen(7 downto 0),
      S_AXI_HP0_FPD_0_arlock => S_AXI_HP0_FPD_0_arlock,
      S_AXI_HP0_FPD_0_arprot(2 downto 0) => S_AXI_HP0_FPD_0_arprot(2 downto 0),
      S_AXI_HP0_FPD_0_arqos(3 downto 0) => S_AXI_HP0_FPD_0_arqos(3 downto 0),
      S_AXI_HP0_FPD_0_arready => S_AXI_HP0_FPD_0_arready,
      S_AXI_HP0_FPD_0_arsize(2 downto 0) => S_AXI_HP0_FPD_0_arsize(2 downto 0),
      S_AXI_HP0_FPD_0_aruser => S_AXI_HP0_FPD_0_aruser,
      S_AXI_HP0_FPD_0_arvalid => S_AXI_HP0_FPD_0_arvalid,
      S_AXI_HP0_FPD_0_awaddr(48 downto 0) => S_AXI_HP0_FPD_0_awaddr(48 downto 0),
      S_AXI_HP0_FPD_0_awburst(1 downto 0) => S_AXI_HP0_FPD_0_awburst(1 downto 0),
      S_AXI_HP0_FPD_0_awcache(3 downto 0) => S_AXI_HP0_FPD_0_awcache(3 downto 0),
      S_AXI_HP0_FPD_0_awid(5 downto 0) => S_AXI_HP0_FPD_0_awid(5 downto 0),
      S_AXI_HP0_FPD_0_awlen(7 downto 0) => S_AXI_HP0_FPD_0_awlen(7 downto 0),
      S_AXI_HP0_FPD_0_awlock => S_AXI_HP0_FPD_0_awlock,
      S_AXI_HP0_FPD_0_awprot(2 downto 0) => S_AXI_HP0_FPD_0_awprot(2 downto 0),
      S_AXI_HP0_FPD_0_awqos(3 downto 0) => S_AXI_HP0_FPD_0_awqos(3 downto 0),
      S_AXI_HP0_FPD_0_awready => S_AXI_HP0_FPD_0_awready,
      S_AXI_HP0_FPD_0_awsize(2 downto 0) => S_AXI_HP0_FPD_0_awsize(2 downto 0),
      S_AXI_HP0_FPD_0_awuser => S_AXI_HP0_FPD_0_awuser,
      S_AXI_HP0_FPD_0_awvalid => S_AXI_HP0_FPD_0_awvalid,
      S_AXI_HP0_FPD_0_bid(5 downto 0) => S_AXI_HP0_FPD_0_bid(5 downto 0),
      S_AXI_HP0_FPD_0_bready => S_AXI_HP0_FPD_0_bready,
      S_AXI_HP0_FPD_0_bresp(1 downto 0) => S_AXI_HP0_FPD_0_bresp(1 downto 0),
      S_AXI_HP0_FPD_0_bvalid => S_AXI_HP0_FPD_0_bvalid,
      S_AXI_HP0_FPD_0_rdata(127 downto 0) => S_AXI_HP0_FPD_0_rdata(127 downto 0),
      S_AXI_HP0_FPD_0_rid(5 downto 0) => S_AXI_HP0_FPD_0_rid(5 downto 0),
      S_AXI_HP0_FPD_0_rlast => S_AXI_HP0_FPD_0_rlast,
      S_AXI_HP0_FPD_0_rready => S_AXI_HP0_FPD_0_rready,
      S_AXI_HP0_FPD_0_rresp(1 downto 0) => S_AXI_HP0_FPD_0_rresp(1 downto 0),
      S_AXI_HP0_FPD_0_rvalid => S_AXI_HP0_FPD_0_rvalid,
      S_AXI_HP0_FPD_0_wdata(127 downto 0) => S_AXI_HP0_FPD_0_wdata(127 downto 0),
      S_AXI_HP0_FPD_0_wlast => S_AXI_HP0_FPD_0_wlast,
      S_AXI_HP0_FPD_0_wready => S_AXI_HP0_FPD_0_wready,
      S_AXI_HP0_FPD_0_wstrb(15 downto 0) => S_AXI_HP0_FPD_0_wstrb(15 downto 0),
      S_AXI_HP0_FPD_0_wvalid => S_AXI_HP0_FPD_0_wvalid,
      pl_clk0_0 => pl_clk0_0,
      pl_resetn0_0 => pl_resetn0_0
    );
end STRUCTURE;
