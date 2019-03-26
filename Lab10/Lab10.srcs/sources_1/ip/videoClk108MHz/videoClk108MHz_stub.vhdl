-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
-- Date        : Tue Mar 26 14:42:38 2019
-- Host        : Alex-XPS running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub {c:/Users/Axelb/Documents/School/WSU Spring 2019/ECE
--               324/Lab10/Lab10.srcs/sources_1/ip/videoClk108MHz/videoClk108MHz_stub.vhdl}
-- Design      : videoClk108MHz
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity videoClk108MHz is
  Port ( 
    clk108MHz : out STD_LOGIC;
    CLK100MHZ : in STD_LOGIC
  );

end videoClk108MHz;

architecture stub of videoClk108MHz is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk108MHz,CLK100MHZ";
begin
end;
