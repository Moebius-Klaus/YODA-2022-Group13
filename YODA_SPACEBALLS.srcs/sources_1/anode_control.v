module anode_control(
input [2:0] refreshcounter,
output reg [7:0] AN=0
);

// Anodes are selected to turn on a particular number in the 
// 7 seg display. The value is controlled by the cathodes
always@(refreshcounter)
begin
    case(refreshcounter)
        3'b000:
            AN = 8'b11111110; //digit 1 on (right digit)
        3'b001:
            AN = 8'b11111101; //digit 2 on
        3'b010:
            AN = 8'b11111011; //digit 3 on
        3'b011:
            AN = 8'b11110111; //digit 4 on (left digit)
        3'b100:
            AN = 8'b11101111; //digit 1 on (right digit)
        3'b101:
            AN = 8'b11011111; //digit 2 on
        3'b110:
            AN = 8'b10111111; //digit 3 on
        3'b111:
            AN = 8'b01111111; //digit 4 on (left digit)
    endcase
end

endmodule