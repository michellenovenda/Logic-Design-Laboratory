module lab7_1(
    input clk,
    input rst,
    input en,
    input dir,
    output[3:0] vgaRed,
    output[3:0] vgaGreen,
    output[3:0] vgaBlue,
    output hsync,
    output vsync
    );

wire[11:0] data;
wire clk_div_22;
wire clk_25MHz;
wire[16:0] pixel_addr;
wire[11:0] pixel;
wire valid;
wire[9:0] h_cnt;
wire[9:0] v_cnt;
wire rst_debounced;
wire rst_one_pulse;

clock_divider_16 clkdiv16(.clk(clk), .clk_div_16(clk_div_16));
debounce debounce_rst(.pb_debounced(rst_debounced), .pb(rst), .clk(clk_div_16));
one_pulse onepulse_rst(.pb_debounced(rst_debounced), .clk(clk_div_16), .pb_one_pulse(rst_one_pulse));

clock_divider_22 clkdiv22(.clk(clk), .clk_div_22(clk_div_22));
clock_divider_25MHz clkdiv25MHz(.clk(clk), .clk_25MHz(clk_25MHz));
vga_controller vga_inst(.pclk(clk_25MHz), .reset(rst_one_pulse), .hsync(hsync), .vsync(vsync), .valid(valid), .h_cnt(h_cnt), .v_cnt(v_cnt));
mem_addr_gen mem_addr(.clk(clk_div_22), .rst(rst_one_pulse), .en(en), .dir(dir), .h_cnt(h_cnt), .v_cnt(v_cnt), .pixel_addr(pixel_addr));

assign {vgaRed, vgaGreen, vgaBlue} = (valid == 1'b1) ? pixel : 12'd0;
assign data = {vgaRed, vgaGreen, vgaBlue};
blk_mem_gen_0 mem_gen(.addra(pixel_addr), .clka(clk_25MHz), .dina(data), .douta(pixel), .wea(0));

endmodule

module vga_controller(
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

module mem_addr_gen(
    input clk,
    input rst,
    input en,
    input dir,
    input[9:0] h_cnt,
    input[9:0] v_cnt,
    output[16:0] pixel_addr
    );
    
    reg[7:0] position;
    
    assign pixel_addr = ((h_cnt >> 1)+320*(v_cnt >> 1)+position*320)%76800;
    
    always@(posedge clk or posedge rst)
    begin
        if(rst)
            position <= 0;
            
        else
        begin
            if(en == 1'b0)
                position <= position;
                
            else
            begin
                if(dir == 1'b0)
                begin
                    if(position < 239)
                        position <= position + 1;
                    else
                        position <= 0;
                end
                
                else
                begin
                    if(position > 1) //>1
                        position <= position - 1;
                    else
                        position <= 240; //240
                end
            end
        end
    end
endmodule

