


module BallMotion(
    //Reset and clock signals
    input logic clk108MHz,
    input logic resetPressed,

    //Ball Inputs
    input logic up, down, left, right,
    input logic wallAbove, wallRight, wallLeft, wallBelow

    //Ball Outputs
    output logic [7:0] ballColumn = 1,
    output logic [7:0] ballRow = 1
);




endmodule