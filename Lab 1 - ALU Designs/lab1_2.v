`timescale 1ns / 1ps

module lab1_2(a, b, sub, d);
    input[3:0] a, b;
    input sub;
    output[3:0] d;
    wire c0, c1, c2, c3;
    wire[3:0] a, b;
    wire sub;
    wire[3:0] d;
    
    lab1_1 full_adder(.a(a[0]), .b(b[0]), .c(sub), .sub(sub), .d(d[0]), .e(c0));
    lab1_1 full_adder_1(.a(a[1]), .b(b[1]), .c(c0), .sub(sub), .d(d[1]), .e(c1));
    lab1_1 full_adder_2(.a(a[2]), .b(b[2]), .c(c1), .sub(sub), .d(d[2]), .e(c2));
    lab1_1 full_adder_3(.a(a[3]), .b(b[3]), .c(c2), .sub(sub), .d(d[3]), .e(c3));
    
endmodule

