/*********************************************************
* ECE 324 Homework 5: FIFO Testbench
* Alex Blake 22 Feb 2019
*********************************************************/

`timescale 1ns/10ps

module fifoTB;
    // -- parameters defined --
    parameter   DATA_WIDTH=16,      //bits per word
                ADDR_WIDTH=3,       //address bits (2^3=8 locations of memory)
                TIME_INC=10;        //one period of the clock cycle

    // -- inputs --
    logic clk = 1, reset = 0;               //single bit inputs clk and reset
    logic rd = 0, wr = 0;                   //single bit read and write bits
    logic [DATA_WIDTH-1:0] w_data = 0;      //write data is a word to write into fifo

    // -- outputs --
    logic empty, full;                      //single bit outputs if fifo is empty or full
    logic [DATA_WIDTH-1:0] r_data;          //read data is a word read from fifo

    // -- generate clock -- 
    always begin
        #(TIME_INC/2) clk = ~clk; //T = 10 * 1ns
    end

    // -- instantiate fifo module --
    fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) f0 (.*);

    initial begin
        // -- reset module to initialize --
        reset = 1; #1; reset = 0; //resets the fifo which sets values to 0, otherwise doesn't work
        
        // -- write for 9 cycles (overflows) --
        w_data = 16'hFF01; wr = 1;
        #(TIME_INC*9); //should overflow at last clock cycle and give error

        // -- read for 9 cycles (underflows) --
        wr = 0; rd = 1;
        #(TIME_INC*9); //should underflow at last clock cycle and give error

        // -- write for 3 cycles --
        rd = 0; wr = 1;
        #(TIME_INC*3); //3 clock cyles of writing

        // -- write and read for 3 cycles --
        rd = 1;
        #(TIME_INC*2) //should read and write for two clock cyles (no changes)

        // -- reset circuit again --
        reset=1; rd = 0; wr = 0; //reset and disable write and read
        #(TIME_INC) reset = 0; //wait one clock cycle and disable reset

        // -- assert empty at end of the simulation -- 
        assert(empty) $info("FIFO is empty as expected");
            else $error("Stack is not empty, it should be empty at end");
        $stop;
    end
endmodule