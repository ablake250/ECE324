 /*********************************************************************
File: Lab10_VideoSketch.sv
Module: Lab10_VideoSketch
Function: Implements a simple sketch utility (like a subset of Microsoft Paint) using a mouse and a 1280x1024 monitor.
Revisions:
12/23/2017 Tom Pritchard: First written
09/13/2018 Tom Pritchard: Converted to SystemVerilog, changed to high resolution image buffer, improved pipeline structure, added rgb2gray
*********************************************************************/
 
module Lab10_VideoSketch(
	input logic CLK100MHZ,
	
	// Button
	input logic CPU_RESETN, // Initializes the frame buffer (erases what's on the screen).
	                  // While the name of this button indicates it's used to reset a CPU, this logic uses it for a different purpose.
	                  // Unlike the other buttons on the Nexys4DDR, this button is negative true, so it's a 0 when pushed.
	
	// PS2 bidirectional ports for mouse
    inout tri PS2_DATA, PS2_CLK,
	
    // VGA outputs
    output logic VGA_VS, VGA_HS,
    output logic [3:0] VGA_R, VGA_G, VGA_B,
	
	// 7-segment displays
	output logic [7:0] AN,               // negative true anodes
	output logic DP,CA,CB,CC,CD,CE,CF,CG // negative true cathodes
);

/////////////////////////////////////////////////////////////////////
// Declarations
/////////////////////////////////////////////////////////////////////

////////////////////////
// Parameters
localparam BITS_IN_FRAME_BUFFER_COLUMN      = 11; // bits needed to address 1280 columns  
localparam BITS_IN_FRAME_BUFFER_ROW         = 10; // bits needed to address 960 rows
localparam BITS_IN_FRAME_BUFFER_COORDINATES = 11; // larger of BITS_IN_FRAME_BUFFER_COLUMN and BITS_IN_FRAME_BUFFER_ROW

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
// Clock and Reset Declarations
logic clk108MHz;
logic meta = 1, reset = 1; // assert reset by setting initial conditions to 1
logic initFrameBuffer, wrInitFrameBuffer;

////////////////////////
// Mouse Declarations
logic [8:0] xm,ym; // range is -256 to 255
logic newMouseButtonCenter, newMouseButtonRight, newMouseButtonLeft;
logic newMousePacketTick;
logic [11:0] newMouseColumn; // range needed is -256 to (1279 + 255)
logic [11:0] newMouseRow;    // range needed is -256 to (1023 + 255)
logic [10:0] mouseColumn = 640, mousePreviousColumn = 640; // range needed is 0 to 1279
logic [9:0] mouseRow = 480, mousePreviousRow = 480; // range needed is 0 to 1023
logic mouseButtonCenter, mouseButtonRight;
logic performDither, configMode;
logic mouseButtonLeft;

////////////////////////
// Linedraw Declarations
logic startLineDrawTick;
logic [BITS_IN_FRAME_BUFFER_COLUMN-1:0] columnWrBresenhamPixel;
logic [BITS_IN_FRAME_BUFFER_ROW   -1:0] rowWrBresenhamPixel;
logic requestWrBresenhamPixel;
logic grantWrBresenhamPixel;

////////////////////////
// Video Display Pipeline Declarations
logic [10:0] vidClmn, vidClmn_SketchOut, vidClmn_ConfigOut, vidClmn_MouseSpriteOut, vidClmn_DitherOut;
logic [10:0] vidRow , vidRow__SketchOut, vidRow__ConfigOut, vidRow__MouseSpriteOut, vidRow__DitherOut;
logic [23:0]          pixlRGB_SketchOut, pixlRGB_ConfigOut, pixlRGB_MouseSpriteOut;
logic [11:0] pixlRGB_DitherOut;
logic [ 2:0] selectedPaletteIndex;
logic [23:0] palette0Color, palette1Color, palette2Color, palette3Color, palette4Color, palette5Color, palette6Color, palette7Color;
logic paletteButtonLocation;
logic [23:0] colorAtMouseLocation;

