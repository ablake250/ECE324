

module readAccel(
    input logic clk, reset, miso,
    output logic [7:0] xAxis, yAxis, zAxis,
    output logic cs, mosi, sclk
);

    logic [15:0] dvsr = 0;
    logic cpol = 0, cpha = 0;
    logic spi_done_tick, ready;
    logic [7:0]din;
    logic maxTick;
    
    localparam WRITE = 8'h0A;
    localparam WADD = 8'h2D;
    localparam MMODE = 8'h02;
    localparam XINST = 8'h0B;
    localparam XADDR = 8'h08;
    localparam YINST = 8'h0B;
    localparam YADDR = 8'h09;
    localparam ZINST = 8'h0B;
    localparam ZADDR = 8'h0A;
    

    logic start;
    logic [7:0]dout, counter = 0;
    
    //clk input is 100MHz, must be converted to slower clock signal
    // 100MHz / 400Hz = 

    mod_m_counter #(.M(200)) mc0(
        .clk(clk),
        .max_tick(maxTick),
        .q()
    );

    spi spi0(
        .clk(maxTick),
        .*
    );

    //////////////////////////////////////////////////////////////////////////
    //FSM
    //////////////////////////////////////////////////////////////////////////

    typedef enum    { initialize0, initialize1, initialize2, idle, xInst0, xInst1, xAddr0, xAddr1, xWait0, xWait1,
                      yInst0, yInst1, yAddr0, yAddr1, yWait0, yWait1,
                      zInst0, zInst1, zAddr0, zAddr1, zWait0, zWait1 } state_type;

    state_type state = initialize0;

    always_ff @(posedge maxTick) begin
        if(reset) begin
            state <= initialize0;
            counter <= 0;
            start <= 0;
            cs <= 0;
            din <= WRITE;
        end
        else begin
            case(state)
            
            /////////////////////////////////
            //initialize
            ///////////////////////////////
                initialize0: begin
                    if(counter == 0) din <= WRITE;
                    cs <= 0;
                    start <= 1;
                    if(counter == 3) begin
                        din <= WADD;
                        counter <= counter + 1;
                    end
                    else if (ready & counter > 4) begin
                        counter <= 0;
                        state <= initialize1;
                    end
                    else counter <= counter + 1;
                end
                initialize1: begin
                    if(counter == 2) begin
                        din <= MMODE;
                        counter <= counter + 1;
                    end
                    else if (ready & counter > 4) begin
                        counter <= 0;
                        state <= initialize2;
                    end
                    else counter <= counter + 1;
                end
                initialize2: begin
                    if(counter == 2) begin
                        start <= 0;
                        din <= 0;
                        counter <= counter + 1;
                    end
                    else if (ready & counter > 4) begin
                        counter <= 0;
                        cs <= 0;
                        state <= idle;
                    end
                    else counter <= counter + 1;
                end
                
                //X
                idle: begin
                    cs = 1;
                    if(counter == 10) begin
                        cs = 1;
                        counter <= 0;
                        state <= xInst0;
                        din <= XINST;
                    end
                    else counter <= counter + 1;
                end
                xInst0: begin
                    start = 1;
                    cs = 0;
                    state <= xInst1;
                    counter <= 0;
                end
                xInst1: begin
                    if(ready & counter >= 4) begin
                        state <= xAddr0;
                        counter <= 0;
                    end
                    else if (counter == 2) begin
                        din <= XADDR;
                        counter <= counter + 1;
                    end
                    else counter <= counter + 1;
                end
                xAddr0: begin
                    start <= 1;
                    state <= xAddr1;
                end

                xAddr1: begin
                    if(ready & counter > 4) begin
                        state <= xWait0;
                        din <= 0;
                        counter <= 0;
                    end
                    else counter <= counter + 1;
                end
                xWait0: begin
                    state <= xWait1;
                end
                
                xWait1: begin
                    if(counter == 20) begin
                        state <= yInst0;
                        counter <= 0;
                    end
                    else if(ready & counter > 4) begin
                        xAxis <= dout;
                        counter <= counter + 1;
                        start <= 0;
                        cs <= 1;
                    end
                    else if (counter == 2) begin
                        start <= 0;
                        counter <= counter + 1;
                        din <= YINST;
                    end
                    else counter <= counter + 1;
                end
                
                // Y

                yInst0: begin
                    start <= 1;
                    cs <= 0;
                    state <= yInst1;
                    counter <= 0;
                end
                yInst1: begin
                    if(ready & counter > 4) begin
                        state <= yAddr0;
                        counter <= 0;
                    end
                    else if (counter == 2) begin
                        din <= YADDR;
                        counter <= counter + 1;
                    end
                    else counter <= counter + 1;
                end
                yAddr0: begin
                    start <= 1;
                    state <= yAddr1;
                end

                yAddr1: begin
                    if(ready & counter > 4) begin
                        state <= yWait0;
                        din <= 0;
                        counter <= 0;
                    end
                    else counter <= counter + 1;
                end
                yWait0: begin
                    state <= yWait1;
                end
                
                yWait1: begin
                    if(counter == 20) begin
                        counter <= 0;
                        state <= zInst0;
                    end
                    else if(ready & counter > 4) begin
                        counter <= counter + 1;
                        yAxis <= dout;
                        cs <= 1;
                    end
                    else if (counter == 2) begin
                        start <= 0;
                        counter <= counter + 1;
                        din <= ZINST;
                    end
                    else counter <= counter + 1;
                end
                
           
                zInst0: begin
                    start <= 1;
                    cs <= 0;
                    state <= zInst1;
                    counter <= 0;
                end
                zInst1: begin
                    if(ready & counter >= 4) begin
                        state <= zAddr0;
                        counter <= 0;
                    end
                    else if (counter == 2) begin
                        din <= ZADDR;
                        counter <= counter + 1;
                    end
                    else counter <= counter + 1;
                end
                zAddr0: begin
                    start <= 1;
                    state <= zAddr1;
                end

                zAddr1: begin
                    if(ready & counter > 4) begin
                        state <= zWait0;
                        din <= 0;
                        counter <= 0;
                    end
                    else counter <= counter + 1;
                end
                zWait0: begin
                    state <= zWait1;
                end
                
                zWait1: begin
                    if(counter == 20) begin
                        state <= idle;
                        counter <= 0;
                    end
                    else if(ready & counter > 4) begin
                        cs <= 1;
                        counter <= counter + 1;
                        zAxis <= dout;
                    end
                   
                    else if (counter == 2) begin
                        start <= 0;
                        counter <= counter + 1;
                    end
                    else counter <= counter + 1;
                end
            endcase
        end
    end





endmodule