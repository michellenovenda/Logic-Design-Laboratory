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

module lab3_1(clk, rst, en, dir, led);
    input clk;
    input rst;
    input en;
    input dir;
    output [15:0] led;    
 
    wire clk;
    wire clk_div;
    wire rst;
    wire en;
    wire dir;
    reg[15:0] led = 16'b1000000000000000;

    clock_divider clkdiv(.clk(clk), .clk_div(clk_div));

    always@(posedge clk_div or posedge rst)
    begin
        if(rst == 1'b1)
        begin
            led <= 16'b1000000000000000;
        end
        
        else if(rst == 1'b0)
        begin
            if(en == 1'b0)
            begin
                led <= led;
            end
            
            else if(en == 1'b1 && dir == 1'b0)
            begin
                led <= led >> 1;
                
                if(led[0] == 1'b1)
                begin
                    led[0] <= 1'b0;
                    led[15] <= 1'b1;
                end    
            end
            
            else if(en == 1'b1 && dir == 1'b1)
            begin
                led <= led << 1;
                
                if(led[15] == 1'b1)
                begin
                    led[15] <= 1'b0;
                    led[0] <= 1'b1;
                end
            end
        end
    end
endmodule