/*********************************************************
* ECE 324 Lab 8: Keyboard Music
* Alex Blake & Jameson Shaw 19 Mar 2019
*********************************************************/

/*********************************************************************
File:   Lab8_KeyboardMusic.sv 
Module: Lab8_KeyboardMusic
Function: ECE 324 Lab8 top level starter file.  Emulates 2 octaves of
          a keyboard musical instrument using a computer keyboard.  
		  At most one key should be pressed at any time.
		  Outputs sine waves, with an ADSR envelope.
Revisions:
15 Dec 2016 Tom Pritchard: initially written 
23 Dec 2017 Tom Pritchard: removed note from backslash key so students can add it.
02 Mar 2017 Tom Pritchard: improved comments and names of states.
17 Jun 2018 Tom Pritchard: converted to SystemVerilog.
08 Sep 2018 Tom Pritchard: changed to sine wave with ADSR.
*********************************************************************/
 
module Lab8_KeyboardMusic(
	input logic CLK100MHZ,
	
	// Switches for adsr entry
	input logic SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0,
	
	// buttons to control adsr
	input logic BTNL, // pushing causes current 16 switch values to become atk_step (attack steepness)
	input logic BTNU, // pushing causes current 16 switch values to become dcy_step (decay steepness)
	input logic BTNC, // pushing causes current 16 switch values to become sus_level (sustain volume level)
	input logic BTND, // pushing causes current 16 switch values to become sus_time (sustain length of time)
	input logic BTNR, // pushing causes current 16 switch values to become rel_step (release steepness)
	
	// LEDs to display volume
	output logic [15:0] LED,
	
	// PS2 ports, which are inputs for a computer keyboard
    input logic PS2_DATA, 
	input logic PS2_CLK,
	
	// Audio amplifier
	output logic AUD_PWM,   // audio signal
	output logic AUD_SD = 1 // audio enable 
);

// Instantiate pullup resistors on the PS2 pins
PULLUP ps2c_pu (.O(PS2_CLK)); 
PULLUP ps2d_pu (.O(PS2_DATA)); 


// **********************************
// Parameters and Declarations
// **********************************
// Keyboard codes
localparam BREAK_BYTE 	= 8'hF0;
localparam CTRL_BYTE	= 8'h14;
localparam EXT_BYTE	    = 8'hE0;


logic meta = 1;
logic reset = 1;

logic rx_done_tick;
logic [7:0] rxData;

// State names
typedef enum {IDLE
             ,MAKE_CODE_AFTER_IDLE
			 ,BREAK_BYTE_AFTER_MAKE_CODE
			 ,BREAK_BYTE_AFTER_IDLE
			 ,EXT_BYTE_AFTER_IDLE
			 ,BREAK_BYTE_AFTER_EXT_BYTE
} state_type;
state_type state, nextState;
logic keyPushed;
logic keyReleased;

logic [15:0] SW;
logic [31:0]
                            dcy_step  = 32'h0000_0000,                             //               decay time
atk_step  = 32'hFFFF_FFFF,  sus_level = 32'h0000_0000,  sus_time  = 32'h0000_0000, // attack time, sustain level, sustain time
                            rel_step  = 32'h0000_0000;                             //              release time
logic [15:0] env;

logic [7:0] makeCode;
logic [29:0] fccw;

logic [15:0] pcm_out;
logic volumeButton;
logic increaseVolume, decreaseVolume;
logic [3:0] volume = 15;
integer i;
logic soundOn;
logic [3:0] volumeEnabled;
logic [7:0] volumeSquared;
logic signed [24:0] pcm;


// **********************************
// Reset Generation
// **********************************
// The FPGA global reset (GSR) is not guaranteed to be synchronous to clk when being released after configuration.  
// So the following logic synchronizes the trailing edge of reset to clk, and also mitigates metastability.
always_ff @(posedge CLK100MHZ) begin
	meta <= 0;
	reset <= meta;
end


