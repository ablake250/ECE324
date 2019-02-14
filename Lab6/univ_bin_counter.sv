// Adapted from Chu's listing 4.12
module univ_bin_counter
   #(parameter N=8)(
   input logic clk, syn_clr, load, en, up,
   input logic [N-1:0] d,
   output logic max_tick, min_tick,
   output logic [N-1:0] q = 0); // output register with initial value

// register with next-state logic
always_ff @(posedge clk) begin
   if (syn_clr)       q <= 0;     // clear
   else if (load)     q <= d;     // load
   else if (en & up)  q <= q + 1; // count up
   else if (en & ~up) q <= q - 1; // count down
   // else            q <= q;     // hold (nop)
end

// output logic
assign max_tick = (q == (2**N-1));
assign min_tick = (q == 0);

endmodule
