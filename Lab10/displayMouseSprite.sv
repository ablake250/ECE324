/*********************************************************************
File: displayMouseSprite.sv
Module: displayMouseSprite
Function: Displays a mouse pointer on a 1280 x 1024 monitor.
Revisions:
09/14/2018 Tom Pritchard: First written
*********************************************************************/
module displayMouseSprite(
	input logic clk108MHz, // clock
	input logic [10:0] mouseColumn,
    input logic [ 9:0] mouseRow,
    input logic paletteButtonLocation,
	// pipeline signals
	input logic [10:0] vidClmn_MouseSpriteIn, output logic [10:0] vidClmn_MouseSpriteOut,
	input logic [10:0] vidRow__MouseSpriteIn, output logic [10:0] vidRow__MouseSpriteOut,
	input logic [23:0] pixlRGB_MouseSpriteIn, output logic [23:0] pixlRGB_MouseSpriteOut
);

// Declarations
logic [10:0] vidClmn_MouseSprite_Stg2;
logic [10:0] vidRow__MouseSprite_Stg2;
logic [23:0] pixlRGB_MouseSprite_Stg2;

logic [4:0] mouseSpriteColumn;
logic [4:0] mouseSpriteRow;
logic [10:0] addrMouseSpriteMem;
(* rom_style = "block" *) logic [1:0] mouseSpriteMem [0:2047]; // memory array for mouse sprites
initial $readmemh ("mouseSpriteMem.txt", mouseSpriteMem, 0, 2047); // initialize mouseSpriteMem
logic [1:0] mouseSpritePixel_Stg2;

always_ff @(posedge clk108MHz) begin
	// pipeline signals
	vidClmn_MouseSpriteOut <= vidClmn_MouseSprite_Stg2; vidClmn_MouseSprite_Stg2 <= vidClmn_MouseSpriteIn;
	vidRow__MouseSpriteOut <= vidRow__MouseSprite_Stg2; vidRow__MouseSprite_Stg2 <= vidRow__MouseSpriteIn;
	                                                    pixlRGB_MouseSprite_Stg2 <= pixlRGB_MouseSpriteIn;
end
	
// Overwrite the mouse sprite pixels.
assign mouseSpriteColumn[4:0] = vidClmn_MouseSpriteIn[4:0] - mouseColumn[4:0] + 5'd16; // mouse pixel location in each sprite is 16 columns from the left edge
assign mouseSpriteRow[4:0]    = vidRow__MouseSpriteIn[4:0] - mouseRow[4:0]; // mouse pixel location in each sprite is at the top edge
assign addrMouseSpriteMem[10:0] = {paletteButtonLocation,mouseSpriteRow[4:0],mouseSpriteColumn[4:0]};

always_ff @(posedge clk108MHz) begin
	// read the mouse sprite memory
	mouseSpritePixel_Stg2[1:0] <= mouseSpriteMem[addrMouseSpriteMem[10:0]];
	
	if (((vidClmn_MouseSprite_Stg2 + 11'd16) < mouseColumn) |       // if videoColumn is to the left of the mouse sprite location, or
	     (vidClmn_MouseSprite_Stg2 >= (mouseColumn + 11'd16)) |     // if videoColumn is to the right of the mouse sprite location, or
	     ((vidRow__MouseSprite_Stg2) < {1'b0,mouseRow}) |           // if videoRow is above the mouse sprite location, or
		 (vidRow__MouseSprite_Stg2 >= ({1'b0,mouseRow} + 11'd32)) | // if videoRow is below the mouse sprite location, or
	     (mouseSpritePixel_Stg2[1:0] == 2'b00))                     // if the mouse sprite is transparent at this location,
			                           pixlRGB_MouseSpriteOut <= pixlRGB_MouseSprite_Stg2; // then the mouse doesn't affect this pixel.
	else if (mouseSpritePixel_Stg2[0]) pixlRGB_MouseSpriteOut <= 24'h00_00_00; // black
	else                               pixlRGB_MouseSpriteOut <= 24'hFF_FF_FF; // white
end

endmodule	
