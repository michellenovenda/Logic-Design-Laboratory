`timescale 1ns / 1ps

module lab1_1(a, b, c, sub, d, e);
    input a, b, c;
    input sub;
    output d, e;
    wire a, b, c;
    wire sub;
    wire d, e;
    
    wire xor_a_b;
    wire xor_sub_b;
    wire and_ab_c;
    wire and_a_b;
    
    xor xor1(xor_sub_b, sub, b);
    xor xor2(xor_a_b, a, xor_sub_b);
    xor xor3(d, xor_a_b, c);
    
    and and1(and_ab_c, xor_a_b, c);
    and and2(and_a_b, a, xor_sub_b);
    or or1(e, and_ab_c, and_a_b);
    
endmodule
