/*********************************************************************
File: sketchFrame.sv
Module: sketchFrame
Function: Generates a full-screen image buffer, and displays it.
Revisions:
09/13/2018 Tom Pritchard: First written
*********************************************************************/
 
 module sketchFrame(
	input  logic clk108MHz, // clock
	input  logic initFrameBufferButton,
	// pipeline signals
	input  logic [10:0] vidClmn_SketchIn, output logic [10:0] vidClmn_SketchOut,
	input  logic [10:0] vidRow__SketchIn, output logic [10:0] vidRow__SketchOut,
	                                      output logic [23:0] pixlRGB_SketchOut,
	// 8 palette colors
	input  logic [23:0] palette0Color, palette1Color, palette2Color, palette3Color, palette4Color, palette5Color, palette6Color, palette7Color,
	// signals to write to frame buffer
	input  logic requestWrBresenhamPixel,
	output logic grantWrBresenhamPixel,
	input  logic [10:0] columnWrBresenhamPixel,
	input  logic [ 9:0] rowWrBresenhamPixel,
	input  logic [2:0] selectedPaletteIndex
);

/////////////////////////////////////////////////////////////////////
// Declarations
/////////////////////////////////////////////////////////////////////
logic [34:0] columnWrBresenhamPixel_x_11184811;
logic [9:0] triColumnWrBresenhamPixel;
logic [1:0] subPointerToBresenhamPixel;
logic [8:0] dina_FrameBuffer;

logic initFrameBuffer, wrInitFrameBuffer;
logic [8:0] douta_FrameBuffer;
logic [8:0] doutb_FrameBuffer_Stg5;

logic [34:0] columnRdVideoPixel_x_11184811_stg2;
logic [9:0] triColumnRdVideoPixel_stg2;
logic [1:0] subPointerToVideoPixel_stg2;
logic [10:0] vidClmn_SketchStg2, vidRow__SketchStg2;

logic [1:0] subPointerToVideoPixel_stg3;
logic [10:0] vidClmn_SketchStg3, vidRow__SketchStg3; 

logic [1:0] subPointerToVideoPixel_stg4;
logic [10:0] vidClmn_SketchStg4, vidRow__SketchStg4; 

logic [1:0] subPointerToVideoPixel_stg5;
logic [10:0] vidClmn_SketchStg5, vidRow__SketchStg5; 

logic [2:0] pixelIndex_Stg6;
logic [10:0] vidClmn_SketchStg6, vidRow__SketchStg6; 


///////////////////////////////////////////////////////////////////// 
// Bresenham Write to port A of Frame Buffer
/////////////////////////////////////////////////////////////////////
// To minimize the number of BRAMs used, there are 3 pixels in each frame buffer memory location, but we need to change only one of them at a time.
// The way it's done here is to read the memory word, modify the one pixel, and then write the result back to the same location many clock cycles later.

// Since there are 3 horizontally-adjacent pixels in each memory location, we need to divide the Bresenham column by 3 to get the memory column.
divideBy3 #(11) div3a(.clk(clk108MHz), .dividend(columnWrBresenhamPixel[10:0]), .quotient(triColumnWrBresenhamPixel[9:0]), .remainder(subPointerToBresenhamPixel[1:0]));

// Wait until douta_FrameBuffer is valid before writing to dina_FrameBuffer
typedef enum {stateGenAddr, stateReadSram, stateAccessBRAMs, stateChooseBRAM, stateGenDin, stateWriteSram} state_type;
state_type state = stateGenAddr;
always_ff @(posedge clk108MHz) begin
    grantWrBresenhamPixel <= 0; // default
	case (state)
		stateGenAddr     : if (requestWrBresenhamPixel) state <= stateReadSram;
		stateReadSram    : state <= stateAccessBRAMs;
		stateAccessBRAMs : state <= stateChooseBRAM;
		stateChooseBRAM  : state <= stateGenDin;
		stateGenDin      : begin state <= stateWriteSram; grantWrBresenhamPixel <= 1; end
		stateWriteSram   : state <= stateGenAddr;
		default          : state <= stateGenAddr;
	endcase
end

always_ff @(posedge clk108MHz) begin
    // Since we want to change only one pixel within a memory word at a time, a read/modify/write operation is performed.
    dina_FrameBuffer <= douta_FrameBuffer; // all except one pixel read from the SRAM get written back out to the SRAM	
    case (subPointerToBresenhamPixel[1:0]) // selects the one pixel that gets modified
        0: dina_FrameBuffer[ 2:0] <= selectedPaletteIndex[2:0];
        1: dina_FrameBuffer[ 5:3] <= selectedPaletteIndex[2:0];
        2: dina_FrameBuffer[ 8:6] <= selectedPaletteIndex[2:0];
    endcase
end


///////////////////////////////////////////////////////////////////// 
// Frame Buffer
/////////////////////////////////////////////////////////////////////
// Single frame buffer for a full 1280x1024 (SXGA) display to a depth of 3 bits, using a 1280 wide x 1024 high x3 bits/pixel frame buffer.
// The frame buffer is composed of an SRAM produced by the Xilinx Block Memory Generator.
// While typically the addresses of pixels is in a row-major order, in this case it's easier to use a pixel-major order since the number of rows is a power of 2.

// Generate the signal to initialize the frame buffer
always_ff @(posedge clk108MHz) begin
	initFrameBuffer <= initFrameBufferButton; // synchronize button to clock
	wrInitFrameBuffer <= initFrameBuffer; // extra flip-flop is to lower chance of metastability problems
