//////////////////////////////////////////////////////////////////////////////////
//ECE 324 - Homework 3 - 2 x 4-bit input, 2-bit select ALU w/ 4-bit output 
//Alex Blake - 2/7/19
//////////////////////////////////////////////////////////////////////////////////

module simpleALU(
    //define logical inputs/outputs
    input logic [3:0]a, b,      //2 4-bit bus data inputs
    input logic [1:0] s,        //2-bit bus select input
    output logic [3:0]y         //4-bit bus output
);

always_comb begin
    //below is a case statement which defines the output y by
    //whichever statement below corresponds with s
    case (s)
        0:          y=a+b;              //s=0; y=a+b
        1:          y=a<<b[1:0];        //s=1
        2:          y=a&b;              //s=2
        3:          y=4'b0001;          //s=3
        default:    y=0;                //s=out of range; this 
                                        //should never be used
    endcase
end

endmodule