// **********************************
// Receiver Logic from Keyboard
// **********************************
ps2rx ps2rx0(
	.clk(CLK100MHZ), 
	.reset(reset),
    .ps2d(PS2_DATA), 
	.ps2c(PS2_CLK), 
	.rx_en(1'b1), // always enable receiver for keyboard application
	.rx_idle(), // output not used
	.rx_done_tick(rx_done_tick),
	.dout(rxData[7:0])
);


// **********************************
// State Machine
// **********************************
always_ff @(posedge CLK100MHZ) begin
	if (reset) state <= IDLE;
	else state <= nextState; // stay in same state whenever not receiving a byte
end

always_comb begin
	// defaults, unless changed in case statement below
	nextState = state;
	keyPushed = 0;
	keyReleased = 0;
	increaseVolume = 0;
	decreaseVolume = 0;

	case(state)
		IDLE: begin
            if (rx_done_tick) begin
                if (rxData == CTRL_BYTE) decreaseVolume = 1; // Pushing Ctrl key causes decrease in volume; releasing Ctrl key does nothing
                // WHEN ADDING TWO NEW STATES TO GENERATE increaseVolume, ALSO UNCOMMENT THE FOLLOWING LINE
                else if (rxData == EXT_BYTE) nextState = EXT_BYTE_AFTER_IDLE; // received start of extended key sequence
                else if (rxData == BREAK_BYTE) nextState = BREAK_BYTE_AFTER_IDLE; // proceed to complete the break code sequence
                else begin
                    keyPushed = 1; // key being pushed will start the sound
                    nextState = MAKE_CODE_AFTER_IDLE; // go to the state that indicates a make was made since the last break.
                end
			end
		end
		
		MAKE_CODE_AFTER_IDLE: begin
		    if (rx_done_tick & rxData == BREAK_BYTE) nextState = BREAK_BYTE_AFTER_MAKE_CODE; // break byte, so proceed to complete the break code sequence
            // ignore further makeCodes (such as with a typematic repeating keyboard)
		end

		BREAK_BYTE_AFTER_MAKE_CODE: begin
		    if (rx_done_tick) begin
                keyReleased = 1; // a key has been released, so turn off the sound (even if the ADSR isn't done).
                nextState = IDLE;
            end
		end
		
		BREAK_BYTE_AFTER_IDLE: begin
		    if (rx_done_tick) nextState = IDLE; // this state completes the break code sequence, so the second byte isn't interpreted as a make code.
		end
		
		EXT_BYTE_AFTER_IDLE: begin
			if(rx_done_tick) begin
				if(rxData == BREAK_BYTE) begin
					increaseVolume = 1;
					nextState = BREAK_BYTE_AFTER_EXT_BYTE;
				end
			end
		end
	
		BREAK_BYTE_AFTER_EXT_BYTE: begin
			if (rx_done_tick) begin
				keyReleased = 1;
				nextState = IDLE;
			end
		end
		
	endcase
end


// **********************************
// ADSR
// **********************************
assign SW = {SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0};
	// Specifying the switches separately in the .xdc file eliminates some warning messages.
	// This has to do with specifying different voltages for different switches, but students can ignore this.

always_ff @(posedge CLK100MHZ) begin
	if (BTNL) atk_step  <= {16'b0,SW[15:0]}; // set SW[15:0] (in hex) to 21.475 / attack time (in seconds)
	if (BTNU) dcy_step  <= {16'b0,SW[15:0]}; // set SW[15:0] (in hex) to 21.475 / decay time (in seconds) * (1 - ratio to maximum volume)
	if (BTNC) sus_level <= {SW[15:0],16'b0}; // set SW[15:0] (in hex) to 32768 * ratio to maximum volume
	if (BTND) sus_time  <= {SW[15:0],16'b0}; // set SW[15:0] (in hex) to 1526 * sustain time (in seconds)
	if (BTNR) rel_step  <= {16'b0,SW[15:0]}; // set SW[15:0] (in hex) to 21.475 / release time (in seconds) * ratio to maximum volume
	if (BTNL & (SW[15:0] == 16'hFFFF)) atk_step <= 32'hFFFFFFFF; // all on code to enable adsr's bypass functionality
end

adsr adsr0(
	// inputs
	.clk(CLK100MHZ),
	.reset(reset),
	.start(keyPushed), // adsr sequence starts when a keyboard key is pressed.
	.atk_step,   // attack steepness
	.dcy_step,   // decay steepness
	.sus_level,  // sustain volume level
	.sus_time,   // sustain length of time
	.rel_step,   // release steepness
	// outputs
	.env,        // envelope
	.adsr_idle() // between notes played, unused
);


// **********************************
// DDFS
// **********************************
// Map keys to notes of a 12-tone equal temperament scale.
// Adjacent notes' frequencies are factors of the twelth root of 2, with note A4 being 440 Hz.
// Since the ddfs logic's phase accumulator is 30 bits, 
// fccw is calculated by multiplying 2^30 by the sine wave frequency divided by the clock frequency (100MHz).
// The "white" keys are replicated in the "caps lock" row for easier use of the thumb when using all 5 right-hand fingers.
always_ff @(posedge CLK100MHZ) begin
	if (keyPushed) makeCode[7:0] <= rxData[7:0];
	case (makeCode[7:0])
		8'h0E: fccw <= 2503; // ` = A#3 = 233.082 Hz
		8'h0D: fccw <= 2652; //TAB= B3  = 246.942 Hz
		8'h58: fccw <= 2652; //CpL= B3  = 246.942 Hz
		8'h15: fccw <= 2809; // Q = C4  = 261.626 Hz
		8'h1C: fccw <= 2809; // A = C4  = 261.626 Hz
		8'h1E: fccw <= 2976; // 2 = C#4 = 277.183 Hz
		8'h1D: fccw <= 3153; // W = D4  = 293.665 Hz
		8'h1B: fccw <= 3153; // S = D4  = 293.665 Hz
		8'h26: fccw <= 3341; // 3 = D#4 = 311.127 Hz
		8'h24: fccw <= 3539; // E = E4  = 329.628 Hz
		8'h23: fccw <= 3539; // D = E4  = 329.628 Hz
		8'h2D: fccw <= 3750; // R = F4  = 349.228 Hz
		8'h2B: fccw <= 3750; // F = F4  = 349.228 Hz
		8'h2E: fccw <= 3973; // 5 = F#4 = 369.994 Hz
		8'h2C: fccw <= 4209; // T = G4  = 391.995 Hz
		8'h34: fccw <= 4209; // G = G4  = 391.995 Hz
		8'h36: fccw <= 4459; // 6 = G#4 = 415.305 Hz
		8'h35: fccw <= 4724; // Y = A4  = 440.000 Hz reference frequency
		8'h33: fccw <= 4724; // H = A4  = 440.000 Hz
		8'h3D: fccw <= 5005; // 7 = A#4 = 466.164 Hz
		8'h3C: fccw <= 5303; // U = B4  = 493.883 Hz
		8'h3B: fccw <= 5303; // J = B4  = 493.883 Hz
		8'h43: fccw <= 5618; // I = C5  = 523.251 Hz
		8'h42: fccw <= 5618; // K = C5  = 523.251 Hz
		8'h46: fccw <= 5952; // 9 = C#5 = 554.365 Hz
		8'h44: fccw <= 6306; // O = D5  = 587.330 Hz
		8'h4B: fccw <= 6306; // L = D5  = 587.330 Hz
		8'h45: fccw <= 6681; // 0 = D#5 = 622.254 Hz
		8'h4D: fccw <= 7079; // P = E5  = 659.255 Hz
		8'h4C: fccw <= 7079; // ; = E5  = 659.255 Hz
		8'h54: fccw <= 7500; // [ = F5  = 698.456 Hz
		8'h52: fccw <= 7500; // ' = F5  = 698.456 Hz
		8'h55: fccw <= 7946; // = = F#5 = 739.989 Hz
		8'h5B: fccw <= 8418; // ] = G5  = 783.991 Hz
		8'h5A: fccw <= 8418; //Ent= G5  = 783.991 Hz
		8'h66: fccw <= 8919; //BkS= G#5 = 830.609 Hz

		// insert here your calculation of the carrier frequency control word (fccw) of the note A5
		/*
			A5 is an octave above A4 (440Hz), so multiply by 2
			A5 frequency = (440Hz)*2=880Hz
			fccw = 880Hz * (2^30) / 100MHz = 9449
		*/
		8'h5D: fccw <= 9449; // \ = A5 = 880Hz

	  default: fccw <= 524288; // 48828 Hz (above human hearing range) if any other key pressed
	endcase
end

ddfs ddfs0(
	// inputs
	.clk(CLK100MHZ),
	.reset(reset),
	.fccw,        // carrier frequency control word
	.focw(30'b0), // frequency offset not used
	.pha(30'b0),  // phase offset not used
	.env,         // envelope from adsr
	// outputs
	.pcm_out,     // pulse code modulated sine wave
	.pulse_out()  // square wave output unused
);


// **********************************
// Volume
// **********************************
always_ff @(posedge CLK100MHZ) begin	
	// generate the volume amplitude
	if      (increaseVolume && (volume != 4'hF)) volume <= volume + 1;
	else if (decreaseVolume && (volume != 4'h0)) volume <= volume - 1;
	
	// display the volume amplitude from left to right on the Nexys4DDR LEDs
	for (i=0; i<=15; i=i+1) LED[15-i] <= (volume >= i);
	
	// sound is on only when a key is being pressed
    if      (keyPushed)   soundOn <= 1;
    else if (keyReleased) soundOn <= 0;
    
    if (soundOn) volumeEnabled[3:0] <= volume;
    else         volumeEnabled[3:0] <= 4'h0;

	volumeSquared[7:0] <= volumeEnabled **2; // compensate for human ear non-linearity of perceived volume
	pcm[24:0] <= $signed(pcm_out[15:0]) * $signed({1'b0,volumeSquared[7:0]}); // pcm is a 2's complement number, volumeSquared is a positive number	
end


// **********************************
// Digital-To-Analog Converter
// **********************************
ds_1bit_dac ds_1bit_dac0(
	.clk(CLK100MHZ),
	.reset(reset),
	.pcm_in(pcm[23:8]), // pulse code modulated input (bit 24 not used since it's always the same sign bit value as bit 23)
	.pdm_out(AUD_PWM)   // pulse density modulated output to low pass filter and speaker
);

endmodule