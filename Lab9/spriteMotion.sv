/*********************************************************
* ECE 324 Lab 9: spriteMotion
* Alex Blake & Jameson Shaw 26 Mar 2019
*********************************************************/

// File: spriteMotion.sv
// Module: spriteMotion
//
// Function:
// Using moving algorithms, provides center locations and face selection of the five sprites in the PacMan game.
//
// Revisions: 
// 18 Oct 2018 Tom Pritchard: Initial development for ECE 324 lab

module spriteMotion (
   input logic clk108MHz, // video clock frequency of 108 MHz
   input logic resetPressed, // pushing initializes the board, and releasing starts the movement
  
   // pacman sprite
   input logic upPressed, rightPressed, downPressed, leftPressed, // buttons making request to make pacman go in a certain direction
   input logic wallAbovePacman, wallRightOfPacman, wallBelowPacman, wallLeftOfPacman, // wall prevents pacman from going in that direction
   output logic [7:0] pacmanColumn = 128, // 0-255
   output logic [7:0] pacmanRow = 188,    // 0-255
   output logic [3:0] pacmanFace = 8,     // 9 faces, 2 (wide and narrow mouth) for each of 4 directions, and 1 for closed mouth
   
   //blinky sprite
   input wallAboveBlinky, wallRightOfBlinky, wallBelowBlinky, wallLeftOfBlinky, // wall prevents blinky from going in that direction
   output logic [7:0] blinkyColumn = 128, // 0-255
   output logic [7:0] blinkyRow = 92,     // 0-255
   output logic [2:0] blinkyFace = 2,     // 8 faces, two skirts for each of 4 directions
   
   // pinky sprite
   output logic [7:0] pinkyColumn,            // 0-255
   output logic [7:0] pinkyRow,               // 0-255
   output logic [2:0] pinkyFace,              // 8 faces, two skirts for each of 4 directions
   
   // inky sprite
   output logic [7:0] inkyColumn,             // 0-255
   output logic [7:0] inkyRow,                // 0-255
   output logic [2:0] inkyFace,               // 8 faces, two skirts for each of 4 directions
   
   // clyde sprite
   output logic [7:0] clydeColumn,            // 0-255
   output logic [7:0] clydeRow,               // 0-255
   output logic [2:0] clydeFace               // 8 faces, two skirts for each of 4 directions
);


////////////////////////////////////
// Declarations
logic max_tick_Pacman; 
logic pacmanCenterColumn, pacmanCenterRow;
logic movePacman, movePacman_stg2;
logic [1:0] pacmanColumnChange=2'b00, pacmanRowChange=2'b00;

logic max_tick_Blinky;
logic blinkyCanGoLeft,blinkyCanGoRight,blinkyCanGoDown,blinkyCanGoUp;
logic blinkyCenterColumn, blinkyCenterRow;
logic [8:3] pacmanToBlinkyColumnDistance, pacmanToBlinkyRowDistance;
logic pacmanToBlinkyRowMagnitudeGtColumnMagnitude;
logic moveBlinky, moveBlinky_stg2;
logic [1:0] blinkyColumnChange=2'b00, blinkyRowChange=2'b00;


////////////////////////////////////
// Pacman Sprite Movement

// In the initial screen, Pacman moves at 80 pixels/second (which is 80% of his maximum speed), which is 1350000 clocks at 108MHz
mod_m_counter #(.M(1350000)) pacmanCntr(.clk(clk108MHz), .max_tick(max_tick_Pacman), .q());

