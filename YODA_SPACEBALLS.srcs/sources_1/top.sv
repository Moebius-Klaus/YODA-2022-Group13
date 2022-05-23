`timescale 1ns/1ps

/////////////////////////////////////////////////////////////////////////////////////// 
////////////////                Top Module Definition          /////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 
module pdm_top #(
    parameter RAM_SIZE = 16384,
    parameter CLK_FREQ = 100
    )(
    // 100Mhz clock
    input wire          clk, 
    
    // Microphone interface
    output logic        m_clk,
    output logic        m_lr_sel,
    input  wire          m_data,
    
    // Tricolor LED
    output logic        RGB_Red,
    output logic        RGB_Green,
    output logic        RGB_Blue,
    
    // Pushbuttons
    input logic         BTNUP,
    input logic         BTNCENTER,
    input logic         BTNDOWN,
    input logic         BTNLEFT,
    input logic         BTNRIGHT,
    
    // Green LED Array
    output logic [15:0] LED,
    
    // Audio output
    output wire         AUD_PWM,
    output wire         AUD_SD,
    
    // Toggle Switches
    input wire [15:0] SW, 
    
    // 7 Segment Display
    output wire [7:0] AN,
    output wire [7:0] CA
    );
  
    
/////////////////////////////////////////////////////////////////////////////////////// 
////////////////        PERIPHERAL VARIABLES & SETUP       /////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////     

// 7 Segmet Display Control Variables
wire [15:0] maxDigits, minDigits;
wire        refresh_clock;
wire [2:0]  refreshcounter;
wire [3:0]  ONE_DIGIT;
reg [15:0]  maxDec;
reg [15:0]  minDec;

// PWM Audio Output Setup
assign AUD_SD = '1; // Enables the 3.5mm Audio Jack
assign m_lr_sel = '0; // Mic is triggered on rising edge clock

// Sync of push buttons
logic [2:0] button_usync;
logic [2:0] button_csync;
logic [2:0] button_dsync;
logic [2:0] button_lsync;
logic [2:0] button_rsync;


/////////////////////////////////////////////////////////////////////////////////////// 
////////////////              Audio Analysis Setup                /////////////////////
///////////////////////////////////////////////////////////////////////////////////////     

// Amplitude Configuration and Seeking Variables
logic [6:0] amplitude;
logic [6:0] amp_check;
logic [6:0] min_max_count;
logic [15:0] compressed_amplitude;
logic       amplitude_valid;
logic [6:0] max_amplitude;
logic [6:0] min_amplitude;
logic       start_capture;
logic       m_clk_en, m_clk_en_del;
logic [6:0] amp_capture;
logic       AUD_PWM_en;
logic [6:0] amp_counter;
logic [3:0] clr_addr;


/////////////////////////////////////////////////////////////////////////////////////// 
////////////////               SUB MODULE DEFINITIONS            /////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 
pdm_inputs u_pdm_inputs
    (
     .clk                 (clk),
     .m_clk               (m_clk),
     .m_clk_en            (m_clk_en),
     .m_data              (m_data),
     .amplitude           (amplitude),
     .amplitude_valid     (amplitude_valid)
     );
     
min_max_display minMaxDisplay(
    .clk(clk), 
    .minDec(minDec), 
    .maxDec(maxDec), 
    .minDigits(minDigits), 
    .maxDigits(maxDigits)
    );
    
clock_divider refreshclock_generator(
    .clk(clk),
    .divided_clk(refresh_clock)
    );    
    
refreshcounter Refreshcounter_wrapper(
    .refresh_clock(refresh_clock),
    .refreshcounter(refreshcounter)
    );
    
anode_control anode_control_wrapper(
    .refreshcounter(refreshcounter),
    .AN(AN)
    );
    
BCD_control BCD_control_wrapper(
    .digit1(maxDigits[3:0]),
    .digit2(maxDigits[7:4]),
    .digit3(maxDigits[11:8]),
    .digit4(maxDigits[15:12]),
    .digit5(minDigits[3:0]),
    .digit6(minDigits[7:4]),
    .digit7(minDigits[11:8]),
    .digit8(minDigits[15:12]),
    .refreshcounter(refreshcounter),
    .ONE_DIGIT(ONE_DIGIT)
    );
    
BCD_to_cathodes BCD_to_cathodes_wrapper(
    .digit(ONE_DIGIT),
    .CA(CA)
    );


// Input feedback through RGB LED
always @(posedge clk) begin
RGB_Blue  <= '0;
RGB_Red   <= ((amplitude >= 100)||(amplitude > 60 && amplitude < 100));
RGB_Green <= ((amplitude <= 60)||(amplitude > 60 && amplitude < 100));
end


/////////////////////////////////////////////////////////////////////////////////////// 
////////////////             INFERRED RAM SETUP                   /////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 

// Capture RAM
logic [6:0] amplitude_store[RAM_SIZE];
logic       start_playback;
logic [$clog2(RAM_SIZE)-1:0] ram_wraddr;
logic [$clog2(RAM_SIZE)-1:0] ram_rdaddr;
logic                        ram_we;
logic [6:0]                  ram_dout;
logic [15:0]                 clr_led;
assign clr_addr = ~ram_rdaddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-4];

// Processing RAM
//logic [6:0] compressor_out[RAM_SIZE];
//logic [$clog2(RAM_SIZE)-1:0] ram_wraddr1;
//logic [$clog2(RAM_SIZE)-1:0] ram_rdaddr1;
//logic                        ram_we1;
//logic [6:0]                  ram_dout1;



/////////////////////////////////////////////////////////////////////////////////////// 
////////////////                 INITIALIZATIONS                   /////////////////// 
///////////////////////////////////////////////////////////////////////////////////////    
initial begin
ram_rdaddr     = '0;
ram_wraddr     = '0;
ram_we         = '0; 
 
//ram_rdaddr1     = '0;
//ram_wraddr1     = '0;
//ram_we1         = '0;

start_capture  = '1;
start_playback = '0;
LED            = '0;
clr_led        = '0;
max_amplitude  = '0;
min_amplitude  = '0;
min_max_count = '0;
end

/////////////////////////////////////////////////////////////////////////////////////// 
////////////////             PDM MIC INPUT                     /////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 
    
// Capture the Audio data if using a PDM mic
always @(posedge clk) begin
    button_usync <= button_usync << 1 | BTNUP;
    ram_we       <= '0;
    
    // Toggles green LED strip
    for (int i = 0; i < 16; i++)
      if (clr_led[i]) LED[i] <= '0;
     
    if (button_usync[2:1] == 2'b01) begin
        start_capture <= '1;
        LED           <= '0;      
    end else if (start_capture && amplitude_valid) begin
        LED[ram_wraddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-4]] <= '1;
        ram_we                      <= '1;
        ram_wraddr                  <= ram_wraddr + 1'b1;
        if (&ram_wraddr) begin
        start_capture <= '0;
        LED[15]       <= '1;
        end
    end
end
    
always @(posedge clk) begin
    // Storage of amplitude in RAM
    if (ram_we) amplitude_store[ram_wraddr] <= amplitude;
    ram_dout <= amplitude_store[ram_rdaddr];
end

/////////////////////////////////////////////////////////////////////////////////////// 
////////////////       AUDIO FILE INPUT (TESTBENCH ONLY)       /////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////

//always @(posedge clk) begin
//    if (start_capture) begin
//      ram_we                      <= '1;
//      ram_wraddr                  <= ram_wraddr + 1'b1;
      
//          if (&ram_wraddr) begin
//            start_capture <= '0;
//          end
//      end
      
//    // Storage of amplitude in RAM
//    if (ram_we) amplitude_store[ram_wraddr] <= m_data;
//    ram_dout <= amplitude_store[ram_rdaddr];
//end
    
    
/////////////////////////////////////////////////////////////////////////////////////// 
////////////////             MIN MAX DISPLAY                       /////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////   

always @(posedge clk) begin
    button_lsync <= button_lsync << 1 | BTNLEFT;
    
    if (button_lsync[2:1] == 2'b01) begin
        minDec <= min_amplitude;
    end
end

always @(posedge clk) begin
    button_rsync <= button_rsync << 1 | BTNRIGHT;
    
    if (button_rsync[2:1] == 2'b01) begin
        maxDec <= max_amplitude;
    end
end

///////////////////////////////////////////////////////////////////////////////////////// 
////////////////////    Min Max Locate (TESTBENCH ONLY)     ////////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////// 

//integer k;

//always @(posedge clk) begin
//    button_csync <= button_csync << 1 | BTNCENTER;
    
//    if (button_csync[2:1] == 2'b01) begin    
//    if (min_max_count < RAM_SIZE) begin
        
//        for(integer k = 0; k < 32; k = k + 1) begin
//            amp_check <= amplitude_store[ram_rdaddr1 + k];
            
//            if (amp_check > max_amplitude) begin
//                max_amplitude <= amp_check;
//            end else if (amp_check < min_amplitude) begin
//                min_amplitude <= amp_check;
//            end                      
//        end
        
//        min_max_count <= min_max_count + 32;    
//    end
//    end
    
//end

/////////////////////////////////////////////////////////////////////////////////////// 
////////////////      Audio Compressor (TESTBENCH ONLY)          /////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 
 
//integer i;

//always @(posedge clk) begin
//    button_csync <= button_csync << 1 | BTNCENTER;
    
//    if (button_csync[2:1] == 2'b01 || ram_we1 == 1'b1) begin
//        ram_we1       <= '1;
        
//        for(integer i = 0; i < 32; i = i + 1) begin
//            compressed_amplitude <= amplitude_store[ram_rdaddr1 + i];
            
//            if (20*($clog2((compressed_amplitude - 64)/64)/$clog2(10)) < 20*($clog2((max_amplitude - 64)/64)/$clog2(10))) begin
//                compressed_amplitude <= (1/6)*(20*($clog2((compressed_amplitude - 64)/64)/$clog2(10)) - max_amplitude*0.3) + max_amplitude*0.3;
//                compressed_amplitude <= 10**(compressed_amplitude/20);
//            end 
                       
//            if (ram_we1) compressor_out[ram_rdaddr1 + i] <= compressed_amplitude;
//            ram_dout1 <= compressor_out[ram_rdaddr1 + i];
            
//        end
        
//        if (&ram_rdaddr1) begin
//            ram_rdaddr1 <= 0;
//            ram_we1       <= '0;    
//        end else begin
//            ram_rdaddr1 <= ram_rdaddr1 + i;  
//        end     
//    end
    
//end

/////////////////////////////////////////////////////////////////////////////////////// 
////////////////   TESTBENCH AUDIO OUTPUT (TESTBENCH ONLY)    /////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 

//always @(posedge clk) begin
//    // Synchronises the button press
//    button_dsync <= button_dsync << 1 | BTNDOWN;

    
//    // Once a button press is detected this will run
//    if (button_dsync[2:1] == 2'b01) begin
//        start_playback <= '1;
//        ram_rdaddr1     <= '0; 
//    end else if (start_playback) begin
//       ram_rdaddr1 <= ram_rdaddr1 + 1;            
//    end
        
//    end
    
//assign AUD_PWM = AUD_PWM_en ? compressor_out[ram_rdaddr1]: 'z;

/////////////////////////////////////////////////////////////////////////////////////// 
////////////////             PWM AUDIO OUTPUT                   /////////////////////// 
/////////////////////////////////////////////////////////////////////////////////////// 
 
// Playback the audio if using the NEXYS Board
always @(posedge clk) begin
    // Synchronises the button press
    button_dsync <= button_dsync << 1 | BTNDOWN;
    
    // Enables the delayed mic clock and clears the LEDs
    m_clk_en_del <= m_clk_en;
    clr_led      <= '0;
    
    // Once a button press is detected this will run
    if (button_dsync[2:1] == 2'b01) begin
        // Starts the playback and sets the initial read address of the RAM      
        start_playback <= '1;
        ram_rdaddr     <= '0;
    end else if (start_playback && m_clk_en_del) begin
        clr_led[clr_addr] <= '1;
        AUD_PWM_en <= '1;
         
        // Uses the amplitude valid from the pdm_inputs module to modulate the
        // signal using delta-sigma modulation
        if (amplitude_valid) begin
        ram_rdaddr <= ram_rdaddr + 1'b1;
        amp_counter <= 7'd1;
        amp_capture <= ram_dout;

        if (ram_dout != 0) AUD_PWM_en <= '0; // Activate pull up
        end else begin
        amp_counter <= amp_counter + 1'b1;
            if (amp_capture < amp_counter) AUD_PWM_en <= '0; // Activate pull up
        end
        
        // Stop Playback
        if (&ram_rdaddr) start_playback <= '0;
    end
end

// Assigns the PWM output a 0 if the enable is 1
// and a high impedance if the enable is 0
// this creates the PWM effect
assign AUD_PWM = AUD_PWM_en ? '0 : 'z;

endmodule