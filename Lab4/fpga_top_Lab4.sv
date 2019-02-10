/* ECE 324 Lab 4 Arithmetic Logic Unit starter code
   07 Sep 2018 Tom Pritchard/WSUV: made separate top level module.
*/
  
module fpga_top_Lab4(
	input logic CLK100MHZ,
	input logic SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0,
	output logic [15:0] LED,
    output logic [7:0] AN,               // anodes of the 7-segment displays
    output logic DP,CG,CF,CE,CD,CC,CB,CA // cathodes of the 7-segment displays
);

// **********************************
// Declarations
// **********************************
// Switch inputs
logic [15:0] SW;
logic [3:0] a, b;
logic Cin;
logic [3:0] opcode;

// ALU outputs
logic aGTb;
logic fEq0;
logic [7:0] f;
logic Cout;

// Output to the 7-segment displays
logic [7:0] sseg7, sseg6, sseg5, sseg4, sseg3, sseg2, sseg1, sseg0, sseg1_x;  
	// positive true seven segment and decimal point that connect hex-to-7seg decoders to LED mux 


// **********************************
// Switch inputs
// **********************************
assign SW = {SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0};
	// Specifying the switches separately in the .xdc file eliminates some warning messages.
	// This has to do with specifying different voltages for different switches, but students can ignore this.

assign a[3:0] = SW[15:12];
assign b[3:0] = SW[11: 8];
assign Cin    = SW[7];
assign opcode = SW[3:0];


// **********************************
// Instantiate the ALU logic
// **********************************
alu alu0 (
	// inputs
	.a(SW[15:12]), .b(SW[11:8]), // two 4-bit operands
	.Cin(SW[7]),                 // carry in
	.opcode(SW[3:0]),            // 4-bit opcode

	// outputs
	.aGTb, // 1 when a > b
	.fEq0, // 1 when f is zero
	.f,	   // 8 bit output
    .Cout  // carry out
);


// **********************************
// Output to the LEDs
// **********************************
assign LED = SW; // Display the switch values on their corresponding LEDs.

// Generate outputs to the eight 7-segment displays and their decimal points
hex_to_sseg_p hts7(.hex(SW[15:12]), .dp(1'b0 ), .sseg_p(sseg7)); // a
hex_to_sseg_p hts6(.hex(SW[11: 8]), .dp(SW[7]), .sseg_p(sseg6)); // b; Cin on decimal point
assign sseg5 = 8'h00;
hex_to_sseg_p hts4(.hex(SW[ 3: 0]), .dp( 1'b0), .sseg_p(sseg4)); // opcode
assign sseg3 = {aGTb,7'h00};                                     // aGBb on decimal point
assign sseg2 = {fEq0,7'h00};                                     // fEq0 on decimal point
hex_to_sseg_p hts1(.hex( f[ 7: 4]), .dp(1'b0 ), .sseg_p(sseg1)); // f upper nybble
hex_to_sseg_p hts0(.hex( f[ 3: 0]), .dp(Cout ), .sseg_p(sseg0)); // f lower nybble; Cout on decimal point

always_comb begin
if (opcode>=5) sseg1_x = 8'h00;
	else sseg1_x = sseg1;
end

// Instantiate 7-segment LED display time-multiplexing module
led_mux8_p dm8_0(
    .clk(CLK100MHZ), .reset(1'b0), 
    .in7(sseg7), .in6(sseg6), .in5(sseg5), .in4(sseg4), .in3(sseg3), .in2(sseg2), .in1(sseg1_x), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA})
);

endmodule