end

frameBuffer frameBuffer0 (
	// Port A used for the Bresenham read/modify/write operation
	// Port A is produced with both primitive and core registers, resulting in a latency of 3 clock cycles.
	.clka(clk108MHz),                                                  // input wire clka
	.ena(requestWrBresenhamPixel),                                     // input wire ena
	.wea(grantWrBresenhamPixel),                                       // input wire [0 : 0] wea
	.addra({triColumnWrBresenhamPixel[8:0],rowWrBresenhamPixel[9:0]}), // input wire [18 : 0] addra; 427 triColumns, 1024 rows
	.dina(dina_FrameBuffer[8:0]),                                      // input wire [8 : 0] dina
	.douta(douta_FrameBuffer[8:0]),                                    // output wire [8 : 0] douta
	
	// Port B used for reading frame buffer to be output to video, and writing to initialize frame buffer  
    // Port B is initially produced with neither primitive nor core registers, resulting in a latency of 1 clock cycle, but students will add 2 more.
    .clkb(clk108MHz),                                                  // input wire clkb
    .enb(1'b1),                                                        // input wire enb; always access, even when not using the read results
    .web(wrInitFrameBuffer),                                           // input wire [0 : 0] web
    .addrb({triColumnRdVideoPixel_stg2[8:0],vidRow__SketchStg2[9:0]}), // input wire [18 : 0] addrb; 427 triColumns, 1024 Rows
    .dinb({3{3'd7}}),                                                  // input wire [8 : 0] dinb; initialized color in frame buffer is palette7
    .doutb(doutb_FrameBuffer_Stg5[8:0])                                // output wire [8 : 0] doutb
);


///////////////////////////////////////////////////////////////////// 
// Video Read Pipeline using Port B of Frame Buffer
/////////////////////////////////////////////////////////////////////
// Pipeline stage 1
// Since there are 3 horizontally-adjacent pixels in each memory location, we need to divide the video column by 3 to get the memory column.
divideBy3 #(11) div3b(.clk(clk108MHz), .dividend(vidClmn_SketchIn[10:0]), .quotient(triColumnRdVideoPixel_stg2[9:0]), .remainder(subPointerToVideoPixel_stg2[1:0]));

always_ff @(posedge clk108MHz) begin 
    vidClmn_SketchStg2 <= vidClmn_SketchIn;   
    vidRow__SketchStg2 <= vidRow__SketchIn;
end

///////////////////
// Pipeline stage 2
// Send the read command to the frame buffer
always_ff @(posedge clk108MHz) begin
    subPointerToVideoPixel_stg3 <= subPointerToVideoPixel_stg2;
    vidClmn_SketchStg3 <= vidClmn_SketchStg2; 
    vidRow__SketchStg3 <= vidRow__SketchStg2;
end

///////////////////
// Pipeline stage 3
// Access BRAMs
always_ff @(posedge clk108MHz) begin
    subPointerToVideoPixel_stg4  <= subPointerToVideoPixel_stg3;
    vidClmn_SketchStg4  <= vidClmn_SketchStg3; 
    vidRow__SketchStg4  <= vidRow__SketchStg3; 
end

///////////////////
// Pipeline stage 4
// Choose which BRAM will drive the frame buffer output
always_ff @(posedge clk108MHz) begin
    subPointerToVideoPixel_stg5  <= subPointerToVideoPixel_stg4;
    vidClmn_SketchStg5  <= vidClmn_SketchStg4; 
    vidRow__SketchStg5  <= vidRow__SketchStg4;
end

///////////////////
// Pipeline stage 5
// Choose which of 3 pixels to use from the SRAM word
always_ff @(posedge clk108MHz) begin 
    case(subPointerToVideoPixel_stg5[1:0])
        0: pixelIndex_Stg6  <= doutb_FrameBuffer_Stg5[2:0];
        1: pixelIndex_Stg6  <= doutb_FrameBuffer_Stg5[5:3];
        2: pixelIndex_Stg6  <= doutb_FrameBuffer_Stg5[8:6];
        default: pixelIndex_Stg6  <= 3'bxxx; // should never happen
    endcase
    
    vidClmn_SketchStg6  <= vidClmn_SketchStg5; 
    vidRow__SketchStg6  <= vidRow__SketchStg5;
end

///////////////////
// Pipeline stage 6
// Decode the color index read from the frame buffer to get the 24 bit RGB color.
always_ff @(posedge clk108MHz) begin
    case(pixelIndex_Stg6[2:0])
        0: pixlRGB_SketchOut[23:0]  <= palette0Color[23:0];
        1: pixlRGB_SketchOut[23:0]  <= palette1Color[23:0];
        2: pixlRGB_SketchOut[23:0]  <= palette2Color[23:0];
        3: pixlRGB_SketchOut[23:0]  <= palette3Color[23:0];
        4: pixlRGB_SketchOut[23:0]  <= palette4Color[23:0];
        5: pixlRGB_SketchOut[23:0]  <= palette5Color[23:0];
        6: pixlRGB_SketchOut[23:0]  <= palette6Color[23:0];
        7: pixlRGB_SketchOut[23:0]  <= palette7Color[23:0];
        // default not needed since all cases covered
        // Any non-zero data outside of the 1280x1024 display region will be cleared later before sending it to the monitor.
    endcase
    
    vidClmn_SketchOut  <= vidClmn_SketchStg6; 
    vidRow__SketchOut  <= vidRow__SketchStg6; 
end

endmodule