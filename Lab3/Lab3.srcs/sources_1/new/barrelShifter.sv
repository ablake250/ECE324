`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//ECE 324 - Lab 3 Barrel Shifter
//Alex Blake Jameson Shaw
//Feb 5, 2019
//////////////////////////////////////////////////////////////////////////////////


module barrelShifter(
    input [15:0] x,         //16bit bus input
    input br,               //right button
    input bl,               //left button
    input bc,               //center button
    output [15:0] y         //16bit bus output
    );
    

    //assign statement below commented out is the first conditional logic
    //assign y = (br|bl)?(br?{x[0],x[15:1]}:{x[14:0],x[15]}):(x);
    
    //Below assign statement is extra credit conditional statement
    assign y = bc?((br|bl)?(br?{x[1:0],x[15:2]}:{x[13:0],x[15:14]}):(x))
            :((br|bl)?(br?{x[0],x[15:1]}:{x[14:0],x[15]}):(x));
    
endmodule
