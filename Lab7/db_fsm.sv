// Leveraged from Pong Chu's Listing 5.6
// Modified 15 June 2018 Tom Pritchard: replaced reset input with declaration initialization.
module db_fsm
   (
    input logic clk,
    input logic sw,
    output logic db
   );

   // number of counter bits (2^N * 10ns = 10ms tick)
   localparam N =20;
   // fsm state type 
   typedef enum {
      zero, wait1_1, wait1_2, wait1_3,
      one,  wait0_1, wait0_2, wait0_3
   } state_type;

   // signal declaration
   state_type state_reg = zero, state_next;
   logic [N-1:0] q_reg = 0;
   logic [N-1:0] q_next;
   logic m_tick;

   // body
   //******************************************************************
   // counter to generate 10 ms tick
   //******************************************************************
   always_ff @(posedge clk)
      q_reg <= q_next;
   // next-state logic
   assign q_next = q_reg + 1;
   // output tick
   assign m_tick = (q_reg==0) ? 1'b1 : 1'b0;

   //******************************************************************
   // debouncing FSM
   //******************************************************************
   // state register
    always_ff @(posedge clk) state_reg <= state_next;

   // next-state logic and output logic
   always_comb
   begin
      state_next = state_reg;  // default state: the same
      db = 1'b0;               // default output: 0
      case (state_reg)
         zero:
            if (sw)
               state_next = wait1_1;
         wait1_1:
            if (~sw)
               state_next = zero;
            else
               if (m_tick)
                  state_next = wait1_2;
         wait1_2:
            if (~sw)
               state_next = zero;
            else
               if (m_tick)
                  state_next = wait1_3;
         wait1_3:
            if (~sw)
               state_next = zero;
            else
               if (m_tick)
                  state_next = one;
         one:
            begin
              db = 1'b1;
              if (~sw)
                 state_next = wait0_1;
            end
         wait0_1:
            begin
               db = 1'b1;
               if (sw)
                  state_next = one;
               else
                 if (m_tick)
                    state_next = wait0_2;
            end
         wait0_2:
            begin
               db = 1'b1;
               if (sw)
                  state_next = one;
               else
                 if (m_tick)
                    state_next = wait0_3;
            end
         wait0_3:
            begin
               db = 1'b1;
               if (sw)
                  state_next = one;
               else
                 if (m_tick)
                    state_next = zero;
            end
         default: state_next = zero;
      endcase
   end
endmodule