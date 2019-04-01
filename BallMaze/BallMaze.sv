

module BallMaze(
    //clock signal
    input logic CLK100MHZ,

    //Buttons
    input logic CPU_RESETN,
    input logic BTNU, BTND, BTNL, BTNR,

    //VGA
    output logic VGA_VS, VGA_HS,
    output logic [3:0] VGA_R, VGA_G, VGA_B 
);

///////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////
//Parameters
///////////////////////////////////////////////////////////////////

//VGA Parameters
localparam HD = 1280; // horizontal display width
localparam HF = 48;   // horizontal front porch width
localparam HR = 112;  // horizontal retrace width
localparam HB = 248;  // horizontal back porch width
localparam HT = HD+HF+HR+HB; // horizontal total width
localparam VD = 1024; // vertical display height
localparam VF = 1;    // vertical front porch height
localparam VR = 3;    // vertical retrace height
localparam VB = 38;   // vertical back porch height
localparam VT = VD+VF+VR+VB; // vertical total height

//Reset & Clock
logic resetPressed;
logic clk108MHz;

//Video Display Column and Row Declarations
logic [10:0] videoColumn_stg1; // range needed is 0 to (1279 + 48 + 112 + 248)
logic [10:0] videoRow_stg1;    // range needed is 0 to (1023 +  1 +   3 +  38)

//ball motion
logic up, down, left, right;
logic wallInTile_stg3;
logic wallAboveball, wallRightOfball, wallLeftOfball, wallBelowball;
logic [7:0] ballColumn, ballRow;

//Sprite (ball) border logic
logic [7:0] ballLeftColumn, ballRightColumn, ballTopRow, ballBottomRow;

