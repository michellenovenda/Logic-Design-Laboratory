module lab2_1(
    input clk,
    input rst,
    input en,
    input dir,
    input load,
    input [5:0] data,
    output [3:0] out
    );    
    
    wire [5:0] data;
    wire rst, en, dir, load;
    reg [3:0] out;
    
    always@(posedge rst)
    begin
        if(rst == 1'b1)
            out = 4'b0000;
    end
    
    always@(negedge clk)
    begin
            if(en == 1'b0 && rst !== 1'b1)
                out = out;
    
            else if(en == 1'b1 && rst !== 1'b1)
            begin
                if(load == 1'b0)
                begin
                    if(dir == 1'b1)
                    begin
                        if(out == 4'b1100) begin
                            out = 4'b1100;
                        end
                            
                        else if(out < 4'b1100 && out >= 4'b0000) begin
                            out = (out + 4'b0001);
                        end
                    end //dir == 1'b1
                    
                    else if(dir == 1'b0)
                    begin
                        if(out == 4'b0000) begin
                            out = 4'b0000;
                        end
                            
                        else if(out > 4'b0000 && out <= 4'b1100) begin
                            out = (out - 4'b0001);
                        end
                    end //dir == 1'b0
                end //load == 1'b0
                
                else if(load == 1'b1)
                begin
                    if(data > 6'b001100)
                        out = 4'b1111; //print error, stays error until the next rst signal.
                    
                    else if(data <= 6'b001100)
                        out = data;
                end //load == 1'b1
            end //en == 1'b1
    end //negedge clk
    
endmodule