/* ECE 324 Homework6: Coin Detector
File:  CoinDetector.sv

Revisions:
29 Dec 2018 Tom Pritchard: Initial version
*/
  
module CoinDetector 
	#(parameter dimeMin    = 380000, 
	            dimeMax    = 420000, 
				nickelMin  = 480000, 
				nickelMax  = 520000, 
				quarterMin = 580000, 
				quarterMax = 620000) 
   (input logic clk,
	input logic reset,
	input logic coinSensor,
	output logic [2:0] coinTest,
	output logic dimeDetected, nickelDetected, quarterDetected,
	output logic coinTestnext
); 

//////////////////////////////////////////////////////////////////////////////////////////////
// Declarations			
logic sensorSync, sensor;
logic [20:0] coinTime, coinThresholdTime;
logic changeCoinTest;

//////////////////////////////////////////////////////////////////////////////////////////////
// Synchronizer
always_ff @(posedge clk) begin
	sensorSync <= coinSensor; // synchronize to clock
	sensor <= sensorSync;     // for metastability
end

//////////////////////////////////////////////////////////////////////////////////////////////
// Timer
always_ff @(posedge clk) begin
	if (sensor == 0) coinTime <= 0;
	else             coinTime <= coinTime + 1;
end

//////////////////////////////////////////////////////////////////////////////////////////////
// Coin Threshold ROM
always_comb case (coinTest[2:0])
	0: coinThresholdTime = dimeMin;
	1: coinThresholdTime = dimeMax;
	2: coinThresholdTime = nickelMin;
	3: coinThresholdTime = nickelMax;
	4: coinThresholdTime = quarterMin;
	5: coinThresholdTime = quarterMax;
	default: coinThresholdTime = 21'bx; // oversize and idle states, not testing threshold
endcase

//////////////////////////////////////////////////////////////////////////////////////////////
// Comparator
always_comb changeCoinTest = (coinTime >= coinThresholdTime);

//////////////////////////////////////////////////////////////////////////////////////////////
// State Machine
typedef enum {testDmin, testDmax, testNmin, testNmax, testQmin, testQmax, oversize, idle} state_type;
state_type state, stateNext;

assign coinTest = state; // the states were assigned to generate the coinTest output bits directly

// ADDED
assign coinTestnext = stateNext;


always_ff @(posedge clk) begin
	if (reset) state <= idle;
	else       state <= stateNext;
end

always_comb begin
	// defaults
	stateNext = state;
	dimeDetected = 0;
	nickelDetected = 0;
	quarterDetected = 0;
	
	case(state)
		testDmin:	begin
			if(sensor & changeCoinTest) stateNext = testDmax;
			else if(!sensor) stateNext = idle;
			else stateNext = state;	
		end
		testDmax:	begin
			if(sensor & changeCoinTest) stateNext = testNmin;
			else if(!sensor) begin
				dimeDetected = 1;
				stateNext = idle;
			end
			else stateNext = state;
		end
		testNmin:	begin
			if(sensor & changeCoinTest) stateNext = testNmax;
			else if(!sensor) stateNext = idle;
			else stateNext = state;
		end
		testNmax:	begin
			if(sensor & changeCoinTest) stateNext = testQmin;
			else if(!sensor) begin 
			nickelDetected = 1; stateNext = idle;
			end
			else stateNext = state;
		end
		testQmin:	begin
			if(sensor & changeCoinTest) stateNext = testQmax;
			else if(!sensor) stateNext = idle;
			else stateNext = state;
		end
		testQmax:	begin
			if(sensor & changeCoinTest) stateNext = oversize;
			else if(!sensor) begin
			     quarterDetected = 1; stateNext = idle;
			end
			else stateNext = state;
		end
		oversize:	begin
			if(!sensor) stateNext = idle;
			else stateNext = state;
		end
		idle:		begin
			if(sensor) stateNext = testDmin;

		end
		default:	stateNext = idle;
	endcase	
end

endmodule