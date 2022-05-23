module BCD_to_cathodes(
input [3:0] digit,
output reg [7:0] CA = 0
);

// Sets the necessary cathodes to high
// to display the relevant number
// The anodes of the 7 seg display are set 
// in the anode control wrapper
always@(digit)
begin
    case(digit)
    4'd0:
        CA = 8'b11000000; //zero
    4'd1:
        CA = 8'b11111001; //one
    4'd2:
        CA = 8'b10100100; //two
    4'd3:
        CA = 8'b10110000; //three
    4'd4:
        CA = 8'b10011001; //four
    4'd5:
        CA = 8'b10010010; //five
    4'd6:
        CA = 8'b10000010; //six
    4'd7:
        CA = 8'b11111000; //seven
    4'd8:
        CA = 8'b10000000; //eight
    4'd9:
        CA = 8'b10010000; //nine
    default:
        CA = 8'b11000000; //zero
    endcase
end

endmodule