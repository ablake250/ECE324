// file divideBy3.sv
// Divides an unsigned N bit dividend by three, and provides an N-1 bit quotient and a 2 bit remainder
// N is a parameter which may be up to 17 bits, and still infer just one Xilinx DSP48E1 block.
// The divide by 3 is done by multiplying by 1/3 (binary 0.0101010101010101010101011), which is accomplished with integers 
//     by a multiplication of 11,184,811 followed by a division of 33,554,432 (2**25).
// The outputs are registered:  they're driven straight from flip-flops, and arrive 1 clock cycle after the input.
//
// Revisions:
// 2019 Feb 03 Tom Pritchard:  First written

module divideBy3
	#(parameter N=17) (
	input logic clk, 
	input logic [N-1:0] dividend,
	output logic [N-2:0] quotient,
	output logic [1:0] remainder
);

logic [N+23:0] dividend_x_11184811;

always_ff @(posedge clk) begin
    dividend_x_11184811[N-1+24:0] <= dividend[N-1:0] * 24'hAAAAAB; // multiply by 11,184,811
end

assign quotient[N-2:0] = dividend_x_11184811[N-2+25:25]; // divide by 33,554,432 (shift 25 bits)
assign remainder[1:0] = dividend_x_11184811[24:23];
    // 0/3 = .000000...
    // 1/3 = .010101...
    // 2/3 = .101010...
    // So the remainder of a multiply by 1/3 is simply the next two bits, ignoring the lesser significant bits.

endmodule
