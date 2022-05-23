module refreshcounter(
input refresh_clock,
output reg [2:0] refreshcounter = 0
);

// Refresh counter is generated using the refresh clk
always@(posedge refresh_clock) refreshcounter <= refreshcounter+1;

endmodule