/*********************************************************
* ECE 324 Homework 7: Vending Machine
* Alex Blake 21 Mar 2019
*********************************************************/


/************************************************
* ECE 324 HW 7
* File VendingMachine.sv
* Source code for vending machine problem
* 06 Jan 2019 Tom Pritchard: initially wrote
************************************************/

module VendingMachine
	      #(parameter dimeMin = 380000,                                  
	      dimeMax = 420000,                                               
	      nickelMin = 480000,                                             
	      nickelMax = 520000,                                             
	      quarterMin = 580000,                                            
	      quarterMax = 620000)(
    input logic clk,                                                      
	input logic reset,                                                    
	input logic coinSensor,                                               
	output logic dispense                                                
);

// Declarations
	logic nickelDetected,  dimeDetected,  quarterDetected ;              

// Instantiate CoinDetector 
CoinDetector 
	#(.dimeMin(dimeMin),
	  .dimeMax(dimeMax),
	  .nickelMin(nickelMin),
	  .nickelMax(nickelMax),
	  .quarterMin(quarterMin),
	  .quarterMax(quarterMax))
	CoinDetector0 
	(.clk, 
	 .reset,
	 .coinSensor,
	 .dimeDetected,
	 .nickelDetected,
	 .quarterDetected
);


// Dispenser State Machine
typedef enum {credit0, credit5, credit10, credit15, credit20} state_type;
state_type credit_state;
always_ff @(posedge clk) begin
	if (reset) begin
	      credit_state <= credit0; 
	      dispense <= 0;        
	end
	
	else begin
	      dispense <= 0;           
		case(credit_state)
	      credit0: if (nickelDetected) credit_state <= credit5;
	      	else if (dimeDetected) credit_state <= credit10;            
	      	else if (quarterDetected) dispense <= 1;    
       
			// FINISH STATE MACHINE HERE

		// -- state credit5 --
			credit5: begin
	      if(nickelDetected) credit_state <= credit10; 				//if nickel added, go to state credit10  
	    	else if (dimeDetected) credit_state <= credit15;    //if dime added, go to state credit15
				else if (quarterDetected) begin											//if quarter added, go to state credit5(doesn't change) and dispense
				credit_state <= credit5;
				dispense <= 1;
				end
			end

			// -- state credit10 --
			credit10: begin
				if(nickelDetected) credit_state <= credit15;				//if nickel added, go to state credit15
	      else if (dimeDetected) credit_state <= credit20;    //if dime added, go to state credit20
				else if (quarterDetected) begin											//if quarter added, go to state credit10 & dispense
					credit_state <= credit10;
					dispense <= 1;
				end
			end

			// -- state credit15 --
			credit15: begin
				if(nickelDetected) credit_state <= credit20;   		//if nickel added, go to state credit20
	      else if (dimeDetected) begin											//if dime added, go to state credit0 & dispense
				  dispense <= 1;																	
					credit_state <= credit0;
				end
				else if (quarterDetected) begin										//if quarter detected, go to state credit15 & dispense
					dispense <= 1;	
					credit_state <= credit15;
				end
			end

			// -- state credit20 --
			credit20: begin
				if(nickelDetected) begin													//if nickel added...
					/*
						This is the state that was broken on purpose to be caught with the testbench.
						Before it was broken, the if statement was the following:

							credit_state <= credit0;
							dispense <= 1;
						
						Instead, it was changed to the below:
					*/
					credit_state <= credit15;    
					dispense <= 1;
				end

				// -- The rest of the code below is not modified like the above was...  --
	      else if (dimeDetected) begin 											//if dime detected, go to state credit5 & dispense
					credit_state <= credit5;
					dispense <= 1;
				end
				else if (quarterDetected) begin 									//if quarter detected, go to state credit20 & dispense
					credit_state <= credit20;
					dispense <= 1;
			    end
			end
		endcase
	end
end
endmodule