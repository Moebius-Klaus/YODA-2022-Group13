`timescale 1ns / 1ps
module clock_divider(
input wire clk,
output reg divided_clk=0
    );

// Clock divider parameter and counter
localparam div_value = 4999;
integer counter_value = 0;

// Using the system clk, a counter is incremented to divide the clock signal 
always@(posedge clk)
begin   
    if (counter_value == div_value)
        counter_value <= 0;
    else
        counter_value <= counter_value + 1;
end

// The divided clock is toggled when the counter reaches the specified param
always@(posedge clk)
begin
    if (counter_value == div_value)
        divided_clk <= ~divided_clk;
    else 
        divided_clk <= divided_clk;
end

endmodule
