/************************************************
* ECE 324 HW 7
* File VendingMachine_tb.sv
* Testbench for vending machine state machine
* 06 Jan 2019 Tom Pritchard: initially wrote
************************************************/
`timescale 1 ns/10 ps
module VendingMachine_tb;
	
localparam T = 10; // clock period

localparam DIME    = 21'd3; // number of clock cycles coinSensor is high
localparam NICKEL  = 21'd7;
localparam QUARTER = 21'd11;

localparam EXPECTED_DISPENSE_0 = 0;
localparam EXPECTED_DISPENSE_1 = 1;

// stimulus declarations
logic clk;
logic reset;
logic coinSensor;

// response declarations
logic dispense;

// instantiate circuit under test
VendingMachine #(.dimeMin(2), .dimeMax(4), .nickelMin(6), .nickelMax(8), .quarterMin(10), .quarterMax(12)) VendingMachine0(
	.clk,
	.reset,
	.coinSensor,
	.dispense
);

// generate clk
always begin
	clk = 1'b0;
	#(T/2);
	clk = 1'b1;
	#(T/2);
end
	
// generate tests
initial begin
	RDDDDDDD();
	RQNQNQNQNQNDD();
	$stop;
end

/////////////////////
// tasks
/////////////////////
task rst();
begin
	coinSensor = 0;
	reset = 1'b1;
	@(negedge clk);	
	reset = 1'b0;
end
endtask

/////////////////////
task depositCoin(
	input logic [20:0] coinType,
	input logic expectedDispense);
begin
	coinSensor = 1;
	repeat(coinType) @(negedge clk);
	coinSensor = 0;
	repeat(3) @(negedge clk); // extra clock delays since inputs and outputs are registered
	assert(dispense == expectedDispense) else $error("dispense is %0d, but expected %0d", dispense, expectedDispense);
end
endtask

/////////////////////
task RDDDDDDD(); // Test every state machine transition path for dime insertions.
                 // The last 2 dimes verify that the accumulated money after 5 dimes and 2 dispenses is 0 cents.
begin
	rst();                                  //  0 cents
	depositCoin(DIME, EXPECTED_DISPENSE_0); //  0 cents + 10 cents -  0 cents = 10 cents
	depositCoin(DIME, EXPECTED_DISPENSE_0); // 10 cents + 10 cents -  0 cents = 20 cents
	depositCoin(DIME, EXPECTED_DISPENSE_1); // 20 cents + 10 cents - 25 cents =  5 cents
	// FINISH THIS TASK AND TASK RQNQNQNQNQNDD HERE
end
endtask

task 
endmodule