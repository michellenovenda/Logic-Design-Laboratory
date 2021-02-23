`timescale 1ns / 1ps

module lab2_2_t;
    reg clk, rst;
    reg pass;
    reg flag;
    reg [7:0] fn_test;
    reg [7:0] f1_test;
    
    lab2_2 counter (
    .clk(clk), 
    .rst(rst),
    .fn(fn)
    );

    wire[7:0] fn;
    
    initial clk = 0;
    always #5 clk = ~clk;
    always #470 rst = ~rst;
    
    initial
    begin
        pass = 1'b1;
        flag = 1'b0;
        f1_test = 8'b00000000;
        fn_test = 8'b00000001;
        rst = 1'b0;
        #10 rst = ~rst;
        #10 rst = ~rst;
        
        $display("Starting the simulation");
//        $monitor("fn = %d\n", fn);
        
        repeat(2**8) begin
            @(negedge clk)
                test();
                
            @(posedge clk)
            begin
            if(!rst)
                begin
                    if(fn_test == 8'd233 && f1_test == 8'd144)
                        flag = 1'b1;
                        
                    else if(fn_test == 8'd1 && f1_test == 8'd0)
                    begin
                        flag <= 1'b0;
                        fn_test <= 8'd1;
                        f1_test <= 8'd0;
                    end 
                    
                    if(flag == 1'b0) begin  
                        fn_test <= fn_test + f1_test;
                        f1_test <= fn_test;
                    end
                    
                    else if(flag == 1'b1 && f1_test > 8'd0) begin
                        fn_test <= f1_test;
                        f1_test <= fn_test-f1_test;
                    end
                end
                
                else if(rst)
                begin
                    fn_test <= 8'd1;
                    f1_test <= 8'd0;
                end
            end
        end

        $display("%g Terminating simulation...", $time);
        
        if(pass)
            $display(">>>> [PASS] Congratulations!");
        else
            $display(">>>> [ERROR] Try it again!");
        $finish;
    end
    
    task test;
    begin
        if(fn !== fn_test)
            printerror();
            
        else if(1 >= fn && fn >= 233)
            printerror();
    end
    endtask
    
    task printerror;
    begin
        pass = 1'b0;
        $display($time," Error: fn=%d\n", fn);
    end
    endtask
endmodule