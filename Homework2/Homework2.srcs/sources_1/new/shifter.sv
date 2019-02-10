`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//ECE 324 Homework2: 8 bit Shifter 
//Alex Blake Jan 28 2019
//////////////////////////////////////////////////////////////////////////////////


module shifter(
    input [7:0] data,   //8 bit input
    input [2:0] shift,  //3 bit shift select
    output [7:0] shout  //8 bit output (shifted)
    );
    
    assign shout = data >> shift;   //shifts right by the shift digit
    
endmodule
