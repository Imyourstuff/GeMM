`timescale 1ns/1ps
module tb_mult;
    parameter WIDTH = 8;
    parameter MODE = 0; // 0=unsigned, 1=signed
    reg [WIDTH-1:0] in_x, in_y;
    wire [2*WIDTH-1:0] out;

    mult #(.WIDTH(WIDTH), .MODE(MODE)) multiply (.in_x(in_x), .in_y(in_y), .out(out));

    initial begin $dumpfile("tb_mult.vcd"); $dumpvars(0, tb_mult); end

    initial begin
        $display("=== Тест mult (MODE=%0d) ===", MODE);
        
        in_x=8'd10;
        in_y=8'd5; #1;
        if(out !== 16'd50) 
            $error("FAIL: 10*5"); else $display("PASS: 10*5=50");
        
        in_x=8'd255; 
        in_y=8'd1; #1;
        if(out !== 16'd255) 
            $error("FAIL: 255*1"); else $display("PASS: 255*1=255");
        
        in_x=8'd128; 
        in_y=8'd128; #1;
        if(out !== 16'd16384) 
            $error("FAIL: 128*128"); else $display("PASS: 128*128=16384");
        
        $display("mult OK\n"); $finish;
    end
endmodule