always_ff @(posedge clk108MHz) begin
    pacmanCenterColumn <= (pacmanColumn[2:0] == 3'b100);
    pacmanCenterRow    <= (pacmanRow[2:0]    == 3'b100);
	
	movePacman <= max_tick_Pacman; // synchronize because of combinational logic delay on max_tick_Pacman
	if (resetPressed | pacmanColumn==blinkyColumn & pacmanRow==blinkyRow) begin pacmanColumnChange <= 2'b00; pacmanRowChange <= 2'b00; end
	   // stop pacman if reset button is pushed, or if pacman and blinky are in the same location
	else if(movePacman) begin   
        if (pacmanCenterColumn && pacmanCenterRow) begin // tile center
            if      (!wallAbovePacman   & upPressed)                     begin pacmanRowChange <= 2'b11; pacmanColumnChange <= 2'b00; end
            else if (!wallRightOfPacman & rightPressed)                  begin pacmanRowChange <= 2'b00; pacmanColumnChange <= 2'b01; end
            else if (!wallBelowPacman   & downPressed)                   begin pacmanRowChange <= 2'b01; pacmanColumnChange <= 2'b00; end
            else if (!wallLeftOfPacman  & leftPressed)                   begin pacmanRowChange <= 2'b00; pacmanColumnChange <= 2'b11; end
            else if (!wallAbovePacman   & (pacmanRowChange    == 2'b11)) begin pacmanRowChange <= 2'b11; pacmanColumnChange <= 2'b00; end
            else if (!wallRightOfPacman & (pacmanColumnChange == 2'b01)) begin pacmanRowChange <= 2'b00; pacmanColumnChange <= 2'b01; end
            else if (!wallBelowPacman   & (pacmanRowChange    == 2'b01)) begin pacmanRowChange <= 2'b01; pacmanColumnChange <= 2'b00; end
            else if (!wallLeftOfPacman  & (pacmanColumnChange == 2'b11)) begin pacmanRowChange <= 2'b00; pacmanColumnChange <= 2'b11; end
            else                                                         begin pacmanRowChange <= 2'b00; pacmanColumnChange <= 2'b00; end
        end 
         
        else if (pacmanCenterRow) begin // enable direction changes when traveling left or right between tile centers
            if      (leftPressed)  pacmanColumnChange <= 2'b11;
            else if (rightPressed) pacmanColumnChange <= 2'b01;
        end
	end

    movePacman_stg2 <= movePacman;
	if (resetPressed) begin pacmanColumn[7:0] <= 128; pacmanRow[7:0] <= 188; end
	else if(movePacman_stg2) begin
		// pacmanColumnChange: 2’b11 => moving left; 2’b00 => no horizontal movement; 2’b01 => moving right
        pacmanColumn[7:0] <= pacmanColumn[7:0] + {{6{pacmanColumnChange[1]}},pacmanColumnChange[1:0]};
        // pacmanRowChange: 2’b11 => moving up;  2’b00 >= no vertical movement; 2’b01 => moving down 
        pacmanRow[7:0]    <= pacmanRow[7:0]    + {{6{pacmanRowChange[1]   }},pacmanRowChange[1:0]   };
	end
    
	pacmanFace[0] <= pacmanColumn[2] ^ pacmanRow[2]; // alternate wide and narrow mouth when moving
	if      (pacmanRowChange    == 2'b01) pacmanFace[3:1] <= 3'b000; // down
	else if (pacmanColumnChange == 2'b11) pacmanFace[3:1] <= 3'b001; // left
	else if (pacmanColumnChange == 2'b01) pacmanFace[3:1] <= 3'b010; // right
	else if (pacmanRowChange    == 2'b11) pacmanFace[3:1] <= 3'b011; // up
	else                                  pacmanFace[3:0] <= 4'b1000; // closed mouth when not moving
end


////////////////////////////////////
// Blinky Sprite Movement

mod_m_counter #(.M(1687501)) blinkyCntr(.clk(clk108MHz), .max_tick(max_tick_Blinky), .q()); // Blinky moves a little slower than Pacman

always_ff @(posedge clk108MHz) begin	
	blinkyCanGoUp    <= !wallAboveBlinky   & (blinkyRowChange != 2'b01);
    blinkyCanGoRight <= !wallRightOfBlinky & (blinkyColumnChange != 2'b11);
    blinkyCanGoDown  <= !wallBelowBlinky   & (blinkyRowChange != 2'b11);
	blinkyCanGoLeft  <= !wallLeftOfBlinky  & (blinkyColumnChange != 2'b01);

    blinkyCenterColumn <= (blinkyColumn[2:0] == 3'b100);
    blinkyCenterRow    <= (blinkyRow[2:0]    == 3'b100);
    
    pacmanToBlinkyColumnDistance[8:3] <= pacmanColumn[7:3] - blinkyColumn[7:3];
    pacmanToBlinkyRowDistance[8:3]    <= pacmanRow[7:3]    - blinkyRow[7:3];
    pacmanToBlinkyRowMagnitudeGtColumnMagnitude <= (pacmanToBlinkyRowDistance[8]    ? -pacmanToBlinkyRowDistance[8:3]    : pacmanToBlinkyRowDistance[8:3]) >
                                                   (pacmanToBlinkyColumnDistance[8] ? -pacmanToBlinkyColumnDistance[8:3] : pacmanToBlinkyColumnDistance[8:3]);
    
    moveBlinky <= max_tick_Blinky; // synchronize, since max_tick_Blinky is driven by a lot of combinational logic
	if (resetPressed | pacmanColumn==blinkyColumn & pacmanRow==blinkyRow) begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b00; end
       // stop blinky if reset button is pushed, or if pacman and blinky are in the same location
    /*
        The 'else if' statement below was modified from:
        else if ((blinkyColumnChange == 2'b00) & (blinkyRowChange == 2'b00) & (leftPressed | rightPressed)) blinkyColumnChange <= 2'b01; 
        to
        else if ((blinkyColumnChange == 2'b00) & (blinkyRowChange == 2'b00) & (leftPressed | rightPressed)) blinkyColumnChange <= 2'b11; 
        where blinkyColumnChange is changed from 2'b01 to 2'b11 which changes the direction from right to left
    */
	else if ((blinkyColumnChange == 2'b00) & (blinkyRowChange == 2'b00) & (leftPressed | rightPressed)) blinkyColumnChange <= 2'b11; 
       // start blinky moving when pacman starts
    else if(moveBlinky & blinkyCenterColumn & blinkyCenterRow) begin // tile center
        case({pacmanToBlinkyRowDistance[8], pacmanToBlinkyColumnDistance[8], pacmanToBlinkyRowMagnitudeGtColumnMagnitude})
            3'b000: begin // pacman is more to the right of blinky than below
                if      (blinkyCanGoRight) begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
                else if (blinkyCanGoDown)  begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
                else if (blinkyCanGoUp)    begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
                else                       begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
            end
            
            3'b001: begin // pacman is more below blinky than to the right
                if      (blinkyCanGoDown)  begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
                else if (blinkyCanGoRight) begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
                else if (blinkyCanGoLeft)  begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
                else                       begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
            end
            
            3'b010: begin // pacman is more to the left of blinky than below
                if      (blinkyCanGoLeft)  begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
                else if (blinkyCanGoDown)  begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
                else if (blinkyCanGoUp)    begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
                else                       begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
            end
            
            3'b011: begin // pacman is more below blinky than to the left
                if      (blinkyCanGoDown)  begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
                else if (blinkyCanGoLeft)  begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
                else if (blinkyCanGoRight) begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
                else                       begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
            end
            
            3'b100: begin // pacman is more to the right of blinky than above
                if      (blinkyCanGoRight) begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
                else if (blinkyCanGoUp)    begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
                else if (blinkyCanGoDown)  begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
                else                       begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
            end
                
            3'b101: begin // pacman is more above blinky than to the right
                if      (blinkyCanGoUp)    begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
                else if (blinkyCanGoRight) begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
                else if (blinkyCanGoLeft)  begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
                else                       begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
            end
            
            3'b110: begin // pacman is more to the left of blinky than above
                if      (blinkyCanGoLeft)  begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
                else if (blinkyCanGoUp)    begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
                else if (blinkyCanGoDown)  begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
                else                       begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
            end
                
            3'b111: begin // pacman is more above blinky than to the left
                if      (blinkyCanGoUp)    begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b11; end // up
                else if (blinkyCanGoLeft)  begin blinkyColumnChange <= 2'b11; blinkyRowChange <= 2'b00; end // left
                else if (blinkyCanGoRight) begin blinkyColumnChange <= 2'b01; blinkyRowChange <= 2'b00; end // right
                else                       begin blinkyColumnChange <= 2'b00; blinkyRowChange <= 2'b01; end // down
            end
        endcase
    end

    moveBlinky_stg2 <= moveBlinky; // wait until the new change values are valid
    if (resetPressed) begin blinkyColumn[7:0] <= 128; blinkyRow[7:0] <= 92; blinkyFace[0] <= 2; end
	else if (moveBlinky_stg2) begin
        blinkyColumn[7:0] <= blinkyColumn[7:0] + {{6{blinkyColumnChange[1]}},blinkyColumnChange[1:0]}; // sign extend to 8 bits
        blinkyRow[7:0]    <= blinkyRow[7:0]    + {{6{blinkyRowChange[1]   }},blinkyRowChange[1:0]   }; // sign extend to 8 bits
    end
    
    blinkyFace[0] <= blinkyColumn[2] ^ blinkyRow[2]; // movement causes changing skirts
    if      (blinkyColumnChange == 2'b01) blinkyFace[2:1] <= 3'b00; // right
    else if (blinkyColumnChange == 2'b11) blinkyFace[2:1] <= 3'b01; // left
    else if (blinkyRowChange    == 2'b11) blinkyFace[2:1] <= 3'b10; // up
    else                                  blinkyFace[2:1] <= 3'b11; // down
end

////////////////////////////////////
// Constant assignments for features not yet implemented    
assign pinkyColumn = 128;
assign pinkyRow = 116;
assign pinkyFace = 6;
assign inkyColumn = 112;
assign inkyRow = 116;
assign inkyFace = 4;
assign clydeColumn = 144;
assign clydeRow = 116;
assign clydeFace = 4;

endmodule