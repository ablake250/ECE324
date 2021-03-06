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

        // -- tests each state per itereation of loop --
        for(int i = 1; i <= 7; i++) begin   
            coinSensor = 1;         //coin sensor detecting coin
            //assert we are in the i'th state, or in other words, each iteration
            //of this for loop will be in the next sequential state and test both
            //the break back to idle or the continuation to the next state
            repeat (1) @(negedge clk);

            //break back to idle
            coinSensor = 0;

            // -- test for correct outputs --
            repeat(2) @(negedge clk);               //delay 2 cycles for delay of input flip-flop
            if(coinTest==1) begin                   //test for Dime Output
                assert(dimeDetected) $info("Dime Detected!");
                    else $error("Dime NOT Detected!");
            end
            else if(coinTest==3) begin              //test for Nickel Output
                assert(nickelDetected) $info("Nickel Detected!");
                    else $error("Nickel NOT Detected!");
            end
            else if(coinTest==5) begin              //test for Quarter Output
                assert(quarterDetected) $info("Quarter Detected!");
                    else $error("Quarter NOT Detected!");
            end

            // -- set state machine to next state by waiting 2*i clock cycles --
            coinSensor = 1;
            repeat(2*i) @(negedge clk);
        end
        $stop;      //stop simulation
    end

endmodule