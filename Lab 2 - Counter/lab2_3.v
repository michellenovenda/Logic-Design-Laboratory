module lab2_3(
    input clk,
    input rst,
    output[7:0] out
    );
    
    reg[7:0] out = 8'b00000000;
    reg[7:0] bin_ctr = 8'b00000000;
    
    always @(posedge clk)
    begin
        if(!rst)
        begin
            bin_ctr <= bin_ctr + 8'b00000001;
        
            out[7] <= bin_ctr[7];
            out[6] <= bin_ctr[7] ^ bin_ctr[6];
            out[5] <= bin_ctr[6] ^ bin_ctr[5];
            out[4] <= bin_ctr[5] ^ bin_ctr[4];
            out[3] <= bin_ctr[4] ^ bin_ctr[3];
            out[2] <= bin_ctr[3] ^ bin_ctr[2];
            out[1] <= bin_ctr[2] ^ bin_ctr[1];
            out[0] <= bin_ctr[1] ^ bin_ctr[0];
        end
        
        else if(rst)
        begin
            out <= 8'b00000000;
            bin_ctr <= 8'b00000000;
        end
    end 
endmodule