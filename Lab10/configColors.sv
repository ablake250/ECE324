/*********************************************************************
File: configColors.sv
Module: configColors
Function: Displays configuration image, and enables selection of 8 palette colors
Revisions:
09/14/2018 Tom Pritchard: First written
*********************************************************************/
module configColors(
	input logic clk108MHz, // clock
	input logic configMode,
	input logic mouseButtonLeft,
	input logic [10:0] mouseColumn, 
	input logic [ 9:0] mouseRow,
	output logic paletteButtonLocation,
	output logic [23:0] colorAtMouseLocation,
	// pipeline signals
	input logic [10:0] vidClmn_ConfigIn, output logic [10:0] vidClmn_ConfigOut,
	input logic [10:0] vidRow__ConfigIn, output logic [10:0] vidRow__ConfigOut,
	input logic [23:0] pixlRGB_ConfigIn, output logic [23:0] pixlRGB_ConfigOut,
	// palette signals
	output logic [2:0] selectedPaletteIndex = 3'b000,
	//                                       R  G  B
	output logic [23:0] palette0Color = 24'h00_00_00, // black: initial selected palette color
	output logic [23:0] palette1Color = 24'h20_20_20, // dark grey
	output logic [23:0] palette2Color = 24'h40_40_40, // 
	output logic [23:0] palette3Color = 24'h60_60_60, // 
	output logic [23:0] palette4Color = 24'h80_80_80, // medium grey
	output logic [23:0] palette5Color = 24'hA0_A0_A0, // 
	output logic [23:0] palette6Color = 24'hC0_C0_C0, // light grey
	output logic [23:0] palette7Color = 24'hFF_FF_FF  // white: initial background color
);

////////////////////////////////////
// Declarations
logic [10:0] vidClmn_ConfigStg2, vidRow__ConfigStg2;
logic [10:0] vidClmn_ConfigStg3, vidRow__ConfigStg3;
logic [10:0] vidClmn_ConfigStg4, vidRow__ConfigStg4;
logic [23:0] pixlRGB_Stg2, pixlRGB_Stg3;
logic [12:0] addrPaletteTileMem_Stg2;
(* rom_style = "block" *) logic [1:0] paletteTileMem [0:8191]; // memory array for palette tiles
initial $readmemh ("paletteTileMem.txt", paletteTileMem, 0, 8191); // initialize paletteTileMem
logic [2:0] paletteTilePixel_Stg3;
logic [23:0] pixlRGB_Stg4;
logic [23:0] previewColor;
logic changePaletteColor;
logic [23:0] selectedPaletteColor;


////////////////////////////////////
// Pipeline pixel location signals
always_ff @(posedge clk108MHz) begin
    vidClmn_ConfigStg2 <= vidClmn_ConfigIn;   vidRow__ConfigStg2 <= vidRow__ConfigIn; 
    vidClmn_ConfigStg3 <= vidClmn_ConfigStg2; vidRow__ConfigStg3 <= vidRow__ConfigStg2;
    vidClmn_ConfigStg4 <= vidClmn_ConfigStg3; vidRow__ConfigStg4 <= vidRow__ConfigStg3;
    vidClmn_ConfigOut  <= vidClmn_ConfigStg4; vidRow__ConfigOut  <= vidRow__ConfigStg4;
end


