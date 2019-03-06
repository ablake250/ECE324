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
	      quarterMax = 620000) (                                          
	logic input clk,                                                      
	logic input reset,                                                    
	logic input coinSensor,                                               
	logic output dispense                                                
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

			credit5: begin
	      		if(nickelDetected) credit_state <= credit10;   
	      		else if (dimeDetected) credit_state <= credit15;    
				else if (quarterDetected) begin	
					credit_state <= credit5;
					dispense <= 1;
				end
			end

			credit10: begin
				if(nickelDetected) credit_state <= credit15;   
	      		else if (dimeDetected) credit_state <= credit20;    
				else if (quarterDetected) begin	
					credit_state <= credit10;
					dispense <= 1;
				end
			end

			credit15: begin
				if(nickelDetected) credit_state <= credit20;   
	      		else if (dimeDetected) begin
				  	dispense <= 1;
					credit_state <= credit0;
				end
				else if (quarterDetected) begin
					dispense <= 1;	
					credit_state <= credit15;
				end
			end

			credit20: begin
				if(nickelDetected) credit_state <= credit0;   
	      		else if (dimeDetected) credit_state <= credit5;    
				else if (quarterDetected) credit_state <= credit20;
				dispense <= 1;
			end
		endcase
	end
end

endmodule
