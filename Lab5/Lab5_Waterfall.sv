/* file name: Lab5_Waterfall.sv
Module name:  Lab5_Waterfall
Function:   
This module roughly models, on LEDs, repetitive falling water from the top to the bottom of Metlako 
waterfall on a short spur trail about 1.5 miles up the Eagle Creek trail in the Columbia River gorge.
This simple model assumes no air friction, which wouldn't apply well to water along the edges of the falls.
It uses the formula d = 0.5 * g * (t**2), where t is time measured in seconds, d is the falling distance 
measured in feet, and g is the acceleration due to earth's gravity near the surface of the earth, which is 
rounded to 32 ft/sec**2.

Revisions:
22 Jan 2016 Tom Pritchard: initially written.
22 Feb 2017 Tom Pritchard: improved some comments.
14 Jun 2018 Tom Pritchard: converted to SystemVerilog.
*/

module Lab5_Waterfall(
	input logic CLK100MHZ,  // 100 MHz clock from crystal oscillator
	output logic [15:0] LED // 16 red LEDs above switches on Nexys4DDR
);

localparam  BITS_IN_TIME_BASE_CNTR = 11;

// -- added localparameters for new functions --
localparam  MOD_M = 381;	//number which modulo gives the correct timeBaseTick frequency
localparam	T_BITS=17;		//number of bits for ubc0 to function correctly

// Declarations
logic timeBaseTick; 		// on for one clock cycle every 1/(2**17) of the fall time
logic [-1:-17] t; 			// time required to fall from zenith to the current location, 
                     		// normalized to the total falling time (so 0<=t<1)
logic [-1:-34] tSquared; 	// the square of the 17 bit value of t
logic [3:-30] d; 			// distance down from zenith, normalized so 0<=d<16
integer i; 					// loop counter

// -- added logic --
logic up = 1;				//counting direction of ubc0
logic min_tick;				//output bit if counter=0
logic max_tick; 			//output bit if counter=max
logic zero = 0;				//zero input to tie some ubc0 to 0

// Starting with a 100 MHz clock, this counter generates a tick every 
//    1/(2**17) of the travel time from the zenith to the bottom.
// With 11 bits, this counter generates a timeBaseTick every 2048/100,000,000 = 20.48us,
//    which will result in a fall time of 20.45us * (2**17) ~= 2.68 seconds,
//    which will result in a fall distance of 0.5 * 32 * (2.68**2) ~= 115 feet.

//New Calculations:
//4=1/(16*t^2), t=0.5sec, 0.5sec/(2^17)=3.81us, timeBaseTick = 381

// -- new modulo counter initialized below to replace frbc0--
mod_m_counter #(.M(MOD_M)) mmc0(
	.clk(CLK100MHZ),
	.max_tick(timeBaseTick),
	.q()
);

/*
free_run_bin_counter #(.N(BITS_IN_TIME_BASE_CNTR)) frbc0(
	.clk(CLK100MHZ), 
	.max_tick(timeBaseTick), // on for one clock cycle every 1/(2**17) of the fall time
	.q() // count value not used
);
*/

/*
// Generate the time it would take to fall from the zenith to the current location,
//    normalized to the total falling time (so 0<=t<1, which is why the range values are negative).
always_ff @(posedge CLK100MHZ) begin
	if(timeBaseTick) t[-1:-17] <= t[-1:-17] + 1;
	else             t[-1:-17] <= t[-1:-17];
end
*/


// -- added ubc0 to replace above statement to control t (time) --
univ_bin_counter #(.N(T_BITS)) ubc0(
	
	//inputs below
	.clk(CLK100MHZ),		//clock signal
	.syn_clr(zero),			//synchronous clear (set to 0)
	.load(zero),			//load (set to 0)
	.d(zero),				//d input set to 0
	.en(timeBaseTick),		//enabled every time timeBaseTick is high
	.up(up),				//direction of counter, determined by always_ff block below

	//outputs below
	.q(t),					//q output to t (time)
	.max_tick(max_tick),	//output when counter maxes out
	.min_tick(min_tick)		//output when counter hits 0
);


// -- ff to change direction of ball by changing count direction of ubc0 --
always_ff @(posedge(CLK100MHZ)) begin
	if (max_tick) up <= 1'b0;		//changes ball direction if ball hit max_tick
	if (min_tick) up <= 1'b1;		//changes ball direction if ball hit min_tick
end

// Generate the distance down from the zenith, using d = 0.5 * g * (t**2).
// Assume g = 32 ft/sec**2, which is close to the acceleration due to gravity near the surface of the earth;
// using the normalized value of t, this results in a normalized distance such that 0<=d<16.
always_ff @(posedge CLK100MHZ) begin
    tSquared[-1:-34] <= t[-1:-17] ** 2; // will be inferred into a DSP block as multiplier and M register
	d[3:-30] <= tSquared[-1:-34]; // multiply by 16 (which is 0.5 * g); these flip-flops will be put on the DSP P register
end

// Map the distance onto the LEDs
// With a normalized distance 0<=d<16, simply rounding down to integers gives a decent display.
always_ff @(posedge CLK100MHZ) begin
    for (i = 0; i <= 15; i = i + 1) begin
        LED[i] <= (d[3:0] == i);
    end
end

endmodule