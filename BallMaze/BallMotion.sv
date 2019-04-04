


module BallMotion(
    //Reset and clock signals
    input logic clk108MHz,
    input logic resetPressed,

    //

    //Ball Inputs
    input logic up, down, left, right,
    input logic wallAboveball, wallRightOfball, wallLeftOfball, wallBelowball,

    //Ball Outputs
    output logic [7:0] ballColumn,
    output logic [7:0] ballRow,

    //output temp. x and y to find walls

    output logic [7:0] AN,               // anodes of the 7-segment displays
    output logic DP,CG,CF,CE,CD,CC,CB,CA
);

/*
logic maxTickRow; moveBallRow; moveBallRow_stg2;
logic maxTickColumn; moveBallColumn; moveBallColumn_stg2;
logic [1:0] ballColumnChange=2'b00, ballRowChange=2'b00;
logic ballColummVel; ballRowVel;
*/

//Acceleration Logic Declarations
logic [3:0] xAcceleration, YAcceleration;
logic [3:0] xAccel_stg2, yAccel_stg2;
logic xAccelPositive, yAccelPositive;
logic xAccelPos_stg2, yAccelPos_stg2;

//Velocity Logic Declarations
logic [3:0] xVelocity, yVelocity;
logic [3:0] xVel_stg2, yVel_stg2;
logic xVelPos, yVelPos;
logic xVelPos_stg2, yVelPos_stg2;

//Position Logic Declarations
logic [7:0] xCoord, yCoord;

//local parameters
localparam START_X = 128;
localparam START_Y = 188;

//Seven-segment display
logic [7:0] sseg7, sseg6, sseg5, sseg4, sseg3, sseg2, sseg1, sseg0;

//logic for max_tick outputs of modulo counters below:
logic maxTick;

mod_m_counter #(.M(10000000)) ballRowTick(.clk(clk108MHz), .max_tick(maxTick), .q());


///////////////////////////////////////////////////////////////////////////////////
//Acceleration of Ball
///////////////////////////////////////////////////////////////////////////////////

