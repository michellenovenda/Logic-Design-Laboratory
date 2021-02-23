module Divide(  
    input clk,  
    input reset,  
    input start,  
    input [31:0] A,  
    input [31:0] B,  
    output [31:0] D,  
    output [31:0] R,  
    output ok,   // =1 when ready to get the result   
    output err  
);  

    reg active;   
    reg [4:0] cycle;  
    reg [31:0] result;  
    reg [31:0] denom;   
    reg [31:0] work;   
    wire [32:0] sub = {work[30:0], result[31]} - denom; 
     
    assign err = !B;  
    assign D = result;  
    assign R = work;  
    assign ok = ~active;

    always @(posedge clk,posedge reset) begin  
        if (reset) begin  
            active <= 0;  
            cycle <= 0;  
            result <= 0;  
            denom <= 0;  
            work <= 0;  
        end  
        else if(start) begin  
            if (active) begin  
                if (sub[32] == 0) begin  
                    work <= sub[31:0];  
                    result <= {result[30:0], 1'b1};  
                end  
                else begin  
                    work <= {work[30:0], result[31]};  
                    result <= {result[30:0], 1'b0};  
                end  
                
                if (cycle == 0) begin  
                    active <= 0;  
                end  
                cycle <= cycle - 5'd1;  
            end  
            else begin  
                cycle <= 5'd31;  
                result <= A;  
                denom <= B;  
                work <= 32'b0;  
                active <= 1;  
            end  
        end  
    end  
endmodule  
