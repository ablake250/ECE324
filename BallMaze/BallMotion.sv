


module BallMotion(
    //Reset and clock signals
    input logic CLK100MHZ,
    input logic clk108MHz,
    input logic resetPressed,
    //Ball Inputs
    input logic up, down, left, right,
    input logic wallAboveball, wallRightOfball, wallLeftOfball, wallBelowball,
    //Ball Outputs
    output logic [7:0] ballColumn,
    output logic [7:0] ballRow,
    //Output logic to drive 7-segment displays
    output logic [7:0] AN,
    output logic DP,CG,CF,CE,CD,CC,CB,CA,
    //Output logic for ball detection
    output logic [4:0] vertOffset, horizOffset,
    //SPI
    input logic ACL_MISO,
    output logic ACL_MOSI, ACL_SCLK, ACL_CSN
);

//////////////////////////////////////////////////////////////////////////////////
//logic declarations
//////////////////////////////////////////////////////////////////////////////////

//Acceleration Logic Declarations
logic [7:0] xAcceleration, yAcceleration;
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

//binary logic:
logic xUpdate;
logic yUpdate;

//initialize ball location
initial begin
	ballColumn <= START_X;
	xCoord <= START_X;
	yCoord <= START_Y;
    ballRow <= START_Y;
end

////////////////////////////////////////////////////////////////////////////////////
//Generate tick rates for ball movement calculations
////////////////////////////////////////////////////////////////////////////////////

mod_m_counter #(.M(5000000)) ballTick(
    .clk(clk108MHz), 
    .max_tick(maxTick), 
    .q()
);

univ_bin_counter #(.N(4)) ubc0(
	//inputs below
	.clk(clk108MHz),
	.syn_clr(0),
	.load(xUpdate),
	.d(xVel_stg2),
	.en(maxTick & (xVel_stg2 != 15)),
	.up(0),
	//outputs below
	.q(),
	.max_tick(),
	.min_tick(xUpdate)
);

univ_bin_counter #(.N(4)) ubc1(	
	//inputs below
	.clk(clk108MHz),
	.syn_clr(0),
	.load(yUpdate),
	.d(yVel_stg2),
	.en(maxTick & (yVel_stg2 != 15)),
	.up(0),

	//outputs below
	.q(),
	.max_tick(),
	.min_tick(yUpdate)
);


///////////////////////////////////////////////////////////////////////////////////
//Acceleration of Ball
///////////////////////////////////////////////////////////////////////////////////
/*
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
*/
    readAccel ra0(
        .clk(clk108MHz),
        .reset(resetPressed),
        .miso(ACL_MISO),
        .mosi(ACL_MOSI),
        .sclk(ACL_SCLK),
        .cs(ACL_CSN),
        .xAxis(yAcceleration),
        .yAxis(xAcceleration)
    );



    always_ff @(posedge clk108MHz) begin
        case(xAcceleration[7:4])
            4'h0: begin
                xAccel_stg2 <= 1;
                xAccelPos_stg2 <= 1;
            end
            4'h1: begin
                xAccel_stg2 <= 2;
                xAccelPos_stg2 <= 1;
            end
            4'h2: begin
                xAccel_stg2 <= 3;
                xAccelPos_stg2 <= 1;
            end
            4'h3: begin
                xAccel_stg2 <= 4;
                xAccelPos_stg2 <= 1;
            end
            4'h4: begin
                xAccel_stg2 <= 4;
                xAccelPos_stg2 <= 1;
            end
            4'hF: begin
                xAccel_stg2 <= 0;
                xAccelPos_stg2 <= 0;
            end
            4'hE: begin
                xAccel_stg2 <= 1;
                xAccelPos_stg2 <= 0;
            end
            4'hD: begin
                xAccel_stg2 <= 2;
                xAccelPos_stg2 <= 0;
            end
            4'hC: begin
                xAccel_stg2 <= 3;
                xAccelPos_stg2 <= 0;
            end
            4'hB: begin
                xAccel_stg2 <= 4;
                xAccelPos_stg2 <= 0;
            end

        endcase

    end

    always_ff @(posedge clk108MHz) begin
        case(yAcceleration[7:4])
            4'h0: begin
                yAccel_stg2 <= 1;
                yAccelPos_stg2 <= 0;
            end
            4'h1: begin
                yAccel_stg2 <= 2;
                yAccelPos_stg2 <= 0;
            end
            4'h2: begin
                yAccel_stg2 <= 3;
                yAccelPos_stg2 <= 0;
            end
            4'h3: begin
                yAccel_stg2 <= 4;
                yAccelPos_stg2 <= 0;
            end
            4'h4: begin
                yAccel_stg2 <= 4;
                yAccelPos_stg2 <= 0;
            end
            4'hF: begin
                yAccel_stg2 <= 0;
                yAccelPos_stg2 <= 1;
            end
            4'hE: begin
                yAccel_stg2 <= 1;
                yAccelPos_stg2 <= 1;
            end
            4'hD: begin
                yAccel_stg2 <= 2;
                yAccelPos_stg2 <= 1;
            end
            4'hC: begin
                yAccel_stg2 <= 3;
                yAccelPos_stg2 <= 1;
            end
            4'hB: begin
                yAccel_stg2 <= 4;
                yAccelPos_stg2 <= 01;
            end

        endcase

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
    else if(xUpdate | (xVel_stg2==15 & maxTick)) begin
        if (xVelPos==0) begin
            if((xVelocity <= xAccel_stg2) & (xAccelPos_stg2)) begin
                xVelocity <= xAccel_stg2 - xVelocity;
                xVelPos <= 1;
            end
            else if (wallLeftOfball) begin
                xVelocity <= 0;
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
            else if (wallRightOfball) begin
                xVelocity <= 0;
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
    //xVel_stg2 <= xVelocity;
    case(xVelocity)
        0:          xVel_stg2 <= 15;
        1:          xVel_stg2 <= 7;
        2:          xVel_stg2 <= 6;
        3:          xVel_stg2 <= 5;
        4:          xVel_stg2 <= 4;
        5:          xVel_stg2 <= 3;
        6:          xVel_stg2 <= 2;
        7:          xVel_stg2 <= 1;
        //8:          xVel_stg2 <= 7;
        //9:          xVel_stg2 <= 6;
        //10:         xVel_stg2 <= 5;
        //11:         xVel_stg2 <= 4;
        //12:         xVel_stg2 <= 3;
        //13:         xVel_stg2 <= 2;
        default:    xVel_stg2 <= 1;
    endcase
    xVelPos_stg2 <= xVelPos;
    horizOffset <= {xVelPos_stg2, xVel_stg2};
