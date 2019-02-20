/*********************************************************
* ECE 324 Homework 4: Universal Shift Register Testbench
* Alex Blake 19 Feb 2019
*********************************************************/



`timescale 10ps/1ps

module usrTB();
    parameter  N_BITS = 4;      //bits to instantiate the width of the register, specified at 4 bits

    // -- logic inputs --
    logic   clk = 1'b1, reset = 0;
    logic [1:0] opcode;

    // -- logic outputs --
    logic [N_BITS-1:0] d, q;

    // -- instantiate univ_shift_reg module --
    univ_shift_reg #(.N(N_BITS)) usr0 (            
        .clk(clk),
        .reset(reset),
        .ctrl(opcode),
        .d(d), 
        .q(q)
    );

    // -- clock signal --
    always begin
        #5 clk <= ~clk;     //generate clock signal with period #10
    end

    // -- initial block testing functions of shift register --
    initial begin
        // -- Load (1 cycle) --
        d=4'b1010; opcode = 2'b11;      //load value of D into shift register, opcode set to 'load'
        #10;                            //pause 1 cycle

        // -- no Operation (4 cycles) --
        opcode = 2'b00;                 //pause 1 cycle, opcode set to 'no op'
        #40;                            //no operations for 4 cycles  

        // -- Shift left (4 cycles) --   
        opcode = 2'b01;                 //opcode set to 'shift left'
        #40;                            //wait 4 cycles

        // -- shift right (4 cycles) --
        opcode = 2'b10;                 //opcode set to 'shift right'
        #40;                            //wait 4 cycles
        
        // -- asynchronous reset (1 cycle) --
        #7;                             //wait 7/10 cycle (clk==0)
        reset = 1;                      //set reset high
                                        //resets shifter regardless of clock
        #3                              //wait 3/10 cycle to finish clock cycle
        
        // -- stop simulation -- 
        $stop;
    end
endmodule