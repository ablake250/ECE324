`timescale 10ps/1ps

module usrTB();
    parameter  N_BITS = 4;      //bits to instantiate the width of the register, specified at 4 bits
    logic   clk = 0, reset;
    logic [1:0] opcode;
    logic [N_BITS-1:0] d, q;

    univ_shift_reg #(.N(N_BITS)) usr0 (            //instantiate a univ_shift_reg module
        .clk(clk),
        .reset(reset),
        .ctrl(opcode),
        .d(d), 
        .q(q)
    );

    always begin
        #5 clk <= ~clk;
    end

    initial begin
        #10     d=4'b1010; opcode = 2'b11;       //load value of D into shifter reg
        #10     opcode = 2'b00;                 //no Operations should happen for this cycle
        #40     opcode = 2'b01;                 //shift left 4 times
        #40     opcode = 2'b10;                 //shift right 4 times
        #42     reset = 1;
        #10 $stop;
    end
endmodule