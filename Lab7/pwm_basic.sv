module pwm_basic
// Leveraged from listing 14.1 in Pong Chu's FPGA Prototyping by SystemVerilog Examples.
// Modified 07 Sep 2018 Tom Pritchard: changed reset input to configuration reset, and simplified.
   #(parameter R=10)  // # bits of PWM resolution (i.e., 2^R levels)
   (
    input  logic clk,
    input  logic [R-1:0] duty,
    output logic pwm_out
   );

   // declaration
   logic [R-1:0] d_reg = 0;
   logic pwm_reg = 0;
   
   // body 
   always_ff @(posedge clk) begin
       d_reg <= d_reg + 1;
       pwm_out <= (d_reg < duty);
   end
endmodule