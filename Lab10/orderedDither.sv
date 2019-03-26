/*********************************************************************
File: orderedDither.sv
Module: orderedDither
Function: Perform a 4x4 ordered dithering algorithm to convert 24 to 12 bit RGB
Revisions:
2018 Oct 27 Tom Pritchard: First written
*********************************************************************/
module orderedDither(
	input logic clk108MHz, // clock
	input logic performDither, // switch controlled
	// pipeline signals
	input logic [10:0] vidClmn_DitherIn, output logic [10:0] vidClmn_DitherOut,
	input logic [10:0] vidRow__DitherIn, output logic [10:0] vidRow__DitherOut,
	input logic [23:0] pixlRGB_DitherIn, output logic [11:0] pixlRGB_DitherOut
);

logic [3:0] th [0:3] [0:3]; // threshold
logic [7:0] red, grn, blu;
logic [1:0] ditherClmn, ditherRow;

always_comb begin
	// these thresholds came from the Ordered dithering article in Wikipedia
	th[0][0]= 0; th[1][0]= 8; th[2][0]= 2; th[3][0]=10;
	th[0][1]=12; th[1][1]= 4; th[2][1]=14; th[3][1]= 6;
	th[0][2]= 3; th[1][2]=11; th[2][2]= 1; th[3][2]= 9;
	th[0][3]=15; th[1][3]= 7; th[2][3]=13; th[3][3]= 5;
	
	red[7:0] = pixlRGB_DitherIn[23:16];
	grn[7:0] = pixlRGB_DitherIn[15: 8];
	blu[7:0] = pixlRGB_DitherIn[ 7: 0];
	
	ditherClmn[1:0] = vidClmn_DitherIn[1:0];
	ditherRow[1:0]  = vidRow__DitherIn[1:0];
end

always_ff @(posedge clk108MHz) begin
	// pipeline signals
	vidClmn_DitherOut <= vidClmn_DitherIn;
	vidRow__DitherOut <= vidRow__DitherIn;

	pixlRGB_DitherOut <= {red[7:4],grn[7:4],blu[7:4]}; // default, may be changed below
	if (performDither) begin
		if((red[3:0] > th[ditherClmn[1:0]][ditherRow[1:0]]) & (red[7:4] < 4'b1111)) pixlRGB_DitherOut[11: 8] <= red[7:4] + 1;
		if((grn[3:0] > th[ditherClmn[1:0]][ditherRow[1:0]]) & (grn[7:4] < 4'b1111)) pixlRGB_DitherOut[ 7: 4] <= grn[7:4] + 1;
		if((blu[3:0] > th[ditherClmn[1:0]][ditherRow[1:0]]) & (blu[7:4] < 4'b1111)) pixlRGB_DitherOut[ 3: 0] <= blu[7:4] + 1;
	end
end

endmodule	
