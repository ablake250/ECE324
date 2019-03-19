/*********************************************************************
File: Lab9_PacMan.sv
Module: Lab9_PacMan
Function: Implements a basic subset of the original Pac-Man game developed by Namco.
Revisions:
18 Oct 2018 Tom Pritchard: Initial development for ECE 324 lab
*********************************************************************/
 
module Lab9_PacMan(
	input logic CLK100MHZ,
	
	// Buttons
	input logic CPU_RESETN, // holding down the left red button on Nexys4DDR initiates a new game, and releasing it enables sprite movements.
	input logic BTNU, BTNL, BTNR, BTND, // used to make PacMan move
	
    // VGA outputs
    output logic VGA_VS, VGA_HS, // VGA vertical and horizontal sync
    output logic [3:0] VGA_R, VGA_G, VGA_B // 4 bits each of Red, Green, and Blue
);

/////////////////////////////////////////////////////////////////////
// Parameters and Declarations
/////////////////////////////////////////////////////////////////////

////////////////////////
// Timing parameters for sxga 1280x1024 display
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

////////////////////////
// Reset and Clock Declarations
logic resetPressed; 
logic clk108MHz;

////////////////////////
// Video Display Column and Row Declarations
logic [10:0] videoColumn_stg1; // range needed is 0 to (1279 + 48 + 112 + 248)
logic [10:0] videoRow_stg1;    // range needed is 0 to (1023 +  1 +   3 +  38)

