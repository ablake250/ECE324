`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//ECE 324 Homework2: 8 bit Shifter Test Bench
//Alex Blake Jan 28 2019
//////////////////////////////////////////////////////////////////////////////////


module shifterTB;           //specify data in (8 bits), shift select (3 bits), and output shifted (8 bits)
    logic [7:0]data;
    logic [2:0]shift;
    logic [7:0]shout;

shifter UUT (               //initialize a shifter module using the above matching logic
    .data(data),
    .shift(shift),
    .shout(shout)
);

initial begin   //begin test bench
    //increment shift by 1 bit and test both 0b00001111 and ob11001100
    //for each shift amount
    #10 data=8'b00001111; shift=3'b000;
    #10 data=8'b11001100; shift=3'b000;
    #10 data=8'b00001111; shift=3'b001;
    #10 data=8'b11001100; shift=3'b001;
    #10 data=8'b00001111; shift=3'b010;
    #10 data=8'b11001100; shift=3'b010;
    #10 data=8'b00001111; shift=3'b011;
    #10 data=8'b11001100; shift=3'b011;
    #10 data=8'b00001111; shift=3'b100;
    #10 data=8'b11001100; shift=3'b100;
    #10 data=8'b00001111; shift=3'b101;
    #10 data=8'b11001100; shift=3'b101;
    #10 data=8'b00001111; shift=3'b110;
    #10 data=8'b11001100; shift=3'b110;
    #10 data=8'b00001111; shift=3'b111;
    #10 data=8'b11001100; shift=3'b111;
    #10 $stop;               //Stop simulation               

end
endmodule
