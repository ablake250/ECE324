/* ECE 324 Lab 6
File Name:   Lab6_Tennis.sv
Module Name: Lab6_Tennis

Function:   
This module, when completed, will implement a game of tennis originally designed in asynchronous logic for TTL, into 
synchronous logic for the Nexys4DDR.

Revisions:
11 Jan 2016 Tom Pritchard: initially written.
08 Dec 2017 Tom Pritchard: doubled displayMem to enable overhead serve.
07 Jan 2018 Tom Pritchard: mirrored bit order of displayMem
14 Jun 2018 Tom Pritchard: converted to SystemVerilog
*/
  
module Lab6_Tennis(
	input logic CLK100MHZ,
	input logic BTNL, BTNC, BTNR, // left, center, and right buttons
	output logic DP,CG,CF,CE,CD,CC,CB,CA, // negative-true decimal point and 7 segments of Nexys4DDR's 7-segment display
	output logic [7:0] AN // negative-true anodes of Nexys4DDR's 7-segment display, from left to right
);

// ***************************************************
// Parameters and Declarations
// ***************************************************
parameter BITS_IN_CLK_COUNTER = 25;   // 25 bits moves the ball at close to 3 Hz
localparam BITS_IN_DISPLAY_COUNTER = 19; // display refresh rate near 191 Hz (100 MHz/2^19)

logic moveBall;
logic [BITS_IN_CLK_COUNTER-1:0] clkCounter;
logic swingLeft, swingRight, toss;
logic nSwing, nToss;
logic nServe, serve;
logic nSet_s1, nSet_s0;
// wire rising_nSwing;
logic s1 = 1, s0 = 1;
logic [7:0] nL = 8'b1111_1110;
logic [2:0] ballLoc;
logic [BITS_IN_DISPLAY_COUNTER-1:0] displayCounter;
logic [2:0] digit; 
(* rom_style = "block" *) logic [7:0] displayMem [0:255]; // 256 byte memory array for 7-segment display
	// "block" forces BRAM to be used, instead of allowing the synthesizer to choose
initial $readmemh ("TennisDisplayMem.txt", displayMem, 0, 255); // initialize displayMem
logic [7:0] displayMemOut;
logic [24:0]d = 33554431;


// ***************************************************
// Emulate a 3 Hz clock signal from a signal generator
// ***************************************************
/*
free_run_bin_counter #(.N(BITS_IN_CLK_COUNTER)) clkCounter_instance(
	.clk(CLK100MHZ), 
	.max_tick(moveBall), // high for one clock cycle approximately every 1/3 seconds
	.q(clkCounter)		 // the most significant bit is a 3 Hz 50% duty cycle square wave
);
*/

univ_bin_counter ubc0(
	.clk(CLK100MHZ),
	.syn_clr(0),
	.en(1),
	.load(moveBall),
	.up(0),
	.d(d),
	.min_tick(moveBall)
);

always_ff @(posedge CLK100MHZ) begin
	if (!nSwing) d <= d-500000;
	else if (toss) d <= 33554431;
	else d <= d;
end


// ***************************************************
// Inputs to the TTL design from the buttons
// ***************************************************
/*
assign swingLeft =  BTNL;
assign swingRight = BTNR;
assign toss = BTNC;
*/
// ***** 1. REPLACE EACH OF THE ABOVE THREE ASSIGN STATEMENTS WITH SOMETHING LIKE THE FOLLOWING:

free_run_shift_reg #(.N(4)) swingLeft_instance(
	.clk(CLK100MHZ),
	.s_in(BTNL),
	.s_out(swingLeft)
);
free_run_shift_reg #(.N(4)) swingRight_instance(
	.clk(CLK100MHZ),
	.s_in(BTNR),
	.s_out(swingRight)
);
free_run_shift_reg #(.N(4)) toss_instance(
	.clk(CLK100MHZ),
	.s_in(BTNC),
	.s_out(toss)
);




// buttons pushed on the Nexys4DDR produce "1", but on the TTL design they produce "0"
assign nSwing = !(swingLeft | swingRight);
assign nToss = !toss;


// ***************************************************
// Emulation of logic on TTL design
// ***************************************************
// Generate when serving the ball

//assign nServe = !(nL[1] &  serve);
//assign  serve = !(nToss & nServe);

// ***** 2. REPLACE THE ABOVE TWO ASSIGN STATEMENTS WITH THE FOLLOWING THAT YOU NEED TO COMPLETE:
always_ff @(posedge CLK100MHZ) begin
	if      (nL[1] == 0) nServe <= 1;
    else if (nToss == 0) nServe <= 0;
end

// Generate the two "and" gates making the asynchronous negative-true sets of s1 and s0
assign nSet_s1 = nL[0] & nToss;
assign nSet_s0 = nL[7] & nToss;


