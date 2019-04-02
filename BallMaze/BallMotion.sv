


module BallMotion(
    //Reset and clock signals
    input logic clk108MHz,
    input logic resetPressed,

    //Ball Inputs
    input logic up, down, left, right,
    input logic wallAboveball, wallRightOfball, wallLeftOfball, wallBelowball,

    //Ball Outputs
    output logic [7:0] ballColumn,
    output logic [7:0] ballRow
);

/*
logic maxTickRow; moveBallRow; moveBallRow_stg2;
logic maxTickColumn; moveBallColumn; moveBallColumn_stg2;
logic [1:0] ballColumnChange=2'b00, ballRowChange=2'b00;
logic ballColummVel; ballRowVel;
*/

//Acceleration Logic Declarations
logic [4:0] xAcceleration, YAcceleration;
logic [4:0] xAccel_stg2, yAccel_stg2;
logic xAccelPositive, yAccelPositive;
logic xAccelPos_stg2, yAccelPos_stg2;

//Velocity Logic Declarations
logic [4:0] xVelocity, yVelocity;
logic [4:0] xVel_stg2, yVel_stg2
logic xVelPos, yVelPos;
logic xVelPos_stg2, yVelPos_stg2;


localparam START_X = 128;
localparam START_Y = 188;


logic maxTickX, maxTickY;

mod_m_counter #(.M(1350000)) ballRowTick(.clk(clk108MHz), .max_tick(maxTickY), .q());
mod_m_counter #(.M(1350000)) ballColumnTick(.clk(clk108MHz), .max_tick(maxTickX), .q());

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
/*
always_ff @(posedge clk108MHz) begin
    moveBallRow <= maxTickRow;
    if (resetPressed) ballRowChange = 2'b00;
    else if (up) bballRowChange = 2'b11;
    else if (down) ballRowChange = 2'b01;
    else;

    moveBallRow_stg2 <= moveBallRow;

    if (resetPressed) ballRow[7:0] = STARTCOLUMN;
    else if (moveBallRow_stg2) begin
        if (ballRowChange == 2'b11 & !wallAboveball) ballRowVel <= ballRow - 1;
        else if (ballRowChange == 2'b01 & !wallBelowball) ballRowVel <= ballRow + 1;
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
        if (ballColumnChange == 2'b11 & !wallLeftofball & !) ballColummVel <= ballColummVel - 1;
        else if (ballColumnChange == 2'b01 & !wallRightofball) ballColummVel <= ballColummVel + 1;
        else;
    end
end
*/

///////////////////////////////////////////////////////////////////////////////////
//Acceleration of Ball
///////////////////////////////////////////////////////////////////////////////////

//x-axis Acceleration
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        xAccelPositive <= 1;
    end
    else if(maxTickX) begin
        if (right & (xAccelPositive == 0) & (xAcceleration == 1)) begin
            xAccelPositive <= 1;
            xAcceleration <= xAcceleration + 1;
        end
        else if (right & (xAccelPositive == 1) & !(xAcceleration == 4'b1111)) begin
            xAcceleration <= xAcceleration + 1;
        end
        else if (right & (xAccelPositive==0) & (xAcceleration > 1))begin
            xAcceleration <= xAcceleration - 1;
        end
        else if (left & (xAccelPositive == 1) & (xAcceleration == 0)) begin
            xAccelPositive <= 0;
            xAcceleration <= xAcceleration + 1;
        end
        else if (left & (xAccelPositive == 0) & !(xAcceleration == 4'b1111)) begin
            xAcceleration <= xAcceleration + 1;
        end
        else if (left & (xAccelPositive == 1) & (xAcceleration > 0)) begin
            xAcceleration <= xAcceleration - 1;
        end
    end
    xAccel_stg2 <= xAcceleration;
    xAccelPos_stg2 <= xAccelPositive;
end

//y-axis Acceleration
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        yAccelPositive <= 1;
    end
    else if(maxTickY) begin
        if (down & (yAccelPositive == 0) & (YAcceleration == 1)) begin
            yAccelPositive <= 1;
            YAcceleration <= YAcceleration + 1;
        end
        else if (down & (yAccelPositive == 1) & !(YAcceleration == 4'b1111)) begin
            YAcceleration <= YAcceleration + 1;
        end
        else if (down & (yAccelPositive==0) & (YAcceleration > 1))begin
            YAcceleration <= YAcceleration - 1;
        end
        else if (up & (yAccelPositive == 1) & (YAcceleration == 0)) begin
            yAccelPositive <= 0;
            YAcceleration <= YAcceleration + 1;
        end
        else if (up & (yAccelPositive == 0) & !(YAcceleration == 4'b1111)) begin
            YAcceleration <= YAcceleration + 1;
        end
        else if (up & (yAccelPositive == 1) & (YAcceleration > 0)) begin
            YAcceleration <= YAcceleration - 1;
        end
    end
    yAccel_stg2 <= YAcceleration;
    yAccelPos_stg2 <= yAccelPositive;
end

////////////////////////////////////////////////////////////////////////////////////
//Velocity of Ball
////////////////////////////////////////////////////////////////////////////////////

//x-axis Velocity
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        xVelocity <= 0;
        xVelPos <= 1;
    end
    else if(maxTickY)
        if (xVelPos==0) begin
            if((xVelocity <= xAccel_stg2) & (xAccelPos_stg2)) begin
                xVelocity <= xAccel_stg2 - xVelocity;
                xVelPos <= 1;
            end
            else if (({1'b0, xVelocity + xAccelPos_stg2} >= 4'b1111) & !(xAccelPos_stg2)) begin
                xVelocity <= 4'b1111;
            end
            else if (!xAccelPos_stg2) xVelocity <= xVelocity + xAccel_stg2;
            else if (xAccelPos_stg2) xVelocity <= xVelocity - xAccel_stg2;
        end
        else if (xVelPos == 1) begin
            if ((xVelocity <= xAccel_stg2) & !(xAccelPos_stg2))
                xVelocity <= xAccel_stg2 - xVelocity;
                xVelPos <= 0;
            end
             else if (({1'b0, xVelocity + xAccelPos_stg2} >= 4'b1111) & (xAccelPos_stg2)) begin
                xVelocity <= 4'b1111;
            end
            else if (!xAccelPos_stg2) xVelocity <= xVelocity - xAccel_stg2;
            else if (xAccelPos_stg2) xVelocity <= xVelocity + xAccel_stg2;
        end
    end

    xVel_stg2 <= xVelocity;
end

//y-axis Velocity
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        yVelocity <= 0;
        yVelPos <= 1;
    end
    else if(maxTickY)

    end
end


///////////////////////////////////////////////////////////////////////////////////
//Position of Ball
///////////////////////////////////////////////////////////////////////////////////

//x-axis Velocity
always_ff @(posedge clk108MHz) begin
    //ballColumn <= 80;
    if (resetPressed) begin
        ballColumn = xVel_stg2;
    end

end

//y-axis Velocity
always_ff @(posedge clk108MHz) begin
    ballRow <= 80;
    if (resetPressed) begin

    end
end

endmodule