/*********************************************************
* ECE 324 Homework 6: Coin Detector Testbench
* Alex Blake 28 Feb 2019
*********************************************************/

`timescale 1ns/10ps

module CoinDetectorTB;
    //Parameters Defined:
    localparam  T = 2;
    localparam  dimeMin = 2, dimeMax = 4, nickelMin = 6, nickelMax = 8,
               quarterMin = 10, quarterMax = 12;

    // -- logic inputs for CoinDetector module --
    logic clk = 1, reset = 0, coinSensor;

    // -- logic outputs for CoinDetector module --
    logic [2:0] coinTest;
    logic dimeDetected, nickelDetected, quarterDetected;

    // -- instantiate a CoinDetector module --
    CoinDetector #(
                .dimeMin(dimeMin),
	            .dimeMax(dimeMax), 
				.nickelMin(nickelMin), 
				.nickelMax(nickelMax), 
				.quarterMin(quarterMin), 
				.quarterMax(quarterMax)
				) cd0 (.*);

    // -- generate clock signal of period T --
    always begin
        #(T/2)  clk=~clk;
    end

    initial begin
        // -- reset module to make sure it is initialized --
        reset = 1;
        repeat (2) @(negedge clk);
        reset = 0; coinSensor = 0;

        // -- 3 clock cycles of idle, should stay on idle --
        repeat (3) @(negedge clk);
        assert(!coinTest==7) $error("FAILED");
            else $info("Pass");

        // -- tests each state per itereation of loop --
        for(int i = 1; i <= 7; i++) begin   
            coinSensor = 1;                 //coin sensor detecting coin

            //assert we are in the i'th state, or in other words, each iteration
            //of this for loop will be in the next sequential state and test both
            //the break back to idle or the continuation to the next state 
            assert(coinTest == i) $info("correct state: coinTest==%d", coinTest);
                else $error("FAILED: coinTest==%d", coinTest);
            repeat (1) @(negedge clk);

            //break back to idle
            coinSensor = 0;

            //if in state 
            if(coinTest==1) begin
                assert(dimeDetected) $info("Dime was detected!");
                    else $error("Expected Dime True");
            end
            else if(coinTest==3) begin
                assert(nickelDetected) $info("Nickel was Detected!");
                    else $error("Expected Nickel, none!");
            end
            else if(coinTest==5) begin
                assert(quarterDetected) $info("Quarter was Detected!");
                    else $error("Expected Quarter, none!");
            end
            repeat(1) @(negedge clk);
            assert(!(coinTest==7)) $error("FAILED");
                else $info("Pass");
            coinSensor = 1;
            repeat(2*i) @(negedge clk);
        end
        $stop;
    end

endmodule