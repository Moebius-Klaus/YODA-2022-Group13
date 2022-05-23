`timescale 1ns / 1ps

module min_max_display(
input wire clk,
input [15:0] minDec, maxDec,
output [15:0] minDigits, maxDigits
);


// Divides the values for the 7 seg display
// into the appropriate bits of the 
assign maxDigits [3:0] = maxDec%10; //6387
assign maxDigits [7:4] = (maxDec-maxDec%10)%100/10; //638
assign maxDigits [11:8] = (maxDec-maxDec%100)%1000/100; //63
assign maxDigits [15:12] = (maxDec-maxDec%1000)%10000/1000; //6

assign minDigits [3:0] = minDec%10; //6387
assign minDigits [7:4] = (minDec-minDec%10)%100/10; //638
assign minDigits [11:8] = (minDec-minDec%100)%1000/100; //63
assign minDigits [15:12] = (minDec-minDec%1000)%10000/1000; //6

endmodule
