`define INITIAL 2'b00
`define SPLIT 2'b01
`define MERGE 2'b10

module lab7_2(
    input clk,
    input rst,
    input split,
    output reg[3:0] vgaRed,
    output reg[3:0] vgaGreen,
    output reg[3:0] vgaBlue,
    output hsync,
    output vsync
    );

wire[11:0] data;
wire[11:0] pixel;

wire clk_div_16;
wire clk_div_22;
wire clk_25MHz;

wire valid;

wire[9:0] h_cnt;
wire[9:0] v_cnt;

wire rst_debounced;
wire rst_one_pulse;
wire split_debounced;
wire split_one_pulse;
    
reg[7:0] position = 0;
reg[7:0] position_v = 120;
reg[7:0] position_v1 = 120;

reg[1:0] state = `INITIAL;
reg[1:0] next_state = `INITIAL;

reg[7:0] border_right = 0;
reg[7:0] border_up = 0;

reg[16:0] pixel_addr;
reg start_split = 1'b0;

clock_divider_16 clkdiv16_1(.clk(clk), .clk_div_16(clk_div_16));
clock_divider_22 clkdiv22_1(.clk(clk), .clk_div_22(clk_div_22));
clock_divider_25MHz clkdiv25MHz_1(.clk(clk), .clk_25MHz(clk_25MHz));

debounce debounce_rst_1(.pb_debounced(rst_debounced), .pb(rst), .clk(clk_div_16));
one_pulse onepulse_rst_1(.pb_debounced(rst_debounced), .clk(clk_div_16), .pb_one_pulse(rst_one_pulse));
debounce debounce_split(.pb_debounced(split_debounced), .pb(split), .clk(clk_div_16));
one_pulse onepulse_split(.pb_debounced(split_debounced), .clk(clk_div_16), .pb_one_pulse(split_one_pulse));

vga_controller_1 vga_inst_1(.pclk(clk_25MHz), .reset(rst_one_pulse), .hsync(hsync), .vsync(vsync), .valid(valid), .h_cnt(h_cnt), .v_cnt(v_cnt));

always@(posedge clk_div_16 or posedge rst_one_pulse)
begin
    if(rst_one_pulse == 1'b1)
        start_split <= 1'b0;
    else
    begin
        if(split_one_pulse == 1'b1)
            start_split <= ~start_split;
        else
            start_split <= start_split;
    end
end

always@(posedge clk_div_22 or posedge rst_one_pulse)
begin
    if(rst_one_pulse == 1'b1)
    begin
        position <= 0;
        position_v <= 120;
        position_v1 <= 120;
        border_right <= 0;
        border_up <= 0;
        state <= `INITIAL;
    end
    
    else
    begin
        if(state == `INITIAL)
        begin
            position <= 0;
            position_v <= 120;
            position_v1 <= 120;
            border_right <= 0;
            border_up <= 0;
            
            if(start_split == 1'b1)
                state <= `SPLIT;
            else
                state <= `INITIAL;
        end
            
        else if(state == `SPLIT)
        begin
            position_v <= 120;
            position_v1 <= 120;
            border_up <= 0;
                
            if(start_split == 1'b1)
            begin
                if(border_right == 160)
                    state <= `MERGE;
                    
                else
                begin
                    border_right <= border_right + 1;
                    state <= `SPLIT;
                end
                
                if(position < 320)
                    position <= position + 1;
                else
                    position <= position;
            end
                
            else
            begin
                if(border_right == 160)
                    state <= state;
                    
                else
                begin
                    border_right <= border_right;
                    state <= state;
                end
                
                if(position < 320)
                    position <= position;
                else
                    position <= position;
            end
        end
        
        else if(state == `MERGE)
        begin
            position <= 0;
            border_right <= 0;
                
            if(start_split == 1'b1)
            begin
                if(border_up == 120)
                    state <= `SPLIT;
                    
                else
                begin
                    state <= `MERGE;
                    border_up <= border_up + 1;
                end
                
                if(position_v1 < 239)
                    position_v1 <= position_v1 + 1;
                else
                    position_v1 <= 120;
            
                if(position_v > 1)
                    position_v <= position_v - 1;
                else
                    position_v <= 120;
            end
                
            else
            begin
                if(border_up == 120)
                    state <= state;
                    
                else
                begin
                    state <= state;
                    border_up <= border_up;
                end
                
                if(position_v1 < 239)
                    position_v1 <= position_v1;
                else
                    position_v1 <= position_v1;
            
                if(position_v > 1)
                    position_v <= position_v;
                else
                    position_v <= position_v;
            end
        end
    end
end

always@(posedge clk or posedge rst_one_pulse)
begin
    if(rst_one_pulse == 1'b1)
    begin
        pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
        {vgaRed, vgaGreen, vgaBlue} = (valid == 1'b1) ? pixel : 12'h0;
    end
    
    else
    begin
        if(valid == 1'b1)
        begin
            if(border_up == 120)
            begin
                pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                {vgaRed, vgaGreen, vgaBlue} = pixel;
            end
            
            else if(border_right == 160)
            begin
                {vgaRed, vgaGreen, vgaBlue} = 12'h0;
            end
            
            else
            begin
                pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                {vgaRed, vgaGreen, vgaBlue} = pixel;
                
                if(state == `INITIAL)
                begin
                    pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                    {vgaRed, vgaGreen, vgaBlue} = (valid == 1'b1) ? pixel : 12'h0;
                end
                    
                else if(state == `SPLIT)
                begin
                    pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1))%76800;
                    {vgaRed, vgaGreen, vgaBlue} = pixel;
                    
                    if(h_cnt >= 320)
                    begin
                        pixel_addr = (((h_cnt>>1))+320*(v_cnt>>1)-position)%76800;
                        {vgaRed, vgaGreen, vgaBlue} = ((((h_cnt>>1)+320*(v_cnt>>1)-position)%76800)%160 >= (((h_cnt>>1)+320*(v_cnt>>1))%76800)%160) ? 12'h0 : pixel;
                    end
                    
                    if(h_cnt < 320)
                    begin
                        pixel_addr = (((h_cnt>>1))+320*(v_cnt>>1)+position)%76800;
                        {vgaRed, vgaGreen, vgaBlue} = ((((h_cnt>>1)+320*(v_cnt>>1)+position)%76800)%160 <= (((h_cnt>>1)+320*(v_cnt>>1))%76800)%160) ? 12'h0 : pixel;
                    end
                end
                
                else if(state == `MERGE)
                begin
                    if(v_cnt >= 240)
                    begin
                        pixel_addr = (((h_cnt>>1))+320*(v_cnt>>1)+320*position_v1)%76800;
                        {vgaRed, vgaGreen, vgaBlue} = ((((h_cnt>>1)+320*(v_cnt>>1)-(position_v1-120))%76800) >= (((h_cnt>>1)+320*(v_cnt>>1)+320*(position_v1-120))%76800)) ? pixel : 12'h0;
                    end
                    
                    if(v_cnt < 240)
                    begin
                        pixel_addr = (((h_cnt>>1))+320*(v_cnt>>1)+320*position_v)%76800;
                        {vgaRed, vgaGreen, vgaBlue} = ((((h_cnt>>1)+320*(v_cnt>>1)+(position_v+120))%76800) <= (((h_cnt>>1)+320*(v_cnt>>1)+320*(position_v+120))%76800)) ? pixel : 12'h0;
                    end
                end
            end
        end
    end
end

assign data = {vgaRed, vgaGreen, vgaBlue};
blk_mem_gen_0 mem_gen_1(.addra(pixel_addr), .clka(clk_25MHz), .dina(data), .douta(pixel), .wea(0));
endmodule

module vga_controller_1(
    input wire pclk, reset,
    output wire hsync, vsync, valid,
    output wire[9:0] h_cnt,
    output wire[9:0] v_cnt
    );
    reg[9:0] pixel_cnt;
    reg[9:0] line_cnt;
    reg hsync_i, vsync_i;
    
    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800;
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;
    
    always@(posedge pclk or posedge reset)
        if(reset)
            pixel_cnt <= 0;
        else
            if(pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;
                
    always@(posedge pclk or posedge reset)
        if(reset)
            hsync_i <= hsync_default;
        else
            if((pixel_cnt >= (HD+HF-1)) && (pixel_cnt < (HD+HF+HS-1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default;
                
    always@(posedge pclk or posedge reset)
        if(reset)
            line_cnt <= 0;
        else
            if(pixel_cnt == (HT-1))
                if(line_cnt < (VT-1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;
                    
    always@(posedge pclk or posedge reset)
        if(reset)
            vsync_i <= vsync_default;
        else
            if((line_cnt >= (VD+VF-1)) && (line_cnt < (VD+VF+VS-1)))
                vsync_i <= ~vsync_default;
            else
                vsync_i <= vsync_default;
                
    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));
    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;
endmodule