//Ball Maze Tile Initialized in Memory
(* rom_style = "block" *) logic [5:0] BallMazeTileMapRom [0:1023]; // memory array for tile map
initial $readmemh ("BallMazeTileRom.txt", BallMazeTileMapRom, 0, 10'h3FF); // initialize ballTileSet
logic [5:0] tileType_stg2;

//Genearate video stage 2-4:
logic [10:0] videoRow_stg2, videoColumn_stg2;
(* rom_style = "block" *) logic [1:0] BallMazeTileSet [0:12'h8FF]; // memory array for ball tiles
initial $readmemh ("BallMazeTileSet.txt", BallMazeTileSet, 0, 12'h8FF); // initialize ballTileSet
logic [1:0] tileVideoPixelIndex_stg3;
logic pelletEaten_stg3;	
logic [10:0] videoRow_stg3, videoColumn_stg3;
logic [11:0] videoPixelRGB_stg4;
logic [10:0] videoRow_stg4, videoColumn_stg4;


//
logic [3:0] ballSpriteRow_stg3, ballSpriteColumn_stg3;
(* rom_style = "block" *) logic ballSpriteSet [0:12'h8FF]; // memory array for ball sprite
initial $readmemh ("BallMazeSprite.txt", ballSpriteSet, 0, 12'h8FF); // initialize ballSpriteSet
logic ballVideoPixelIndex_stg4;
logic videoPixelWithinball_stg4;	
logic [11:0] videoPixelRGB_stg5;
logic [10:0] videoRow_stg5, videoColumn_stg5;

////////////////////////////////////////////////////////////////////
//Generate Reset
////////////////////////////////////////////////////////////////////
free_run_shift_reg #(.N(4)) CPU_RESETN_instance(
    .clk(clk108MHz), 
    .s_in(!CPU_RESETN), 
    .s_out(resetPressed)
    );

////////////////////////////////////////////////////////////////////
//Generate 108MHz Clock Signal
////////////////////////////////////////////////////////////////////
videoClk108MHz videoClk108MHz_0 (
    .clk108MHz, // output
	.CLK100MHZ  // input
);

////////////////////////////////////////////////////////////////////
//Directional Button Inputs
////////////////////////////////////////////////////////////////////

free_run_shift_reg #(.N(4)) BTNU_instance(.clk(clk108MHz), .s_in(BTNU), .s_out(up));
free_run_shift_reg #(.N(4)) BTNR_instance(.clk(clk108MHz), .s_in(BTNR), .s_out(right));
free_run_shift_reg #(.N(4)) BTND_instance(.clk(clk108MHz), .s_in(BTND), .s_out(down));
free_run_shift_reg #(.N(4)) BTNL_instance(.clk(clk108MHz), .s_in(BTNL), .s_out(left));

/////////////////////////////////////////////////////////////////////
//Motion Calculations
BallMotion ballMotion0 (
	.*
);
/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////
// Generate Video Display Column and Row.
/////////////////////////////////////////////////////////////////////

// Generate Sprite Borders
always_ff @(posedge clk108MHz) begin	
	if (VGA_VS) begin // only allow sprite changes between video display frames
		ballLeftColumn <= ballColumn-8;
		ballRightColumn <= ballColumn+7;
		ballTopRow <= ballRow-8;
		ballBottomRow <= ballRow+7;
	end
end

always_ff @(posedge clk108MHz) begin
    wallInTile_stg3 <= tileType_stg2[5:0]!=6'h00 & tileType_stg2[5:0]!=6'h01 & tileType_stg2[5:0]!=6'h02; // only 3 tile types that aren't walls
	if (videoColumn_stg3[9:5]==(ballColumn[7:3]  ) & videoRow_stg3[9:5]==(ballRow[7:3]-1)) wallAboveball   <= wallInTile_stg3;
	if (videoColumn_stg3[9:5]==(ballColumn[7:3]+1) & videoRow_stg3[9:5]==(ballRow[7:3]  )) wallRightOfball <= wallInTile_stg3;
	if (videoColumn_stg3[9:5]==(ballColumn[7:3]  ) & videoRow_stg3[9:5]==(ballRow[7:3]+1)) wallBelowball   <= wallInTile_stg3;
	if (videoColumn_stg3[9:5]==(ballColumn[7:3]-1) & videoRow_stg3[9:5]==(ballRow[7:3]  )) wallLeftOfball  <= wallInTile_stg3;	
end


//increment location to display
always_ff @(posedge clk108MHz) begin
    if (videoColumn_stg1 != HT-1) videoColumn_stg1 <= videoColumn_stg1 + 1;
	else begin
        videoColumn_stg1 <= 0;
        if (videoRow_stg1 != VT-1) videoRow_stg1 <= videoRow_stg1 + 1;
		else videoRow_stg1 <= 0;
    end
end

/////////////////////////////////////////////////////////////////////
//Video Generation
/////////////////////////////////////////////////////////////////////

//tileType initialized to index to correct location in BallMazeTileSet
always_ff @(posedge clk108MHz) begin
	tileType_stg2[5:0] <= BallMazeTileMapRom[{videoRow_stg1[9:5],videoColumn_stg1[9:5]}];
end


//Draw Tiles
always_ff @(posedge clk108MHz) begin
	// generate pipeline stage 2 signals
	videoRow_stg2[10:0]    <= videoRow_stg1[10:0];
	videoColumn_stg2[10:0] <= videoColumn_stg1[10:0];
	
	// generate pipeline stage 3 signals
	tileVideoPixelIndex_stg3[1:0] <= BallMazeTileSet[{tileType_stg2[5:0],videoRow_stg2[4:2],videoColumn_stg2[4:2]}]; 
		// skipping video bits 1 and 0 duplicates rows and columns	
	videoRow_stg3[10:0] <= videoRow_stg2[10:0];
	videoColumn_stg3[10:0] <= videoColumn_stg2[10:0];

	// generate pipeline stage 4 signals
	case(tileVideoPixelIndex_stg3[1:0])
		0: videoPixelRGB_stg4[11:0] <= 12'h000; // black background
		1: videoPixelRGB_stg4[11:0] <= 12'h00F; // blue wall
		2: videoPixelRGB_stg4[11:0] <= 12'hFCA; // peach pellets
		3: videoPixelRGB_stg4[11:0] <= 12'hxxx; // unused
	endcase
	videoRow_stg4[10:0] <= videoRow_stg3[10:0];
	videoColumn_stg4[10:0] <= videoColumn_stg3[10:0];
end

//Ball Sprite
// Overlay ball Sprite
always_ff @(posedge clk108MHz) begin
	ballSpriteRow_stg3[3:0]    <= videoRow_stg2[5:2]    - ballTopRow[3:0];
	ballSpriteColumn_stg3[3:0] <= videoColumn_stg2[5:2] - ballLeftColumn[3:0];
		// skipping videoRow and videoColumn bits 1 and 0 duplicates rows and columns

	ballVideoPixelIndex_stg4 <= ballSpriteSet[{4'b0000,ballSpriteRow_stg3[3:0],ballSpriteColumn_stg3[3:0]}];
	videoPixelWithinball_stg4 <= (videoColumn_stg3[9:2] >= ballLeftColumn) & 
                                   (videoColumn_stg3[9:2] <= ballRightColumn) &
								   (videoRow_stg3[9:2]    >= ballTopRow) & 
                                   (videoRow_stg3[9:2]    <= ballBottomRow);	

	if (!videoPixelWithinball_stg4) videoPixelRGB_stg5[11:0] <= videoPixelRGB_stg4[11:0]; // don't change
    else if (!ballVideoPixelIndex_stg4) videoPixelRGB_stg5[11:0] <= videoPixelRGB_stg4[11:0]; // don't change
    else videoPixelRGB_stg5[11:0] <= 12'hFF0; // yellow ball body

	videoRow_stg5[10:0] <= videoRow_stg4[10:0];
	videoColumn_stg5[10:0] <= videoColumn_stg4[10:0];
end

// Generate video signals to be sent to monitor
always_ff @(posedge clk108MHz) begin
	// Overlay black outside the tile locations	(including outside the display area)
	if ((videoColumn_stg5 >= 1024-64) | (videoRow_stg5>= VD) | (videoColumn_stg5 <= 64)) {VGA_R, VGA_G, VGA_B} <= 12'h000; // Blanking
	else {VGA_R, VGA_G, VGA_B} <= videoPixelRGB_stg5[11:0];
	// generate video sync signals
	VGA_HS <= (videoColumn_stg5 >= (HD+HF)) && (videoColumn_stg5 <= (HD+HF+HR));
    VGA_VS <= (videoRow_stg5    >= (VD+VF)) && (videoRow_stg5    <= (VD+VF+VR));
end


endmodule