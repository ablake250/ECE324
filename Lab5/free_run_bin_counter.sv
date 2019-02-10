// Adapted from Chu's listing 4.11
module free_run_bin_counter
   #(parameter N=8)(
   input logic clk,
   output logic max_tick,
   output logic [N-1:0] q = 0 // output register with initial value
);

// register with next-state logic
always_ff @(posedge clk) q <= q + 1;

// output logic
assign max_tick = (q == (2**N)-1);

endmodule

