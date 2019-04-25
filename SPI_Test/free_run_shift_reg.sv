// Adapted from Chu's Listing 4.9
// 
module free_run_shift_reg
	#(parameter N=8) (
	input logic clk, 
	input logic s_in,
	output logic s_out
);

// signal declaration
logic [N-1:0] q = 0; // initialize to 0
   
// register
always_ff @(posedge clk) q <= {s_in, q[N-1:1]};

// output logic
assign s_out = q[0];

endmodule