// ***** 3. INSERT A RISING EDGE DETECTOR HERE

risingEdgeDetector nHit_instance(
	.clk(CLK100MHZ),
	.signal(nSwing),
	.risingEdge(rising_nSwing)
);



// Generate the s1 and s0 flip-flops
/*
always_ff @(posedge nSwing, negedge nSet_s1) begin
	if (!nSet_s1) s1 <= 1;
	else          s1 <= nL[7];
end
always_ff @(posedge nSwing, negedge nSet_s0) begin
	if (!nSet_s0) s0 <= 1;
	else          s0 <= nL[0];
end
*/
// ***** 4. CONVERT THE ABOVE 2 FLIP-FLOPS TO BE FULLY SYNCHRONOUS (INCLUDING SETS)

always_ff @(posedge CLK100MHZ) begin
	if      (!nSet_s1)      s1 <= 1;
	else if (rising_nSwing) s1 <= nL[7];
	else                    s1 <= s1;
end
always_ff @(posedge CLK100MHZ) begin
	if      (!nSet_s0)      s0 <= 1;
	else if (rising_nSwing) s0 <= nL[0];
	else                    s0 <= s0;
end

	
// Generate the function of the two 74LS194 shift registers
// The 74LS194's asynchronous reset isn't needed for this design.
// Because this design never has s1=s0=0, that case isn't included here.
// The shift register's bit 0 is on the right.

/*
always_ff @(posedge clkCounter[BITS_IN_CLK_COUNTER-1]) begin // the clock rises every 1/3 second
	case({s1,s0})
		2'b01  : nL <= {1'b1,nL[7:1]};       // shift right
		2'b10  : nL <= {nL[6:0],1'b1};       // shift left
		default: nL <= {7'b1111_111,nServe}; // parallel load
	endcase
end
*/
// ***** 5. MAKE THE ABOVE COUNTER SYNCHRONOUS TO CLK100MHZ

always_ff @(posedge CLK100MHZ) begin
	if (!moveBall) nL <= nL;
	else begin
		case({s1,s0})
			2'b01:		nL <= {1'b1,nL[7:1]};
			2'b10:		nL <= {nL[6:0],1'b1};
			default:	nL <= {7'b1111_111,nServe};
		endcase
	end
end



// ***************************************************
// Outputs of the TTL design to the Nexys4DDR
// ***************************************************
// Use the eight 7-segment displays to simulate the tennis ball, tennis racquets, and net.

// Encode from the shift register where the ball is located.
// This can be a non-priority encoder, since the ball can be in only one location.
// ballLoc==3'b000 means the ball is on the left.
always_comb begin
	case(nL[7:0])
		8'b01111111: ballLoc = 0;
		8'b10111111: ballLoc = 1;
		8'b11011111: ballLoc = 2;
		8'b11101111: ballLoc = 3;
		8'b11110111: ballLoc = 4;
		8'b11111011: ballLoc = 5;
		8'b11111101: ballLoc = 6;
		8'b11111110: ballLoc = 7;
		default    : ballLoc = 3'bxxx;
	endcase
end

// Generate counter for multiplexing of the 7-segment displays
free_run_bin_counter #(.N(BITS_IN_DISPLAY_COUNTER)) displayCounter_instance(
	.clk(CLK100MHZ), 
	.max_tick(), // no need for this output; synthesizer will remove logic
	.q(displayCounter)
);

assign digit[2:0] = displayCounter[BITS_IN_DISPLAY_COUNTER-1:BITS_IN_DISPLAY_COUNTER-3];
	// the counter will increment through the 8 digits, turning each one on for 655us.

// Read the display memory
//                ___
// Bit numbers:  | 0 |
//              5|___|1
//               | 6 |
//              4|___|2
//                 3   7 (decimal point)
always_ff @(posedge CLK100MHZ) begin
	displayMemOut <= displayMem[{nServe,ballLoc[2:0],s1,digit[2:0]}]; // read-only memory (ROM)
	
	if(&(nL[7:0])) AN[7:0] <= 8'b11111111; // blank display when between points, when nL is all 1's
	else case (digit[2:0])
		0: AN[7:0] <= 8'b01111111;
		1: AN[7:0] <= 8'b10111111;
		2: AN[7:0] <= 8'b11011111;
		3: AN[7:0] <= 8'b11101111;
		4: AN[7:0] <= 8'b11110111;
		5: AN[7:0] <= 8'b11111011;
		6: AN[7:0] <= 8'b11111101;
		7: AN[7:0] <= 8'b11111110;
	endcase
end 

always_comb {DP,CG,CF,CE,CD,CC,CB,CA} = ~displayMemOut; // the cathode segments are negative-true

endmodule