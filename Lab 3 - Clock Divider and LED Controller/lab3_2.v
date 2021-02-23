module clock_divider_23(
    clk,
    clk_div23
    );
    
    parameter n = 23;
    input clk;
    output clk_div23;
    
    reg[22:0] num = 23'd0;
    wire [22:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div23 = (num == 4194304) ? 1'b1: 1'b0;
endmodule

module clock_divider_25(
    clk,
    clk_div25
    );
    
    parameter n = 25;
    input clk;
    output clk_div25;
    
    reg[24:0] num = 25'd0;
    wire [24:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div25 = (num == 16777216) ? 1'b1: 1'b0;
endmodule

module lab3_2(
    input clk,
    input rst,
    input en,
    input speed,
    output[15:0] led
);
    
    reg[15:0] mr1 = 16'b1000000000000000;
    reg[15:0] mr3 = 16'b0000000000000111;
    
    wire clk_div_23;
    wire clk_div_25;
    
    wire rst;
    wire[15:0] led;
    
    clock_divider_23 clkdiv23(.clk(clk), .clk_div23(clk_div_23));
    clock_divider_25 clkdiv25(.clk(clk), .clk_div25(clk_div_25));
    
    always@(posedge clk or posedge rst)
    begin
        if(rst == 1'b1)
        begin
            mr1 <= 16'b1000000000000000;
            mr3 <= 16'b0000000000000111;
        end
        
        else if(rst == 1'b0 && en == 1'b0)
        begin
            mr1 <= mr1;
            mr3 <= mr3;
        end
        
        else if(rst == 1'b0 && en == 1'b1)
        begin
            if((speed == 1'b0 && clk_div_23 == 1'b1) || (speed == 1'b1 && clk_div_25 == 1'b1))
            begin
                mr1 <= mr1 >> 1;
                                                
                if(mr1[0] == 1'b1)
                begin
                    mr1[15] <= 1'b1;
                end
            end
            
            else if((speed == 1'b1 && clk_div_23 == 1'b1) || (speed == 1'b0 && clk_div_25 == 1'b1))
            begin
                mr3 <= mr3 << 1;
                        
                if(mr3[15] == 1'b1)
                begin
                    mr3[0] <= 1'b1;
                end
            end
        end
    end
    
    assign led = (mr1 | mr3);
endmodule
