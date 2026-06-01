`timescale 1ns/1ps
module tb_sumAcc;
    parameter WIDTH = 8;
    parameter N = 4;
    parameter ACC_WIDTH = 18; // 2*8 + log2(4)
    parameter MODE = 0;
    
    reg [2*WIDTH-1:0] in_x;
    reg [ACC_WIDTH-1:0] in_accum;
    wire [ACC_WIDTH-1:0] out;

    sumAcc #(.WIDTH(WIDTH), .N(N), .ACC_WIDTH(ACC_WIDTH), .MODE(MODE)) dut (
        .in_x(in_x), .in_accum(in_accum), .out(out));

    initial begin $dumpfile("tb_sumAcc.vcd"); $dumpvars(0, tb_sumAcc); end

    initial begin
        $display("=== Тест sumAcc (ACC_WIDTH=%0d) ===", ACC_WIDTH);
        
        in_x=16'd50; in_accum=18'd100; #1;
        if(out !== 18'd150) $error("FAIL: 50+100"); else $display("PASS: 50+100=150");
        
        in_x=0; in_accum=0; #1;
        if(out !== 0) $error("FAIL: 0+0"); else $display("PASS: 0+0=0");
        
        in_x=16'd1000; in_accum=18'd5000; #1;
        if(out !== 18'd6000) $error("FAIL: Large sum"); else $display("PASS: 1000+5000=6000");
        
        $display("sumAcc OK\n"); $finish;
    end
endmodule