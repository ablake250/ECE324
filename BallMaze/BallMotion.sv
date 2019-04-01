


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

logic maxTickRow; moveBallRow; moveBallRow_stg2;
logic maxTickColumn; moveBallColumn; moveBallColumn_stg2;
logic [1:0] ballColumnChange=2'b00, ballRowChange=2'b00;
logic ballColummVel; ballRowVel;

localparam STARTCOLUMN = 128;
localparam STARTROW = 188;

mod_m_counter #(.M(1350000)) ballRow(.clk(clk108MHz), .max_tick(maxTickRow), .q());
mod_m_counter #(.M(1350000)) ballColumn(.clk(clk108MHz), .max_tick(maxTickColumn), .q());

/*
always_ff @(posedge clk108MHz) begin

    moveBall <= maxTickRow;
    if (resetPressed) begin ballRowChange <=2'b00; ballColumnChange <= 2'b00; end
    else if (up & !left & !right) begin ballRowChange <= 2'b11; ballColumnChange <= 2'b00 end
    else if (up & left) begin ballRowChange <= 2'b11; ballColumnChange <= 2'b11; end
    else if (up & right) begin ballRowChange <= 2'b11; ballColumnChange <= 2'b01; end

    else if (down & !left & !right) begin ballRowChange <= 2'b01; ballColumnChange <= 2'b00; end
    else if (down & left) begin ballRowChange <= 2'b01; ballColumnChange <= 2'b11; end
    else if (down & right) begin ballRowChange <= 2'b01; ballColumnChange <= 2'b01; end
    else;

    moveBall_stg2 <= moveBall;

    if (resetPressed) begin ballColumn[7:0] = STARTCOLUMN; ballRow = STARTROW; end
    else if (moveBall_stg2) begin
        if ()
    end
end

*/

always_ff @(posedge clk108MHz) begin
    moveBallRow <= maxTickRow;
    if (resetPressed) ballRowChange = 2'b00;
    else if (up) bballRowChange = 2'b11;
    else if (down) ballRowChange = 2'b01;
    else;

    moveBallRow_stg2 <= moveBallRow;

    if (resetPressed) ballRow[7:0] = STARTCOLUMN;
    else if (moveBallRow_stg2) begin
        if (ballRowChange == 2'b11 & !wallAbove) ballRowVel <= ballRow - 1;
        else if (ballRowChange == 2'b01 & !wallBelow) ballRowVel <= ballRow + 1;
        else;
    end
end

always_ff @(posedge clk108MHz) begin
    moveBallColumn <= maxTickColumn;
    if (resetPressed) ballColumnChange = 2'b00;
    else if (left) ballColumnChange = 2'b11;
    else if (right) ballColumnChange = 2'b01;
    else;

    moveBallColumn_stg2 <= moveBallColumn;

    if (resetPressed) ballColumn[7:0] = STARTCOLUMN;
    else if (moveBallColumn_stg2) begin
        if (ballColumnChange == 2'b11 & !wallLeft & !) ballColummVel <= ballColummVel - 1;
        else if (ballColumnChange == 2'b01 & !wallRight) ballColummVel <= ballColummVel + 1;
        else;
    end
end

endmodule