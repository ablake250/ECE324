/*********************************************************
* ECE 324 Lab 7: Traffic Light
* Alex Blake & Jameson Shaw 5 Mar 2019
*********************************************************/

This starter code emulates a USA 3-color dumb traffic light, using an Agilent Nexys4DDR board.
7-segment displays illustrate the positions of the red (top), yellow (center), and green (bottom) traffic lights for road A (left) and road B (right).
Two RGB LEDs illustrate the color of the light that's on for road A (left) and road B (right).

Instead of making these switch-programmable, the duration of each light is hard coded for each state,
so to change any durations, the FPGA must be re-synthesized.

Revisions:
10 Dec 2017 Tom Pritchard: Initial version
22 Dec 2017 Tom Pritchard: Added the 5 buttons and changed the state machine as specified in the lab 7 procedure.
07 Jan 2018 Tom Pritchard: Rearranged cathode order.
15 Jun 2018 Tom Pritchard: Converted to SystemVerilog.
07 Sep 2018 Tom Pritchard: Made LED brightness switch-programmable.
*/
  
module Lab7_TrafficLight(
	input logic CLK100MHZ,               // Nexys4DDR's 100 MHz clock
	input logic SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0, // 16 switches to control LED brightness
	input logic BTNL, BTNR, BTNC, BTNU, BTND,
	output logic LED16_G, LED16_R,       // green and red color signals on Nexys4DDR's right RGB LED
	output logic LED17_G, LED17_R,       // green and red color signals on Nexys4DDR's left  RGB LED
	output logic [7:0] AN,               // negative true anodes   for Nexys4DDR's 7-segment displays
	output logic DP,CG,CF,CE,CD,CC,CB,CA // negative true cathodes for Nexys4DDR's 7-segment displays
); 

//////////////////////////////////////////////////////////////////////////////////////////////
// Parameters and Declarations
parameter OFF = 0, ON = 1;
parameter N_BITS=4;		//added for shift registers for buttons

logic  [26:0] trafficLightPrescaler; // 27 bits needed for a 100 MHz clock	
logic oneSecondTick;
logic [3:0] trafficLightTimer; 
typedef enum {greenA, yellowA, redA, greenB, yellowB, redB, flashRedOn, flashRedOff} state_type;	
		// 6 state names, numbered 0 to 5
																					// 7th state added (flashRed)
state_type state_TrafficLight = flashRedOn, nextState_TrafficLight;		//Changed default state to flashRedOn
logic initializeTrafficLightTimer;
logic roadA_GreenLight, roadA_YellowLight, roadA_RedLight;
logic roadB_GreenLight, roadB_YellowLight, roadB_RedLight;
logic LED_On;
logic [7:0] sseg2, sseg1, sseg0;

// -- added logic --
logic sensorA, sensorB, sensorCBounce, sensorCDeBounce, sensorC;

// -- sensors ---
// sensorA - Raod A east/west
// sensorB - Road B north/south
// sensorC - road reset/flashing red


// -- button buffers -- 

free_run_shift_reg srlr (
	.clk(CLK100MHZ),		//synchronous
	.s_in(BTNL | BTNR),		// Left or Right Buttons OR'd together
	.s_out(sensorA)			//sensorA is the Road A Sensor used later in module
);
free_run_shift_reg srud (
	.clk(CLK100MHZ),		//synchronous
	.s_in(BTNU | BTND),		//Top and Bottom Buttons OR'd  together
	.s_out(sensorB)			//sensorB is the Road B Sensor used later in module
);
free_run_shift_reg srlc (
	.clk(CLK100MHZ),		//synchronous
	.s_in(BTNC),			//center button
	.s_out(sensorCBounce)	//SensorCBounce sent to debounce module to debounce
);

// --- Debounce the Center Button with db_fsm ---
db_fsm dbBTNC(
	.clk(CLK100MHZ),		//synchronous
	.sw(sensorCBounce),		//bounced button to be debounced
	.db(sensorCDeBounce)	//debounced output sent to rising edge module
);

// --- Rising edge detector to output sensorC to be used in state machine ---
risingEdgeDetector redBTNC(
	.clk(CLK100MHZ),			//synchronous
	.signal(sensorCDeBounce),	//debounced signal to find rising edge
	.risingEdge(sensorC)		//rising edge output used in module later
);

//////////////////////////////////////////////////////////////////////////////////////////////
// Timers

// This prescaler generates a tick every 1 second.
// This lowers the number of bits needed for each comparator to trafficLightTimer.
always_ff @ (posedge CLK100MHZ) begin
	if (trafficLightPrescaler == 100_000_000) begin oneSecondTick <= 1; trafficLightPrescaler <= 1; end
	else                                      begin oneSecondTick <= 0; trafficLightPrescaler <= trafficLightPrescaler + 1; end
end

// Traffic Light Timer
// The value of this timer is the number of seconds since the lights have changed (which is the last time a state changed).
// This single timer is shared (time-multiplexed) by many states using different duration times.
always_ff @ (posedge CLK100MHZ) begin
	if (initializeTrafficLightTimer) trafficLightTimer <= 1;
	else if (oneSecondTick)          trafficLightTimer <= trafficLightTimer + 1;
	else                             trafficLightTimer <= trafficLightTimer;
end


