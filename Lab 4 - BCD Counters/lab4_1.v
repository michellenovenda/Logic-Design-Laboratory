module clock_divider(
    clk,
    clk_div
    );
    
    parameter n = 25;
    input clk;
    output clk_div;
    
    reg[24:0] num = 25'd0;
    wire [24:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div = num[n-1];
endmodule

module debounce_clock_divider(
    clk,
    debounce_clk_div
    );
    
    parameter n = 13;
    input clk;
    output debounce_clk_div;
    
    reg[12:0] num = 13'd0;
    wire [22:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign debounce_clk_div = num[n-1];
endmodule

module one_pulse_clock_divider(
    clk,
    one_pulse_clk_div
    );
    
    parameter n = 23;
    input clk;
    output one_pulse_clk_div;
    
    reg[22:0] num = 23'd0;
    wire [22:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign one_pulse_clk_div = num[n-1];
endmodule
    
module debounce(pb_debounced, pb, clk);
    output pb_debounced;
    input pb;
    input clk;
   
    reg[3:0] shift_reg = 4'd0;
   
    always@(posedge clk)
    begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end
   
    assign pb_debounced = (shift_reg == 4'b1111) ? 1'b1 : 1'b0;
endmodule

module one_pulse(pb_debounced, clk, pb_one_pulse);
    input pb_debounced;
    input clk;
    output pb_one_pulse;
    
    reg pb_one_pulse;
    reg pb_debounced_delay;
    
    always@(posedge clk)
    begin
        if(pb_debounced == 1'b1 & pb_debounced_delay == 1'b0)
            pb_one_pulse <= 1'b1;        
        else
            pb_one_pulse <= 1'b0;

        pb_debounced_delay <= pb_debounced;
    end
endmodule

module lab4_1(
    input clk,
    input rst,
    input en,
    input dir,
    output [3:0] DIGIT,
    output [6:0] DISPLAY,
    output max,
    output min
);

wire rst;
wire en;
wire dir;

reg[3:0] DIGIT = 4'b0000;
reg[6:0] DISPLAY = 7'b0000001;

reg max = 1'b0;
reg min = 1'b0;

wire clk_div;
wire debounce_clk_div;
wire one_pulse_clk_div;

wire rst_debounced;
wire en_debounced;
wire dir_debounced;

wire rst_one_pulse;
wire en_one_pulse;
wire dir_one_pulse;

reg[19:0] refresh_counter = 20'd0;
wire[1:0] refresher;

reg[3:0] ones = 4'd0;
reg[3:0] tens = 4'd0;

reg[3:0] ACT_DIGIT;

reg resume = 1'b0;
reg count_up = 1'b1;

clock_divider clkdiv(.clk(clk), .clk_div(clk_div));
debounce_clock_divider db_clkdiv(.clk(clk), .debounce_clk_div(debounce_clk_div));
one_pulse_clock_divider op_clkdiv(.clk(clk), .one_pulse_clk_div(one_pulse_clk_div));

debounce debounce_rst(.pb_debounced(rst_debounced), .pb(rst), .clk(debounce_clk_div));
debounce debounce_en(.pb_debounced(en_debounced), .pb(en), .clk(debounce_clk_div));
debounce debounce_dir(.pb_debounced(dir_debounced), .pb(dir), .clk(debounce_clk_div));

one_pulse onepulse_rst(.pb_debounced(rst_debounced), .clk(one_pulse_clk_div), .pb_one_pulse(rst_one_pulse));
one_pulse onepulse_en(.pb_debounced(en_debounced), .clk(one_pulse_clk_div), .pb_one_pulse(en_one_pulse));
one_pulse onepulse_dir(.pb_debounced(dir_debounced), .clk(one_pulse_clk_div), .pb_one_pulse(dir_one_pulse));

always@(posedge clk)
begin
    refresh_counter <= refresh_counter + 20'd1;
end    
assign refresher = refresh_counter[19:18];

always@(posedge en_one_pulse or posedge rst_one_pulse)
begin
    if(rst_one_pulse == 1'b1)
    begin
        resume <= 1'b0;
    end

    else if(en_one_pulse == 1'b1)
        resume <= ~resume;
        
    else
        resume <= resume;        
end

always@(posedge dir_one_pulse or posedge rst_one_pulse)
begin
    if(rst_one_pulse == 1'b1)
        count_up <= 1'b1;
    
    else if(dir_one_pulse == 1'b1)
        count_up <= ~count_up;
        
    else
        count_up <= count_up;        
end

always@(posedge clk_div or posedge rst_one_pulse)
begin  
   if(rst_one_pulse == 1'b1)
   begin
       ones <= 4'd0;
       tens <= 4'd0;
       min <= 1'd0;
       max <= 1'd0;
   end
   
   else
   begin
        if(resume == 1'b0)
        begin
            ones <= ones;
            tens <= tens;
        end            
            
        else if(resume == 1'b1)
        begin
            //reach 00 or 99
            if((ones == 4'd9 && tens == 4'd9 && count_up == 1'b1) || 
            (ones == 4'd0 && tens == 4'd0 && count_up == 1'b0)) 
            begin
                ones <= ones;
                tens <= tens;
            end
            
            else 
            begin
                if(count_up == 1'b1)
                begin
                    if(ones !== 4'd9)
                    begin
                        ones <= ones + 4'd1;
                        tens <= tens;
                    end
                    
                    else if(ones == 4'd9 && tens !== 4'd9)
                    begin
                        ones <= 4'd0;
                        tens <= tens + 4'd1;
                    end
                end
                
                else if(count_up == 1'b0)
                begin
                    if(ones !== 4'd0)
                    begin
                        ones <= ones - 4'd1;
                        tens <= tens;
                    end
                    
                    else if(ones == 4'd0 && tens !== 4'd0)
                    begin
                        ones <= 4'd9;
                        tens <= tens - 4'd1;
                    end
                end
   
                if(ones == 4'd1 && tens == 4'd0 && count_up == 1'b0)
                    min <= 1'b1;
                    
                else
                    min <= 1'b0;                    
                
                
                if(ones == 4'd8 && tens == 4'd9 && count_up == 1'b1)
                    max <= 1'b1;
                    
                else 
                    max <= 1'b0;   
            end                              
        end
    end
end

always@(*)
begin
    case(refresher)
        2'b00:
        begin
            DIGIT <= 4'b1110;
            ACT_DIGIT <= ones;
        end
        
        2'b01:
        begin
            DIGIT <= 4'b1101;
            ACT_DIGIT <= tens;
        end
        
        2'b10:
        begin
            DIGIT <= 4'b1011;
            ACT_DIGIT <= (count_up == 1'b1) ? 4'd11 : 4'd12;          
        end
        
        2'b11: 
        begin
            DIGIT <= 4'b0111;
            ACT_DIGIT <= (count_up == 1'b1) ? 4'd11 : 4'd12;
        end
        
        default:
        begin
            DIGIT <= 4'b1110;
            ACT_DIGIT <= ones;
        end        
    endcase
end

always@(*)
begin 
    case(ACT_DIGIT) //digit
        4'd0: DISPLAY <= 7'b0000001;
        4'd1: DISPLAY <= 7'b1001111;
        4'd2: DISPLAY <= 7'b0010010;
        4'd3: DISPLAY <= 7'b0000110;
        4'd4: DISPLAY <= 7'b1001100;
        4'd5: DISPLAY <= 7'b0100100;
        4'd6: DISPLAY <= 7'b0100000;
        4'd7: DISPLAY <= 7'b0001111;
        4'd8: DISPLAY <= 7'b0000000;
        4'd9: DISPLAY <= 7'b0000100;
        4'd11: DISPLAY <= 7'b0011101; //up
        4'd12: DISPLAY <= 7'b1100011; //down
        default: DISPLAY <= 7'b1111111;
    endcase
end
endmodule

