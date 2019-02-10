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
localparam  MOD_M = 381;
localparam	t_bits=17;

// Declarations
logic timeBaseTick; 		// on for one clock cycle every 1/(2**17) of the fall time
logic [-1:-17] t = 0; 		// time required to fall from zenith to the current location, 
                     		// normalized to the total falling time (so 0<=t<1)
logic [-1:-34] tSquared; 	// the square of the 17 bit value of t
logic [3:-30] d; 			// distance down from zenith, normalized so 0<=d<16
integer i; 					// loop counter
logic up;
logic min_tick = 0;
logic [16:0]max_tick = 0; 

// Starting with a 100 MHz clock, this counter generates a tick every 
//    1/(2**17) of the travel time from the zenith to the bottom.
// With 11 bits, this counter generates a timeBaseTick every 2048/100,000,000 = 20.48us,
//    which will result in a fall time of 20.45us * (2**17) ~= 2.68 seconds,
//    which will result in a fall distance of 0.5 * 32 * (2.68**2) ~= 115 feet.

//New Calculations:
//4=1/(16*t^2), t=0.5sec, 0.5sec/(2^17)=3.81us, timeBaseTick = 381

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

univ_bin_counter #(.N(t_bits)) ubc0(
	
	//inputs below
	.clk(CLK100MHZ),
	.syn_clr(0),
	.load(0),
	.d(0),
	.en(1),
	.up(up),

	//outputs below
	.q(t),
	.max_tick(max_tick),
	.min_tick(max_tick)
);

always_ff @(posedge(CLK100MHZ)) begin
	if (t==max_tick | t==min_tick) up <= ~up;
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