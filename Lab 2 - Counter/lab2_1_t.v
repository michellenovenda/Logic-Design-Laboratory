`timescale 1ns / 1ps

module lab2_1_t;
    reg clk, rst, en, dir, load;
    reg [5:0] data;
    wire [3:0] out;
    reg [6:0] op;
    reg [3:0] check_out;
    
    reg pass;
    
    lab2_1 counter (
    .clk(clk), 
    .rst(rst), 
    .en(en), 
    .dir(dir), 
    .load(load), 
    .data(data), 
    .out(out)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    always #720 rst = ~rst;
    
    initial
    begin
        warmUp();

        $display("Starting the simulation");
//        $monitor("%g\trst=%b\ten=%b\tload=%b\tdir=%b\tdata=%b\tout=%b\n",$time, rst, en, load, dir, data, out);

        repeat(2**10)
        begin
            @(negedge clk)
            begin
               data = data + 6'b000001;
               op = op - 7'b0000001;
               en = op[6];
               load = op[5];
               dir = op[4];
               
                    if(en == 1'b0 && rst !== 1'b1)
                        check_out = check_out;
    
                    else if(en == 1'b1 && rst !== 1'b1)
                    begin
                        if(load == 1'b0)
                        begin
                            if(dir == 1'b1)
                            begin
                                if(check_out == 4'b1100) begin
                                    check_out = 4'b1100;
                                end
                                    
                                else if(check_out < 4'b1100 && check_out >= 4'b0000) begin
                                    check_out = check_out + 4'b0001;
                                end
                            end //dir == 1'b1
                            
                            else if(dir == 1'b0)
                            begin
                                if(check_out == 4'b0000) begin
                                    check_out = 4'b0000;
                                end
                                    
                                else if(check_out > 4'b0000 && check_out <= 4'b1100) begin
                                    check_out = (check_out - 4'b0001);
                                end
                            end //dir == 1'b0
                        end //load == 1'b0
                        
                        else if(load == 1'b1)
                        begin
                            if(data > 6'b001100) begin
                                check_out = 4'b1111; //print error, stays error until the next rst signal.
                            end
                            
                            else if(data <= 6'b001100) begin
                                check_out = data;
                            end
                        end //load == 1'b1
                    end //en == 1'b1
                    
                    else if(rst == 1'b1)
                        check_out = 4'b0000;
            end
                
            @(posedge clk)
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
        if(check_out !== out)
             printerror;
        end
     endtask
     
     task printerror;
     begin
        pass = 1'b0;
        $display(" Error: rst=%b, en=%b, load=%b, dir=%b, data=%b, out=%b\n", rst, en, load, dir, data, out);
     end
     endtask
     
     task warmUp;
     begin
        rst = 1'b0;
        op = 7'b1111111;
        en = op[6];
        load = op[5];
        dir = op[4];
        data = 6'b000000;
        check_out = 4'b0000;
        pass = 1'b1;
     end
     endtask
     
endmodule