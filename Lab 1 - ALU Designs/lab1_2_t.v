`timescale 1ns/100ps

module lab1_2_t;

  reg [3:0] a;
  reg [3:0] b;
  wire [3:0] d;
  reg sub;
  reg pass;
  reg clk;

  lab1_2 bit_adder(
  .a(a),
  .b(b),
  .d(d),
  .sub(sub)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b1;
    {a, b, sub} = 9'd0;
    pass = 1'b1;

    $display("Starting the simulation");

    repeat (2**9) begin
      @ (posedge clk)
        test();
        
      @ (negedge clk)
        {a,b,sub} = {a,b,sub} + 1'b1;
    end

    $display("%g Terminating simulation...", $time);
    if (pass) $display(">>>> [PASS]  Congratulations!");
    else      $display(">>>> [ERROR] Try it again!");
    $finish;
  end
            
  task test; 
    begin
      if ((sub == 1 && d !== a - b) || (sub == 0 && d !== a + b)) begin
        printerror;
      end
    end
  endtask

  task printerror;
    begin
      pass = 1'b0;
      $display($time," Error:  a = %b, b = %b, d = %b, sub = %b", a, b, d, sub);
    end
  endtask
endmodule