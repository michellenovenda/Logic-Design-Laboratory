//divides from 100MHz to 10Hz
module clock_divider(
    clk,
    clk_div
    );
    
input clk;
output clk_div;
reg[23:0]  num;

parameter n = 24;

always@(posedge clk)
begin
    if(num < 10000000-1'b1)
        num <= num + 1'b1;
    else
        num <= 0;
end

assign clk_div = num[n-1];
endmodule

module debounce(pb_debounced, pb, clk);
    output pb_debounced;
    input pb;
    input clk;
   
    reg[3:0] shift_reg;
   
    always@(posedge clk)
    begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end
   
    assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
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

module lab4_2(
    input clk,
    input rst,
    input en,
    input record,
    input display_1,
    input display_2,
    output[3:0] DIGIT,
    output[6:0] DISPLAY
    );

wire rst;
wire en;
wire record;

wire display_1;
wire display_2;

reg[3:0] DIGIT = 4'b0000;
reg[6:0] DISPLAY = 7'b0000001;

reg[3:0] digit1 = 4'd0;
reg[3:0] digit2 = 4'd0;
reg[3:0] digit3 = 4'd0;
reg[3:0] digit4 = 4'd0;

reg[3:0] display_digit1 = 4'd0;
reg[3:0] display_digit2 = 4'd0;
reg[3:0] display_digit3 = 4'd0;
reg[3:0] display_digit4 = 4'd0;

reg[3:0] record1_digit1 = 4'd0;
reg[3:0] record1_digit2 = 4'd0;
reg[3:0] record1_digit3 = 4'd0;
reg[3:0] record1_digit4 = 4'd0;

reg[3:0] record2_digit1 = 4'd0;
reg[3:0] record2_digit2 = 4'd0;
reg[3:0] record2_digit3 = 4'd0;
reg[3:0] record2_digit4 = 4'd0;

reg[3:0] ACT_DIGIT = 4'd0;

wire clk_div;

reg[19:0] refresh_counter;
wire[1:0] refresher;

wire rst_debounced;
wire en_debounced;
wire record_debounced;

wire rst_one_pulse;
wire en_one_pulse;
wire record_one_pulse;

reg resume = 1'b0;
reg recorded1 = 1'b0;
reg recorded2 = 1'b0;

clock_divider clkdiv(.clk(clk), .clk_div(clk_div));

debounce debounce_rst(.pb_debounced(rst_debounced), .pb(rst), .clk(clk));
debounce debounce_en(.pb_debounced(en_debounced), .pb(en), .clk(clk));
debounce debounce_record(.pb_debounced(record_debounced), .pb(record), .clk(clk));

one_pulse onepulse_rst(.pb_debounced(rst_debounced), .clk(clk_div), .pb_one_pulse(rst_one_pulse));
one_pulse onepulse_en(.pb_debounced(en_debounced), .clk(clk_div), .pb_one_pulse(en_one_pulse));
one_pulse onepulse_record(.pb_debounced(record_debounced), .clk(clk_div), .pb_one_pulse(record_one_pulse));


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
end

always@(posedge clk_div or posedge rst_one_pulse)
begin
    if(rst_one_pulse == 1'b1)
    begin
        digit1 <= 4'd0;
        digit2 <= 4'd0;
        digit3 <= 4'd0;
        digit4 <= 4'd0;
        
        recorded1 <= 1'b0;
        recorded2 <= 1'b0;
                
        record1_digit1 <= 4'd0;
        record1_digit2 <= 4'd0;
        record1_digit3 <= 4'd0;
        record1_digit4 <= 4'd0;
        
        record2_digit1 <= 4'd0;
        record2_digit2 <= 4'd0;
        record2_digit3 <= 4'd0;
        record2_digit4 <= 4'd0;
    end
    
    else
    begin
        if(resume == 1'b0) //pause
        begin
            if(display_1 == 1'b0 && display_2 == 1'b0)
            begin
                digit1 <= digit1;
                digit2 <= digit2;
                digit3 <= digit3;
                digit4 <= digit4;
            end
        end
    
        else if(resume == 1'b1)
        begin
            //first record
            if(record_one_pulse == 1'b1 && recorded1 == 1'b0 && recorded2 == 1'b0)
            begin
                recorded1 <= 1'b1;
                
                record1_digit1 <= digit1;
                record1_digit2 <= digit2;
                record1_digit3 <= digit3;
                record1_digit4 <= digit4;
            end
            
            //second record
            else if(record_one_pulse == 1'b1 && recorded1 == 1'b1 && recorded2 == 1'b0)
            begin
                recorded2 = 1'b1;
                
                record2_digit1 <= digit1;
                record2_digit2 <= digit2;
                record2_digit3 <= digit3;
                record2_digit4 <= digit4;
            end
            
            //stopwatch count
            if(digit4 == 4'd2)
            begin
                digit4 <= digit4;
                digit3 <= 4'd0;
                digit2 <= 4'd0;
                digit1 <= 4'd0;
            end
            
            else if(digit4 != 4'd2)
            begin
                if(digit1 != 4'd9)
                begin
                    digit4 <= digit4;
                    digit3 <= digit3;
                    digit2 <= digit2;
                    digit1 <= digit1 + 4'd1;
                end
                
                else if(digit1 == 4'd9)
                begin
                    if(digit2 != 4'd9)
                    begin
                        digit4 <= digit4;
                        digit3 <= digit3;
                        digit2 <= digit2 + 4'd1;
                        digit1 <= 4'd0;
                    end
                    
                    if(digit2 == 4'd9)
                    begin
                        if(digit3 != 4'd5)
                        begin
                            digit4 <= digit4;
                            digit3 <= digit3 + 4'd1;
                            digit2 <= 4'd0;
                            digit1 <= 4'd0;
                        end
                    
                        else if(digit3 == 4'd5)
                        begin
                            digit4 <= digit4 + 4'd1;
                            digit3 <= 4'd0;
                            digit2 <= 4'd0;
                            digit1 <= 4'd0;
                        end
                    end
                end
            end
        end
    end
end


always@(*)
begin
    case(refresher)
        2'b00:
        begin
            DIGIT = 4'b1110;
            
            if(display_1 == 1'b1 && display_2 == 1'b0 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b0 && digit4 == 4'd2)
            begin
                display_digit1 <= record1_digit1;
            end
            
            else if(display_1 == 1'b0 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b0 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit1 <= record2_digit1;
            end
            
            else if(display_1 == 1'b1 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit1 <= 4'd11;
            end
            
            else if(resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b1 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b1 ||
            resume == 1'b0 && display_1 == 1'b0 && display_2 == 1'b0)
                display_digit1 <= digit1;
                
            ACT_DIGIT = display_digit1;
        end
        
        2'b01:
        begin
            DIGIT = 4'b1101;
            
            if(display_1 == 1'b1 && display_2 == 1'b0 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b0 && digit4 == 4'd2)
            begin
                display_digit2 <= record1_digit2;
            end
            
            else if(display_1 == 1'b0 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b0 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit2 <= record2_digit2;
            end
            
            else if(display_1 == 1'b1 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit2 <= 4'd11;
            end
            
            else if(resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b1 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b1 ||
            resume == 1'b0 && display_1 == 1'b0 && display_2 == 1'b0)
                display_digit2 <= digit2;
                
            ACT_DIGIT = display_digit2;
        end
        
        2'b10:
        begin
            DIGIT = 4'b1011;
            
            if(display_1 == 1'b1 && display_2 == 1'b0 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b0 && digit4 == 4'd2)
            begin
                display_digit3 <= record1_digit3;
            end
            
            else if(display_1 == 1'b0 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b0 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit3 <= record2_digit3;
            end
            
            else if(display_1 == 1'b1 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit3 <= 4'd11;
            end
            
            else if(resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b1 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b1 ||
            resume == 1'b0 && display_1 == 1'b0 && display_2 == 1'b0)
                display_digit3 <= digit3;
                
            ACT_DIGIT = display_digit3;
        end
        
        2'b11: begin
            DIGIT = 4'b0111;
            
            if(display_1 == 1'b1 && display_2 == 1'b0 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b0 && digit4 == 4'd2)
            begin
                display_digit4 <= record1_digit4;
            end
            
            else if(display_1 == 1'b0 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b0 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit4 <= record2_digit4;
            end
            
            else if(display_1 == 1'b1 && display_2 == 1'b1 && resume == 1'b0 || display_1 == 1'b1 && display_2 == 1'b1 && digit4 == 4'd2)
            begin
                display_digit4 <= 4'd11;
            end
            
            else if(resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b0 && display_2 == 1'b1 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b0 ||
            resume == 1'b1 && display_1 == 1'b1 && display_2 == 1'b1 ||
            resume == 1'b0 && display_1 == 1'b0 && display_2 == 1'b0)
                display_digit4 <= digit4;
                
            ACT_DIGIT = display_digit4;
        end
    endcase
end

always@(*)
begin 
    case(ACT_DIGIT) //digit
        4'd0: DISPLAY = 7'b0000001;
        4'd1: DISPLAY = 7'b1001111;
        4'd2: DISPLAY = 7'b0010010;
        4'd3: DISPLAY = 7'b0000110;
        4'd4: DISPLAY = 7'b1001100;
        4'd5: DISPLAY = 7'b0100100;
        4'd6: DISPLAY = 7'b0100000;
        4'd7: DISPLAY = 7'b0001111;
        4'd8: DISPLAY = 7'b0000000;
        4'd9: DISPLAY = 7'b0000100;
        4'd11: DISPLAY = 7'b1111110; //----
        default: DISPLAY = 7'b1111111;
    endcase
end
endmodule

