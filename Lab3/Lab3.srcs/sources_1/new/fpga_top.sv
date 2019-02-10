`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//ECE 324 - Lab 3 Barrel Shifter
//Alex Blake Jameson Shaw
//Feb 5, 2019
//////////////////////////////////////////////////////////////////////////////////


module fpga_top(
    input logic [15:0] SW,      //define switches buttons and LEDs
    input logic BTNC,           //center button
    input logic BTNL,           //left button
    input logic BTNR,           //right button
    output logic [15:0]LED      //16bit LED bus
    );
    
barrelShifter bs0(
    .x(SW),                     //instantuates and links above hardware to barrelShifter module
    .bl(BTNL),
    .br(BTNR),
    .bc(BTNC),
    .y(LED)
    );
    
endmodule