//////////////////////////////////////////////////////////////////////////////////////////////
// Traffic Light State Machine
always_comb begin
	// default nextState and outputs, if not changed in the case statement below
	nextState_TrafficLight = state_TrafficLight; // default is that the state doesn't change
	initializeTrafficLightTimer = 0; // default allow the timer to increment
	roadA_GreenLight = OFF; roadA_YellowLight = OFF; roadA_RedLight = OFF; // default road A lights are off
	roadB_GreenLight = OFF; roadB_YellowLight = OFF; roadB_RedLight = OFF; // default road B lights are off
	
	case (state_TrafficLight)

		// -- add additional if statement to break from any state to flashing red (part b) below --
		greenA: begin
			roadA_GreenLight = ON; roadB_RedLight = ON;
			//if statement below added to break to flashing red if center button pressed
			if (sensorC) begin	
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 6 & !sensorA & sensorB) begin
				nextState_TrafficLight = yellowA;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 9) begin // 8 seconds --> changed to 9
				nextState_TrafficLight = yellowA;
				initializeTrafficLightTimer = 1;
			end
		end
		
		yellowA: begin
			roadA_YellowLight = ON; roadB_RedLight = ON;
			//if statement below added to break to flashing red if center button pressed
			if (sensorC) begin
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 2) begin // 2 seconds
				nextState_TrafficLight = redA;
				initializeTrafficLightTimer = 1;
			end
		end
		
		redA: begin
			roadA_RedLight = ON; roadB_RedLight = ON;
			if (sensorC) begin
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 2) begin // 2 seconds
				nextState_TrafficLight = greenB;
				initializeTrafficLightTimer = 1;
			end
		end

		greenB: begin
		roadB_GreenLight = ON; roadA_RedLight = ON;
			//if statement below added to break to flashing red if center button pressed
			if (sensorC) begin
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 6 & sensorA) begin
				nextState_TrafficLight = yellowB;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 9) begin // 6 seconds
				nextState_TrafficLight = yellowB;
				initializeTrafficLightTimer = 1;
			end
		end
		
		yellowB: begin
			roadB_YellowLight = ON; roadA_RedLight = ON;
			//if statement below added to break to flashing red if center button pressed
			if (sensorC) begin
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 2) begin // 2 seconds
				nextState_TrafficLight = redB;
				initializeTrafficLightTimer = 1;
			end
		end
		
		redB: begin
			roadB_RedLight = ON; roadA_RedLight = ON;
			//if statement below added to break to flashing red if center button pressed
			if (sensorC) begin
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
			else if (oneSecondTick & trafficLightTimer >= 2) begin // 2 seconds
				nextState_TrafficLight = greenA;
				initializeTrafficLightTimer = 1;
			end
		end

		// -- Added states to incorperate fhashing red lights (Part C) --
		flashRedOn:		begin
			roadB_RedLight=ON; roadA_RedLight=ON;		//turn all red lights on
			
			//if sensorC, break back to yellowB state and reset timer
			if(sensorC) begin
				nextState_TrafficLight = yellowB;
				initializeTrafficLightTimer = 1;
			end

			//after 1 second, change state to flashRedOff and reset timer
			else if(oneSecondTick & trafficLightTimer >= 1) begin
				nextState_TrafficLight = flashRedOff;
				initializeTrafficLightTimer = 1;
			end
		end

		flashRedOff:	begin
			//if sensorC break back to yellowB state and reset timer
			if(sensorC) begin
				nextState_TrafficLight = yellowB;
				initializeTrafficLightTimer = 1;
			end

			//after 1 second, change state to flashRedOn and reset timer
			//this keeps flashing loop until center button pressed
			else if(oneSecondTick & trafficLightTimer >= 1) begin
				nextState_TrafficLight = flashRedOn;
				initializeTrafficLightTimer = 1;
			end
		end

		default: begin
			nextState_TrafficLight = yellowB; // get illegal states to a known state
			initializeTrafficLightTimer = 1;
		end
	endcase
end

always_ff @(posedge CLK100MHZ) begin
   state_TrafficLight <= nextState_TrafficLight;
end


//////////////////////////////////////////////////////////////////////////////////////////////
// Emulation of traffic lights using the RGB LEDs and 7-segment displays on a Nexys4DDR.

// Use a Pulse Width Modulator to give the user the ability to adjust the traffic RGB LED brightness with switches.
pwm_basic #(.R(16)) pwm0( // 16 bits of PWM resolution from 100MHz gives a PWM frequency of 1526 Hz
	.clk(CLK100MHZ),
	.duty({SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0}), 
		// Specifying the switches separately in the .xdc file eliminates some warning messages.
		// This has to do with specifying different voltages for different switches, but students can ignore this.
	.pwm_out(LED_On)
);

// Yellow light is produced by turning on both green and red lights (although on these LEDs it's not a very good yellow).
 always_ff @(posedge CLK100MHZ) begin
	LED17_G <= (roadA_GreenLight | roadA_YellowLight) & LED_On; // left  green LED
	LED17_R <= (roadA_RedLight   | roadA_YellowLight) & LED_On; // left  red   LED
	LED16_G <= (roadB_GreenLight | roadB_YellowLight) & LED_On; // right green LED
	LED16_R <= (roadB_RedLight   | roadB_YellowLight) & LED_On; // right red   LED
 end


// Display the number of seconds it's been in the current state, and the locations of the lights that are on.
hex_to_sseg_p hex_to_sseg_p0(.hex(trafficLightTimer[3:0]), .dp(1'b0), .sseg_p(sseg2[7:0]));
assign sseg1[7:0] = {1'b0,roadA_YellowLight,2'b0,roadA_GreenLight,2'b0,roadA_RedLight};
assign sseg0[7:0] = {1'b0,roadB_YellowLight,2'b0,roadB_GreenLight,2'b0,roadB_RedLight};
led_mux8_p led_mux8_p0(
    .clk(CLK100MHZ), .reset(1'b0), 
    .in7(8'b0), .in6(8'b0), .in5(8'b0), .in4(8'b0), .in3(8'b0), .in2(sseg2), .in1(sseg1), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA})
);

endmodule