//x-axis Acceleration
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        xAccelPositive <= 1;
        xAccelPos_stg2 <= 1;
        xAcceleration <= 0;
        xAccel_stg2 <= 0;
    end
    else if(maxTick) begin
        //negative to positive transition
        if (right & (xAccelPositive == 0) & (xAcceleration == 1)) begin
            xAccelPositive <= 1;
            xAcceleration <= 0;
        end
        //increasing positive acceleration
        else if (right & (xAccelPositive == 1) & !(xAcceleration == 4'b1111)) begin
            xAcceleration <= xAcceleration + 1;
        end
        //decreasing negative acceleration
        else if (right & (xAccelPositive==0) & (xAcceleration > 0))begin
            xAcceleration <= xAcceleration - 1;
        end
        //positive to negative transition
        else if (left & (xAccelPositive == 1) & (xAcceleration == 0)) begin
            xAccelPositive <= 0;
            xAcceleration <= 1;
        end
        //increasing negative acceleration
        else if (left & (xAccelPositive == 0) & !(xAcceleration == 4'b1111)) begin
            xAcceleration <= xAcceleration + 1;
        end
        // decreasing positive acceleration
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
        YAcceleration <= 0;
        yAccelPos_stg2 <= 1;
        yAccel_stg2 <= 0;
        
    end
    else if(maxTick) begin
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
        xVelPos_stg2 <= 1;
        xVel_stg2 <= 0;
    end
    else if(maxTick) begin
        if (xVelPos==0) begin
            if((xVelocity <= xAccel_stg2) & (xAccelPos_stg2)) begin
                xVelocity <= xAccel_stg2 - xVelocity;
                xVelPos <= 1;
            end
            else if ((({1'b0, xVelocity} + {1'b0, xAccel_stg2}) >= 4'b1111) & !(xAccelPos_stg2)) begin
                xVelocity <= 4'b1111;
            end
            else if (!xAccelPos_stg2) begin 
                xVelocity <= xVelocity + xAccel_stg2;
            end
            else if (xAccelPos_stg2) begin 
                xVelocity <= xVelocity - xAccel_stg2;
            end
        end
        else if (xVelPos == 1) begin
            if ((xVelocity <= xAccel_stg2) & !(xAccelPos_stg2)) begin
                xVelocity <= xAccel_stg2 - xVelocity;
                xVelPos <= 0;
            end
            else if ((({1'b0, xVelocity} + {1'b0,xAccel_stg2}) > 4'b1111) & (xAccelPos_stg2)) begin
                xVelocity <= 4'b1111;
            end

            else if (!xAccelPos_stg2) begin 
                xVelocity <= xVelocity - xAccel_stg2;
            end
            else if (xAccelPos_stg2) begin 
                xVelocity <= xVelocity + xAccel_stg2;
            end
        end
    end
    xVel_stg2 <= xVelocity;
    xVelPos_stg2 <= xVelPos;
end

//y-axis Velocity
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        yVelocity <= 0;
        yVelPos <= 1;
        yVelPos_stg2 <= 1;
        yVel_stg2 <= 0;
    end
    else if(maxTick) begin
        if (yVelPos==0) begin
            if((yVelocity <= yAccel_stg2) & (yAccelPos_stg2)) begin
                yVelocity <= yAccel_stg2 - yVelocity;
                yVelPos <= 1;
            end
            else if ((({1'b0, yVelocity} + {1'b0, yAccel_stg2}) >= 4'b1111) & !(yAccelPos_stg2)) begin
                yVelocity <= 4'b1111;
            end
            else if (!yAccelPos_stg2) begin 
                yVelocity <= yVelocity + yAccel_stg2;
            end
            else if (yAccelPos_stg2) begin 
                yVelocity <= yVelocity - yAccel_stg2;
            end
        end
        else if (yVelPos == 1) begin
            if ((yVelocity <= yAccel_stg2) & !(yAccelPos_stg2)) begin
                yVelocity <= yAccel_stg2 - yVelocity;
                yVelPos <= 0;
            end
            else if ((({1'b0, yVelocity} + {1'b0,yAccel_stg2}) > 4'b1111) & (yAccelPos_stg2)) begin
                yVelocity <= 4'b1111;
            end

            else if (!yAccelPos_stg2) begin 
                yVelocity <= yVelocity - yAccel_stg2;
            end
            else if (yAccelPos_stg2) begin 
                yVelocity <= yVelocity + yAccel_stg2;
            end
        end
    end
    yVel_stg2 <= yVelocity;
    yVelPos_stg2 <= yVelPos;
end


///////////////////////////////////////////////////////////////////////////////////
//Position of Ball
///////////////////////////////////////////////////////////////////////////////////

//x-axis Coordinates
always_ff @(posedge clk108MHz) begin
    //ballColumn <= 80;
    //ballColumn <= xVel_stg2 + 100;
    if (resetPressed) begin
        xCoord <= START_X;
        ballColumn <= START_X;
    end
    else if (maxTick) begin
        if (xVelPos_stg2) begin
            if (({1'b0, xCoord} + xVel_stg2) >= 8'b11111000) begin
                xCoord <= 8'b11111000;
            end
            if (wallAboveball)
            else begin
                xCoord <= xCoord + xVel_stg2;
            end
        end
        else if (!(xVelPos_stg2)) begin
            if ((xCoord +8'b00000111) <= xVel_stg2) begin
                xCoord <= 8'b00000111;
            end
            else begin
                xCoord <= xCoord - xVel_stg2;
            end
        end
    end
    ballColumn <= xCoord;
end

//y-axis Coordinates
always_ff @(posedge clk108MHz) begin
    //ballRow <= yVel_stg2 + 80;
    if (resetPressed) begin
        yCoord <= START_Y;
        ballRow <= START_Y;
    end
    else  if (maxTick)begin
        if (yVelPos_stg2) begin
            if (({1'b0, yCoord} + yVel_stg2) >= 8'b11111000) begin
                yCoord <= 8'b11111000;
            end
            else begin
                yCoord <= yCoord + yVel_stg2;
            end
        end
        else if (!(yVelPos_stg2)) begin
            if (yCoord + 8'b0000111 <= yVel_stg2) begin
                yCoord <= 8'b00000111;
            end
            else begin
                yCoord <= yCoord - yVel_stg2;
            end
        end
    end
    ballRow <= yCoord;
end

//////////////////////////////////////////////////////////////////
//Conversion for SSEG
//////////////////////////////////////////////////////////////////

hex_to_sseg_p hts7 (.hex(xAccel_stg2), .dp(xAccelPos_stg2), .sseg_p(sseg7));
hex_to_sseg_p hts6 (.hex(yAccel_stg2), .dp(yAccelPos_stg2), .sseg_p(sseg6));

hex_to_sseg_p hts5 (.hex(xVel_stg2), .dp(xVelPos_stg2), .sseg_p(sseg5));
hex_to_sseg_p hts4 (.hex(yVel_stg2), .dp(yVelPos_stg2), .sseg_p(sseg4));

hex_to_sseg_p hts3 (.hex(ballColumn[7:4]), .dp(1'b0), .sseg_p(sseg3));
hex_to_sseg_p hts2 (.hex(ballColumn[3:0]), .dp(1'b0), .sseg_p(sseg2));

hex_to_sseg_p hts1 (.hex(ballRow[7:4]), .dp(1'b0), .sseg_p(sseg1));
hex_to_sseg_p hts0 (.hex(ballRow[3:0]), .dp(1'b0), .sseg_p(sseg0));


//////////////////////////////////////////////////////////////////
//generate SSEG for Acceleration, Velocity, and Position
//////////////////////////////////////////////////////////////////

led_mux8_p dm8_0(
    .clk(clk108MHz), .reset(1'b0), 
    .in7(sseg7), .in6(sseg6), .in5(sseg5), .in4(sseg4), .in3(sseg3), .in2(sseg2), .in1(sseg1), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA}));

endmodule