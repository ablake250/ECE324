/* ECE 324 Lab 4 Arithmetic Logic Unit starter code
   01 Feb 2012 Dr. Lynch/WSUV: started as Lollapalooza code.
   28 Jan 2015 Tom Pritchard/WSUV: put sw[7:4] = "a" on the left.
   30 Jul 2015 Tom Pritchard/WSUV: changed lab to ALU on Nexys4DDR.
   06 Jan 2016 Tom Pritchard/WSUV: changed order of opcodes and digits.
   07 Jan 2018 Tom Pritchard/WSUV: reversed order of sseg's, made top segment bit 0.
   14 Jun 2018 Tom Pritchard/WSUV: converted to SystemVerilog.
   07 Sep 2018 Tom Pritchard/WSUV: added separate top level module.
*/
  
module alu(
	input logic [3:0] a, b,   // two 4-bit operands
	input logic Cin,          // carry in
	input logic [3:0] opcode, // 4-bit opcode

	output logic aGTb,        // 1 when a > b
	output logic fEq0,        // 1 when f is zero
	output logic [7:0] f,	  // 8 bit output
    output logic Cout         // carry out
);


// **********************************
// Generate the ALU logic
// **********************************
// The following are temporary assign statements; you need to change all of these.

always_comb begin
case (opcode)
    0: begin
        f = a + b;
        Cout = f[4];
    end
    1: begin
        f = a + b + Cin;
        Cout = f[4];
    end
    2: begin
        f = a - b;
        Cout = f[4];
    end
    3: begin
        f = a - b - Cin;
        Cout = f[4];
    end
    4: begin
        f = a * b;
        Cout = Cin;
    end
    5: begin
        f = {4'b0000, a & b};
        Cout = Cin;
    end
    6: begin
        f = {4'b0000, a | b};
        Cout = Cin;
    end
    7: begin
        f = {4'b0000, ~a};
        Cout = Cin;
    end
    8: begin
        f = {4'b0000, a ^ b};
        Cout = Cin;
    end
    9: begin
        f = {4'b0000, a & ~b};
        Cout = Cin;
    end
    10: begin
        f = {4'b0000, a[2:0], a[3]};
        Cout = Cin;
    end
    11: begin
        f = {4'b0000, a[0], a[3:1]};
        Cout = Cin;
    end
    12: begin
        f = {4'b0000, a[2:0], Cin};
        Cout = a[3];
    end
    13: begin
        f = {4'b0000, Cin, a[3:1]};
        Cout = a[0];
    end
    14: begin
        f = {4'b0000, a[2:0], 1'b0};
        Cout = a[3];
    end
    15: begin
        f = {4'b0000, 1'b0, a[3:1]};
        Cout = a[0];
    end
    default: begin
        f=0;
        Cout=0;
    end
endcase
end

assign aGTb = a>b;
assign fEq0 = f==0;

endmodule