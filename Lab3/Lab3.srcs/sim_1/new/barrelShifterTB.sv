`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/26/2019 09:11:31 PM
// Design Name: 
// Module Name: barrelShifterTB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module barrelShifterTB();

    logic [15:0] x;
    logic bl;
    logic br;
    logic bc;
    logic [15:0] y;
    
    
    barrelShifter UUT(
    
        .x(x),
        .bl(bl),
        .br(br),
        .bc(bc),
        .y(y)
    );
    
    initial begin
        #10 x=16'b0000000111111111; br=1; bl=0; bc=0;
        #10 x=16'b0000000111111111; br=0; bl=1; bc=0;
        #10 x=16'b0000000111111111; br=1; bl=0; bc=1;
        #10 x=16'b0000000111111111; br=0; bl=1; bc=1;
        #10 $stop;        
    end
    
endmodule
