`timescale 10ps/1ps

module usrTB;
    parameter  N_BITS = 4;
    logic   clk = 0, reset;
    logic [1:0] opcode;
    logic [N_BITS-1:0] d, q;

    univ_shift_reg usr0(
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
        #10;
        #10;



        #10 $stop;
    end

endmodule