////////////////////////
// PacMan Tile Memory Declarations
(* rom_style = "block" *) logic [5:0] PacManTileMapRom [0:1023]; // memory array for tile map
initial $readmemh ("PacManTileMapRom.txt", PacManTileMapRom, 0, 10'h3FF); // initialize PacManTileSet
logic [5:0] tileType_stg2;

logic wr_pelletEatenRam;
logic [9:0] addrWr_pelletEatenRam;
logic dataWr_pelletEatenRam;
logic [9:0] addrRd_pelletEatenRam;
(* ram_style = "block" *) logic pelletEatenRam [0:1023]; // memory array for pelletEaten
integer j; initial for(j = 0; j <= 1023; j = j+1) pelletEatenRam[j] = 0; // initialize so all pellets are displayed.
logic pelletEaten_stg2;

////////////////////////
// Sprite Motion Generation Declarations
logic upPressed, rightPressed, downPressed, leftPressed;
logic wallInTile_stg3;
logic wallAbovePacman, wallRightOfPacman, wallBelowPacman, wallLeftOfPacman;
logic wallAboveBlinky, wallRightOfBlinky, wallBelowBlinky, wallLeftOfBlinky;
logic [7:0] pacmanColumn, blinkyColumn, pinkyColumn, inkyColumn, clydeColumn; // 0-255
logic [7:0] pacmanRow, blinkyRow, pinkyRow, inkyRow, clydeRow;    // 0-255
logic [3:0] pacmanFace; // 9 images, two (wide and narrow mouth) for each of 4 directions, and 1 for closed mouth
logic [2:0] blinkyFace, pinkyFace, inkyFace, clydeFace;  // 8 images, two types of skirt for each of 4 directions

////////////////////////
// Video Pixel Generation Declarations
logic [7:0] pacmanLeftColumn, blinkyLeftColumn, pinkyLeftColumn, inkyLeftColumn, clydeLeftColumn;
logic [7:0] pacmanRightColumn, blinkyRightColumn, pinkyRightColumn, inkyRightColumn, clydeRightColumn;
logic [7:0] pacmanTopRow, blinkyTopRow, pinkyTopRow, inkyTopRow, clydeTopRow;
logic [7:0] pacmanBottomRow, blinkyBottomRow, pinkyBottomRow, inkyBottomRow, clydeBottomRow;
logic [3:0] pacmanImage;
logic [2:0] blinkyImage, pinkyImage, inkyImage, clydeImage;

logic [10:0] videoRow_stg2, videoColumn_stg2;
(* rom_style = "block" *) logic [1:0] PacManTileSet [0:12'h8FF]; // memory array for PacMan tiles
initial $readmemh ("PacManTileSet.txt", PacManTileSet, 0, 12'h8FF); // initialize PacManTileSet
logic [1:0] tileVideoPixelIndex_stg3;
logic pelletEaten_stg3;	
logic [10:0] videoRow_stg3, videoColumn_stg3;
logic [11:0] videoPixelRGB_stg4;
logic [10:0] videoRow_stg4, videoColumn_stg4;

logic [3:0] pacmanSpriteRow_stg3, pacmanSpriteColumn_stg3;
(* rom_style = "block" *) logic PacManSpriteSet [0:12'h8FF]; // memory array for PacMan sprite
initial $readmemh ("PacManSpriteSet.txt", PacManSpriteSet, 0, 12'h8FF); // initialize PacManSpriteSet
logic pacmanVideoPixelIndex_stg4;
logic videoPixelWithinPacman_stg4;	
logic [11:0] videoPixelRGB_stg5;
logic [10:0] videoRow_stg5, videoColumn_stg5;

logic [3:0] blinkySpriteRow_stg4, blinkySpriteColumn_stg4;
(* rom_style = "block" *) logic [1:0] BlinkySpriteSet [0:11'h7FF]; // memory array for Blinky sprite
initial $readmemh ("GhostSpriteSet.txt", BlinkySpriteSet, 0, 11'h7FF); // initialize BlinkySpriteSet
logic [1:0] blinkyVideoPixelIndex_stg5;
logic videoPixelWithinBlinky_stg5;
logic [11:0] videoPixelRGB_stg6;
logic [10:0] videoRow_stg6, videoColumn_stg6;

logic [3:0] pinkySpriteRow_stg5, pinkySpriteColumn_stg5;
(* rom_style = "block" *) logic [1:0] PinkySpriteSet [0:11'h7FF]; // memory array for Pinky sprite
initial $readmemh ("GhostSpriteSet.txt", PinkySpriteSet, 0, 11'h7FF); // initialize PinkySpriteSet
logic [1:0] pinkyVideoPixelIndex_stg6;
logic videoPixelWithinPinky_stg6;	
logic [11:0] videoPixelRGB_stg7;
logic [10:0] videoRow_stg7, videoColumn_stg7;

logic [3:0] inkySpriteRow_stg6, inkySpriteColumn_stg6;
(* rom_style = "block" *) logic [1:0] InkySpriteSet [0:11'h7FF]; // memory array for Inky sprite
initial $readmemh ("GhostSpriteSet.txt", InkySpriteSet, 0, 11'h7FF); // initialize InkySpriteSet
logic [1:0] inkyVideoPixelIndex_stg7;
logic videoPixelWithinInky_stg7;	
logic [11:0] videoPixelRGB_stg8;
logic [10:0] videoRow_stg8, videoColumn_stg8;

logic [3:0] clydeSpriteRow_stg7, clydeSpriteColumn_stg7;
(* rom_style = "block" *) logic [1:0] ClydeSpriteSet [0:11'h7FF]; // memory array for Clyde sprite
initial $readmemh ("GhostSpriteSet.txt", ClydeSpriteSet, 0, 11'h7FF); // initialize ClydeSpriteSet
logic [1:0] clydeVideoPixelIndex_stg8;
logic videoPixelWithinClyde_stg8;	
logic [11:0] videoPixelRGB_stg9;
logic [10:0] videoRow_stg9;
logic [10:0] videoColumn_stg9;
	
	
/////////////////////////////////////////////////////////////////////
// Generate Reset and Clock Signals.
/////////////////////////////////////////////////////////////////////
// Perform synchronization and handle metastability of the left red button on the Nexys4DDR to act as a game reset.
free_run_shift_reg #(.N(4)) CPU_RESETN_instance(.clk(clk108MHz), .s_in(!CPU_RESETN), .s_out(resetPressed));

// Generate a 108 MHz clock for the data rate of a SXGA (1280x1024) monitor at 60 Hz.
// This clock is used not just for the video, but for all sequential logic in this module, to make everything (except button inputs) synchronous.
videoClk108MHz videoClk108MHz_0 (
    .clk108MHz, // output
	.CLK100MHZ  // input
);


/////////////////////////////////////////////////////////////////////
// Generate Video Display Column and Row.
/////////////////////////////////////////////////////////////////////
always_ff @(posedge clk108MHz) begin
    if (videoColumn_stg1 != HT-1) videoColumn_stg1 <= videoColumn_stg1 + 1;
	else begin
        videoColumn_stg1 <= 0;
        if (videoRow_stg1 != VT-1) videoRow_stg1 <= videoRow_stg1 + 1;
		else videoRow_stg1 <= 0;
    end
end


/////////////////////////////////////////////////////////////////////
// PacMan Tile Memory
/////////////////////////////////////////////////////////////////////
// These inferred Block Memories contain, for each tile map location, the type of tile to be displayed, and whether the pellet is eaten there.
// The reason why all of this isn't put into one wider RAM is because we don't want to change the tile map when writing to pelletEaten.

// Infer single port ROM
always_ff @(posedge clk108MHz) begin
	tileType_stg2[5:0] <= PacManTileMapRom[{videoRow_stg1[9:5],videoColumn_stg1[9:5]}];
end


always_ff @(posedge clk108MHz) begin
	// The write port is shared by two functions:
    //     when the reset button is being pressed, the RAM is written to a 1, cycling through the 1024 tile locations;
    //     when pacman is located at the center of a tile, the RAM is written to a 0 in that tile location.
    wr_pelletEatenRam <= resetPressed | (pacmanRow[2:0]==3'b100) & (pacmanColumn[2:0]==3'b100);
    addrWr_pelletEatenRam[9:0] <= resetPressed ? videoColumn_stg1[9:0] : {pacmanRow[7:3],pacmanColumn[7:3]};  
    dataWr_pelletEatenRam <= !resetPressed;
end
assign addrRd_pelletEatenRam[9:0] = {videoRow_stg1[9:5],videoColumn_stg1[9:5]};

// Infer simple dual port RAM
always_ff @(posedge clk108MHz) begin	
	if (wr_pelletEatenRam) pelletEatenRam[addrWr_pelletEatenRam] <= dataWr_pelletEatenRam;
	pelletEaten_stg2 <= pelletEatenRam[addrRd_pelletEatenRam];
end	


/////////////////////////////////////////////////////////////////////
// Sprite Motion Generation
/////////////////////////////////////////////////////////////////////
// Perform synchronization and handle metastability of the four directional buttons.
free_run_shift_reg #(.N(4)) BTNU_instance(.clk(clk108MHz), .s_in(BTNU), .s_out(upPressed));
free_run_shift_reg #(.N(4)) BTNR_instance(.clk(clk108MHz), .s_in(BTNR), .s_out(rightPressed));
free_run_shift_reg #(.N(4)) BTND_instance(.clk(clk108MHz), .s_in(BTND), .s_out(downPressed));
free_run_shift_reg #(.N(4)) BTNL_instance(.clk(clk108MHz), .s_in(BTNL), .s_out(leftPressed));

// capture wall locations around sprites to determine where they can go
always_ff @(posedge clk108MHz) begin
    wallInTile_stg3 <= tileType_stg2[5:0]!=6'h00 & tileType_stg2[5:0]!=6'h01 & tileType_stg2[5:0]!=6'h02; // only 3 tile types that aren't walls
	if (videoColumn_stg3[9:5]==(pacmanColumn[7:3]  ) & videoRow_stg3[9:5]==(pacmanRow[7:3]-1)) wallAbovePacman   <= wallInTile_stg3;
	if (videoColumn_stg3[9:5]==(pacmanColumn[7:3]+1) & videoRow_stg3[9:5]==(pacmanRow[7:3]  )) wallRightOfPacman <= wallInTile_stg3;
	if (videoColumn_stg3[9:5]==(pacmanColumn[7:3]  ) & videoRow_stg3[9:5]==(pacmanRow[7:3]+1)) wallBelowPacman   <= wallInTile_stg3;
	if (videoColumn_stg3[9:5]==(pacmanColumn[7:3]-1) & videoRow_stg3[9:5]==(pacmanRow[7:3]  )) wallLeftOfPacman  <= wallInTile_stg3;
	
	if (videoColumn_stg2[9:5]==(blinkyColumn[7:3]  ) & videoRow_stg2[9:5]==(blinkyRow[7:3]-1)) wallAboveBlinky   <= wallInTile_stg3;
	if (videoColumn_stg2[9:5]==(blinkyColumn[7:3]+1) & videoRow_stg2[9:5]==(blinkyRow[7:3]  )) wallRightOfBlinky <= wallInTile_stg3;
	if (videoColumn_stg2[9:5]==(blinkyColumn[7:3]  ) & videoRow_stg2[9:5]==(blinkyRow[7:3]+1)) wallBelowBlinky   <= wallInTile_stg3;
	if (videoColumn_stg2[9:5]==(blinkyColumn[7:3]-1) & videoRow_stg2[9:5]==(blinkyRow[7:3]  )) wallLeftOfBlinky  <= wallInTile_stg3;
end

// Perform motion algorithms
spriteMotion spriteMotion0(
	.clk108MHz, .resetPressed,
	.upPressed, .rightPressed, .downPressed, .leftPressed,
	.wallAbovePacman, .wallRightOfPacman, .wallBelowPacman, .wallLeftOfPacman,
	.wallAboveBlinky, .wallRightOfBlinky, .wallBelowBlinky, .wallLeftOfBlinky,
	.pacmanColumn, .pacmanRow, .pacmanFace,
	.blinkyColumn, .blinkyRow, .blinkyFace,
	 .pinkyColumn,  .pinkyRow,  .pinkyFace,	
	  .inkyColumn,   .inkyRow,   .inkyFace,	
	 .clydeColumn,  .clydeRow,  .clydeFace
);


/////////////////////////////////////////////////////////////////////
// Video Pixel Generation
/////////////////////////////////////////////////////////////////////

////////////////////////	
// Generate Sprite Borders
always_ff @(posedge clk108MHz) begin	
	if (VGA_VS) begin // only allow sprite changes between video display frames
		pacmanLeftColumn <= pacmanColumn-8; pacmanRightColumn <= pacmanColumn+7; pacmanTopRow <= pacmanRow-8; pacmanBottomRow <= pacmanRow+7; pacmanImage <= pacmanFace;
		blinkyLeftColumn <= blinkyColumn-8; blinkyRightColumn <= blinkyColumn+7; blinkyTopRow <= blinkyRow-8; blinkyBottomRow <= blinkyRow+7; blinkyImage <= blinkyFace;
		 pinkyLeftColumn <=  pinkyColumn-8;  pinkyRightColumn <=  pinkyColumn+7;  pinkyTopRow <=  pinkyRow-8;  pinkyBottomRow <=  pinkyRow+7;  pinkyImage <=  pinkyFace;
		  inkyLeftColumn <=   inkyColumn-8;   inkyRightColumn <=   inkyColumn+7;   inkyTopRow <=   inkyRow-8;   inkyBottomRow <=   inkyRow+7;   inkyImage <=   inkyFace;
		 clydeLeftColumn <=  clydeColumn-8;  clydeRightColumn <=  clydeColumn+7;  clydeTopRow <=  clydeRow-8;  clydeBottomRow <=  clydeRow+7;  clydeImage <=  clydeFace;
	end
end

////////////////////////	
// Draw Tiles
always_ff @(posedge clk108MHz) begin
	// generate pipeline stage 2 signals
	videoRow_stg2[10:0]    <= videoRow_stg1[10:0];
	videoColumn_stg2[10:0] <= videoColumn_stg1[10:0];
	
	// generate pipeline stage 3 signals
	tileVideoPixelIndex_stg3[1:0] <= PacManTileSet[{tileType_stg2[5:0],videoRow_stg2[4:2],videoColumn_stg2[4:2]}]; 
		// skipping video bits 1 and 0 duplicates rows and columns
	pelletEaten_stg3 <= pelletEaten_stg2;	
	videoRow_stg3[10:0] <= videoRow_stg2[10:0];
	videoColumn_stg3[10:0] <= videoColumn_stg2[10:0];

	// generate pipeline stage 4 signals
	if (pelletEaten_stg3) videoPixelRGB_stg4[11:0] <= 12'h000; // all black in tile where pellet has been eaten
	else case(tileVideoPixelIndex_stg3[1:0])
		0: videoPixelRGB_stg4[11:0] <= 12'h000; // black background
		1: videoPixelRGB_stg4[11:0] <= 12'h00F; // blue wall
		2: videoPixelRGB_stg4[11:0] <= 12'hFCA; // peach pellets
		3: videoPixelRGB_stg4[11:0] <= 12'hxxx; // unused
	endcase
	videoRow_stg4[10:0] <= videoRow_stg3[10:0];
	videoColumn_stg4[10:0] <= videoColumn_stg3[10:0];
end

////////////////////////
// Overlay Pacman Sprite
always_ff @(posedge clk108MHz) begin
	pacmanSpriteRow_stg3[3:0]    <= videoRow_stg2[5:2]    - pacmanTopRow[3:0];
	pacmanSpriteColumn_stg3[3:0] <= videoColumn_stg2[5:2] - pacmanLeftColumn[3:0];
		// skipping videoRow and videoColumn bits 1 and 0 duplicates rows and columns

	pacmanVideoPixelIndex_stg4 <= PacManSpriteSet[{pacmanImage[3:0],pacmanSpriteRow_stg3[3:0],pacmanSpriteColumn_stg3[3:0]}];
	videoPixelWithinPacman_stg4 <= (videoColumn_stg3[9:2] >= pacmanLeftColumn) & 
                                   (videoColumn_stg3[9:2] <= pacmanRightColumn) &
								   (videoRow_stg3[9:2]    >= pacmanTopRow) & 
                                   (videoRow_stg3[9:2]    <= pacmanBottomRow);	

	if (!videoPixelWithinPacman_stg4) videoPixelRGB_stg5[11:0] <= videoPixelRGB_stg4[11:0]; // don't change
    else if (!pacmanVideoPixelIndex_stg4) videoPixelRGB_stg5[11:0] <= videoPixelRGB_stg4[11:0]; // don't change
    else videoPixelRGB_stg5[11:0] <= 12'hFF0; // yellow Pacman body

	videoRow_stg5[10:0] <= videoRow_stg4[10:0];
	videoColumn_stg5[10:0] <= videoColumn_stg4[10:0];
end

////////////////////////
// Overlay Blinky Sprite
always_ff @(posedge clk108MHz) begin
	// generate pipeline stage 4 signals
	blinkySpriteRow_stg4[3:0]    <= videoRow_stg3[5:2]    - blinkyTopRow[3:0];     // skipping video bits 1 and 0 duplicates rows
	blinkySpriteColumn_stg4[3:0] <= videoColumn_stg3[5:2] - blinkyLeftColumn[3:0]; // skipping video bits 1 and 0 duplicates columns	

	// generate pipeline stage 5 signals
	blinkyVideoPixelIndex_stg5[1:0] <= BlinkySpriteSet[{blinkyImage[2:0],blinkySpriteRow_stg4[3:0],blinkySpriteColumn_stg4[3:0]}];
	videoPixelWithinBlinky_stg5 <= blinkyLeftColumn<=videoColumn_stg4[9:2] & videoColumn_stg4[9:2]<=blinkyRightColumn & blinkyTopRow<=videoRow_stg4[9:2] & videoRow_stg4[9:2]<=blinkyBottomRow;

	// generate pipeline stage 6 signals
	if (!videoPixelWithinBlinky_stg5) videoPixelRGB_stg6[11:0] <= videoPixelRGB_stg5[11:0]; // if not in sprite location, don't change pixel
	else case(blinkyVideoPixelIndex_stg5[1:0])
		0: videoPixelRGB_stg6[11:0] <= videoPixelRGB_stg5[11:0]; // transparent
		1: videoPixelRGB_stg6[11:0] <= 12'hF00; // red Blinky body
		2: videoPixelRGB_stg6[11:0] <= 12'hFFF; // white part of eyes
		3: videoPixelRGB_stg6[11:0] <= 12'h00F; // blue part of eyes
	endcase
	videoRow_stg6[10:0] <= videoRow_stg5[10:0];
	videoColumn_stg6[10:0] <= videoColumn_stg5[10:0];
end	

////////////////////////
// Overlay Pinky Sprite
always_ff @(posedge clk108MHz) begin
	// generate pipeline stage 5 signals
	pinkySpriteRow_stg5[3:0]    <= videoRow_stg4[5:2]    - pinkyTopRow[3:0];     // skipping video bits 1 and 0 duplicates rows
	pinkySpriteColumn_stg5[3:0] <= videoColumn_stg4[5:2] - pinkyLeftColumn[3:0]; // skipping video bits 1 and 0 duplicates columns	

	// generate pipeline stage 6 signals
	pinkyVideoPixelIndex_stg6[1:0] <= PinkySpriteSet[{pinkyImage[2:0],pinkySpriteRow_stg5[3:0],pinkySpriteColumn_stg5[3:0]}];
	videoPixelWithinPinky_stg6 <= pinkyLeftColumn<=videoColumn_stg5[9:2] & videoColumn_stg5[9:2]<=pinkyRightColumn & pinkyTopRow<=videoRow_stg5[9:2] & videoRow_stg5[9:2]<=pinkyBottomRow;	

	// generate pipeline stage 7 signals 
	if (!videoPixelWithinPinky_stg6) videoPixelRGB_stg7[11:0] <= videoPixelRGB_stg6[11:0]; // if not in sprite location, don't change pixel
	else case(pinkyVideoPixelIndex_stg6[1:0])
		0: videoPixelRGB_stg7[11:0] <= videoPixelRGB_stg6[11:0]; // transparent
		1: videoPixelRGB_stg7[11:0] <= 12'hFBB; // pink Pinky body
		2: videoPixelRGB_stg7[11:0] <= 12'hFFF; // white part of eyes
		3: videoPixelRGB_stg7[11:0] <= 12'h00F; // blue part of eyes
	endcase
	videoRow_stg7[10:0] <= videoRow_stg6[10:0];
	videoColumn_stg7[10:0] <= videoColumn_stg6[10:0];
end	

////////////////////////
// Overlay Inky Sprite
always_ff @(posedge clk108MHz) begin
	// generate pipeline stage 6 signals
	inkySpriteRow_stg6[3:0]    <= videoRow_stg5[5:2]    - inkyTopRow[3:0];     // skipping video bits 1 and 0 duplicates rows
	inkySpriteColumn_stg6[3:0] <= videoColumn_stg5[5:2] - inkyLeftColumn[3:0]; // skipping video bits 1 and 0 duplicates columns	

	// generate pipeline stage 7 signals 
	inkyVideoPixelIndex_stg7[1:0] <= InkySpriteSet[{inkyImage[2:0],inkySpriteRow_stg6[3:0],inkySpriteColumn_stg6[3:0]}];
	videoPixelWithinInky_stg7 <= inkyLeftColumn<=videoColumn_stg6[9:2] & videoColumn_stg6[9:2]<=inkyRightColumn & inkyTopRow<=videoRow_stg6[9:2] & videoRow_stg6[9:2]<=inkyBottomRow;	

	// generate pipeline stage 8 signals 
	if (!videoPixelWithinInky_stg7) videoPixelRGB_stg8[11:0] <= videoPixelRGB_stg7[11:0]; // if not in sprite location, don't change pixel
	else case(inkyVideoPixelIndex_stg7[1:0])
		0: videoPixelRGB_stg8[11:0] <= videoPixelRGB_stg7[11:0]; // transparent
		1: videoPixelRGB_stg8[11:0] <= 12'h0FF; // cyan Inky body
		2: videoPixelRGB_stg8[11:0] <= 12'hFFF; // white part of eyes
		3: videoPixelRGB_stg8[11:0] <= 12'h00F; // blue part of eyes
	endcase
	videoRow_stg8[10:0] <= videoRow_stg7[10:0];
	videoColumn_stg8[10:0] <= videoColumn_stg7[10:0];
end	
	
////////////////////////
// Overlay Clyde Sprite
always_ff @(posedge clk108MHz) begin
	// generate pipeline stage 7 signals 
	clydeSpriteRow_stg7[3:0]    <= videoRow_stg6[5:2]    - clydeTopRow[3:0];     // skipping video bits 1 and 0 duplicates rows
	clydeSpriteColumn_stg7[3:0] <= videoColumn_stg6[5:2] - clydeLeftColumn[3:0]; // skipping video bits 1 and 0 duplicates columns	

	// generate pipeline stage 8 signals
	clydeVideoPixelIndex_stg8[1:0] <= ClydeSpriteSet[{clydeImage[2:0],clydeSpriteRow_stg7[3:0],clydeSpriteColumn_stg7[3:0]}];
	videoPixelWithinClyde_stg8 <= clydeLeftColumn<=videoColumn_stg7[9:2] & videoColumn_stg7[9:2]<=clydeRightColumn & clydeTopRow<=videoRow_stg7[9:2] & videoRow_stg7[9:2]<=clydeBottomRow;	

	// generate pipeline stage 9 signals 
	if (!videoPixelWithinClyde_stg8) videoPixelRGB_stg9[11:0] <= videoPixelRGB_stg8[11:0]; // if not in sprite location, don't change pixel
	else case(clydeVideoPixelIndex_stg8[1:0])
		0: videoPixelRGB_stg9[11:0] <= videoPixelRGB_stg8[11:0]; // transparent
		1: videoPixelRGB_stg9[11:0] <= 12'hF80; // orange Clyde body
		2: videoPixelRGB_stg9[11:0] <= 12'hFFF; // white part of eyes
		3: videoPixelRGB_stg9[11:0] <= 12'h00F; // blue part of eyes
	endcase
	videoRow_stg9[10:0] <= videoRow_stg8[10:0];
	videoColumn_stg9[10:0] <= videoColumn_stg8[10:0];
end		

////////////////////////
// Generate video signals to be sent to monitor
always_ff @(posedge clk108MHz) begin
	// Overlay black outside the tile locations	(including outside the display area)
	if ((videoColumn_stg9 >= 1024-64) | (videoRow_stg9 >= VD) | (videoColumn_stg9 <= 64)) {VGA_R, VGA_G, VGA_B} <= 12'h000; // Blanking
	else {VGA_R, VGA_G, VGA_B} <= videoPixelRGB_stg9[11:0];
	// generate video sync signals
	VGA_HS <= (videoColumn_stg9 >= (HD+HF)) && (videoColumn_stg9 <= (HD+HF+HR));
    VGA_VS <= (videoRow_stg9    >= (VD+VF)) && (videoRow_stg9    <= (VD+VF+VR));
end

endmodule