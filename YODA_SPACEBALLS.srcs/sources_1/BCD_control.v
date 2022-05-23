`timescale 1ns / 1ps
module BCD_control(
input [3:0] digit1,//ones
input [3:0] digit2,//tens
input [3:0] digit3,//hundreds
input [3:0] digit4,//thousands
input [3:0] digit5,//ones
input [3:0] digit6,//tens
input [3:0] digit7,//hundreds
input [3:0] digit8,//thousands
input [2:0] refreshcounter,
output reg [3:0] ONE_DIGIT = 0 //choose which input digit is to be displayed
    );

// Uses a case statement choose a particular digit to show.
// Makes use of a refresh counter to display only a single
// digit at a time since the 7 seg display has a common anode.
//   
always@(refreshcounter)
begin
    case(refreshcounter)
        4'd0:
            ONE_DIGIT = digit1; //digit 1 value (right digit)
        4'd1:
            ONE_DIGIT = digit2; //digit 2 value
        4'd2:
            ONE_DIGIT = digit3; //digit 3 value
        4'd3:
            ONE_DIGIT = digit4; //digit 4 value (left digit)
        4'd4:
            ONE_DIGIT = digit5; //digit 1 value (right digit)
        4'd5:
            ONE_DIGIT = digit6; //digit 2 value
        4'd6:
            ONE_DIGIT = digit7; //digit 3 value
        4'd7:
            ONE_DIGIT = digit8; //digit 4 value (left digit)
    endcase
end    

endmodule