////////////////////////
// 7-Segment Display Declarations
logic [7:0] sseg7, sseg6, sseg5, sseg4, sseg3, sseg2, sseg1, sseg0;


/////////////////////////////////////////////////////////////////////
// Tri-state pads
/////////////////////////////////////////////////////////////////////
// Make these two signals logic 1 when not being driven.
PULLUP ps2c_pu (.O(PS2_CLK)); 
PULLUP ps2d_pu (.O(PS2_DATA)); 

/////////////////////////////////////////////////////////////////////
// Generate Clock and Resets
/////////////////////////////////////////////////////////////////////

// Produce a 108 MHz clock for the data rate of an SXGA (1280x1024) monitor at 60 Hz.
// This clock is used not just for the video, but for all sequential logic in this module, to make everything synchronous.
videoClk108MHz videoClk108MHz_0 (
    .clk108MHz(clk108MHz),   // output clk108MHz
	.CLK100MHZ(CLK100MHZ)    // input CLK100MHZ
);

// Generate a reset signal with its falling edge synchronous to clk.
always_ff @(posedge clk108MHz) begin
	meta <= 0;
	reset <= meta;
end

// When CPU_RESETN button is pushed, constantly write to the frame buffer to initialize it.
always_ff @(posedge clk108MHz) begin
	initFrameBuffer <= !CPU_RESETN; // synchronize, and invert since this button becomes 0 when pushed.
	wrInitFrameBuffer <= initFrameBuffer; // extra flip-flop is to lower chance of metastability problems
end


/////////////////////////////////////////////////////////////////////
// Generate Mouse Logic
/////////////////////////////////////////////////////////////////////

mouse mouse0(
	.clk(clk108MHz), // There is some real-time logic in ps2, but 108 MHz vs. 100 MHz should be okay.
	.reset, 
	.ps2d(PS2_DATA), // ps/2 data line
	.ps2c(PS2_CLK), // ps/2 clock line
    .xm, // x-axis movement, MSB is sign bit
	.ym, // y-axis movement, MSB is sign bit
	.btnm({newMouseButtonCenter, newMouseButtonRight, newMouseButtonLeft}), // bit2 = center button, bit1 = right button, b0 = left button
    .m_done_tick(newMousePacketTick) // 1 = data packet received from mouse
);

