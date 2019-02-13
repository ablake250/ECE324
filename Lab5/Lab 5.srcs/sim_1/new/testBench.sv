`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2019 03:52:00 PM
// Design Name: 
// Module Name: testBench
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


module testBench;

    logic clk, zero, one;
    logic [16:0]d, q, maxt, mint;

    assign zero = 0;
    assign one = 1;

    univ_bin_counter ubc0(
        .clk(clk),
        .syn_clear(zero),
        .load(zero),
        .en(one),
        .d(d),

        .q(q),
        .max_tick(maxt),
        .min_tick(mint)
    );


    initial begin
        for(int i=0; i<10;i++) begin
            #1  clk = ~clk;
        end

    $stop;
    end


endmodule
