`timescale 1ns/100ps

module lab1_1_t;

  reg a, b, c; 
  wire d, e;
  reg sub;
  reg pass;
  reg clk;

    lab1_1 full_adder(
    .e(e),
    .d(d),
    .a(a),
    .b(b),
    .c(c),
    .sub(sub)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b1;   
    pass = 1'b1;  
    {a, b, c, sub} = 4'd0;

    $display("Starting the simulation");

    repeat (2 ** 4) begin
      @ (posedge clk)
        test();
      @ (negedge clk)
        {a,b,c,sub} = {a,b,c,sub} + 4'b1;
    end

    $display("%g Terminating the simulation...", $time);

    if(pass)  $display(">>>> [PASS]  Congratulations!");
    else      $display(">>>> [ERROR] Try it again!");

    $finish;
  end
            
  task test; 
    begin
    if ((sub == 1 && {e,d} !== a + !b + c) || (sub == 0 && {e,d} !== a + b + c)) begin
        printerror;
      end
    end
  endtask

  task printerror;
    begin
    pass = 1'b0;
      $display($time," Error:  a = %b, b = %b, c = %b, d = %b, e = %b, sub = %b", a, b, c, d, e, sub);
    end
  endtask
endmodule
 