////////////////////////////////////
// Display image
always_ff @(posedge clk108MHz) begin
    if (!configMode) pixlRGB_Stg2 <= pixlRGB_ConfigIn;
	// Generate the configuration image background colors
	else if (vidClmn_ConfigIn < 1024) pixlRGB_Stg2 <= {~vidRow__ConfigIn[9:2], selectedPaletteColor[15:8], vidClmn_ConfigIn[9:2]}; // left of screen shows a 24 bit/pixel color cube slice
	else if (vidClmn_ConfigIn < 1056) pixlRGB_Stg2 <= {~vidRow__ConfigIn[9:2], 8'h00, 8'h00}; // red   amplitude bar
	else if (vidClmn_ConfigIn < 1088) pixlRGB_Stg2 <= {8'h00, ~vidRow__ConfigIn[9:2], 8'h00}; // green amplitude bar
	else if (vidClmn_ConfigIn < 1120) pixlRGB_Stg2 <= {8'h00, 8'h00, ~vidRow__ConfigIn[9:2]}; // blue  amplitude bar
	else if (vidClmn_ConfigIn < 1152) pixlRGB_Stg2 <= {{3{~vidRow__ConfigIn[9:2]}}};          // gray  amplitude bar
	else if (vidClmn_ConfigIn < 1216) pixlRGB_Stg2 <= {~vidRow__ConfigIn[5:2],4'h0, ~vidRow__ConfigIn[9:6],4'h0, vidClmn_ConfigIn[5:2],4'h0}; // eight 12 bit/pixel color cube slices
	else if (!vidRow__ConfigIn[9]) case (vidRow__ConfigIn[8:6]) // upper right of display shows the 8 palette colors
		0: pixlRGB_Stg2 <= palette0Color[23:0];
		1: pixlRGB_Stg2 <= palette1Color[23:0];
		2: pixlRGB_Stg2 <= palette2Color[23:0];
		3: pixlRGB_Stg2 <= palette3Color[23:0];
		4: pixlRGB_Stg2 <= palette4Color[23:0];
		5: pixlRGB_Stg2 <= palette5Color[23:0];
		6: pixlRGB_Stg2 <= palette6Color[23:0];
		7: pixlRGB_Stg2 <= palette7Color[23:0];
	endcase
	else if (vidRow__ConfigIn[8:6] != 3'b111) pixlRGB_Stg2 <= palette7Color[23:0]; // background in sample line sketch
	else pixlRGB_Stg2 <= previewColor; // lower right of display shows preview color
	// anything non-zero outside of the 1280x1024 display range will be cleared later before sending to the monitor

	// Generate the preview color, and overwrite the preview line onto the background
	previewColor[23:0] <= selectedPaletteColor; // default unless changed below
    if      (mouseColumn < 1024) previewColor[23:16] <= colorAtMouseLocation[23:16]; // 24 bit/pixel color cube slice; red changes, but leave green alone
    if      (mouseColumn < 1024) previewColor[ 7: 0] <= colorAtMouseLocation[ 7: 0]; // 24 bit/pixel color cube slice; blue changes, but leave green alone
    else if (mouseColumn < 1056) previewColor[23:16] <= colorAtMouseLocation[23:16]; // red amplitude bar; only red changes
    else if (mouseColumn < 1088) previewColor[15: 8] <= colorAtMouseLocation[15: 8]; // green amplitude bar; only green changes
    else if (mouseColumn < 1120) previewColor[ 7: 0] <= colorAtMouseLocation[ 7: 0]; // blue amplitude bar; only blue changes
    else if (mouseColumn < 1152) previewColor[23: 0] <= colorAtMouseLocation[23: 0]; // gray amplitude bar; all colors change
    else if (mouseColumn < 1216) previewColor[23: 0] <= colorAtMouseLocation[23: 0]; // 8 bit/pixel color cube slices; all colors change

    if (configMode & (vidClmn_ConfigStg2 == 1248) & (vidRow__ConfigStg2 >= 544) & (vidRow__ConfigStg2 < 928)) pixlRGB_Stg3 <= previewColor;
    else pixlRGB_Stg3 <= pixlRGB_Stg2;
end

	// Overwrite borders on palette buttons
always_comb begin
	addrPaletteTileMem_Stg2[11:0]  = {vidRow__ConfigStg2[5:0],vidClmn_ConfigStg2[5:0]}; // location within each 64x64 tile
    addrPaletteTileMem_Stg2[12]  = (selectedPaletteIndex[2:0] == vidRow__ConfigStg2[8:6]) | vidRow__ConfigStg2[9]; // selected border tile
end

always_ff @(posedge clk108MHz) begin
    paletteTilePixel_Stg3[1:0] <= paletteTileMem[addrPaletteTileMem_Stg2[12:0]]; // read the palette tile memory	
   
	if (!configMode | (vidClmn_ConfigStg3 < 1216) | (vidRow__ConfigStg3[9] & (vidRow__ConfigIn[8:6] != 3'b111))) pixlRGB_Stg4 <= pixlRGB_Stg3; // bypass if not in a tiled location
    else case (paletteTilePixel_Stg3[1:0])
        2'b00: pixlRGB_Stg4 <= 24'hD0_D0_D0; // light grey for color surrounding palette color
        2'b01: pixlRGB_Stg4 <= 24'h40_40_40; // dark grey for upper and left shadow, and for select highlight
        2'b10: pixlRGB_Stg4 <= 24'hFF_FF_FF; // white for lower and right shadow
        2'b11: pixlRGB_Stg4 <= pixlRGB_Stg3; // passthrough
    endcase

    // Save color at mouse location (and below selectedColor markers and mouse sprite)
    if ((vidClmn_ConfigStg4[10:0] == mouseColumn[10:0]) & (vidRow__ConfigStg4[9:0] == mouseRow[9:0])) begin
        colorAtMouseLocation[23:0] <= pixlRGB_Stg4[23:0];    
    end
     
    // Overwrite selectedColor markers
    pixlRGB_ConfigOut <= pixlRGB_Stg4; // default pass-through
    if (configMode) begin      
        // overwrite crosshair pattern (except over center superpixel) onto 24 bit/pixel color cube slice on left of screen
        if ((vidClmn_ConfigStg4 < 1024) & ((vidRow__ConfigStg4[9:2] == ~selectedPaletteColor[23:16]) ^ (vidClmn_ConfigStg4[9:2] == selectedPaletteColor[7:0]))) begin
            pixlRGB_ConfigOut <= {24{vidRow__ConfigStg4[0] ^ vidClmn_ConfigStg4[0]}}; // black and white checkerboard to always provide some contrast no matter what the background
        end
        // overwrite horizontal markers on the RGB amplitude bars
        if ((vidClmn_ConfigStg4 >= 1024) & (vidClmn_ConfigStg4 < 1056) & (vidRow__ConfigStg4[10:2] == {1'b0,~selectedPaletteColor[23:16]})) pixlRGB_ConfigOut <= {24{vidRow__ConfigStg4[0] ^ vidClmn_ConfigStg4[0]}}; // red
        if ((vidClmn_ConfigStg4 >= 1056) & (vidClmn_ConfigStg4 < 1088) & (vidRow__ConfigStg4[10:2] == {1'b0,~selectedPaletteColor[15: 8]})) pixlRGB_ConfigOut <= {24{vidRow__ConfigStg4[0] ^ vidClmn_ConfigStg4[0]}}; // green
        if ((vidClmn_ConfigStg4 >= 1088) & (vidClmn_ConfigStg4 < 1120) & (vidRow__ConfigStg4[10:2] == {1'b0,~selectedPaletteColor[ 7: 0]})) pixlRGB_ConfigOut <= {24{vidRow__ConfigStg4[0] ^ vidClmn_ConfigStg4[0]}}; // blue
	end
end


////////////////////////////////////
// Respond to the left mouse button to configure the colors

always_ff @(posedge clk108MHz) begin
	// Change which of the 8 palette colors is currently selected
	paletteButtonLocation <= (mouseColumn[10:0] >= 1232) & (mouseColumn[10:0] < 1264) & // within the 32 columns used to display the 8 palette colors
                             !mouseRow[9] & (mouseRow[5] ^ mouseRow[4]) &               // within the rows used to display the 8 palette colors
                             configMode;
	if (mouseButtonLeft & paletteButtonLocation) selectedPaletteIndex[2:0] <= mouseRow[8:6]; // change selected palette color

	// Generate the 8 palette colors
	changePaletteColor <= configMode & mouseButtonLeft & (mouseColumn < 1216);
	if (changePaletteColor) case (selectedPaletteIndex[2:0])
		0: palette0Color[23:0] <= previewColor[23:0];
		1: palette1Color[23:0] <= previewColor[23:0];
		2: palette2Color[23:0] <= previewColor[23:0];
		3: palette3Color[23:0] <= previewColor[23:0];
		4: palette4Color[23:0] <= previewColor[23:0];
		5: palette5Color[23:0] <= previewColor[23:0];
		6: palette6Color[23:0] <= previewColor[23:0];
		7: palette7Color[23:0] <= previewColor[23:0];
	endcase
	
	case (selectedPaletteIndex[2:0])
        0: selectedPaletteColor[23:0] <= palette0Color[23:0];
        1: selectedPaletteColor[23:0] <= palette1Color[23:0];
        2: selectedPaletteColor[23:0] <= palette2Color[23:0];
        3: selectedPaletteColor[23:0] <= palette3Color[23:0];
        4: selectedPaletteColor[23:0] <= palette4Color[23:0];
        5: selectedPaletteColor[23:0] <= palette5Color[23:0];
        6: selectedPaletteColor[23:0] <= palette6Color[23:0];
        7: selectedPaletteColor[23:0] <= palette7Color[23:0];
    endcase   
end

endmodule	
