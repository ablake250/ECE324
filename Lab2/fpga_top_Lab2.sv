//////////////////////////////////////////////////////////////////////////////////
// Company: WSU Vancouver
// Engineer: Pritchard
// 
// Create Date:    13:11:14 01/18/2012 
// Design Name: 
// Module Name:  fpga_top_Lab2 
// Project Name:
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fpga_top_Lab2(
    input logic [3:0] SW,
    input logic BTNC,
    output logic [0:15] LED
);

FourToSixteenDecoder FTSD0 (
	.w(SW), 
	.En(BTNC), 
	.y(LED)
);

endmodule
