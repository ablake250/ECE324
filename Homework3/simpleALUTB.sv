//////////////////////////////////////////////////////////////////////////////////
//ECE 324 - Homework 3 - Test Bench for simpleALU
//Alex Blake - 2/7/19
//////////////////////////////////////////////////////////////////////////////////

`timescale 100ps/10ps               //shrink the incremental units from
                                    //1ns to 100ps, simulation now has time
                                    //to finish all different inputs
module simpleALUTB;

    //logic matching the simpleALU is defined
    logic [3:0] a, b, y;
    logic [1:0] s;

    //instantiate the simpleALU module
    simpleALU alu0(
        .a(a),
        .b(b),
        .y(y),
        .s(s)
    );

    //below is the test for the simpleALU to pass
    initial begin
        for (int i=0; i<=15; i++) begin         //loops through all values of a
            for (int j=0; j<=15; j++) begin     //loops through all values of b
                for (int k=0; k<=3; k++) begin  //loops through all values of s
                //below the integer values of the loop counters are set
                //to their corresponding variable
                    a=i;
                    b=j;
                    s=k;
                    #1;     //increment time by 100ps
                    case (s)
                        0:  begin
                            //assert when s==0, y==a+b and print either pass or fail including values
                            //of a, b, and s
                            assert(y==a+b) ("Pass! a=%d, b=%d, s=%d", a,b,s);
                                else $error("FAILED: a=%d, b=%d, s=%d", a,b,s);
                        end
                        1:  begin
                            //assert when s==0, y==a<<b[1:0] and print either pass or fail including values
                            //of a, b, and s
                            assert(y==a<<b[1:0]) $info("Pass!  a=%d, b=%d, s=%d", a,b,s);
                                else $error("FAILED: a=%d, b=%d, s=%d", a,b,s);
                        end
                        2:  begin
                            //assert when s==0, y==(a&b) and print either pass or fail including values
                            //of a, b, and s
                            assert(y==(a&b)) $info("Pass! a=%d, b=%d, s=%d", a,b,s);
                                else $error("FAILED: a=%d, b=%d, s=%d, y=%d", a,b,s,y);
                        end
                        3:  begin
                            //assert when s==0, y==4'b0001 and print either pass or fail including values
                            //of a, b, and s
                            assert(y==4'b0001) $info("Pass!  a=%d, b=%d, s=%d", a,b,s);
                                else $error("FAILED: a=%d, b=%d, s=%d", a,b,s);
                        end
                        default: begin
                            //default case should not happen; 0<=s<=3
                            //if it does, this will error
                            assert(s>3) $error("FAILED: s>2'b11");
                                else    $error("FAILED: s out of bounds");
                        end
                    endcase
                    #1;             //increment by 100ps again, this ensures the assert
                                    //statements read in the between the input changes so
                                    //to remove any ambiguity 
                end
            end
        end
        $stop;                      //stop the simulation
    end
endmodule