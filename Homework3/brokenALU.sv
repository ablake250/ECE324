//////////////////////////////////////////////////////////////////////////////////
//ECE 324 - Homework 3 - Broken simpleALU
//Alex Blake - 2/7/19
//////////////////////////////////////////////////////////////////////////////////

//Everything is exactly the same as simpleALU except
//the case 0 argument: should be y=a+b

module brokenALU(
    input logic [3:0]a, b,
    input logic [1:0] s,
    output logic [3:0]y
);
always_comb begin
    case (s)
    
        0:          y=a-b;              //wrong operation, this line is different 
                                        //from simpleALU
        1:          y=a<<b[1:0];
        2:          y=a&b;
        3:          y=4'b0001;
        default:    y=0;        
    endcase
end
endmodule
