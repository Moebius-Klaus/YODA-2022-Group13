`timescale 1ns / 1ps

module audio_gen(
    input clk,
    output reg [7:0] data_out
    );
    
parameter SIZE = 16384;    
reg [7:0] rom_memory [SIZE-1:0];
integer i;

initial
begin
$readmemh("starwarsaudio.mem", rom_memory);
i = 0;
end

// writes the data from the mem file onto the data_out wire
always@ (posedge clk) begin
data_out = rom_memory[i];
i = i + 1;
if(i == SIZE)
    i = 0;
end

endmodule
