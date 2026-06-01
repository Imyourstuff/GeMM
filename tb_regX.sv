`timescale 1ns/1ps
module tb_regX();
    parameter WIDTH = 8;
    reg clk, reset;
    reg [WIDTH-1:0] d_in;
    wire [WIDTH-1:0] q_out;

    regX #(.WIDTH(WIDTH)) dut (.clk(clk), .reset(reset), .d_in(d_in), .q_out(q_out));

    initial begin clk=0; forever #5 clk=~clk; end
    initial begin $dumpfile("tb_regX.vcd"); $dumpvars(0, tb_regX); end

    initial begin
        $display("RegX");
        reset=1; d_in=0; #10; reset=0; #10;
        
        d_in=8'd42; #10;
        if(q_out !== 8'd42) $error("FAIL!", q_out);
        else $display("PASS: Writing data!");
        
        reset=1; #10;
        if(q_out !== 8'd0) $error("FAIL: Reset");
        else $display("PASS: Reset");
        
        $display("regX OK\n"); $finish;
    end
endmodule