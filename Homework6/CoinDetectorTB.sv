`timescale 1ns/10ps

module CoinDetectorTB;
    localparam  T = 2;
    localparam  dimeMin = 2, dimeMax = 4, nickelMin = 6, nickelMax = 8,
               quarterMin = 10, quarterMax = 12;

    logic clk = 1, reset = 0, coinSensor;
    logic [2:0] coinTest;
    logic dimeDetected, nickelDetected, quarterDetected;
    
    logic coinTestnext = 0;

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

        for(int i = 1; i <= 1; i++) begin
            coinSensor = 1;
            repeat (1) @(negedge clk);
            coinSensor = 0;
            repeat(1) @(negedge clk);
            assert(!coinTest==7) $error("FAILED");
                else $info("Pass");
            coinSensor = 1;
            repeat(2*i) @(negedge clk);
        end
        repeat(1) @(negedge clk); 
        $stop;
    end

endmodule