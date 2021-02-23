`timescale 1ns/100ps

module lab1_3(a, b, aluctr, d);
    input[3:0] a,b;
    input[1:0] aluctr;
    output[3:0] d;
    wire[3:0] d1;
    reg[3:0] d;
    
    lab1_2 bit_adder(.a(a), .b(b), .sub(aluctr[0]), .d(d1));
    
     always@(*)
        begin
            if(aluctr == 2'b00)
                d = d1;
            else if(aluctr == 2'b01)
                d = d1;
            else if(aluctr == 2'b10)
                d = a & b;
            else
                d = a ^ b;
        end
endmodule