// Generate the video column and row to where the mouse points.
assign newMouseColumn[11:0] = {1'b0,mouseColumn[10:0]} + {{4{xm[8]}},xm[7:0]}; // calculate location, even if outside of video boundaries
assign newMouseRow[11:0]    = {2'b0,mouseRow[9:0]}     - {{4{ym[8]}},ym[7:0]}; // subtract because mouseRow increases down the screen
always_ff @(posedge clk108MHz) begin
	if      (!newMousePacketTick)   mouseColumn <= mouseColumn;
	else if (newMouseColumn[11])    mouseColumn <= 0;    // limit movement to left edge
	else if (newMouseColumn > 1279) mouseColumn <= 1279; // limit movement to right edge
	else                            mouseColumn <= newMouseColumn[10:0];

	if      (!newMousePacketTick)   mouseRow <= mouseRow;
	else if (newMouseRow[11])       mouseRow <= 0;    // limit movement to top edge
	else if (newMouseRow > 1023)    mouseRow <= 1023; // limit movement to bottom edge
	else                            mouseRow <= newMouseRow[9:0];

	if (newMousePacketTick) mousePreviousColumn <= mouseColumn;
	if (newMousePacketTick) mousePreviousRow    <= mouseRow;
	
	// Generate the mouse button logic
	if (newMousePacketTick) mouseButtonCenter <= newMouseButtonCenter;
	if (newMousePacketTick) mouseButtonRight  <= newMouseButtonRight;
	
	if (!mouseButtonCenter & newMousePacketTick & newMouseButtonCenter) performDither <= !performDither; // toggle whether dithering   when center button pushed
	if (!mouseButtonRight  & newMousePacketTick & newMouseButtonRight ) configMode    <= !configMode;    // toggle whether configuring when right  button pushed
	
	if (newMousePacketTick) mouseButtonLeft <= newMouseButtonLeft;
end


/////////////////////////////////////////////////////////////////////
// Generate Linedraw Logic
/////////////////////////////////////////////////////////////////////
// Use Bresenham's line algorithm to write a line segment into the frame buffer.

// start drawing the line segment when get a new mouse packet, and the left button has been pressed during the last 2 packets.
always_ff @(posedge clk108MHz) startLineDrawTick <= !configMode & mouseButtonLeft & newMousePacketTick & newMouseButtonLeft;

// The longest line segment, with one clock cycle per pixel drawn, easily fits within the mouse's sampling rate,
// so x0, y0, x1, and y1 won't change while linedraw is running, and don't need to look at running output.
BresenhamLineDraw #(.BITS_IN_FRAME_BUFFER_COLUMN(BITS_IN_FRAME_BUFFER_COLUMN),
                    .BITS_IN_FRAME_BUFFER_ROW(BITS_IN_FRAME_BUFFER_ROW),
					.BITS_IN_FRAME_BUFFER_COORDINATES(BITS_IN_FRAME_BUFFER_COORDINATES)) 
	BresenhamLineDraw0 (
	.clk(clk108MHz),
	.start(startLineDrawTick),      // tick to start a line segment
	.running(),                     // line segment generation in process
	.x0(mousePreviousColumn[10:0]), // starting column
	.y0(mousePreviousRow[9:0]),     // starting row
	.x1(mouseColumn[10:0]),         // ending column
	.y1(mouseRow[9:0]),             // ending row
	.x(columnWrBresenhamPixel),     // column of frame buffer write location
	.y(rowWrBresenhamPixel),        // row of frame buffer write location
	.requestWrBresenhamPixel,       // request to write a pixel to frame buffer
	.grantWrBresenhamPixel          // the request to write a pixel is granted
);


///////////////////////////////////////////////////////////////////// 
// Generate the Video Display Pipeline
/////////////////////////////////////////////////////////////////////

////////////////////////
// Generate Video Display Column and Row.

always_ff @(posedge clk108MHz) begin
    if (vidClmn == HT-1) begin
        vidClmn <= 0;
        if (vidRow == VT-1) vidRow <= 0;
        else vidRow <= vidRow + 1;
    end
    else vidClmn <= vidClmn + 1;
end

// The following blocks are pipelined to enable a high clock frequency independent of how many algorithms are performed.
// Each block delays the timing signals by as many clocks cycles as needed to overlay whatever pixel data is modified by that block.

////////////////////////
// Generate the frame buffer, and display it.
sketchFrame sketchFrame0(
	.clk108MHz,
	.initFrameBufferButton(!CPU_RESETN), // inverted because CPU_RESETN button is 0 when pushed
	// pipeline signals
	.vidClmn_SketchIn(vidClmn), .vidClmn_SketchOut,
	.vidRow__SketchIn(vidRow),  .vidRow__SketchOut,
	                            .pixlRGB_SketchOut,
	// 8 palette colors
	.palette0Color, .palette1Color, .palette2Color, .palette3Color, .palette4Color, .palette5Color, .palette6Color, .palette7Color,
	// signals to write to frame buffer
	.requestWrBresenhamPixel,
	.grantWrBresenhamPixel,
	.columnWrBresenhamPixel,
	.rowWrBresenhamPixel,
	.selectedPaletteIndex
);

////////////////////////
// Display the 8 Palette Colors and the Featured Color in the lower right of the display.
configColors configColors0(
	.clk108MHz,
	.configMode,
	.mouseButtonLeft,
	.mouseColumn, 
	.mouseRow,
	.paletteButtonLocation,
	.colorAtMouseLocation,
	// pipeline signals
    .vidClmn_ConfigIn(vidClmn_SketchOut), .vidClmn_ConfigOut,
    .vidRow__ConfigIn(vidRow__SketchOut), .vidRow__ConfigOut,
    .pixlRGB_ConfigIn(pixlRGB_SketchOut), .pixlRGB_ConfigOut,
	// palette signals
	.selectedPaletteIndex,
	.palette0Color, .palette1Color, .palette2Color, .palette3Color, .palette4Color, .palette5Color, .palette6Color, .palette7Color
);

////////////////////////
// Display the Mouse Sprite 
displayMouseSprite displayMouseSprite0(
	.clk108MHz,
	.mouseColumn,
    .mouseRow,
    .paletteButtonLocation,
	// pipeline signals
    .vidClmn_MouseSpriteIn(vidClmn_ConfigOut), .vidClmn_MouseSpriteOut,
    .vidRow__MouseSpriteIn(vidRow__ConfigOut), .vidRow__MouseSpriteOut,
    .pixlRGB_MouseSpriteIn(pixlRGB_ConfigOut), .pixlRGB_MouseSpriteOut
);

////////////////////////
// Halftone to 4 bits/color/pixel
orderedDither orderedDither0(
	.clk108MHz,
	.performDither,
	// pipeline signals
	.vidClmn_DitherIn(vidClmn_MouseSpriteOut), .vidClmn_DitherOut,
    .vidRow__DitherIn(vidRow__MouseSpriteOut), .vidRow__DitherOut,
    .pixlRGB_DitherIn(pixlRGB_MouseSpriteOut), .pixlRGB_DitherOut
);

////////////////////////
// Send timing and data signals to Nexys4DDR VGA outputs
always_ff @(posedge clk108MHz) begin	
    VGA_HS <= (vidClmn_DitherOut >= (HD+HF)) && (vidClmn_DitherOut <= (HD+HF+HR));
    VGA_VS <= (vidRow__DitherOut >= (VD+VF)) && (vidRow__DitherOut <= (VD+VF+VR));
    if ((vidClmn_DitherOut < HD) && (vidRow__DitherOut < VD)) {VGA_R[3:0], VGA_G[3:0], VGA_B[3:0]} <= pixlRGB_DitherOut;
	else {VGA_R[3:0], VGA_G[3:0], VGA_B[3:0]} <=  12'h000; // black outside display region
end


///////////////////////////////////////////////////////////////////// 
// 7-Segment Displays
///////////////////////////////////////////////////////////////////// 
// Put the 24 bit/pixel color under the mouse pointer on the 7-segment displays
hex_to_sseg_p hts7(.hex(colorAtMouseLocation[23:20]), .dp(1'b0), .sseg_p(sseg7)); // Red   bits 7:4 on digit7 (hex)
hex_to_sseg_p hts6(.hex(colorAtMouseLocation[19:16]), .dp(1'b0), .sseg_p(sseg6)); // Red   bits 3:0 on digit6 (hex)
assign sseg5 = 8'h08; // underscore between red and green digits
hex_to_sseg_p hts4(.hex(colorAtMouseLocation[15:12]), .dp(1'b0), .sseg_p(sseg4)); // Green bits 7:4 on digit4 (hex)
hex_to_sseg_p hts3(.hex(colorAtMouseLocation[11: 8]), .dp(1'b0), .sseg_p(sseg3)); // Green bits 3:0 on digit3 (hex)
assign sseg2 = 8'h08; // underscore between green and blue digits
hex_to_sseg_p hts1(.hex(colorAtMouseLocation[ 7: 4]), .dp(1'b0), .sseg_p(sseg1)); // Blue  bits 7:4 on digit1 (hex)
hex_to_sseg_p hts0(.hex(colorAtMouseLocation[ 3: 0]), .dp(1'b0), .sseg_p(sseg0)); // Blue  bits 3:0 on digit0 (hex)

// Instantiate 7-segment LED display time-multiplexing module
led_mux8_p dm8_0(
    .clk(CLK100MHZ), .reset(1'b0), 
    .in7(sseg7), .in6(sseg6), .in5(sseg5), .in4(sseg4), .in3(sseg3), .in2(sseg2), .in1(sseg1), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA})
);

endmodule
