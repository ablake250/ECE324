//Testbench

//Alex Blake 
//ECE 324 Lab 4
`timescale 1 ns/10 ps


module aluTB;

logic [7:0]f; 
logic [3:0]a, b, opcode;
logic Cin, aGTb, fEq0, Cout;
integer i;

alu alu0(
    .a(a),
    .b(b),
    .Cin(Cin),
    .opcode(opcode),

    .aGTb(aGTb),
    .fEq0(fEq0),
    .f(f),
    .Cout(Cout)
);

    initial begin
        #0 a=4'b1010; b=4'b0001; opcode=4'b0000; Cin=1'b0;
        for (i=0; i!=16; i++) #10 opcode=i;
        #10 $stop;
    end
endmodule