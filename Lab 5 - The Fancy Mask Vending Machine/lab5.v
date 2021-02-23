`define INITIAL 3'd0
`define DEPOSIT 3'd1
`define AMOUNT 3'd2
`define RELEASE 3'd3
`define CHANGE 3'd4

module clock_divider_13(clk, clk_div_13);
    
    parameter n = 13;
    input clk;
    output clk_div_13;
    
    reg[12:0] num = 13'd0;
    wire [12:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_13 = num[n-1];
endmodule

module clock_divider_16(clk, clk_div_16);
    
    parameter n = 16;
    input clk;
    output clk_div_16;
    
    reg[15:0] num = 16'd0;
    wire [15:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_16 = num[n-1];
endmodule

module clock_divider_27(clk, clk_div_27);
    
    parameter n = 27;
    input clk;
    output clk_div_27;
    
    reg[26:0] num = 27'd0;
    wire [26:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_27 = num[n-1];
endmodule

module clock_divider_29(clk, clk_div_29);
    
    parameter n = 29;
    input clk;
    output clk_div_29;
    
    reg[28:0] num = 29'd0;
    wire [28:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_29 = num[n-1];
endmodule

module lab5(clk, rst, money_5, money_10, cancel, check,
count_down, LED, DIGIT, DISPLAY);

input clk;
input rst;
input money_5;
input money_10;
input cancel;
input check;
input count_down;
output [15:0] LED;
output [3:0] DIGIT;
output [6:0] DISPLAY;

wire clk;
wire rst;

wire money_5;
wire money_10;
wire cancel;
wire check;
wire count_down;

wire money_5_debounced;
wire money_10_debounced;
wire cancel_debounced;
wire check_debounced;
wire count_down_debounced;

wire money_5_one_pulse;
wire money_10_one_pulse;
wire cancel_one_pulse;
wire check_one_pulse;
wire count_down_one_pulse;

reg[15:0] LED = 16'd0;
reg[3:0] DIGIT = 4'd0;
reg[6:0] DISPLAY = 7'd0;

wire clk_div_16;
wire clk_div_27;
wire clk_div_29;

reg[3:0] ACT_DIGIT = 4'd0;
reg[19:0] refresh_counter = 20'd0;
wire[1:0] refresher;

reg[2:0] state = 3'd0;
reg[2:0] next_state = 3'd0;

reg[3:0] balance_digit1 = 4'd0;
reg[3:0] balance_digit2 = 4'd0;

reg[3:0] max = 4'd0;
reg[3:0] init_max = 4'd0;

reg[3:0] money_digit1 = 4'd0;
reg[3:0] money_digit2 = 4'd0;
reg[3:0] change_digit1 = 4'd0;
reg[3:0] change_digit2 = 4'd0;
reg[3:0] return_digit1 = 4'd0;
reg[3:0] return_digit2 = 4'd0;

reg[3:0] digit1 = 4'd0;
reg[3:0] digit2 = 4'd0;
reg[3:0] digit3 = 4'd0;
reg[3:0] digit4 = 4'd0;

reg[3:0] sec = 4'd0;
reg change_state = 1'b0;

reg[3:0] multiply = 4'd0;
reg[3:0] amt_1 = 4'd0;
reg[3:0] amt_2 = 4'd0;
reg[3:0] amount_digit1 = 4'd0;
reg[3:0] amount_digit2 = 4'd0;

reg flag_check_dp = 1'b0;
reg flag_cancel_dp = 1'b0;
reg flag_check_amt = 1'b0;
reg flag_cancel_amt = 1'b0;
reg flag_buy = 1'b0;
reg flag_cancel = 1'b0;
reg change_init = 1'b0;
reg flag_transition = 1'b0;

clock_divider_13 clkdiv13(.clk(clk), .clk_div_13(clk_div_13));
clock_divider_16 clkdiv16(.clk(clk), .clk_div_16(clk_div_16));
clock_divider_27 clkdiv27(.clk(clk), .clk_div_27(clk_div_27));
clock_divider_29 clkdiv29(.clk(clk), .clk_div_29(clk_div_29));

debounce debounce_money_5(.pb_debounced(money_5_debounced), .pb(money_5), .clk(clk_div_16));
debounce debounce_money_10(.pb_debounced(money_10_debounced), .pb(money_10), .clk(clk_div_16));
debounce debounce_cancel(.pb_debounced(cancel_debounced), .pb(cancel), .clk(clk_div_16));
debounce debounce_check(.pb_debounced(check_debounced), .pb(check), .clk(clk_div_16));
debounce debounce_count_down(.pb_debounced(count_down_debounced), .pb(count_down), .clk(clk_div_16));

one_pulse onepulse_money_5(.pb_debounced(money_5_debounced), .clk(clk_div_16), .pb_one_pulse(money_5_one_pulse));
one_pulse onepulse_money_10(.pb_debounced(money_10_debounced), .clk(clk_div_16), .pb_one_pulse(money_10_one_pulse));
one_pulse onepulse_cancel(.pb_debounced(cancel_debounced), .clk(clk_div_16), .pb_one_pulse(cancel_one_pulse));
one_pulse onepulse_check(.pb_debounced(check_debounced), .clk(clk_div_16), .pb_one_pulse(check_one_pulse));
one_pulse onepulse_count_down(.pb_debounced(count_down_debounced), .clk(clk_div_16), .pb_one_pulse(count_down_one_pulse));

always@(posedge clk)
begin
    refresh_counter <= refresh_counter + 20'd1;
end    
assign refresher = refresh_counter[19:18];

always@(posedge clk or posedge rst or posedge change_init)
begin
    if (rst == 1'b1 || change_init == 1'b1)
    begin
        state <= `INITIAL;
    end
    
    else
    begin
        state <= next_state;
    end
