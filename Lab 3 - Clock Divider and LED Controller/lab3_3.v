module clock_divider_23(
    clk,
    clk_div_23
    );
    
    parameter n = 23;
    input clk;
    output clk_div_23;
    
    reg[22:0] num = 23'd0;
    wire [22:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_23 = (num == 4194304) ? 1'b1: 1'b0;
endmodule

module clock_divider_25(
    clk,
    clk_div_25
    );
    
    parameter n = 25;
    input clk;
    output clk_div_25;
    
    reg[24:0] num = 25'd0;
    wire [24:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_25 = (num == 16777216) ? 1'b1: 1'b0;
endmodule

module lab3_3(
    input clk,
    input rst,
    input en,
    input speed,
    output[15:0] led
);

    reg[15:0] mr1a = 16'b1000000000000000;
    reg[15:0] mr3 = 16'b0000111000000000;
    reg[15:0] mr1b = 16'b0000000000000001;
    
    wire clk_div_23;
    wire clk_div_25;
    
    wire rst;
    wire[15:0] led;
    
    //to determine the direction of the movements
    reg flag1a = 1'b0;
    reg flag1b = 1'b0;
    reg flag3 = 1'b0;

    //get the position of each runners
    //use this to determine the collision between mr1 and mr3
    reg[3:0] pos = 4'd10;
    reg[3:0] pos1a = 4'd15;
    reg[3:0] pos1b = 4'd0;
    
    clock_divider_23 clkdiv23(.clk(clk), .clk_div_23(clk_div_23));
    clock_divider_25 clkdiv25(.clk(clk), .clk_div_25(clk_div_25));
    
    always@(posedge clk or posedge rst)
    begin
        if(rst == 1'b1)
        begin
            mr1a <= 16'b1000000000000000;
            mr3 <= 16'b0000111000000000;
            mr1b <= 16'b0000000000000001;
            pos <= 4'd10;
            pos1a <= 4'd15;
            pos1b <= 4'd0;
            flag1a <= 1'b0;
            flag1b <= 1'b0;
            flag3 <= 1'b0;
        end //rst == 1'b1
        
        else if(rst == 1'b0 && en == 1'b0)
        begin
            mr1a <= mr1a;
            mr1b <= mr1b;
            mr3 <= mr3;
            pos <= pos;
            pos1a <= pos1a;
            pos1b <= pos1b;
        end //rst == 1'b0 && en == 1'b0
        
        else if(rst == 1'b0 && en == 1'b1)
        begin
            if(speed == 1'b0)
            begin
                if(clk_div_23 == 1'b1)
                begin
                    //movements
                    if(flag1a == 1'b0)
                    begin
                        mr1a <= mr1a >> 1;
                        pos1a <= pos1a - 4'd1;
                    end
                        
                    else if(flag1a == 1'b1)
                    begin
                        mr1a <= mr1a << 1;
                        pos1a <= pos1a + 4'd1;
                    end
                        
                    if(flag1b == 1'b0)
                    begin
                        mr1b <= mr1b << 1;
                        pos1b <= pos1b + 4'd1;
                    end
                    
                    else if(flag1b == 1'b1)
                    begin
                        mr1b <= mr1b >> 1;
                        pos1b <= pos1b - 4'd1;
                    end
                    
                    //collision to end for mr1a
                    if((mr1a[1] == 1'b1) && (flag1a == 1'b0))
                    begin
                        flag1a <= 1'b1;
                    end
                    
                    else if((mr1a[14] == 1'b1) && (flag1a == 1'b1))
                    begin
                        flag1a <= 1'b0;
                    end
                    
                    //collision to end for mr1b     
                    if((mr1b[1] == 1'b1) && (flag1b == 1'b1))
                    begin
                        flag1b <= 1'b0;
                    end   
                    
                    else if((mr1b[14] == 1'b1) && (flag1b == 1'b0))
                    begin
                        flag1b <= 1'b1;
                    end
                    
                    //collision of mr1 and mr3    
                    if((pos1a - pos == 4'd2) || (pos1a - pos == 4'd1) || (pos1a == pos))
                    begin
                        flag1a <= 1'b1;
                    end
                         
                    else if((pos - pos1b == 4'd2) || (pos - pos1b == 4'd1) || (pos == pos1b))
                    begin
                        flag1b <= 1'b1;
                    end
                end //clk_div_23 == 1'b1
                
                else if(clk_div_25 == 1'b1)
                begin
                    if(flag3 == 1'b0)
                    begin
                        mr3 <= mr3 << 1;
                        pos <= pos + 4'd1;
                        
                        //mr3 touch end
                        if(mr3[11] == 1'b1)
                        begin
                            mr3 <= mr3 >> 1;
                            flag3 <= 1'b1;
                            pos <= 4'd9;
                        end
                    end //flag3 == 1'b0
                        
                    else if(flag3 == 1'b1)
                    begin
                        mr3 <= mr3 >> 1;
                        pos <= pos - 4'd1;
                        
                        //mr3 touch end
                        if(mr3[4] == 1'b1)
                        begin
                            mr3 <= mr3 << 1;
                            flag3 <= 1'b0;
                            pos <= 4'd6;
                        end
                    end //flag3 == 1'b1
                end //clk_div_25 == 1'b1
            end //speed == 1'b0
            
            else if(speed == 1'b1)
            begin
                if(clk_div_25 == 1'b1)
                begin
                    //movements
                    if(flag1a == 1'b0)
                    begin
                        mr1a <= mr1a >> 1;
                        pos1a <= pos1a - 4'd1;
                    end
                        
                    else if(flag1a == 1'b1)
                    begin
                        mr1a <= mr1a << 1;
                        pos1a <= pos1a + 4'd1;
                    end
                        
                    if(flag1b == 1'b0)
                    begin
                        mr1b <= mr1b << 1;
                        pos1b <= pos1b + 4'd1;
                    end
                    
                    else if(flag1b == 1'b1)
                    begin
                        mr1b <= mr1b >> 1;
                        pos1b <= pos1b - 4'd1;
                    end
                    
                    //collision to end for mr1a
                    if((mr1a[1] == 1'b1) && (flag1a == 1'b0))
                    begin
                        flag1a <= 1'b1;
                    end
                            
                    else if((mr1a[14] == 1'b1) && (flag1a == 1'b1))
                    begin
                        flag1a <= 1'b0;
                    end
                    
                    //collision to end for mr1b        
                    if((mr1b[1] == 1'b1) && (flag1b == 1'b1))
                    begin
                        flag1b <= 1'b0;
                    end
                            
                    else if((mr1b[14] == 1'b1) && (flag1b == 1'b0))
                    begin
                        flag1b <= 1'b1;
                    end
                    
                    //collision of mr1 and mr3     
                    if((pos1a - pos == 4'd2) || (pos1a - pos == 4'd1) || (pos1a == pos))
                    begin
                        flag1a <= 1'b1;
                    end
                         
                    else if((pos - pos1b == 4'd2) || (pos - pos1b == 4'd1) || (pos == pos1b))
                    begin
                        flag1b <= 1'b1;
                    end
                end //clk_div_25
                
                else if(clk_div_23 == 1'b1)
                begin
                    if(flag3 == 1'b0)
                    begin
                        mr3 <= mr3 << 1;
                        pos <= pos + 4'd1;
                        
                        //mr3 touch end
                        if(mr3[11] == 1'b1)
                        begin
                            mr3 <= mr3 >> 1;
                            flag3 <= 1'b1;
                            pos <= 4'd9;
                        end
                    end //flag3 == 1'b0
                        
                    else if(flag3 == 1'b1)
                    begin
                        mr3 <= mr3 >> 1;
                        pos <= pos - 4'd1;
                        
                        //mr3 touch end
                        if(mr3[4] == 1'b1)
                        begin
                            mr3 <= mr3 << 1;
                            flag3 <= 1'b0;
                            pos <= 4'd6;
                        end
                    end //flag3 == 1'b1
                end //clk_div_23 == 1'b1
            end //speed == 1'b1
        end //rst == 1'b0 && en == 1'b1
    end //posedge clk
    
    assign led = (mr1a | mr1b | mr3);
endmodule