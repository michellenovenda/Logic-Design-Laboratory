module lab2_3_t;
    reg clk, rst;
    wire[7:0] out;
    reg pass;
    
    reg[7:0] bin_ctr;
    
    lab2_3 counter (
    .clk(clk),
    .rst(rst),
    .out(out));
    
    initial clk = 0;
    always #5 clk = ~clk;
    always #2560 rst = ~rst;
    
    initial
    begin
        warmUp();
        
        clk = 1'b1;
        pass = 1'b1;
        
        $display("Starting the simulation");
//        $monitor("bin_ctr=%b\tout = %b\n", bin_ctr, out);
        
        repeat(2**8) begin
            @(posedge clk)
                bin_ctr = bin_ctr + 8'b00000001;
        
            @(negedge clk)
            begin
                test();
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
        if(out[7] !== bin_ctr[7] ||
        out[6] !== bin_ctr[7] ^ bin_ctr[6] ||
        out[5] !== bin_ctr[6] ^ bin_ctr[5] ||
        out[4] !== bin_ctr[5] ^ bin_ctr[4] ||
        out[3] !== bin_ctr[4] ^ bin_ctr[3] ||
        out[2] !== bin_ctr[3] ^ bin_ctr[2] ||
        out[1] !== bin_ctr[2] ^ bin_ctr[1] ||
        out[0] !== bin_ctr[1] ^ bin_ctr[0])
            printerror();
            
        else if(rst == 1'b1 && out !== 8'b00000000)
            printerror();
    end
    endtask
    
    task printerror;
    begin
        pass = 1'b0;
        $display($time," Error: bin_ctr=%b, out=%b\n", bin_ctr, out);
    end
    endtask
    
    task warmUp;
     begin
        rst = 1'b0;
        bin_ctr = 8'b00000000;
     end
     endtask
    
endmodule