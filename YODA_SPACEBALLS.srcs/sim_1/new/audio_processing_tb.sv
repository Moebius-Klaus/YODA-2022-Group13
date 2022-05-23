`timescale 1ns / 1ps


module audio_processing_tb();

// Simulated external inputs and outputs.
// These would normally be connected to GPIO via
// the constraints file
reg clk, BTNUP, BTNCENTER, BTNDOWN, BTNLEFT, BTNRIGHT;
wire m_clk, m_lr_sel, RGB_Red, RGB_Green, RGB_Blue, AUD_PWM, AUD_SD;
wire [15:0] LED, SW;
wire [7:0] AN, CA, m_audio_data;

// Implementation of the pdm mic file
pdm_top dut(
.clk(clk),
.m_clk(m_clk),
.m_lr_sel(m_lr_sel),
.m_data(m_audio_data),
.RGB_Red(RGB_Red),
.RGB_Green(RGB_Green),
.RGB_Blue(RGB_Blue),
.BTNUP(BTNUP),
.BTNCENTER(BTNCENTER),
.BTNDOWN(BTNDOWN),
.BTNLEFT(BTNLEFT),
.BTNRIGHT(BTNRIGHT),
.LED(LED),
.AUD_PWM(AUD_PWM),
.AUD_SD(AUD_SD),
.SW(SW),
.AN(AN),
.CA(CA)
);

// Reads in 8bit PCM encoded audio data
audio_gen audiogen1(
    .clk (clk),
    .data_out(m_audio_data)
);

integer count;

// Clock and counter initialization
initial
begin
clk = 1'b1;
count = 0;
end

// Toggles the clock and the counter
always
begin
clk = ~clk;
#1;
count = count + 1;
end

// Button press simulation
always@ (posedge clk)
begin
if (count > 40000 && count <= 45000) begin
    BTNCENTER = '1;
end else if (count > 45000) begin
    BTNCENTER = '0;
end

end

endmodule