end

always@(posedge clk_div_16 or posedge rst or posedge change_init)
begin
    if(rst == 1'b1 || change_init == 1'b1)
    begin
        flag_cancel_dp = 1'b0;
        flag_check_dp = 1'b0;
    end
    
    else
    begin
        if(state == `DEPOSIT)
        begin
            if(check_one_pulse == 1'b1)
            begin    
                if(balance_digit1 > 0 || balance_digit2 > 0)
                    flag_check_dp = 1'b1;
                else
                    flag_check_dp = 1'b0;
            end
            
            else
                flag_check_dp = 1'b0;
                
            if(cancel_one_pulse == 1'b1)
            begin    
                if(balance_digit1 > 0 || balance_digit2 > 0)
                begin
                    flag_cancel_dp = 1'b1;
                end
                
                else
                    flag_cancel_dp = 1'b0;
            end
            
            else
                flag_cancel_dp = 1'b0;
        end
    end
end

always@(posedge clk_div_16 or posedge rst or posedge change_init)
begin
    if(rst == 1'b1 || change_init == 1'b1)
    begin
        flag_cancel_amt = 1'b0;
        flag_check_amt = 1'b0;
    end
    
    else
    begin
        if(state == `AMOUNT)
        begin
            if(check_one_pulse == 1'b1)
                flag_check_amt = 1'b1;
            else
                flag_check_amt = 1'b0;
                
            if(cancel_one_pulse == 1'b1)
            begin
                flag_cancel_amt = 1'b1;
            end
            
            else
                flag_cancel_amt = 1'b0;
        end
    end
end

always@(posedge clk_div_16 or posedge rst or posedge change_init)
begin
    if(rst == 1'b1 || change_init == 1'b1)
    begin
        flag_cancel = 1'b0;
        next_state = `INITIAL;
    end
    
    else
    begin
        if(state == `INITIAL)
        begin
            next_state = `DEPOSIT;
        end
            
        else if(state == `DEPOSIT)
        begin
            if(flag_check_dp == 1'b1)
                next_state = `AMOUNT;
                
            else if(flag_cancel_dp == 1'b1)
            begin
                flag_cancel = 1'b1;
                next_state = `CHANGE;
            end
            
            else
                next_state = `DEPOSIT;
        end
            
        else if(state == `AMOUNT)
        begin
            if(flag_check_amt == 1'b1)
            begin
                next_state = `RELEASE;
            end
                
            else if(flag_cancel_amt == 1'b1)
            begin
                flag_cancel = 1'b1;
                next_state = `CHANGE;
            end
                
            else
                next_state = `AMOUNT;
        end
        
        else if(state == `RELEASE)
        begin
            if(change_state == 1'b1)
                next_state = `CHANGE;
            
            else
                next_state = `RELEASE;
        end
        
        else if(state == `CHANGE)
        begin
            if(change_init == 1'b1)
                next_state = `INITIAL;
            
            else
                next_state = `CHANGE;
        end
    end
end

always@(posedge clk_div_16 or posedge rst or posedge change_init)
begin
    if(rst == 1'b1 || change_init == 1'b1)
    begin
        balance_digit1 <= 4'd0;
        balance_digit2 <= 4'd0;
        max <= 4'd0;
        init_max <= 4'd0;
        multiply <= 4'd0;
        
        amount_digit1 <= 4'd0;
        amount_digit2 <= 4'd0;
        amt_1 <= 4'd0;
        amt_2 <= 4'd0;
        
        money_digit1 <= 4'd0;
        money_digit2 <= 4'd0;
    end
    
    else
    begin
        if(state == `DEPOSIT)
        begin
            if(money_5_one_pulse == 1'b1)
            begin
                if(balance_digit1 == 4'd0 && balance_digit2 == 4'd5)
                begin
                    balance_digit1 <= balance_digit1;
                    balance_digit2 <= balance_digit2;
                    max <= 4'd9;
                    init_max <= 4'd9;
                end
                
                else if(balance_digit1 == 4'd5 && balance_digit2 == 4'd4)
                begin
                    balance_digit1 <= 4'd0;
                    balance_digit2 <= balance_digit2 + 4'd1;
                    max <= 4'd9;
                    init_max <= 4'd9;
                end
                
                else
                begin
                    if(balance_digit1 == 4'd0)
                    begin
                        balance_digit1 <= balance_digit1 + 4'd5;
                        max <= max + 4'd1;
                        init_max <= init_max + 4'd1;
                    end
                    
                    if(balance_digit1 == 4'd5)
                    begin
                        balance_digit1 <= 4'd0;
                        balance_digit2 <= balance_digit2 + 4'd1;
                        max <= max + 4'd1;
                        init_max <= init_max + 4'd1;
                    end
                end
            end
        
            else if(money_10_one_pulse == 1'b1)
            begin
                if((balance_digit1 == 4'd5 && balance_digit2 == 4'd4) || (balance_digit1 == 4'd0 && balance_digit2 == 4'd5))
                begin
                    balance_digit1 <= 4'd0;
                    balance_digit2 <= 4'd5;
                    max <= 4'd9;
                    init_max <= 4'd9;
                end
                
                else if(balance_digit1 == 4'd0 && balance_digit2 == 4'd4)
                begin
                    balance_digit1 <= balance_digit1;
                    balance_digit2 <= balance_digit2 + 4'd1;
                    max <= 4'd9;
                    init_max <= 4'd9;
                end
                
                else
                begin
                    balance_digit2 <= balance_digit2 + 4'd1;
                    max <= max + 4'd2;
                    init_max <= init_max + 4'd2;
                end
            end
        end
        
        if(state == `AMOUNT)
        begin
            if(count_down_one_pulse == 1'b1)
            begin
                if(max > 4'd1)
                    max <= max - 4'd1;
    
                else
                    max <= init_max;
            end
            
            else
                max <= max;
            
            //gets the price of the mask 
            if(max <= 4'd7)
            begin
                if(multiply != 4'd5)
                begin
                    if(amt_1 >= 4'd10)
                    begin
                        amt_1 <= amt_1 + max - 4'd10;
                        amt_2 <= amt_2 + 4'd1;
                        multiply <= multiply + 4'd1;
                    end
                    
                    else
                    begin
                        amt_1 <= max + amt_1;
                        amt_2 <= amt_2 + 4'd0;
                        multiply <= multiply + 4'd1;
                    end
                end
                
                else
                begin                
                    if(amt_1 >= 4'd10)
                    begin
                        amount_digit1 <= amt_1 - 4'd10;
                        amount_digit2 <= amt_2 + 4'd1;
                        amt_1 <= 4'd0;
                        amt_2 <= 4'd0;
                        multiply <= 4'd0;
                    end
                    
                    else
                    begin
                        amount_digit1 <= amt_1;
                        amount_digit2 <= amt_2;
                        amt_1 <= 4'd0;
                        amt_2 <= 4'd0;
                        multiply <= 4'd0;
                    end
                end
            end
                
            else if(4'd7 < max <= 4'd9)
            begin
                if(max == 4'd8)
                begin
                    amount_digit1 <= 4'd0;
                    amount_digit2 <= 4'd4;
                    amt_1 <= 4'd0;
                    amt_2 <= 4'd0;
                end
                
                else if(max == 4'd9)
                begin
                    amount_digit1 <= 4'd5;
                    amount_digit2 <= 4'd4;
                    amt_1 <= 4'd0;
                    amt_2 <= 4'd0;
                end
            end
            
            if(amount_digit1 == 4'd5 && balance_digit1 == 4'd0)
            begin
                money_digit1 <= 4'd5;
                money_digit2 <= balance_digit2 - 4'd1 - amount_digit2;
            end 
            
            else
            begin
                money_digit1 <= balance_digit1 - amount_digit1;
                money_digit2 <= balance_digit2 - amount_digit2;
            end
        end
    end
end

always@(posedge clk_div_27 or posedge rst or posedge change_init)
begin
    return_digit1 <= balance_digit1;
    return_digit2 <= balance_digit2;
    
    if(rst == 1'b1 || change_init == 1'b1)
    begin
        LED <= 16'd0;
        sec <= 4'd0;
        flag_buy <= 1'b0;
        change_state <= 1'b0;
        change_digit1 <= 4'd0;
        change_digit2 <= 4'd0;
        change_init <= 1'b0;
        return_digit1 <= 4'd0;
        return_digit2 <= 4'd0;
        flag_transition = 1'b0;
    end

    else
    begin
        if(state == `RELEASE)
        begin
            change_digit1 <= money_digit1;
            change_digit2 <= money_digit2;
            
            LED <= ~LED;
            sec <= sec + 4'd1;
            
            if(sec == 4'd5)
            begin
                flag_buy <= 1'b1;
                change_state <= 1'b1;
            end
        end
        
        if(state == `CHANGE)
        begin
            if(flag_cancel == 1'b0)
            begin
                if(change_digit1 == 4'd0 && change_digit2 == 4'd0)
                begin
                    change_digit1 <= 4'd0;
                    change_digit2 <= 4'd0;
                    change_init <= 1'b1;
                end
                
                else
                begin
                    if(change_digit1 == 4'd5 && change_digit2 == 4'd0)
                    begin
                        change_digit1 <= change_digit1 - 4'd5;
                    end
                        
                    else if(change_digit2 > 4'd0 && change_digit1 == 4'd5)
                    begin
                        if(change_digit2 == 4'd0)
                        begin
                            change_digit2 <= 4'd0;  
                            change_digit1 <= change_digit1 - 4'd5;
                        end
                        
                        else
                            change_digit2 <= change_digit2 - 4'd1;
                    end
                    
                    else if(change_digit2 > 4'd0 && change_digit1 == 4'd0)
                    begin
                        change_digit2 <= change_digit2 - 4'd1;
                    end
                end
            end
            
            else
            begin
                if(return_digit1 == 4'd0 && return_digit2 == 4'd0)
                begin
                    return_digit1 <= 4'd0;
                    return_digit2 <= 4'd0;
                    change_init <= 1'b1;
                end
                
                else
                begin
                    if(return_digit1 == 4'd5 && return_digit2 == 4'd0)
                    begin
                        return_digit1 <= return_digit1 - 4'd5;
                        return_digit2 <= 4'd0;
                    end
                        
                    else if(return_digit2 > 4'd0 && return_digit1 == 4'd5)
                    begin
                        if(return_digit2 == 4'd0)
                        begin
                            return_digit2 <= 4'd0;  
                            return_digit1 <= return_digit1 - 4'd5;
                        end
                        
                        else
                            return_digit2 <= return_digit2 - 4'd1;
                    end
                    
                    else if(return_digit2 > 4'd0 && return_digit1 == 4'd0)
                    begin
                        return_digit2 <= return_digit2 - 4'd1;
                    end
                end
            end
        end
    end
end  

always@(posedge clk_div_13)
begin
    if(state == `INITIAL)
    begin
        digit1 <= balance_digit1;
        digit2 <= balance_digit2;
        digit3 <= max;
        digit4 <= 4'd0;
    end
    
    else if(state == `DEPOSIT)
    begin
        digit1 <= balance_digit1;
        digit2 <= balance_digit2;
        digit3 <= max;
        digit4 <= 4'd0;
    end
    
    else if(state == `AMOUNT)
    begin
        digit1 <= balance_digit1;
        digit2 <= balance_digit2;
        digit3 <= max;
        digit4 <= 4'd0;
    end
    
    else if(state == `RELEASE)
    begin
        digit1 <= 4'd13;
        digit2 <= 4'd12;
        digit3 <= 4'd11;
        digit4 <= 4'd10;
    end
    
    else if(state == `CHANGE)
    begin
        digit1 <= (flag_cancel == 1'b0) ? change_digit1 : return_digit1;
        digit2 <= (flag_cancel == 1'b0) ? change_digit2 : return_digit2;
        digit3 <= 4'd0;
        digit4 <= 4'd0;
    end
    
    else
    begin
        digit1 <= 4'd0;
        digit2 <= 4'd0;
        digit3 <= 4'd0;
        digit4 <= 4'd0;
    end
    
end


always@(posedge clk_div_13)
begin
    case(refresher)
        2'b00:
        begin
            DIGIT <= 4'b1110;
            ACT_DIGIT <= digit1;
        end
        
        2'b01:
        begin
            DIGIT <= 4'b1101;
            ACT_DIGIT <= digit2;
        end
        
        2'b10:
        begin
            DIGIT <= 4'b1011;
            ACT_DIGIT <= digit3;          
        end
        
        2'b11: 
        begin
            DIGIT <= 4'b0111;
            ACT_DIGIT <= digit4;
        end
        
        default:
        begin
            DIGIT <= 4'b1110;
            ACT_DIGIT <= 4'd0;
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
        4'd10: DISPLAY <= 7'b1110000; //T
        4'd11: DISPLAY <= 7'b0000010; //A
        4'd12: DISPLAY <= 7'b0101000; //K
        4'd13: DISPLAY <= 7'b0110000; //E
        default: DISPLAY <= 7'b1111111;
    endcase
end
endmodule