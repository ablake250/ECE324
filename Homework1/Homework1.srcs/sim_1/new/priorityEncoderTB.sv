//////////////////////////////////////////////////////////////////////////////////
// ECE 324 Homework 1: 4 to 2 bit priority encoder
// Alex Blake 24 Jan 2019
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module priorityEncoderTB;
    //define test bench variables
    logic [3:0] x;
    logic [1:0] y;
    logic z;
    
    //initialize the encoder with above variables
    priorityEncoder UUT (
        .x(x),
        .y(y),
        .z(z)
    );
    
    
    //increment the input bus (x) by 1 through all possible combinations
    initial begin
        #10 x = 4'b0000; 
        #10 x = 4'b0001; 
        #10 x = 4'b0010; 
        #10 x = 4'b0011;
        #10 x = 4'b0100;  
        #10 x = 4'b0101;
        #10 x = 4'b0110; 
        #10 x = 4'b0111; 
        #10 x = 4'b1000; 
        #10 x = 4'b1001;
        #10 x = 4'b1010; 
        #10 x = 4'b1011; 
        #10 x = 4'b1100; 
        #10 x = 4'b1101; 
        #10 x = 4'b1110; 
        #10 x = 4'b1111;          
        #10 $stop;
    end
endmodule