// adapted from Chu Listing 5.5
// Detects a rising edge of a signal
// Modifications:
// Dr. Lynch: deleted reset input, added default init
// Tom Pritchard: changed names

module risingEdgeDetector(
	input  logic clk,
	input  logic signal,
	output logic risingEdge
);

// signal declaration
logic previousSignal = 0; // default init

// delay register
always_ff @(posedge clk) previousSignal <= signal;

// decoding logic
assign risingEdge = ~previousSignal & signal;

endmodule
