
module Top (

    //clock signal
    input logic CLK100MHZ,
    //SSEG
    output logic [7:0] AN,               
    output logic DP,CG,CF,CE,CD,CC,CB,CA,

    //spi
    input logic ACL_MISO,
    output logic ACL_MOSI, ACL_SCLK, ACL_CSN 
);

    logic reset;
    logic [7:0] xAxis, yAxis, zAxis, xAxis_stg2, yAxis_stg2, zAxis_stg2;
    logic [7:0] sseg7, sseg6, sseg5, sseg4, sseg3, sseg2, sseg1, sseg0;


    readAccel ra0(
        .clk(CLK100MHZ),
        .reset(reset),
        .miso(ACL_MISO),
        .mosi(ACL_MOSI),
        .sclk(ACL_SCLK),
        .cs(ACL_CSN),
        .xAxis(xAxis),
        .yAxis(yAxis),
        .zAxis(zAxis)
    );

    always_ff @(posedge CLK100MHZ) begin
        xAxis_stg2 <= xAxis;
        yAxis_stg2 <= yAxis;
        zAxis_stg2 <= zAxis;
    end


    hex_to_sseg_p hts7 (.hex(xAxis_stg2[7:4]), .dp(0), .sseg_p(sseg7));
    hex_to_sseg_p hts6 (.hex(yAxis_stg2[7:4]), .dp(0), .sseg_p(sseg6));
    hex_to_sseg_p hts5 (.hex(0), .dp(0), .sseg_p(sseg5));
    hex_to_sseg_p hts4 (.hex(0), .dp(0), .sseg_p(sseg4));
    hex_to_sseg_p hts3 (.hex(0), .dp(0), .sseg_p(sseg3));
    hex_to_sseg_p hts2 (.hex(0), .dp(0), .sseg_p(sseg2));
    hex_to_sseg_p hts1 (.hex(0), .dp(0), .sseg_p(sseg1));
    hex_to_sseg_p hts0 (.hex(0), .dp(0), .sseg_p(sseg0));

    led_mux8_p dm8_0(
    .clk(CLK100MHZ), .reset(1'b0), 
    .in7(sseg7), .in6(sseg6), .in5(sseg5), .in4(sseg4), .in3(sseg3), .in2(sseg2), .in1(sseg1), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA}));

endmodule
