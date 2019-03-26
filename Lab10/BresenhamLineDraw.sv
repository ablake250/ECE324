// File: BresenhamLineDraw.sv

// Function:
// This implements Bresenham's line algorithm, which draws a line segment between two (x,y) coordinates in a frame buffer.
// It's based roughly on the algorithm in https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm, but instead of
// swapping the x and y axes and/or reversing the direction of x, instead both x and y can be incremented or decremented.
// This design assumes the frame buffer can always be written every clock cycle.
//
// Revisions:
// 2018Jan21 Tom Pritchard: Initially written.
// 2018Sep25 Tom Pritchard: Converted to SystemVerilog
// 2018Nov30 Tom Pritchard: Added request/grant handshake to enable stalling writing pixels to the frame buffer

module BresenhamLineDraw #(parameter BITS_IN_FRAME_BUFFER_COLUMN=10, 
                                     BITS_IN_FRAME_BUFFER_ROW=9, 
									 BITS_IN_FRAME_BUFFER_COORDINATES=10) ( // max(BITS_IN_FRAME_BUFFER_COLUMN,BITS_IN_FRAME_BUFFER_ROW)
	input logic clk,
	input logic start,             // one clock cycle tick to start the process
	output logic running = 0,      // indicates when this process is busy; don't generate another start until running is low.
	
	// line segment starting and ending locations; these should be made valid from start until running goes low.
	input logic [BITS_IN_FRAME_BUFFER_COLUMN-1:0] x0, // the start x location in frame buffer
	input logic [BITS_IN_FRAME_BUFFER_ROW   -1:0] y0, // the start y location in frame buffer
	input logic [BITS_IN_FRAME_BUFFER_COLUMN-1:0] x1, // the end x location in frame buffer
	input logic [BITS_IN_FRAME_BUFFER_ROW   -1:0] y1, // the end y location in frame buffer
 
	// Frame Buffer write signals
	output logic [BITS_IN_FRAME_BUFFER_COLUMN-1:0] x,  // the current x write location in frame buffer
	output logic [BITS_IN_FRAME_BUFFER_ROW   -1:0] y,  // the current y write location in frame buffer
	output logic requestWrBresenhamPixel = 0,          // request to write a pixel to frame buffer
	input  logic grantWrBresenhamPixel                 // the request to write a pixel is granted
);

// Declarations
logic [BITS_IN_FRAME_BUFFER_COLUMN-1:0] dx; // absolute value of the distance between the x coordinates
logic [BITS_IN_FRAME_BUFFER_ROW   -1:0] dy; // absolute value of the distance between the y coordinates
logic drawLeft, drawUp, drawSteep; // derived octant the line segment is in
logic [BITS_IN_FRAME_BUFFER_COORDINATES+1:0] D_AddendDontAdvance, D_AddendAdvance; // pre-calculated two possible addends to D
logic startDelayed1 = 0, startDelayed2 = 0; // delayed signals from start
logic [BITS_IN_FRAME_BUFFER_COORDINATES+1:0] D; // This is the "error" distance from the threshold that determines when to advance the row or column.

// Line Drawing Algorithm
always_ff @(posedge clk) begin
	// set up in advance the variables that are fixed for the whole line segment,
	// using multiple clock cycles to enable a higher clock frequency.
	dx <= (x1 < x0) ? (x0 - x1) : (x1 - x0); // magnitude of x distance of line segment
	dy <= (y1 < y0) ? (y0 - y1) : (y1 - y0); // magnitude of y distance of line segment
	drawLeft <= (x1 < x0); // x direction of drawing
	drawUp   <= (y1 < y0); // y direction of drawing
	drawSteep <= (dy > dx); // indicates if slope of line segment is closer to vertical than horizontal.
	D_AddendDontAdvance <= !drawSteep ? 2*dy : 2*dx; // pre-calculate the next addend to D when haven't yet reached the threshold
	D_AddendAdvance <= !drawSteep ? (2*dy - 2*dx) : (2*dx - 2*dy); // pre-calculate the next addend to D when have reached the threshold
	
	// initialization
	startDelayed1 <= start; // dx, dy, drawLeft, and drawUp become valid
	startDelayed2 <= startDelayed1; // drawSteep becomes valid
	if (startDelayed2) begin
		x <= x0; // x value at starting point
		y <= y0; // y value at starting point
		D <= !drawSteep ? (2*dy - dx) : (2*dx - dy); // Distance from threshold one pixel after starting point
	end	
	
	// main algorithm
	else if (grantWrBresenhamPixel) begin
		if (~drawSteep | !D[BITS_IN_FRAME_BUFFER_COORDINATES+1]) x <= !drawLeft ? (x+1) : (x-1); // advance when not steep or D has become positive
		if ( drawSteep | !D[BITS_IN_FRAME_BUFFER_COORDINATES+1]) y <= !drawUp   ? (y+1) : (y-1); // advance when steep or D has become positive
		D <= D[BITS_IN_FRAME_BUFFER_COORDINATES+1] ? (D + D_AddendDontAdvance) : (D + D_AddendAdvance); // advance when D has become positive
	end
	
	// control outputs
	if (startDelayed2) requestWrBresenhamPixel <= 1; // wr goes high after the initialization
	else if (grantWrBresenhamPixel & (!drawSteep ? (x == x1) : (y == y1))) requestWrBresenhamPixel <= 0; // reaching the end point causes termination
	
	if (start) running <= 1; // running goes high after start
	else if (grantWrBresenhamPixel & (!drawSteep ? (x == x1) : (y == y1))) running <= 0; // reaching the end point causes termination
end

endmodule