module lab2_2 (
    input clk,
    input rst,
    output[7:0] fn
    );
    
    reg[7:0] fn;
    reg[7:0] f1;
    reg flag = 1'b0;

    always @(posedge clk)
    begin
        if(!rst)
        begin
            if(fn == 8'd233 && f1 == 8'd144)
                flag = 1'b1;
                
            else if(fn == 8'd1 && f1 == 8'd0)
            begin
                flag <= 1'b0;
                fn <= 8'd1;
                f1 <= 8'd0;
            end 
            
            if(flag == 1'b0) begin  
                fn <= fn + f1;
                f1 <= fn;
            end
            
            else if(flag == 1'b1 && f1 > 8'd0) begin
                fn <= f1;
                f1 <= fn-f1;
            end
        end
        
        else if(rst)
        begin
            fn <= 8'd1;
            f1 <= 8'd0;
        end
    end
endmodule