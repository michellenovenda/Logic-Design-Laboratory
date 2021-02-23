

`define la  32'd220
`define lb  32'd247
`define lc  32'd131
`define ld  32'd147
`define le  32'd165
`define lf  32'd175
`define lg  32'd196
`define c   32'd262   // C3
`define d   32'd294
`define e   32'd330
`define f   32'd349
`define g   32'd392   // G3
`define a   32'd440
`define b   32'd494   // B3
`define ha  32'd880
`define hb  32'd988
`define hc  32'd524   // C4 524
`define hd  32'd588   // D4 588
`define he  32'd660   // E4 660
`define hf  32'd698   // F4 698
`define hg  32'd784   // G4
`define ab  32'd415
`define bb  32'd466
`define hfs 32'd740
`define hes 32'd698 //???
`define hds 32'd622
`define gs  32'd415
`define as  32'd466
`define hcs 32'd554
`define db  32'd277
`define cb  32'd247 //???
`define llg 32'd98
`define lab 32'd208
`define lbb 32'd233
`define hhc 32'd1048
`define heb 32'd622

`define sil   32'd50000000 // silence
`define silence   32'd50000000

module speaker(
    clk, // clock from crystal
    rst, // active high reset: BTNC
    _play, // SW: Play/Pause
    _mute, // SW: Mute
    _repeat, // SW: Repeat
    _rewind, // SW: Rewind
    _music, // SW: Music
    _volUP, // BTN: Vol up
    _volDOWN, // BTN: Vol down
    _higherOCT, //BTN: Oct higher
    _lowerOCT, //BTN: Oct lower
    _led, // LED: octave & volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck, // serial clock
    audio_sdin, // serial audio data input
    DISPLAY, // 7-seg
    DIGIT // 7-seg
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input _play, _mute, _repeat, _rewind, _music;
    input _volUP, _volDOWN, _higherOCT, _lowerOCT;
    output reg [15:0] _led;
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    output [6:0] DISPLAY;
    output [3:0] DIGIT;
    
    // Modify these
    //assign _led = 16'b1110_0000_0001_1111;
    //assign DIGIT = 4'b0000;
    //assign DISPLAY = 7'b0111111;

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;
    
    wire clkDiv22;
    wire [11:0] ibeatNum; // Beat counter

    clock_divider #(.n(22)) clock_22(
        .clk(clk),
        .clk_div(clkDiv22)
    );
    
    clock_divider #(.n(16)) clock_16(
        .clk(clk),
        .clk_div(clkDiv16)
    );
    
    wire clkDiv13;
    clock_divider #(.n(13)) clock_13(
        .clk(clk),
        .clk_div(clkDiv13)
    );
    
    reg[3:0] notes = 4'd0;
    reg[2:0] volume = 3'd3;
    reg[2:0] octave = 3'd2;
    
    wire _volUP_debounced, _volDOWN_debounced, _higherOCT_debounced, _lowerOCT_debounced;
    wire _volUP_one_pulse, _volDOWN_one_pulse, _higherOCT_one_pulse, _lowerOCT_one_pulse;

    //rst button
    debounce debounce_rst(.pb_debounced(rst_debounced), .pb(rst) , .clk(clkDiv16));
    onepulse onepulse_rst(.signal(rst_debounced), .clk(clkDiv16), .op(rst_one_pulse));
    
    //volume up button
    debounce debounce__volUP(.pb_debounced(_volUP_debounced), .pb(_volUP) , .clk(clkDiv16));
    onepulse onepulse__volUP(.signal(_volUP_debounced), .clk(clkDiv16), .op(_volUP_one_pulse));
    
    //volume down button
    debounce debounce__volDOWN(.pb_debounced(_volDOWN_debounced), .pb(_volDOWN) , .clk(clkDiv16));
    onepulse onepulse__volDOWN(.signal(_volDOWN_debounced), .clk(clkDiv16), .op(_volDOWN_one_pulse));
    
    //higher octave button
    debounce debounce__higherOCT(.pb_debounced(_higherOCT_debounced), .pb(_higherOCT) , .clk(clkDiv16));
    onepulse onepulse__higherOCT(.signal(_higherOCT_debounced), .clk(clkDiv16), .op(_higherOCT_one_pulse));
    
    //lower octave button
    debounce debounce__lowerOCT(.pb_debounced(_lowerOCT_debounced), .pb(_lowerOCT) , .clk(clkDiv16));
    onepulse onepulse__lowerOCT(.signal(_lowerOCT_debounced), .clk(clkDiv16), .op(_lowerOCT_one_pulse));
    
    always@(posedge clkDiv16 or posedge rst_one_pulse)
    begin
        if(rst_one_pulse)
        begin
            volume <= 3'd3;
            octave <= 3'd2;
        end
        
        else
        begin
            if(_volUP_one_pulse == 1'b1 && volume == 3'd5)
                volume <= volume;
            else if(_volUP_one_pulse == 1'b1 && volume < 3'd5)
                volume <= volume + 3'd1;
            else if(_volDOWN_one_pulse == 1'b1 && volume > 3'd1)
                volume <= volume - 3'd1;
            else if(_volDOWN_one_pulse == 1'b1 && volume == 3'd1)
                volume <= volume;
            else
                volume <= volume;
   
            if(_higherOCT_one_pulse == 1'b1 && octave == 3'd3)
                octave <= octave;
            else if(_higherOCT_one_pulse == 1'b1 && octave < 3'd3)
                octave <= octave + 3'd1;
            else if(_lowerOCT_one_pulse == 1'b1 && octave > 3'd1)
                octave <= octave - 3'd1;
            else if(_lowerOCT_one_pulse == 1'b1 && octave == 3'd1)
                octave <= octave;
            else
                octave <= octave;
        end
    end
    
    
    wire [31:0] freqL, freqR; // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR; // Processed Frequency, adapted to the clock rate of Basys3

    assign freq_outL = (octave == 3) ? (50000000 / (_mute ? `silence : freqL*2)) : ((octave == 1) ? (50000000 / (_mute ? `silence : freqL/2)) : (50000000 / (_mute ? `silence : freqL))); // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outR = (octave == 3) ? (50000000 / (_mute ? `silence : freqR*2)) : ((octave == 1) ? (50000000 / (_mute ? `silence : freqR/2)) : (50000000 / (_mute ? `silence : freqR)));
    
    wire[15:0] nums;
    reg [3:0] num1 = 4'd10;
    reg [3:0] num2 = 4'd10;
    reg [3:0] num3 = 4'd10;
    reg [3:0] num4 = 4'd10;
    
    always@(*)
    begin
        if(freqR == `la || freqR == `a || freqR == `ha || freqR == `ab || freqR == `as || freqR == `lab)
            num1 = 4'd7;
        else if(freqR == `lb || freqR == `b || freqR == `hb || freqR == `bb || freqR == `lbb)
            num1 = 4'd8;
        else if(freqR == `lc || freqR == `c || freqR == `hc || freqR == `hcs || freqR == `cb || freqR == `hhc)
            num1 = 4'd2;
        else if(freqR == `ld || freqR == `d || freqR == `hd || freqR == `hds || freqR == `db)
            num1 = 4'd3;
        else if(freqR == `le || freqR == `e || freqR == `he || freqR == `hes || freqR == `heb)
            num1 = 4'd4;
        else if(freqR == `lf || freqR == `f || freqR == `hf || freqR == `hfs)
            num1 = 4'd5;
        else if(freqR == `lg || freqR == `g || freqR == `hg || freqR == `gs || freqR == `llg)
            num1 = 4'd6;
        else if(`sil)
            num1 = 4'd10;
        else
            num1 = 4'd10;
    end
    
    assign nums = {4'd11, 4'd11, 4'd11, num1};
    SevenSegment(.display(DISPLAY), .digit(DIGIT), .nums(nums), .rst(rst_op), .clk(clk));
    
    always@(*)
    begin
        if(octave == 1)
            _led[15] = 1'b1;
        else
            _led[15] = 1'b0;
            
        if(octave == 2)
            _led[14] = 1'b1;
        else
            _led[14] = 1'b0;
            
        if(octave == 3)
            _led[13] = 1'b1;
        else
            _led[13] = 1'b0;
    end
    
    always@(*)
    begin
        if(_mute)
            _led[4:0] = 5'b00000;
            
        else
        begin
            if(volume == 1)
                _led[4:0] = 5'b00001;
            else if(volume == 2)
                _led[4:0] = 5'b00011;
            else if(volume == 3)
                _led[4:0] = 5'b00111;
            else if(volume == 4)
                _led[4:0] = 5'b01111;
            else if(volume == 5)
                _led[4:0] = 5'b11111;
            else
                _led[4:0] = 5'b00000;
        end
    end
    
    // Player Control
    player_control #(.LEN(512)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst_one_pulse),
        ._play(_play),
        ._repeat(_repeat),
        ._rewind(_rewind),
        ._music(_music),
        .ibeat(ibeatNum)
    );
    
    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(_play),
        ._music(_music),
        .toneL(freqL),
        .toneR(freqR)
    );

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), // clock from crystal
        .rst(rst_one_pulse), // active high reset
        .note_div_left(freq_outL),
        .note_div_right(freq_outR),
        .audio_left(audio_in_left), // left sound audio
        .audio_right(audio_in_right),
        .volume(volume) // 3 bits for 5 levels
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk),  // clock from the crystal
        .rst(rst_one_pulse),  // active high reset
        .audio_in_left(audio_in_left), // left channel audio data input
        .audio_in_right(audio_in_right), // right channel audio data input
        .audio_mclk(audio_mclk), // master clock
        .audio_lrck(audio_lrck), // left-right clock
        .audio_sck(audio_sck), // serial clock
        .audio_sdin(audio_sdin) // serial audio data input
    );

endmodule

module player_control (
 input clk,
 input reset,
 input _play,
 input _repeat,
 input _rewind,
 input _music,
 output reg [11:0] ibeat
);
    parameter LEN = 512;
    reg [11:0] next_ibeat;
    reg prev_music = 1'b0;
    
    always @(posedge clk, posedge reset)
    begin
        if (reset)
            ibeat <= 0;
            
        else
        begin
            if(_play)
            begin
                if(_music != prev_music)
                begin
                    if(_rewind)
                    begin
                        prev_music <= _music;
                        ibeat <= LEN+12;
                    end
                    
                    else
                    begin
                        prev_music <= _music;
                        ibeat <= 0;
                    end
                end
                
                else
                begin
                    if(_rewind)
                    begin
                        if((0 < ibeat) && (ibeat != LEN+12))
                            ibeat <= ibeat - 1;
                        else                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
                            ibeat <= LEN + 12;
                    end
                    
                    else
                    begin
                        if(_repeat) //play again if repeat
                        begin
                            if(ibeat == LEN+12)
                                ibeat <= 0;
                                
                            else
                            begin
                                if((0 <= ibeat) && (ibeat != LEN))
                                    ibeat <= ibeat + 1;
                                else
                                    ibeat <= 0;
                            end
                        end
                       
                        else //stop otherwise
                        begin
                            if(ibeat == LEN+12)
                                ibeat <= 0;
                            
                            else
                            begin
                                if((0 <= ibeat) && (ibeat != LEN))
                                    ibeat <= ibeat + 1;
                                else     
                                    ibeat <= LEN;
                            end
                        end
                    end
                end
            end
        
            else
                ibeat <= ibeat;
        end
    end

endmodule

module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right,
    volume
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [21:0] note_div_left, note_div_right; // div for note generation
    output reg[15:0] audio_left, audio_right;
    input [2:0] volume;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
        
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    always@(*)
    begin
        if(note_div_left == 22'd1)
            audio_left = 16'h0000;
        else
        begin
            if(volume == 1)
                audio_left = (b_clk == 1'b0) ? 16'hFF40 : 16'hC0; //192
            else if(volume == 2)
                audio_left = (b_clk == 1'b0) ? 16'hF388 : 16'hC78; //3192
            else if(volume == 3)
                audio_left = (b_clk == 1'b0) ? 16'hE7D0 : 16'h1830; //6192
            else if(volume == 4)
                audio_left = (b_clk == 1'b0) ? 16'hDC18 : 16'h23E8; //9192
            else if(volume == 5)
                audio_left = (b_clk == 1'b0) ? 16'hD060 : 16'h2FA0; //12192
            else
                audio_left = 16'h0000;
        end
    end
    
    always@(*)
    begin
        if(note_div_right == 22'd1)
            audio_right = 16'h0000;
        else
        begin
            if(volume == 1)
                audio_right = (c_clk == 1'b0) ? 16'hFF40 : 16'hC0;
            else if(volume == 2)
                audio_right = (c_clk == 1'b0) ? 16'hF388 : 16'hC78;
            else if(volume == 3)
                audio_right = (c_clk == 1'b0) ? 16'hE7D0 : 16'h1830;
            else if(volume == 4)
                audio_right = (c_clk == 1'b0) ? 16'hDC18 : 16'h23E8;
            else if(volume == 5)
                audio_right = (c_clk == 1'b0) ? 16'hD060 : 16'h2FA0;
            else
                audio_right = 16'h0000;
        end
    end
    //assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
    //                            (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
    //assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
    //                            (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
endmodule

module speaker_control(
    clk,  // clock from the crystal
    rst,  // active high reset
    audio_in_left, // left channel audio data input
    audio_in_right, // right channel audio data input
    audio_mclk, // master clock
    audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    audio_sck, // serial clock
    audio_sdin // serial audio data input
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input [15:0] audio_in_left; // left channel audio data input
    input [15:0] audio_in_right; // right channel audio data input
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    reg audio_sdin;

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule

module music_example (
	input [11:0] ibeatNum,
	input en,
	input _music,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);
    
    always @*
    begin
        if(_music == 1'b0) //ni hao bu hao
        begin
            if(en == 1)
            begin
                case(ibeatNum)
                    12'd0: toneR = `hd;     12'd1: toneR = `hd;
                    12'd2: toneR = `hd;     12'd3: toneR = `hd;
                    12'd4: toneR = `hd;     12'd5: toneR = `hd;
                    12'd6: toneR = `hd;     12'd7: toneR = `hd;
                    
                    12'd8: toneR = `he;     12'd9: toneR = `he;
                    12'd10: toneR = `he;     12'd11: toneR = `he;
                    12'd12: toneR = `he;     12'd13: toneR = `he;
                    12'd14: toneR = `he;     12'd15: toneR = `sil;
                    
                    12'd16: toneR = `he;     12'd17: toneR = `he;
                    12'd18: toneR = `he;     12'd19: toneR = `he;
                    12'd20: toneR = `he;     12'd21: toneR = `he;
                    12'd22: toneR = `he;     12'd23: toneR = `he;
                    
                    12'd24: toneR = `he;     12'd25: toneR = `he;
                    12'd26: toneR = `he;     12'd27: toneR = `he;
                    12'd28: toneR = `he;     12'd29: toneR = `he;
                    12'd30: toneR = `he;     12'd31: toneR = `he;
                    
                    12'd32: toneR = `hd;     12'd33: toneR = `hd;
                    12'd34: toneR = `hd;     12'd35: toneR = `hd;
                    12'd36: toneR = `hd;     12'd37: toneR = `hd;
                    12'd38: toneR = `hd;     12'd39: toneR = `hd;
                    
                    12'd40: toneR = `he;     12'd41: toneR = `he;
                    12'd42: toneR = `he;     12'd43: toneR = `he;
                    12'd44: toneR = `he;     12'd45: toneR = `he;
                    12'd46: toneR = `he;     12'd47: toneR = `sil;
                    
                    12'd48: toneR = `he;     12'd49: toneR = `he;
                    12'd50: toneR = `he;     12'd51: toneR = `he;
                    12'd52: toneR = `he;     12'd53: toneR = `he;
                    12'd54: toneR = `he;     12'd55: toneR = `he;
                    
                    12'd56: toneR = `he;     12'd57: toneR = `he;
                    12'd58: toneR = `he;     12'd59: toneR = `he;
                    12'd60: toneR = `he;     12'd61: toneR = `he;
                    12'd62: toneR = `he;     12'd63: toneR = `he;
                    
                    //-------------------------------------------
                    
                    12'd64: toneR = `hd;     12'd65: toneR = `hd;
                    12'd66: toneR = `hd;     12'd67: toneR = `hd;
                    12'd68: toneR = `hd;     12'd69: toneR = `hd;
                    12'd70: toneR = `hd;     12'd71: toneR = `hd;
                    
                    12'd72: toneR = `hg;     12'd73: toneR = `hg;
                    12'd74: toneR = `hg;     12'd75: toneR = `hg;
                    12'd76: toneR = `hg;     12'd77: toneR = `hg;
                    12'd78: toneR = `hg;     12'd79: toneR = `sil;
                    
                    12'd80: toneR = `hg;     12'd81: toneR = `hg;
                    12'd82: toneR = `hg;     12'd83: toneR = `hg;
                    12'd84: toneR = `hg;     12'd85: toneR = `hg;
                    12'd86: toneR = `hg;     12'd87: toneR = `hg;
                    
                    12'd88: toneR = `hg;     12'd89: toneR = `hg;
                    12'd90: toneR = `hg;     12'd91: toneR = `hg;
                    12'd92: toneR = `hg;     12'd93: toneR = `hg;
                    12'd94: toneR = `hg;     12'd95: toneR = `hg;
                    
                    12'd96: toneR = `g;     12'd97: toneR = `g;
                    12'd98: toneR = `g;     12'd99: toneR = `g;
                    12'd100: toneR = `g;     12'd101: toneR = `g;
                    12'd102: toneR = `g;     12'd103: toneR = `g;
                    
                    12'd104: toneR = `hg;     12'd105: toneR = `hg;
                    12'd106: toneR = `hg;     12'd107: toneR = `hg;
                    12'd108: toneR = `hg;     12'd109: toneR = `hg;
                    12'd110: toneR = `hg;     12'd111: toneR = `hg;
                    
                    12'd112: toneR = `hg;     12'd113: toneR = `hg;
                    12'd114: toneR = `hg;     12'd115: toneR = `hg;
                    12'd116: toneR = `hg;     12'd117: toneR = `hg;
                    12'd118: toneR = `hg;     12'd119: toneR = `hg;
                    
                    12'd120: toneR = `b;     12'd121: toneR = `b;
                    12'd122: toneR = `b;     12'd123: toneR = `b;
                    12'd124: toneR = `b;     12'd125: toneR = `b;
                    12'd126: toneR = `b;     12'd127: toneR = `sil;
                    
                    //-------------------------------------------
                    
                    12'd128: toneR = `b;     12'd129: toneR = `b;
                    12'd130: toneR = `b;     12'd131: toneR = `b;
                    12'd132: toneR = `b;     12'd133: toneR = `b;
                    12'd134: toneR = `b;     12'd135: toneR = `b;
                    
                    12'd136: toneR = `hc;     12'd137: toneR = `hc;
                    12'd138: toneR = `hc;     12'd139: toneR = `hc;
                    12'd140: toneR = `hc;     12'd141: toneR = `hc;
                    12'd142: toneR = `hc;     12'd143: toneR = `sil;
                    
                    12'd144: toneR = `hc;     12'd145: toneR = `hc;
                    12'd146: toneR = `hc;     12'd147: toneR = `hc;
                    12'd148: toneR = `hc;     12'd149: toneR = `hc;
                    12'd150: toneR = `hc;     12'd151: toneR = `hc;
                    
                    12'd152: toneR = `hc;     12'd153: toneR = `hc;
                    12'd154: toneR = `hc;     12'd155: toneR = `hc;
                    12'd156: toneR = `hc;     12'd157: toneR = `hc;
                    12'd158: toneR = `hc;     12'd159: toneR = `hc;
                    
                    12'd160: toneR = `b;     12'd161: toneR = `b;
                    12'd162: toneR = `b;     12'd163: toneR = `b;
                    12'd164: toneR = `b;     12'd165: toneR = `b;
                    12'd166: toneR = `b;     12'd167: toneR = `b;
                    
                    12'd168: toneR = `hc;     12'd169: toneR = `hc;
                    12'd170: toneR = `hc;     12'd171: toneR = `hc;
                    12'd172: toneR = `hc;     12'd173: toneR = `hc;
                    12'd174: toneR = `hc;     12'd175: toneR = `sil;
                    
                    12'd176: toneR = `hc;     12'd177: toneR = `hc;
                    12'd178: toneR = `hc;     12'd179: toneR = `hc;
                    12'd180: toneR = `hc;     12'd181: toneR = `hc;
                    12'd182: toneR = `hc;     12'd183: toneR = `hc;
                    
                    12'd184: toneR = `hc;     12'd185: toneR = `hc;
                    12'd186: toneR = `hc;     12'd187: toneR = `hc;
                    12'd188: toneR = `hc;     12'd189: toneR = `hc;
                    12'd190: toneR = `hc;     12'd191: toneR = `hc;
                    
                    //---------------------------------------------
                    
                    12'd192: toneR = `b;     12'd193: toneR = `b;
                    12'd194: toneR = `b;     12'd195: toneR = `b;
                    12'd196: toneR = `b;     12'd197: toneR = `b;
                    12'd198: toneR = `b;     12'd199: toneR = `b;
                    
                    12'd200: toneR = `hb;     12'd201: toneR = `hb;
                    12'd202: toneR = `hb;     12'd203: toneR = `hb;
                    12'd204: toneR = `hb;     12'd205: toneR = `hb;
                    12'd206: toneR = `hb;     12'd207: toneR = `hb;
                    
                    12'd208: toneR = `ha;     12'd209: toneR = `ha;
                    12'd210: toneR = `ha;     12'd211: toneR = `ha;
                    12'd212: toneR = `ha;     12'd213: toneR = `ha;
                    12'd214: toneR = `ha;     12'd215: toneR = `ha;
                    
                    12'd216: toneR = `hg;     12'd217: toneR = `hg;
                    12'd218: toneR = `hg;     12'd219: toneR = `hg;
                    12'd220: toneR = `hg;     12'd221: toneR = `hg;
                    12'd222: toneR = `hg;     12'd223: toneR = `hg;
                    
                    12'd224: toneR = `sil;     12'd225: toneR = `sil;
                    12'd226: toneR = `sil;     12'd227: toneR = `sil;
                    12'd228: toneR = `sil;     12'd229: toneR = `sil;
                    12'd230: toneR = `sil;     12'd231: toneR = `sil;
                    
                    12'd232: toneR = `he;     12'd233: toneR = `he;
                    12'd234: toneR = `he;     12'd235: toneR = `he;
                    12'd236: toneR = `he;     12'd237: toneR = `he;
                    12'd238: toneR = `he;     12'd239: toneR = `he;
                    
                    12'd240: toneR = `hf;     12'd241: toneR = `hf;
                    12'd242: toneR = `hf;     12'd243: toneR = `hf;
                    12'd244: toneR = `hf;     12'd245: toneR = `hf;
                    12'd246: toneR = `hf;     12'd247: toneR = `hf;
                    
                    12'd248: toneR = `hg;     12'd249: toneR = `hg;
                    12'd250: toneR = `hg;     12'd251: toneR = `hg;
                    12'd252: toneR = `hg;     12'd253: toneR = `hg;
                    12'd254: toneR = `hg;     12'd255: toneR = `hg;
                    
                    //---------------------------------------------
                    
                    12'd256: toneR = `ha;     12'd257: toneR = `ha;
                    12'd258: toneR = `ha;     12'd259: toneR = `ha;
                    12'd260: toneR = `ha;     12'd261: toneR = `ha;
                    12'd262: toneR = `ha;     12'd263: toneR = `ha;
                    
                    12'd264: toneR = `ha;     12'd265: toneR = `ha;
                    12'd266: toneR = `ha;     12'd267: toneR = `ha;
                    12'd268: toneR = `ha;     12'd269: toneR = `ha;
                    12'd270: toneR = `ha;     12'd271: toneR = `ha;
                    
                    12'd272: toneR = `ha;     12'd273: toneR = `ha;
                    12'd274: toneR = `ha;     12'd275: toneR = `ha;
                    12'd276: toneR = `ha;     12'd277: toneR = `ha;
                    12'd278: toneR = `ha;     12'd279: toneR = `ha;
                    
                    12'd280: toneR = `ha;     12'd281: toneR = `ha;
                    12'd282: toneR = `ha;     12'd283: toneR = `ha;
                    12'd284: toneR = `ha;     12'd285: toneR = `ha;
                    12'd286: toneR = `ha;     12'd287: toneR = `ha;
                    
                    12'd288: toneR = `hc;     12'd289: toneR = `hc;
                    12'd290: toneR = `hc;     12'd291: toneR = `hc;
                    12'd292: toneR = `hc;     12'd293: toneR = `hc;
                    12'd294: toneR = `hc;     12'd295: toneR = `hc;
                    
                    12'd296: toneR = `hd;     12'd297: toneR = `hd;
                    12'd298: toneR = `hd;     12'd299: toneR = `hd;
                    12'd300: toneR = `hd;     12'd301: toneR = `hd;
                    12'd302: toneR = `hd;     12'd303: toneR = `hd;
                    
                    12'd304: toneR = `he;     12'd305: toneR = `he;
                    12'd306: toneR = `he;     12'd307: toneR = `he;
                    12'd308: toneR = `he;     12'd309: toneR = `he;
                    12'd310: toneR = `he;     12'd311: toneR = `he;
                    
                    12'd312: toneR = `hg;     12'd313: toneR = `hg;
                    12'd314: toneR = `hg;     12'd315: toneR = `hg;
                    12'd316: toneR = `hg;     12'd317: toneR = `hg;
                    12'd318: toneR = `hg;     12'd319: toneR = `sil;
                    
                    //---------------------------------------------
                    
                    12'd320: toneR = `hg;     12'd321: toneR = `hg;
                    12'd322: toneR = `hg;     12'd323: toneR = `hg;
                    12'd324: toneR = `hg;     12'd325: toneR = `hg;
                    12'd326: toneR = `hg;     12'd327: toneR = `hg;
                    
                    12'd328: toneR = `hg;     12'd329: toneR = `hg;
                    12'd330: toneR = `hg;     12'd331: toneR = `hg;
                    12'd332: toneR = `hg;     12'd333: toneR = `hg;
                    12'd334: toneR = `hg;     12'd335: toneR = `hg;
                    
                    12'd336: toneR = `hg;     12'd337: toneR = `hg;
                    12'd338: toneR = `hg;     12'd339: toneR = `hg;
                    12'd340: toneR = `hg;     12'd341: toneR = `hg;
                    12'd342: toneR = `hg;     12'd343: toneR = `hg;
                    
                    12'd344: toneR = `hg;     12'd345: toneR = `hg;
                    12'd346: toneR = `hg;     12'd347: toneR = `hg;
                    12'd348: toneR = `hg;     12'd349: toneR = `hg;
                    12'd350: toneR = `hg;     12'd351: toneR = `hg;
                    
                    12'd352: toneR = `hc;     12'd353: toneR = `hc;
                    12'd354: toneR = `hc;     12'd355: toneR = `hc;
                    12'd356: toneR = `hc;     12'd357: toneR = `hc;
                    12'd358: toneR = `hc;     12'd359: toneR = `hc;
                    
                    12'd360: toneR = `hd;     12'd361: toneR = `hd;
                    12'd362: toneR = `hd;     12'd363: toneR = `hd;
                    12'd364: toneR = `hd;     12'd365: toneR = `hd;
                    12'd366: toneR = `hd;     12'd367: toneR = `hd;
                    
                    12'd368: toneR = `he;     12'd369: toneR = `he;
                    12'd370: toneR = `he;     12'd371: toneR = `he;
                    12'd372: toneR = `he;     12'd373: toneR = `he;
                    12'd374: toneR = `he;     12'd375: toneR = `he;
                    
                    12'd376: toneR = `he;     12'd377: toneR = `he;
                    12'd378: toneR = `he;     12'd379: toneR = `he;
                    12'd380: toneR = `he;     12'd381: toneR = `he;
                    12'd382: toneR = `he;     12'd383: toneR = `he;
                    
                    //-----------------------------------------------
                    
                    12'd384: toneR = `sil;     12'd385: toneR = `sil;
                    12'd386: toneR = `sil;     12'd387: toneR = `sil;
                    12'd388: toneR = `sil;     12'd389: toneR = `sil;
                    12'd390: toneR = `sil;     12'd391: toneR = `sil;
                    
                    12'd392: toneR = `hc;     12'd393: toneR = `hc;
                    12'd394: toneR = `hc;     12'd395: toneR = `hc;
                    12'd396: toneR = `hc;     12'd397: toneR = `hc;
                    12'd398: toneR = `hc;     12'd399: toneR = `hc;
                    
                    12'd400: toneR = `sil;     12'd401: toneR = `sil;
                    12'd402: toneR = `sil;     12'd403: toneR = `sil;
                    12'd404: toneR = `sil;     12'd405: toneR = `sil;
                    12'd406: toneR = `sil;     12'd407: toneR = `sil;
                    
                    12'd408: toneR = `hc;     12'd409: toneR = `hc;
                    12'd410: toneR = `hc;     12'd411: toneR = `hc;
                    12'd412: toneR = `hc;     12'd413: toneR = `hc;
                    12'd414: toneR = `hc;     12'd415: toneR = `hc;
                    
                    12'd416: toneR = `sil;     12'd417: toneR = `sil;
                    12'd418: toneR = `sil;     12'd419: toneR = `sil;
                    12'd420: toneR = `sil;     12'd421: toneR = `sil;
                    12'd422: toneR = `sil;     12'd423: toneR = `sil;
                    
                    12'd424: toneR = `a;     12'd425: toneR = `a;
                    12'd426: toneR = `a;     12'd427: toneR = `a;
                    12'd428: toneR = `a;     12'd429: toneR = `a;
                    12'd430: toneR = `a;     12'd431: toneR = `a;
                    
                    12'd432: toneR = `he;     12'd433: toneR = `he;
                    12'd434: toneR = `he;     12'd435: toneR = `he;
                    12'd436: toneR = `he;     12'd437: toneR = `he;
                    12'd438: toneR = `he;     12'd439: toneR = `he;
                    
                    12'd440: toneR = `hd;     12'd441: toneR = `hd;
                    12'd442: toneR = `hd;     12'd443: toneR = `hd;
                    12'd444: toneR = `hd;     12'd445: toneR = `hd;
                    12'd446: toneR = `hd;     12'd447: toneR = `hd;
                    
                    //-----------------------------------------------
                    
                    12'd448: toneR = `sil;     12'd449: toneR = `sil;
                    12'd450: toneR = `sil;     12'd451: toneR = `sil;
                    12'd452: toneR = `sil;     12'd453: toneR = `sil;
                    12'd454: toneR = `sil;     12'd455: toneR = `sil;
                    
                    12'd456: toneR = `sil;     12'd457: toneR = `sil;
                    12'd458: toneR = `sil;     12'd459: toneR = `sil;
                    12'd460: toneR = `sil;     12'd461: toneR = `sil;
                    12'd462: toneR = `sil;     12'd463: toneR = `sil;
                    
                    12'd464: toneR = `sil;     12'd465: toneR = `sil;
                    12'd466: toneR = `sil;     12'd467: toneR = `sil;
                    12'd468: toneR = `sil;     12'd469: toneR = `sil;
                    12'd470: toneR = `sil;     12'd471: toneR = `sil;
                    
                    12'd472: toneR = `g;     12'd473: toneR = `g;
                    12'd474: toneR = `g;     12'd475: toneR = `g;
                    12'd476: toneR = `g;     12'd477: toneR = `g;
                    12'd478: toneR = `g;     12'd479: toneR = `sil;
                    
                    12'd480: toneR = `g;     12'd481: toneR = `g;
                    12'd482: toneR = `g;     12'd483: toneR = `g;
                    12'd484: toneR = `g;     12'd485: toneR = `g;
                    12'd486: toneR = `g;     12'd487: toneR = `g;
                    
                    12'd488: toneR = `hg;     12'd489: toneR = `hg;
                    12'd490: toneR = `hg;     12'd491: toneR = `hg;
                    12'd492: toneR = `hg;     12'd493: toneR = `hg;
                    12'd494: toneR = `hg;     12'd495: toneR = `hg;
                    
                    12'd496: toneR = `hg;     12'd497: toneR = `hg;
                    12'd498: toneR = `hg;     12'd499: toneR = `hg;
                    12'd500: toneR = `hg;     12'd501: toneR = `hg;
                    12'd502: toneR = `hg;     12'd503: toneR = `hg;
                    
                    12'd504: toneR = `hd;     12'd505: toneR = `hd;
                    12'd506: toneR = `hd;     12'd507: toneR = `hd;
                    12'd508: toneR = `hd;     12'd509: toneR = `hd;
                    12'd510: toneR = `hd;     12'd511: toneR = `hd;
                                    
                    default: toneR = `sil;
                endcase
            end
        
            else begin
                toneR = `sil;
            end
        end
        
        else //mario
        begin
            if(en == 1)
            begin
                case(ibeatNum)
                    12'd0: toneR = `hc;     12'd1: toneR = `hc;
                    12'd2: toneR = `hc;     12'd3: toneR = `hc;
                    
                    12'd4: toneR = `hc;     12'd5: toneR = `hc;
                    12'd6: toneR = `hc;     12'd7: toneR = `hc;
                    
                    12'd8: toneR = `sil;     12'd9: toneR = `sil;
                    12'd10: toneR = `sil;     12'd11: toneR = `sil;
                    
                    12'd12: toneR = `g;     12'd13: toneR = `g;
                    12'd14: toneR = `g;     12'd15: toneR = `g;
                    
                    12'd16: toneR = `g;     12'd17: toneR = `g;
                    12'd18: toneR = `g;     12'd19: toneR = `g;
                    
                    12'd20: toneR = `sil;     12'd21: toneR = `sil;
                    12'd22: toneR = `sil;     12'd23: toneR = `sil;
                    
                    12'd24: toneR = `e;     12'd25: toneR = `e;
                    12'd26: toneR = `e;     12'd27: toneR = `e;
                    
                    12'd28: toneR = `e;     12'd29: toneR = `e;
                    12'd30: toneR = `e;     12'd31: toneR = `e;
                    
                    12'd32: toneR = `sil;     12'd33: toneR = `sil;
                    12'd34: toneR = `sil;     12'd35: toneR = `sil;
                    
                    12'd36: toneR = `a;     12'd37: toneR = `a;
                    12'd38: toneR = `a;     12'd39: toneR = `a;
                    
                    12'd40: toneR = `a;     12'd41: toneR = `a;
                    12'd42: toneR = `a;     12'd43: toneR = `a;
                    
                    12'd44: toneR = `b;     12'd45: toneR = `b;
                    12'd46: toneR = `b;     12'd47: toneR = `b;
                    
                    12'd48: toneR = `b;     12'd49: toneR = `b;
                    12'd50: toneR = `b;     12'd51: toneR = `b;
                    
                    12'd52: toneR = `bb;     12'd53: toneR = `bb;
                    12'd54: toneR = `bb;     12'd55: toneR = `bb;
                    
                    12'd56: toneR = `a;     12'd57: toneR = `a;
                    12'd58: toneR = `a;     12'd59: toneR = `a;
                    
                    12'd60: toneR = `sil;     12'd61: toneR = `sil;
                    12'd62: toneR = `sil;     12'd63: toneR = `sil;
                    
                    //----------------------------------------------
                    
                    12'd64: toneR = `g;     12'd65: toneR = `g;
                    12'd66: toneR = `g;     12'd67: toneR = `g;
                    
                    12'd68: toneR = `g;     12'd69: toneR = `g;
                    12'd70: toneR = `g;     12'd71: toneR = `g;
                    
                    12'd72: toneR = `he;     12'd73: toneR = `he;
                    12'd74: toneR = `he;     12'd75: toneR = `he;
                    
                    12'd76: toneR = `hg;     12'd77: toneR = `hg;
                    12'd78: toneR = `hg;     12'd79: toneR = `hg;
                    
                    12'd80: toneR = `ha;     12'd81: toneR = `ha;
                    12'd82: toneR = `ha;     12'd83: toneR = `ha;
                    
                    12'd84: toneR = `ha;     12'd85: toneR = `ha;
                    12'd86: toneR = `ha;     12'd87: toneR = `ha;
                    
                    12'd88: toneR = `hf;     12'd89: toneR = `hf;
                    12'd90: toneR = `hf;     12'd91: toneR = `hf;
                    
                    12'd92: toneR = `hg;     12'd93: toneR = `hg;
                    12'd94: toneR = `hg;     12'd95: toneR = `sil;
                    
                    12'd96: toneR = `hg;     12'd97: toneR = `hg;
                    12'd98: toneR = `hg;     12'd99: toneR = `hg;
                    
                    12'd100: toneR = `he;     12'd101: toneR = `he;
                    12'd102: toneR = `he;     12'd103: toneR = `he;
                    
                    12'd104: toneR = `he;     12'd105: toneR = `he;
                    12'd106: toneR = `he;     12'd107: toneR = `he;
                    
                    12'd108: toneR = `hc;     12'd109: toneR = `hc;
                    12'd110: toneR = `hc;     12'd111: toneR = `hc;
                    
                    12'd112: toneR = `hd;     12'd113: toneR = `hd;
                    12'd114: toneR = `hd;     12'd115: toneR = `hd;
                    
                    12'd116: toneR = `b;     12'd117: toneR = `b;
                    12'd118: toneR = `b;     12'd119: toneR = `b;
                    
                    12'd120: toneR = `sil;     12'd121: toneR = `sil;
                    12'd122: toneR = `sil;     12'd123: toneR = `sil;
                    
                    12'd124: toneR = `sil;     12'd125: toneR = `sil;
                    12'd126: toneR = `sil;     12'd127: toneR = `sil;
                    
                    //-----------------------------------------------
                    
                    12'd128: toneR = `hc;     12'd129: toneR = `hc;
                    12'd130: toneR = `hc;     12'd131: toneR = `hc;
                    
                    12'd132: toneR = `hc;     12'd133: toneR = `hc;
                    12'd134: toneR = `hc;     12'd135: toneR = `hc;
                    
                    12'd136: toneR = `sil;     12'd137: toneR = `sil;
                    12'd138: toneR = `sil;     12'd139: toneR = `sil;
                    
                    12'd140: toneR = `g;     12'd141: toneR = `g;
                    12'd142: toneR = `g;     12'd143: toneR = `g;
                    
                    12'd144: toneR = `g;     12'd145: toneR = `g;
                    12'd146: toneR = `g;     12'd147: toneR = `g;
                    
                    12'd148: toneR = `sil;     12'd149: toneR = `sil;
                    12'd150: toneR = `sil;     12'd151: toneR = `sil;
                    
                    12'd152: toneR = `e;     12'd153: toneR = `e;
                    12'd154: toneR = `e;     12'd155: toneR = `e;
                    
                    12'd156: toneR = `e;     12'd157: toneR = `e;
                    12'd158: toneR = `e;     12'd159: toneR = `e;
                    
                    12'd160: toneR = `sil;     12'd161: toneR = `sil;
                    12'd162: toneR = `sil;     12'd163: toneR = `sil;
                    
                    12'd164: toneR = `a;     12'd165: toneR = `a;
                    12'd166: toneR = `a;     12'd167: toneR = `a;
                    
                    12'd168: toneR = `a;     12'd169: toneR = `a;
                    12'd170: toneR = `a;     12'd171: toneR = `a;
                    
                    12'd172: toneR = `b;     12'd173: toneR = `b;
                    12'd174: toneR = `b;     12'd175: toneR = `b;
                    
                    12'd176: toneR = `b;     12'd177: toneR = `b;
                    12'd178: toneR = `b;     12'd179: toneR = `b;
                    
                    12'd180: toneR = `bb;     12'd181: toneR = `bb;
                    12'd182: toneR = `bb;     12'd183: toneR = `bb;
                    
                    12'd184: toneR = `a;     12'd185: toneR = `a;
                    12'd186: toneR = `a;     12'd187: toneR = `a;
                    
                    12'd188: toneR = `sil;     12'd189: toneR = `sil;
                    12'd190: toneR = `sil;     12'd191: toneR = `sil;
                    
                    //-----------------------------------------------
                    
                    12'd192: toneR = `g;     12'd193: toneR = `g;
                    12'd194: toneR = `g;     12'd195: toneR = `g;
                    
                    12'd196: toneR = `g;     12'd197: toneR = `g;
                    12'd198: toneR = `g;     12'd199: toneR = `g;
                    
                    12'd200: toneR = `he;     12'd201: toneR = `he;
                    12'd202: toneR = `he;     12'd203: toneR = `he;
                    
                    12'd204: toneR = `hg;     12'd205: toneR = `hg;
                    12'd206: toneR = `hg;     12'd207: toneR = `hg;
                    
                    12'd208: toneR = `ha;     12'd209: toneR = `ha;
                    12'd210: toneR = `ha;     12'd211: toneR = `ha;
                    
                    12'd212: toneR = `ha;     12'd213: toneR = `ha;
                    12'd214: toneR = `ha;     12'd215: toneR = `ha;
                    
                    12'd216: toneR = `hf;     12'd217: toneR = `hf;
                    12'd218: toneR = `hf;     12'd219: toneR = `hf;
                    
                    12'd220: toneR = `hg;     12'd221: toneR = `hg;
                    12'd222: toneR = `hg;     12'd223: toneR = `sil;
                    
                    12'd224: toneR = `hg;     12'd225: toneR = `hg;
                    12'd226: toneR = `hg;     12'd227: toneR = `hg;
                    
                    12'd228: toneR = `he;     12'd229: toneR = `he;
                    12'd230: toneR = `he;     12'd231: toneR = `he;
                    
                    12'd232: toneR = `he;     12'd233: toneR = `he;
                    12'd234: toneR = `he;     12'd235: toneR = `he;
                    
                    12'd236: toneR = `hc;     12'd237: toneR = `hc;
                    12'd238: toneR = `hc;     12'd239: toneR = `hc;
                    
                    12'd240: toneR = `hd;     12'd241: toneR = `hd;
                    12'd242: toneR = `hd;     12'd243: toneR = `hd;
                    
                    12'd244: toneR = `b;     12'd245: toneR = `b;
                    12'd246: toneR = `b;     12'd247: toneR = `b;
                    
                    12'd248: toneR = `sil;     12'd249: toneR = `sil;
                    12'd250: toneR = `sil;     12'd251: toneR = `sil;
                    
                    12'd252: toneR = `sil;     12'd253: toneR = `sil;
                    12'd254: toneR = `sil;     12'd255: toneR = `sil;
                    
                    //------------------------------------------------
                    
                    12'd256: toneR = `sil;     12'd257: toneR = `sil;
                    12'd258: toneR = `sil;     12'd259: toneR = `sil;
                    
                    12'd260: toneR = `sil;     12'd261: toneR = `sil;
                    12'd262: toneR = `sil;     12'd263: toneR = `sil;
                    
                    12'd264: toneR = `hg;     12'd265: toneR = `hg;
                    12'd266: toneR = `hg;     12'd267: toneR = `hg;
                    
                    12'd268: toneR = `hfs;     12'd269: toneR = `hfs;
                    12'd270: toneR = `hfs;     12'd271: toneR = `hfs;
                    
                    12'd272: toneR = `hf;     12'd273: toneR = `hf;
                    12'd274: toneR = `hf;     12'd275: toneR = `hf;
                    
                    12'd276: toneR = `hds;     12'd277: toneR = `hds;
                    12'd278: toneR = `hds;     12'd279: toneR = `hds;
                    
                    12'd280: toneR = `sil;     12'd281: toneR = `sil;
                    12'd282: toneR = `sil;     12'd283: toneR = `sil;
                    
                    12'd284: toneR = `hes;     12'd285: toneR = `hes;
                    12'd286: toneR = `hes;     12'd287: toneR = `hes;
                    
                    12'd288: toneR = `sil;     12'd289: toneR = `sil;
                    12'd290: toneR = `sil;     12'd291: toneR = `sil;
                    
                    12'd292: toneR = `gs;     12'd293: toneR = `gs;
                    12'd294: toneR = `gs;     12'd295: toneR = `gs;
                    
                    12'd296: toneR = `a;     12'd297: toneR = `a;
                    12'd298: toneR = `a;     12'd299: toneR = `a;
                    
                    12'd300: toneR = `hc;     12'd301: toneR = `hc;
                    12'd302: toneR = `hc;     12'd303: toneR = `hc;
                    
                    12'd304: toneR = `sil;     12'd305: toneR = `sil;
                    12'd306: toneR = `sil;     12'd307: toneR = `sil;
                    
                    12'd308: toneR = `a;     12'd309: toneR = `a;
                    12'd310: toneR = `a;     12'd311: toneR = `a;
                    
                    12'd312: toneR = `hc;     12'd313: toneR = `hc;
                    12'd314: toneR = `hc;     12'd315: toneR = `hc;
                    
                    12'd316: toneR = `hd;     12'd317: toneR = `hd;
                    12'd318: toneR = `hd;     12'd319: toneR = `hd;
                    
                    //-------------------------------------------------
                    
                    12'd320: toneR = `sil;     12'd321: toneR = `sil;
                    12'd322: toneR = `sil;     12'd323: toneR = `sil;
                    
                    12'd324: toneR = `sil;     12'd325: toneR = `sil;
                    12'd326: toneR = `sil;     12'd327: toneR = `sil;
                    
                    12'd328: toneR = `hg;     12'd329: toneR = `hg;
                    12'd330: toneR = `hg;     12'd331: toneR = `hg;
                    
                    12'd332: toneR = `hfs;     12'd333: toneR = `hfs;
                    12'd334: toneR = `hfs;     12'd335: toneR = `hfs;
                    
                    12'd336: toneR = `hf;     12'd337: toneR = `hf;
                    12'd338: toneR = `hf;     12'd339: toneR = `hf;
                    
                    12'd340: toneR = `hds;     12'd341: toneR = `hds;
                    12'd342: toneR = `hds;     12'd343: toneR = `hds;
                    
                    12'd344: toneR = `sil;     12'd345: toneR = `sil;
                    12'd346: toneR = `sil;     12'd347: toneR = `sil;
                    
                    12'd348: toneR = `he;     12'd349: toneR = `he;
                    12'd350: toneR = `he;     12'd351: toneR = `he;
                    
                    12'd352: toneR = `sil;     12'd353: toneR = `sil;
                    12'd354: toneR = `sil;     12'd355: toneR = `sil;
                    
                    12'd356: toneR = `hhc;     12'd357: toneR = `hhc;
                    12'd358: toneR = `hhc;     12'd359: toneR = `hhc;
                    
                    12'd360: toneR = `hhc;     12'd361: toneR = `hhc;
                    12'd362: toneR = `hhc;     12'd363: toneR = `hhc;
                    
                    12'd364: toneR = `hhc;     12'd365: toneR = `hhc;
                    12'd366: toneR = `hhc;     12'd367: toneR = `sil;
                    
                    12'd368: toneR = `hhc;     12'd369: toneR = `hhc;
                    12'd370: toneR = `hhc;     12'd371: toneR = `hhc;
                    
                    12'd372: toneR = `hhc;     12'd373: toneR = `hhc;
                    12'd374: toneR = `hhc;     12'd375: toneR = `hhc;
                    
                    12'd376: toneR = `sil;     12'd377: toneR = `sil;
                    12'd378: toneR = `sil;     12'd379: toneR = `sil;
                    
                    12'd380: toneR = `sil;     12'd381: toneR = `sil;
                    12'd382: toneR = `sil;     12'd383: toneR = `sil;
                    
                    //------------------------------------------------
                    
                    12'd384: toneR = `sil;     12'd385: toneR = `sil;
                    12'd386: toneR = `sil;     12'd387: toneR = `sil;
                    
                    12'd388: toneR = `sil;     12'd389: toneR = `sil;
                    12'd390: toneR = `sil;     12'd391: toneR = `sil;
                    
                    12'd392: toneR = `hg;     12'd393: toneR = `hg;
                    12'd394: toneR = `hg;     12'd395: toneR = `hg;
                    
                    12'd396: toneR = `hfs;     12'd397: toneR = `hfs;
                    12'd398: toneR = `hfs;     12'd399: toneR = `hfs;
                    
                    12'd400: toneR = `hf;     12'd401: toneR = `hf;
                    12'd402: toneR = `hf;     12'd403: toneR = `hf;
                    
                    12'd404: toneR = `hds;     12'd405: toneR = `hds;
                    12'd406: toneR = `hds;     12'd407: toneR = `hds;
                    
                    12'd408: toneR = `sil;     12'd409: toneR = `sil;
                    12'd410: toneR = `sil;     12'd411: toneR = `sil;
                    
                    12'd412: toneR = `hes;     12'd413: toneR = `hes;
                    12'd414: toneR = `hes;     12'd415: toneR = `hes;
                    
                    12'd416: toneR = `sil;     12'd417: toneR = `sil;
                    12'd418: toneR = `sil;     12'd419: toneR = `sil;
                    
                    12'd420: toneR = `gs;     12'd421: toneR = `gs;
                    12'd422: toneR = `gs;     12'd423: toneR = `gs;
                    
                    12'd424: toneR = `a;     12'd425: toneR = `a;
                    12'd426: toneR = `a;     12'd427: toneR = `a;
                    
                    12'd428: toneR = `hc;     12'd429: toneR = `hc;
                    12'd430: toneR = `hc;     12'd431: toneR = `hc;
                    
                    12'd432: toneR = `sil;     12'd433: toneR = `sil;
                    12'd434: toneR = `sil;     12'd435: toneR = `sil;
                    
                    12'd436: toneR = `a;     12'd437: toneR = `a;
                    12'd438: toneR = `a;     12'd439: toneR = `a;
                    
                    12'd440: toneR = `hc;     12'd441: toneR = `hc;
                    12'd442: toneR = `hc;     12'd443: toneR = `hc;
                    
                    12'd444: toneR = `hd;     12'd445: toneR = `hd;
                    12'd446: toneR = `hd;     12'd447: toneR = `hd;
                    
                    //-----------------------------------------------
                    
                    12'd448: toneR = `sil;     12'd449: toneR = `sil;
                    12'd450: toneR = `sil;     12'd451: toneR = `sil;
                    
                    12'd452: toneR = `sil;     12'd453: toneR = `sil;
                    12'd454: toneR = `sil;     12'd455: toneR = `sil;
                    
                    12'd456: toneR = `heb;     12'd457: toneR = `heb;
                    12'd458: toneR = `heb;     12'd459: toneR = `heb;
                    
                    12'd460: toneR = `heb;     12'd461: toneR = `heb;
                    12'd462: toneR = `heb;     12'd463: toneR = `heb;
                    
                    12'd464: toneR = `sil;     12'd465: toneR = `sil;
                    12'd466: toneR = `sil;     12'd467: toneR = `sil;
                    
                    12'd468: toneR = `hd;     12'd469: toneR = `hd;
                    12'd470: toneR = `hd;     12'd471: toneR = `hd;
                    
                    12'd472: toneR = `sil;     12'd473: toneR = `sil;
                    12'd474: toneR = `sil;     12'd475: toneR = `sil;
                    
                    12'd476: toneR = `sil;     12'd477: toneR = `sil;
                    12'd478: toneR = `sil;     12'd479: toneR = `sil;
                    
                    12'd480: toneR = `hc;     12'd481: toneR = `hc;
                    12'd482: toneR = `hc;     12'd483: toneR = `hc;
                    
                    12'd484: toneR = `hc;     12'd485: toneR = `hc;
                    12'd486: toneR = `hc;     12'd487: toneR = `hc;
                    
                    12'd488: toneR = `hc;     12'd489: toneR = `hc;
                    12'd490: toneR = `hc;     12'd491: toneR = `hc;
                    
                    12'd492: toneR = `hc;     12'd493: toneR = `hc;
                    12'd494: toneR = `hc;     12'd495: toneR = `hc;
                    
                    12'd496: toneR = `sil;     12'd497: toneR = `sil;
                    12'd498: toneR = `sil;     12'd499: toneR = `sil;
                    
                    12'd500: toneR = `sil;     12'd501: toneR = `sil;
                    12'd502: toneR = `sil;     12'd503: toneR = `sil;
                    
                    12'd504: toneR = `sil;     12'd505: toneR = `sil;
                    12'd506: toneR = `sil;     12'd507: toneR = `sil;
                    
                    12'd508: toneR = `sil;     12'd509: toneR = `sil;
                    12'd510: toneR = `sil;     12'd511: toneR = `sil;
                                                        
                    default: toneR = `sil;
                endcase
            end
        
            else begin
                toneR = `sil;
            end
        end
    end

    always @(*)
    begin
        if(_music == 1'b0) //ni hao bu hao
        begin
            if(en == 1)
            begin
                case(ibeatNum)
                    12'd0: toneL = `c;     12'd1: toneL = `c;
                    12'd2: toneL = `c;     12'd3: toneL = `c;
                    12'd4: toneL = `c;     12'd5: toneL = `c;
                    12'd6: toneL = `c;     12'd7: toneL = `c;
                    
                    12'd8: toneL = `c;     12'd9: toneL = `c;
                    12'd10: toneL = `c;     12'd11: toneL = `c;
                    12'd12: toneL = `c;     12'd13: toneL = `c;
                    12'd14: toneL = `c;     12'd15: toneL = `c;
                    
                    12'd16: toneL = `e;     12'd17: toneL = `e;
                    12'd18: toneL = `e;     12'd19: toneL = `e;
                    12'd20: toneL = `e;     12'd21: toneL = `e;
                    12'd22: toneL = `e;     12'd23: toneL = `e;
                    
                    12'd24: toneL = `e;     12'd25: toneL = `e;
                    12'd26: toneL = `e;     12'd27: toneL = `e;
                    12'd28: toneL = `e;     12'd29: toneL = `e;
                    12'd30: toneL = `e;     12'd31: toneL = `e;
                    
                    12'd32: toneL = `g;     12'd33: toneL = `g;
                    12'd34: toneL = `g;     12'd35: toneL = `g;
                    12'd36: toneL = `g;     12'd37: toneL = `g;
                    12'd38: toneL = `g;     12'd39: toneL = `g;
                    
                    12'd40: toneL = `g;     12'd41: toneL = `g;
                    12'd42: toneL = `g;     12'd43: toneL = `g;
                    12'd44: toneL = `g;     12'd45: toneL = `g;
                    12'd46: toneL = `g;     12'd47: toneL = `g;
                    
                    12'd48: toneL = `g;     12'd49: toneL = `g;
                    12'd50: toneL = `g;     12'd51: toneL = `g;
                    12'd52: toneL = `g;     12'd53: toneL = `g;
                    12'd54: toneL = `g;     12'd55: toneL = `g;
                    
                    12'd56: toneL = `g;     12'd57: toneL = `g;
                    12'd58: toneL = `g;     12'd59: toneL = `g;
                    12'd60: toneL = `g;     12'd61: toneL = `g;
                    12'd62: toneL = `g;     12'd63: toneL = `g;
                    
                    12'd64: toneL = `lb;     12'd65: toneL = `lb;
                    12'd66: toneL = `lb;     12'd67: toneL = `lb;
                    12'd68: toneL = `lb;     12'd69: toneL = `lb;
                    12'd70: toneL = `lb;     12'd71: toneL = `lb;
                    
                    12'd72: toneL = `lb;     12'd73: toneL = `lb;
                    12'd74: toneL = `lb;     12'd75: toneL = `lb;
                    12'd76: toneL = `lb;     12'd77: toneL = `lb;
                    12'd78: toneL = `lb;     12'd79: toneL = `lb;
                    
                    12'd80: toneL = `d;     12'd81: toneL = `d;
                    12'd82: toneL = `d;     12'd83: toneL = `d;
                    12'd84: toneL = `d;     12'd85: toneL = `d;
                    12'd86: toneL = `d;     12'd87: toneL = `d;
                    
                    12'd88: toneL = `d;     12'd89: toneL = `d;
                    12'd90: toneL = `d;     12'd91: toneL = `d;
                    12'd92: toneL = `d;     12'd93: toneL = `d;
                    12'd94: toneL = `d;     12'd95: toneL = `d;
                    
                    12'd96: toneL = `g;     12'd97: toneL = `g;
                    12'd98: toneL = `g;     12'd99: toneL = `g;
                    12'd100: toneL = `g;     12'd101: toneL = `g;
                    12'd102: toneL = `g;     12'd103: toneL = `g;
                    
                    12'd104: toneL = `g;     12'd105: toneL = `g;
                    12'd106: toneL = `g;     12'd107: toneL = `g;
                    12'd108: toneL = `g;     12'd109: toneL = `g;
                    12'd110: toneL = `g;     12'd111: toneL = `g;
                    
                    12'd112: toneL = `g;     12'd113: toneL = `g;
                    12'd114: toneL = `g;     12'd115: toneL = `g;
                    12'd116: toneL = `g;     12'd117: toneL = `g;
                    12'd118: toneL = `g;     12'd119: toneL = `g;
                    
                    12'd120: toneL = `g;     12'd121: toneL = `g;
                    12'd122: toneL = `g;     12'd123: toneL = `g;
                    12'd124: toneL = `g;     12'd125: toneL = `g;
                    12'd126: toneL = `g;     12'd127: toneL = `g;
                    
                    12'd128: toneL = `la;     12'd129: toneL = `la;
                    12'd130: toneL = `la;     12'd131: toneL = `la;
                    12'd132: toneL = `la;     12'd133: toneL = `la;
                    12'd134: toneL = `la;     12'd135: toneL = `la;
                    
                    12'd136: toneL = `la;     12'd137: toneL = `la;
                    12'd138: toneL = `la;     12'd139: toneL = `la;
                    12'd140: toneL = `la;     12'd141: toneL = `la;
                    12'd142: toneL = `la;     12'd143: toneL = `la;
                    
                    12'd144: toneL = `c;     12'd145: toneL = `c;
                    12'd146: toneL = `c;     12'd147: toneL = `c;
                    12'd148: toneL = `c;     12'd149: toneL = `c;
                    12'd150: toneL = `c;     12'd151: toneL = `c;
                    
                    12'd152: toneL = `c;     12'd153: toneL = `c;
                    12'd154: toneL = `c;     12'd155: toneL = `c;
                    12'd156: toneL = `c;     12'd157: toneL = `c;
                    12'd158: toneL = `c;     12'd159: toneL = `c;
                    
                    12'd160: toneL = `g;     12'd161: toneL = `g;
                    12'd162: toneL = `g;     12'd163: toneL = `g;
                    12'd164: toneL = `g;     12'd165: toneL = `g;
                    12'd166: toneL = `g;     12'd167: toneL = `g;
                    
                    12'd168: toneL = `g;     12'd169: toneL = `g;
                    12'd170: toneL = `g;     12'd171: toneL = `g;
                    12'd172: toneL = `g;     12'd173: toneL = `g;
                    12'd174: toneL = `g;     12'd175: toneL = `g;
                    
                    12'd176: toneL = `e;     12'd177: toneL = `e;
                    12'd178: toneL = `e;     12'd179: toneL = `e;
                    12'd180: toneL = `e;     12'd181: toneL = `e;
                    12'd182: toneL = `e;     12'd183: toneL = `e;
                    
                    12'd184: toneL = `e;     12'd185: toneL = `e;
                    12'd186: toneL = `e;     12'd187: toneL = `e;
                    12'd188: toneL = `e;     12'd189: toneL = `e;
                    12'd190: toneL = `e;     12'd191: toneL = `e;
                    
                    12'd192: toneL = `g;     12'd193: toneL = `g;
                    12'd194: toneL = `g;     12'd195: toneL = `g;
                    12'd196: toneL = `g;     12'd197: toneL = `g;
                    12'd198: toneL = `g;     12'd199: toneL = `g;
                    
                    12'd200: toneL = `g;     12'd201: toneL = `g;
                    12'd202: toneL = `g;     12'd203: toneL = `g;
                    12'd204: toneL = `g;     12'd205: toneL = `g;
                    12'd206: toneL = `g;     12'd207: toneL = `g;
                    
                    12'd208: toneL = `d;     12'd209: toneL = `d;
                    12'd210: toneL = `d;     12'd211: toneL = `d;
                    12'd212: toneL = `d;     12'd213: toneL = `d;
                    12'd214: toneL = `d;     12'd215: toneL = `d;
                    
                    12'd216: toneL = `d;     12'd217: toneL = `d;
                    12'd218: toneL = `d;     12'd219: toneL = `d;
                    12'd220: toneL = `d;     12'd221: toneL = `d;
                    12'd222: toneL = `d;     12'd223: toneL = `d;
                    
                    12'd224: toneL = `lb;     12'd225: toneL = `lb;
                    12'd226: toneL = `lb;     12'd227: toneL = `lb;
                    12'd228: toneL = `lb;     12'd229: toneL = `lb;
                    12'd230: toneL = `lb;     12'd231: toneL = `lb;
                    
                    12'd232: toneL = `lb;     12'd233: toneL = `lb;
                    12'd234: toneL = `lb;     12'd235: toneL = `lb;
                    12'd236: toneL = `lb;     12'd237: toneL = `lb;
                    12'd238: toneL = `lb;     12'd239: toneL = `lb;
                    
                    12'd240: toneL = `lb;     12'd241: toneL = `lb;
                    12'd242: toneL = `lb;     12'd243: toneL = `lb;
                    12'd244: toneL = `lb;     12'd245: toneL = `lb;
                    12'd246: toneL = `lb;     12'd247: toneL = `lb;
                    
                    12'd248: toneL = `lb;     12'd249: toneL = `lb;
                    12'd250: toneL = `lb;     12'd251: toneL = `lb;
                    12'd252: toneL = `lb;     12'd253: toneL = `lb;
                    12'd254: toneL = `lb;     12'd255: toneL = `lb;
                    
                    12'd256: toneL = `f;     12'd257: toneL = `f;
                    12'd258: toneL = `f;     12'd259: toneL = `f;
                    12'd260: toneL = `f;     12'd261: toneL = `f;
                    12'd262: toneL = `f;     12'd263: toneL = `f;
                    
                    12'd264: toneL = `f;     12'd265: toneL = `f;
                    12'd266: toneL = `f;     12'd267: toneL = `f;
                    12'd268: toneL = `f;     12'd269: toneL = `f;
                    12'd270: toneL = `f;     12'd271: toneL = `f;
                    
                    12'd272: toneL = `a;     12'd273: toneL = `a;
                    12'd274: toneL = `a;     12'd275: toneL = `a;
                    12'd276: toneL = `a;     12'd277: toneL = `a;
                    12'd278: toneL = `a;     12'd279: toneL = `a;
                    
                    12'd280: toneL = `a;     12'd281: toneL = `a;
                    12'd282: toneL = `a;     12'd283: toneL = `a;
                    12'd284: toneL = `a;     12'd285: toneL = `a;
                    12'd286: toneL = `a;     12'd287: toneL = `a;
                    
                    12'd288: toneL = `hc;     12'd289: toneL = `hc;
                    12'd290: toneL = `hc;     12'd291: toneL = `hc;
                    12'd292: toneL = `hc;     12'd293: toneL = `hc;
                    12'd294: toneL = `hc;     12'd295: toneL = `hc;
                    
                    12'd296: toneL = `hc;     12'd297: toneL = `hc;
                    12'd298: toneL = `hc;     12'd299: toneL = `hc;
                    12'd300: toneL = `hc;     12'd301: toneL = `hc;
                    12'd302: toneL = `hc;     12'd303: toneL = `hc;
                    
                    12'd304: toneL = `hc;     12'd305: toneL = `hc;
                    12'd306: toneL = `hc;     12'd307: toneL = `hc;
                    12'd308: toneL = `hc;     12'd309: toneL = `hc;
                    12'd310: toneL = `hc;     12'd311: toneL = `hc;
                    
                    12'd312: toneL = `hc;     12'd313: toneL = `hc;
                    12'd314: toneL = `hc;     12'd315: toneL = `hc;
                    12'd316: toneL = `hc;     12'd317: toneL = `hc;
                    12'd318: toneL = `hc;     12'd319: toneL = `hc;
                    
                    12'd320: toneL = `e;     12'd321: toneL = `e;
                    12'd322: toneL = `e;     12'd323: toneL = `e;
                    12'd324: toneL = `e;     12'd325: toneL = `e;
                    12'd326: toneL = `e;     12'd327: toneL = `e;
                    
                    12'd328: toneL = `e;     12'd329: toneL = `e;
                    12'd330: toneL = `e;     12'd331: toneL = `e;
                    12'd332: toneL = `e;     12'd333: toneL = `e;
                    12'd334: toneL = `e;     12'd335: toneL = `e;
                    
                    12'd336: toneL = `g;     12'd337: toneL = `g;
                    12'd338: toneL = `g;     12'd339: toneL = `g;
                    12'd340: toneL = `g;     12'd341: toneL = `g;
                    12'd342: toneL = `g;     12'd343: toneL = `g;
                    
                    12'd344: toneL = `g;     12'd345: toneL = `g;
                    12'd346: toneL = `g;     12'd347: toneL = `g;
                    12'd348: toneL = `g;     12'd349: toneL = `g;
                    12'd350: toneL = `g;     12'd351: toneL = `g;
                    
                    12'd352: toneL = `c;     12'd353: toneL = `c;
                    12'd354: toneL = `c;     12'd355: toneL = `c;
                    12'd356: toneL = `c;     12'd357: toneL = `c;
                    12'd358: toneL = `c;     12'd359: toneL = `c;
                    
                    12'd360: toneL = `c;     12'd361: toneL = `c;
                    12'd362: toneL = `c;     12'd363: toneL = `c;
                    12'd364: toneL = `c;     12'd365: toneL = `c;
                    12'd366: toneL = `c;     12'd367: toneL = `c;
                    
                    12'd368: toneL = `c;     12'd369: toneL = `c;
                    12'd370: toneL = `c;     12'd371: toneL = `c;
                    12'd372: toneL = `c;     12'd373: toneL = `c;
                    12'd374: toneL = `c;     12'd375: toneL = `c;
                    
                    12'd376: toneL = `c;     12'd377: toneL = `c;
                    12'd378: toneL = `c;     12'd379: toneL = `c;
                    12'd380: toneL = `c;     12'd381: toneL = `c;
                    12'd382: toneL = `c;     12'd383: toneL = `c;
                    
                    12'd384: toneL = `d;     12'd385: toneL = `d;
                    12'd386: toneL = `d;     12'd387: toneL = `d;
                    12'd388: toneL = `d;     12'd389: toneL = `d;
                    12'd390: toneL = `d;     12'd391: toneL = `d;
                    
                    12'd392: toneL = `d;     12'd393: toneL = `d;
                    12'd394: toneL = `d;     12'd395: toneL = `d;
                    12'd396: toneL = `d;     12'd397: toneL = `d;
                    12'd398: toneL = `d;     12'd399: toneL = `d;
                    
                    12'd400: toneL = `a;     12'd401: toneL = `a;
                    12'd402: toneL = `a;     12'd403: toneL = `a;
                    12'd404: toneL = `a;     12'd405: toneL = `a;
                    12'd406: toneL = `a;     12'd407: toneL = `a;
                    
                    12'd408: toneL = `a;     12'd409: toneL = `a;
                    12'd410: toneL = `a;     12'd411: toneL = `a;
                    12'd412: toneL = `a;     12'd413: toneL = `a;
                    12'd414: toneL = `a;     12'd415: toneL = `a;
                    
                    12'd416: toneL = `d;     12'd417: toneL = `d;
                    12'd418: toneL = `d;     12'd419: toneL = `d;
                    12'd420: toneL = `d;     12'd421: toneL = `d;
                    12'd422: toneL = `d;     12'd423: toneL = `d;
                    
                    12'd424: toneL = `d;     12'd425: toneL = `d;
                    12'd426: toneL = `d;     12'd427: toneL = `d;
                    12'd428: toneL = `d;     12'd429: toneL = `d;
                    12'd430: toneL = `d;     12'd431: toneL = `d;
                    
                    12'd432: toneL = `la;     12'd433: toneL = `la;
                    12'd434: toneL = `la;     12'd435: toneL = `la;
                    12'd436: toneL = `la;     12'd437: toneL = `la;
                    12'd438: toneL = `la;     12'd439: toneL = `la;
                    
                    12'd440: toneL = `la;     12'd441: toneL = `la;
                    12'd442: toneL = `la;     12'd443: toneL = `la;
                    12'd444: toneL = `la;     12'd445: toneL = `la;
                    12'd446: toneL = `la;     12'd447: toneL = `la;
                    
                    12'd448: toneL = `lg;     12'd449: toneL = `lg;
                    12'd450: toneL = `lg;     12'd451: toneL = `lg;
                    12'd452: toneL = `lg;     12'd453: toneL = `lg;
                    12'd454: toneL = `lg;     12'd455: toneL = `lg;
                    
                    12'd456: toneL = `lg;     12'd457: toneL = `lg;
                    12'd458: toneL = `lg;     12'd459: toneL = `lg;
                    12'd460: toneL = `lg;     12'd461: toneL = `lg;
                    12'd462: toneL = `lg;     12'd463: toneL = `lg;
                    
                    12'd464: toneL = `lb;     12'd465: toneL = `lb;
                    12'd466: toneL = `lb;     12'd467: toneL = `lb;
                    12'd468: toneL = `lb;     12'd469: toneL = `lb;
                    12'd470: toneL = `lb;     12'd471: toneL = `lb;
                    
                    12'd472: toneL = `lb;     12'd473: toneL = `lb;
                    12'd474: toneL = `lb;     12'd475: toneL = `lb;
                    12'd476: toneL = `lb;     12'd477: toneL = `lb;
                    12'd478: toneL = `lb;     12'd479: toneL = `lb;
                    
                    12'd480: toneL = `d;     12'd481: toneL = `d;
                    12'd482: toneL = `d;     12'd483: toneL = `d;
                    12'd484: toneL = `d;     12'd485: toneL = `d;
                    12'd486: toneL = `d;     12'd487: toneL = `d;
                    
                    12'd488: toneL = `d;     12'd489: toneL = `d;
                    12'd490: toneL = `d;     12'd491: toneL = `d;
                    12'd492: toneL = `d;     12'd493: toneL = `d;
                    12'd494: toneL = `d;     12'd495: toneL = `d;
                    
                    12'd496: toneL = `d;     12'd497: toneL = `d;
                    12'd498: toneL = `d;     12'd499: toneL = `d;
                    12'd500: toneL = `d;     12'd501: toneL = `d;
                    12'd502: toneL = `d;     12'd503: toneL = `d;
                    
                    12'd504: toneL = `d;     12'd505: toneL = `d;
                    12'd506: toneL = `d;     12'd507: toneL = `d;
                    12'd508: toneL = `d;     12'd509: toneL = `d;
                    12'd510: toneL = `d;     12'd511: toneL = `d;
                                    
                    default: toneL = `sil;
                endcase
            end
        
            else begin
                toneL = `sil;
            end
        end
        
        else //mario
        begin
            if(en == 1)
            begin
                case(ibeatNum)
                    12'd0: toneL = `e;     12'd1: toneL = `e;
                    12'd2: toneL = `e;     12'd3: toneL = `e;
                    
                    12'd4: toneL = `e;     12'd5: toneL = `e;
                    12'd6: toneL = `e;     12'd7: toneL = `e;
                    
                    12'd8: toneL = `sil;     12'd9: toneL = `sil;
                    12'd10: toneL = `sil;     12'd11: toneL = `sil;
                    
                    12'd12: toneL = `c;     12'd13: toneL = `c;
                    12'd14: toneL = `c;     12'd15: toneL = `c;
                    
                    12'd16: toneL = `c;     12'd17: toneL = `c;
                    12'd18: toneL = `c;     12'd19: toneL = `c;
                    
                    12'd20: toneL = `sil;     12'd21: toneL = `sil;
                    12'd22: toneL = `sil;     12'd23: toneL = `sil;
                    
                    12'd24: toneL = `llg;     12'd25: toneL = `llg;
                    12'd26: toneL = `llg;     12'd27: toneL = `llg;
                    
                    12'd28: toneL = `llg;     12'd29: toneL = `llg;
                    12'd30: toneL = `llg;     12'd31: toneL = `llg;
                    
                    12'd32: toneL = `sil;     12'd33: toneL = `sil;
                    12'd34: toneL = `sil;     12'd35: toneL = `sil;
                    
                    12'd36: toneL = `c;     12'd37: toneL = `c;
                    12'd38: toneL = `c;     12'd39: toneL = `c;
                    
                    12'd40: toneL = `c;     12'd41: toneL = `c;
                    12'd42: toneL = `c;     12'd43: toneL = `c;
                    
                    12'd44: toneL = `d;     12'd45: toneL = `d;
                    12'd46: toneL = `d;     12'd47: toneL = `d;
                    
                    12'd48: toneL = `d;     12'd49: toneL = `d;
                    12'd50: toneL = `d;     12'd51: toneL = `d;
                    
                    12'd52: toneL = `db;     12'd53: toneL = `db;
                    12'd54: toneL = `db;     12'd55: toneL = `db;
                    
                    12'd56: toneL = `c;     12'd57: toneL = `c;
                    12'd58: toneL = `c;     12'd59: toneL = `c;
                    
                    12'd60: toneL = `sil;     12'd61: toneL = `sil;
                    12'd62: toneL = `sil;     12'd63: toneL = `sil;
                    
                    //----------------------------------------------
                    
                    12'd64: toneL = `c;     12'd65: toneL = `c;
                    12'd66: toneL = `c;     12'd67: toneL = `c;
                    
                    12'd68: toneL = `c;     12'd69: toneL = `c;
                    12'd70: toneL = `c;     12'd71: toneL = `c;
                    
                    12'd72: toneL = `g;     12'd73: toneL = `g;
                    12'd74: toneL = `g;     12'd75: toneL = `g;
                    
                    12'd76: toneL = `b;     12'd77: toneL = `b;
                    12'd78: toneL = `b;     12'd79: toneL = `b;
                    
                    12'd80: toneL = `hc;     12'd81: toneL = `hc;
                    12'd82: toneL = `hc;     12'd83: toneL = `hc;
                    
                    12'd84: toneL = `hc;     12'd85: toneL = `hc;
                    12'd86: toneL = `hc;     12'd87: toneL = `hc;
                    
                    12'd88: toneL = `a;     12'd89: toneL = `a;
                    12'd90: toneL = `a;     12'd91: toneL = `a;
                    
                    12'd92: toneL = `b;     12'd93: toneL = `b;
                    12'd94: toneL = `b;     12'd95: toneL = `sil;
                    
                    12'd96: toneL = `b;     12'd97: toneL = `b;
                    12'd98: toneL = `b;     12'd99: toneL = `b;
                    
                    12'd100: toneL = `a;     12'd101: toneL = `a;
                    12'd102: toneL = `a;     12'd103: toneL = `a;
                    
                    12'd104: toneL = `a;     12'd105: toneL = `a;
                    12'd106: toneL = `a;     12'd107: toneL = `a;
                    
                    12'd108: toneL = `e;     12'd109: toneL = `e;
                    12'd110: toneL = `e;     12'd111: toneL = `e;
                    
                    12'd112: toneL = `f;     12'd113: toneL = `f;
                    12'd114: toneL = `f;     12'd115: toneL = `f;
                    
                    12'd116: toneL = `d;     12'd117: toneL = `d;
                    12'd118: toneL = `d;     12'd119: toneL = `d;
                    
                    12'd120: toneL = `sil;     12'd121: toneL = `sil;
                    12'd122: toneL = `sil;     12'd123: toneL = `sil;
                    
                    12'd124: toneL = `sil;     12'd125: toneL = `sil;
                    12'd126: toneL = `sil;     12'd127: toneL = `sil;
                    
                    //------------------------------------------------
                    
                    12'd128: toneL = `e;     12'd129: toneL = `e;
                    12'd130: toneL = `e;     12'd131: toneL = `e;
                    
                    12'd132: toneL = `e;     12'd133: toneL = `e;
                    12'd134: toneL = `e;     12'd135: toneL = `e;
                    
                    12'd136: toneL = `sil;     12'd137: toneL = `sil;
                    12'd138: toneL = `sil;     12'd139: toneL = `sil;
                    
                    12'd140: toneL = `c;     12'd141: toneL = `c;
                    12'd142: toneL = `c;     12'd143: toneL = `c;
                    
                    12'd144: toneL = `c;     12'd145: toneL = `c;
                    12'd146: toneL = `c;     12'd147: toneL = `c;
                    
                    12'd148: toneL = `sil;     12'd149: toneL = `sil;
                    12'd150: toneL = `sil;     12'd151: toneL = `sil;
                    
                    12'd152: toneL = `llg;     12'd153: toneL = `llg;
                    12'd154: toneL = `llg;     12'd155: toneL = `llg;
                    
                    12'd156: toneL = `llg;     12'd157: toneL = `llg;
                    12'd158: toneL = `llg;     12'd159: toneL = `llg;
                    
                    12'd160: toneL = `sil;     12'd161: toneL = `sil;
                    12'd162: toneL = `sil;     12'd163: toneL = `sil;
                    
                    12'd164: toneL = `c;     12'd165: toneL = `c;
                    12'd166: toneL = `c;     12'd167: toneL = `c;
                    
                    12'd168: toneL = `c;     12'd169: toneL = `c;
                    12'd170: toneL = `c;     12'd171: toneL = `c;
                    
                    12'd172: toneL = `d;     12'd173: toneL = `d;
                    12'd174: toneL = `d;     12'd175: toneL = `d;
                    
                    12'd176: toneL = `d;     12'd177: toneL = `d;
                    12'd178: toneL = `d;     12'd179: toneL = `d;
                    
                    12'd180: toneL = `db;     12'd181: toneL = `db;
                    12'd182: toneL = `db;     12'd183: toneL = `db;
                    
                    12'd184: toneL = `c;     12'd185: toneL = `c;
                    12'd186: toneL = `c;     12'd187: toneL = `c;
                    
                    12'd188: toneL = `sil;     12'd189: toneL = `sil;
                    12'd190: toneL = `sil;     12'd191: toneL = `sil;
                    
                    //------------------------------------------------
                    
                    12'd192: toneL = `c;     12'd193: toneL = `c;
                    12'd194: toneL = `c;     12'd195: toneL = `c;
                    
                    12'd196: toneL = `c;     12'd197: toneL = `c;
                    12'd198: toneL = `c;     12'd199: toneL = `c;
                    
                    12'd200: toneL = `g;     12'd201: toneL = `g;
                    12'd202: toneL = `g;     12'd203: toneL = `g;
                    
                    12'd204: toneL = `b;     12'd205: toneL = `b;
                    12'd206: toneL = `b;     12'd207: toneL = `b;
                    
                    12'd208: toneL = `hc;     12'd209: toneL = `hc;
                    12'd210: toneL = `hc;     12'd211: toneL = `hc;
                    
                    12'd212: toneL = `hc;     12'd213: toneL = `hc;
                    12'd214: toneL = `hc;     12'd215: toneL = `hc;
                    
                    12'd216: toneL = `a;     12'd217: toneL = `a;
                    12'd218: toneL = `a;     12'd219: toneL = `a;
                    
                    12'd220: toneL = `b;     12'd221: toneL = `b;
                    12'd222: toneL = `b;     12'd223: toneL = `sil;
                    
                    12'd224: toneL = `b;     12'd225: toneL = `b;
                    12'd226: toneL = `b;     12'd227: toneL = `b;
                    
                    12'd228: toneL = `a;     12'd229: toneL = `a;
                    12'd230: toneL = `a;     12'd231: toneL = `a;
                    
                    12'd232: toneL = `a;     12'd233: toneL = `a;
                    12'd234: toneL = `a;     12'd235: toneL = `a;
                    
                    12'd236: toneL = `e;     12'd237: toneL = `e;
                    12'd238: toneL = `e;     12'd239: toneL = `e;
                    
                    12'd240: toneL = `f;     12'd241: toneL = `f;
                    12'd242: toneL = `f;     12'd243: toneL = `f;
                    
                    12'd244: toneL = `d;     12'd245: toneL = `d;
                    12'd246: toneL = `d;     12'd247: toneL = `d;
                    
                    12'd248: toneL = `sil;     12'd249: toneL = `sil;
                    12'd250: toneL = `sil;     12'd251: toneL = `sil;
                    
                    12'd252: toneL = `sil;     12'd253: toneL = `sil;
                    12'd254: toneL = `sil;     12'd255: toneL = `sil;
                    
                    //------------------------------------------------
                    
                    12'd256: toneL = `c;     12'd257: toneL = `c;
                    12'd258: toneL = `c;     12'd259: toneL = `c;
                    
                    12'd260: toneL = `c;     12'd261: toneL = `c;
                    12'd262: toneL = `c;     12'd263: toneL = `c;
                    
                    12'd264: toneL = `sil;     12'd265: toneL = `sil;
                    12'd266: toneL = `sil;     12'd267: toneL = `sil;
                    
                    12'd268: toneL = `g;     12'd269: toneL = `g;
                    12'd270: toneL = `g;     12'd271: toneL = `g;
                    
                    12'd272: toneL = `sil;     12'd273: toneL = `sil;
                    12'd274: toneL = `sil;     12'd275: toneL = `sil;
                    
                    12'd276: toneL = `sil;     12'd277: toneL = `sil;
                    12'd278: toneL = `sil;     12'd279: toneL = `sil;
                    
                    12'd280: toneL = `hc;     12'd281: toneL = `hc;
                    12'd282: toneL = `hc;     12'd283: toneL = `hc;
                    
                    12'd284: toneL = `hc;     12'd285: toneL = `hc;
                    12'd286: toneL = `hc;     12'd287: toneL = `hc;
                    
                    12'd288: toneL = `f;     12'd289: toneL = `f;
                    12'd290: toneL = `f;     12'd291: toneL = `f;
                    
                    12'd292: toneL = `f;     12'd293: toneL = `f;
                    12'd294: toneL = `f;     12'd295: toneL = `f;
                    
                    12'd296: toneL = `sil;     12'd297: toneL = `sil;
                    12'd298: toneL = `sil;     12'd299: toneL = `sil;
                    
                    12'd300: toneL = `c;     12'd301: toneL = `c;
                    12'd302: toneL = `c;     12'd303: toneL = `c;
                    
                    12'd304: toneL = `sil;     12'd305: toneL = `sil;
                    12'd306: toneL = `sil;     12'd307: toneL = `sil;
                    
                    12'd308: toneL = `sil;     12'd309: toneL = `sil;
                    12'd310: toneL = `sil;     12'd311: toneL = `sil;
                    
                    12'd312: toneL = `f;     12'd313: toneL = `f;
                    12'd314: toneL = `f;     12'd315: toneL = `f;
                    
                    12'd316: toneL = `f;     12'd317: toneL = `f;
                    12'd318: toneL = `f;     12'd319: toneL = `f;
                    
                    //------------------------------------------------
                    
                    12'd320: toneL = `c;     12'd321: toneL = `c;
                    12'd322: toneL = `c;     12'd323: toneL = `c;
                    
                    12'd324: toneL = `c;     12'd325: toneL = `c;
                    12'd326: toneL = `c;     12'd327: toneL = `c;
                    
                    12'd328: toneL = `sil;     12'd329: toneL = `sil;
                    12'd330: toneL = `sil;     12'd331: toneL = `sil;
                    
                    12'd332: toneL = `g;     12'd333: toneL = `g;
                    12'd334: toneL = `g;     12'd335: toneL = `g;
                    
                    12'd336: toneL = `sil;     12'd337: toneL = `sil;
                    12'd338: toneL = `sil;     12'd339: toneL = `sil;
                    
                    12'd340: toneL = `sil;     12'd341: toneL = `sil;
                    12'd342: toneL = `sil;     12'd343: toneL = `sil;
                    
                    12'd344: toneL = `g;     12'd345: toneL = `g;
                    12'd346: toneL = `g;     12'd347: toneL = `g;
                    
                    12'd348: toneL = `hc;     12'd349: toneL = `hc;
                    12'd350: toneL = `hc;     12'd351: toneL = `hc;
                    
                    12'd352: toneL = `sil;     12'd353: toneL = `sil;
                    12'd354: toneL = `sil;     12'd355: toneL = `sil;
                    
                    12'd356: toneL = `hc;     12'd357: toneL = `hc;
                    12'd358: toneL = `hc;     12'd359: toneL = `hc;
                    
                    12'd360: toneL = `hc;     12'd361: toneL = `hc;
                    12'd362: toneL = `hc;     12'd363: toneL = `hc;
                    
                    12'd364: toneL = `hc;     12'd365: toneL = `hc;
                    12'd366: toneL = `hc;     12'd367: toneL = `sil;
                    
                    12'd368: toneL = `hc;     12'd369: toneL = `hc;
                    12'd370: toneL = `hc;     12'd371: toneL = `hc;
                    
                    12'd372: toneL = `hc;     12'd373: toneL = `hc;
                    12'd374: toneL = `hc;     12'd375: toneL = `hc;
                    
                    12'd376: toneL = `sil;     12'd377: toneL = `sil;
                    12'd378: toneL = `sil;     12'd379: toneL = `sil;
                    
                    12'd380: toneL = `sil;     12'd381: toneL = `sil;
                    12'd382: toneL = `sil;     12'd383: toneL = `sil;
                    
                    //------------------------------------------------
                    
                    12'd384: toneL = `c;     12'd385: toneL = `c;
                    12'd386: toneL = `c;     12'd387: toneL = `c;
                    
                    12'd388: toneL = `c;     12'd389: toneL = `c;
                    12'd390: toneL = `c;     12'd391: toneL = `c;
                    
                    12'd392: toneL = `sil;     12'd393: toneL = `sil;
                    12'd394: toneL = `sil;     12'd395: toneL = `sil;
                    
                    12'd396: toneL = `g;     12'd397: toneL = `g;
                    12'd398: toneL = `g;     12'd399: toneL = `g;
                    
                    12'd400: toneL = `sil;     12'd401: toneL = `sil;
                    12'd402: toneL = `sil;     12'd403: toneL = `sil;
                    
                    12'd404: toneL = `sil;     12'd405: toneL = `sil;
                    12'd406: toneL = `sil;     12'd407: toneL = `sil;
                    
                    12'd408: toneL = `hc;     12'd409: toneL = `hc;
                    12'd410: toneL = `hc;     12'd411: toneL = `hc;
                    
                    12'd412: toneL = `hc;     12'd413: toneL = `hc;
                    12'd414: toneL = `hc;     12'd415: toneL = `hc;
                    
                    12'd416: toneL = `f;     12'd417: toneL = `f;
                    12'd418: toneL = `f;     12'd419: toneL = `f;
                    
                    12'd420: toneL = `f;     12'd421: toneL = `f;
                    12'd422: toneL = `f;     12'd423: toneL = `f;
                    
                    12'd424: toneL = `sil;     12'd425: toneL = `sil;
                    12'd426: toneL = `sil;     12'd427: toneL = `sil;
                    
                    12'd428: toneL = `c;     12'd429: toneL = `c;
                    12'd430: toneL = `c;     12'd431: toneL = `c;
                    
                    12'd432: toneL = `sil;     12'd433: toneL = `sil;
                    12'd434: toneL = `sil;     12'd435: toneL = `sil;
                    
                    12'd436: toneL = `sil;     12'd437: toneL = `sil;
                    12'd438: toneL = `sil;     12'd439: toneL = `sil;
                    
                    12'd440: toneL = `f;     12'd441: toneL = `f;
                    12'd442: toneL = `f;     12'd443: toneL = `f;
                    
                    12'd444: toneL = `f;     12'd445: toneL = `f;
                    12'd446: toneL = `f;     12'd447: toneL = `f;
                    
                    //------------------------------------------------
                    
                    12'd448: toneL = `c;     12'd449: toneL = `c;
                    12'd450: toneL = `c;     12'd451: toneL = `c;
                    
                    12'd452: toneL = `c;     12'd453: toneL = `c;
                    12'd454: toneL = `c;     12'd455: toneL = `c;
                    
                    12'd456: toneL = `lab;     12'd457: toneL = `lab;
                    12'd458: toneL = `lab;     12'd459: toneL = `lab;
                    
                    12'd460: toneL = `lab;     12'd461: toneL = `lab;
                    12'd462: toneL = `lab;     12'd463: toneL = `lab;
                    
                    12'd464: toneL = `sil;     12'd465: toneL = `sil;
                    12'd466: toneL = `sil;     12'd467: toneL = `sil;
                    
                    12'd468: toneL = `lbb;     12'd469: toneL = `lbb;
                    12'd470: toneL = `lbb;     12'd471: toneL = `lbb;
                    
                    12'd472: toneL = `lbb;     12'd473: toneL = `lbb;
                    12'd474: toneL = `lbb;     12'd475: toneL = `lbb;
                    
                    12'd476: toneL = `sil;     12'd477: toneL = `sil;
                    12'd478: toneL = `sil;     12'd479: toneL = `sil;
                    
                    12'd480: toneL = `c;     12'd481: toneL = `c;
                    12'd482: toneL = `c;     12'd483: toneL = `c;
                    
                    12'd484: toneL = `c;     12'd485: toneL = `c;
                    12'd486: toneL = `c;     12'd487: toneL = `c;
                    
                    12'd488: toneL = `c;     12'd489: toneL = `c;
                    12'd490: toneL = `c;     12'd491: toneL = `c;
                    
                    12'd492: toneL = `c;     12'd493: toneL = `c;
                    12'd494: toneL = `c;     12'd495: toneL = `c;
                    
                    12'd496: toneL = `sil;     12'd497: toneL = `sil;
                    12'd498: toneL = `sil;     12'd499: toneL = `sil;
                    
                    12'd500: toneL = `sil;     12'd501: toneL = `sil;
                    12'd502: toneL = `sil;     12'd503: toneL = `sil;
                    
                    12'd504: toneL = `sil;     12'd505: toneL = `sil;
                    12'd506: toneL = `sil;     12'd507: toneL = `sil;
                    
                    12'd508: toneL = `sil;     12'd509: toneL = `sil;
                    12'd510: toneL = `sil;     12'd511: toneL = `sil;
                                   
                    default: toneL = `sil;
                endcase
            end
        
            else begin
                toneL = `sil;
            end
        end
    end
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                               
			2 : display = 7'b0100111;   //C                                             
			3 : display = 7'b0100001;   //D                                             
			4 : display = 7'b0000110;   //E                                               
			5 : display = 7'b0001110;   //F                                               
			6 : display = 7'b1000010;   //G
			7 : display = 7'b0100000;   //A
			8 : display = 7'b0000011;   //B
			9 : display = 7'b0010000;	//
			10: display = 7'b0111111;   //-
			11: display = 7'b1111111;   //blank
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

