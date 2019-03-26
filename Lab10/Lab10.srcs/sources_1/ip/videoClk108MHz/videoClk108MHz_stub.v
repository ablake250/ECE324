// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Tue Mar 26 14:42:38 2019
// Host        : Alex-XPS running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {c:/Users/Axelb/Documents/School/WSU Spring 2019/ECE
//               324/Lab10/Lab10.srcs/sources_1/ip/videoClk108MHz/videoClk108MHz_stub.v}
// Design      : videoClk108MHz
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module videoClk108MHz(clk108MHz, CLK100MHZ)
/* synthesis syn_black_box black_box_pad_pin="clk108MHz,CLK100MHZ" */;
  output clk108MHz;
  input CLK100MHZ;
endmodule