end

//y-axis Velocity
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        yVelocity <= 0;
        yVelPos <= 1;
        yVelPos_stg2 <= 1;
        yVel_stg2 <= 0;
    end
    else if(yUpdate | (yVel_stg2==15 & maxTick)) begin
        if (yVelPos==0) begin
            if((yVelocity <= yAccel_stg2) & (yAccelPos_stg2)) begin
                yVelocity <= yAccel_stg2 - yVelocity;
                yVelPos <= 1;
            end
            else if (wallAboveball) begin
                yVelocity <= 0;
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
            else if (wallBelowball) begin
                yVelocity <= 0;
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
    //yVel_stg2 <= yVelocity;
    case(yVelocity)
        0:          yVel_stg2 <= 15;
        1:          yVel_stg2 <= 7;
        2:          yVel_stg2 <= 6;
        3:          yVel_stg2 <= 5;
        4:          yVel_stg2 <= 4;
        5:          yVel_stg2 <= 3;
        6:          yVel_stg2 <= 2;
        7:          yVel_stg2 <= 1;
        //8:          yVel_stg2 <= 7;
        //9:          yVel_stg2 <= 6;
        //10:         yVel_stg2 <= 5;
        //11:         yVel_stg2 <= 4;
        //12:         yVel_stg2 <= 3;
        //13:         yVel_stg2 <= 2;
        default:    yVel_stg2 <= 1;


    endcase
    yVelPos_stg2 <= yVelPos;
    vertOffset <= {yVelPos_stg2, yVelPos_stg2};
end

///////////////////////////////////////////////////////////////////////////////////
//Position of Ball
///////////////////////////////////////////////////////////////////////////////////

//x-axis Coordinates 
always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        xCoord <= START_X;
        ballColumn <= START_X;
    end
    else if (xUpdate) begin
        if (xVelPos_stg2) begin
            if (wallRightOfball);
            else xCoord <= xCoord + 1;
        end
        else if (!(xVelPos_stg2)) begin
            if (wallLeftOfball);
            else xCoord <= xCoord - 1;
        end
    end
    ballColumn <= xCoord;
end

always_ff @(posedge clk108MHz) begin
    if (resetPressed) begin
        yCoord <= START_Y;
        ballRow <= START_Y;
    end
    else if (yUpdate) begin
        if (yVelPos_stg2) begin
            if (wallBelowball);
            else yCoord <= yCoord + 1;
        end
        else if (!(xVelPos_stg2)) begin
            if (wallAboveball);
            else yCoord <= yCoord - 1;
        end
    end
    ballRow <= yCoord;
end

//////////////////////////////////////////////////////////////////
//SSEG Driving Logic
//////////////////////////////////////////////////////////////////

hex_to_sseg_p hts7 (.hex(xAccel_stg2), .dp(xAccelPos_stg2), .sseg_p(sseg7));
hex_to_sseg_p hts6 (.hex(yAccel_stg2), .dp(yAccelPos_stg2), .sseg_p(sseg6));
hex_to_sseg_p hts5 (.hex(xVel_stg2), .dp(xVelPos_stg2), .sseg_p(sseg5));
hex_to_sseg_p hts4 (.hex(yVel_stg2), .dp(yVelPos_stg2), .sseg_p(sseg4));
hex_to_sseg_p hts3 (.hex(ballColumn[7:4]), .dp(wallLeftOfball), .sseg_p(sseg3));
hex_to_sseg_p hts2 (.hex(ballColumn[3:0]), .dp(wallAboveball), .sseg_p(sseg2));
hex_to_sseg_p hts1 (.hex(ballRow[7:4]), .dp(wallBelowball), .sseg_p(sseg1));
hex_to_sseg_p hts0 (.hex(ballRow[3:0]), .dp(wallRightOfball), .sseg_p(sseg0));

led_mux8_p dm8_0(
    .clk(clk108MHz), .reset(1'b0), 
    .in7(sseg7), .in6(sseg6), .in5(sseg5), .in4(sseg4), .in3(sseg3), .in2(sseg2), .in1(sseg1), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA}));

endmodule