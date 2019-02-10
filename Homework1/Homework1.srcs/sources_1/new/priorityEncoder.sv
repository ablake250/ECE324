//////////////////////////////////////////////////////////////////////////////////
// ECE 324 Homework 1: 4 to 2 bit priority encoder
// Alex Blake 24 Jan 2019
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module priorityEncoder(
    //ports
    input logic [3:0]x,
    output logic [1:0]y,
    output logic z
    );
    
    //logic assignment below
    assign z = x[0] | x[1] | x[2] | x[3] ;
    assign y[1]= x[2] | x[3];
    assign y[0] = (x[1] & ~x[2]) | x[3];
    
endmodule