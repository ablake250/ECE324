
`timescale 1ns/1ns

module SPI_TB;

localparam T = 6;

logic clk = 1;
logic reset = 1;
logic [7:0] din, dout;
logic [15:0] dvsr = 0;
logic start;
logic cpol = 0, cpha = 0;
logic sclk, miso, mosi;
logic spi_done_tick, ready;
logic [7:0]xAxis, yAxis, zAxis;
logic max_Tick;
logic maxTick;
logic [7:0] counter;

logic [3:0] state;

logic cs;

readAccel ra0(
    .*
);

always begin
    #(T/2) clk = !clk;
end

initial begin 
    repeat(1) @(negedge clk);
    reset = 0;
    repeat(600) @(negedge clk);
    //$stop;
end

initial begin
    #380 miso = 1;
    #16 miso = 0;
    #32 miso = 1;

end



endmodule