/* File:  ps2_top.sv
Complete PS2 implementation, from Pong Chu's FPGA Prototyping by SystemVerilog Examples, listing 18.3 
Modifications:
2018 Sep 29 Tom Pritchard: removed fifo, since not needed for implementation without processor.
*/ 
module ps2_top(
    input  logic clk, reset,
    input  logic wr_ps2,
    input  logic [7:0] ps2_tx_data,
	output logic tx_done_tick,
    output logic [7:0] ps2_rx_data,
	output logic rx_done_tick,
    inout  tri ps2d, ps2c
);

// declarations
logic rx_idle, tx_idle;

// body
// instantiate ps2 transmitter
ps2tx ps2_tx_unit (.*, .din(ps2_tx_data));
// instantiate ps2 receiver
ps2rx ps2_rx_unit (.*, .rx_en(tx_idle),.dout(ps2_rx_data));

endmodule
