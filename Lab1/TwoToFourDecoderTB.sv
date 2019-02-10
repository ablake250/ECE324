/************************************************
* ECE 324 Lab 1: TwoToFourDecoderTB
* your name(s) here, today's date
* testbench for 2:4 decoder
************************************************/ 
`timescale 1 ns/10 ps
module TwoToFourDecoderTB; // testbench module has no ports
	// signal declarations
	logic [1:0] w; // stimulus to decoder
	logic En;      // stimulus to decoder
	logic [0:3] y; // results from decoder
	
	// instantiate circuit under test
	TwoToFourDecoder UUT(
		.w(w),
		.En(En),
		.y(y)
	);
	
	// generate stimulus
	initial begin
		#10 En = 0; w = 2'b00;
		#10 En = 1; w = 2'b00;
		// add your stimulus here
		#10 En = 0; w = 2'b01;
		#10 En = 1; w = 2'b01;
		
		#10 En = 0; w = 2'b10;
		#10 En = 1; w = 2'b10;
		
		#10 En = 0; w = 2'b11;
		#10 En = 1; w = 2'b11;
			
		#10 $stop;
	end
endmodule
