`timescale 1ns/10ps

module fifoTB;

    parameter   DATA_WIDTH=16, 
                ADDR_WIDTH=3,
                TIME_INC=10;

    logic clk = 1, reset = 0;
    logic rd = 0, wr = 0;
    logic [DATA_WIDTH-1:0] w_data = 0;
    logic empty, full;
    logic [DATA_WIDTH-1:0] r_data;


    //generate clock signal below, T = 10 * 1ns
    always begin
        #(TIME_INC/2) clk = ~clk;
    end

    fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) f0 (.*);


    initial begin

        reset = 1; #1; reset = 0; //resets the fifo which sets values to 0, otherwise doesn't work

        w_data = 16'hFF01; wr = 1;
        #(TIME_INC*9); //should overflow at last clock cycle and give error
        wr = 0; rd = 1;
        #(TIME_INC*9); //should underflow at last clock cycle and give error
        rd = 0; wr = 1;
        #(TIME_INC*3); //3 clock cyles of writing
        rd = 1;
        #(TIME_INC*2) //should read and write for two clock cyles (no changes)
        reset=1; rd = 0; wr = 0; //reset and disable write and read
        #(TIME_INC) reset = 0; //wait one clock cycle and disable reset

        assert(empty) $info("FIFO is empty as expected");
            else $error("Stack is not empty, it should be empty at end");
        $stop;
    end

endmodule