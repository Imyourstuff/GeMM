`timescale 1ns/1ps

module tb_gemmArray;

    localparam WIDTH = 8;
    localparam N = 4;
    localparam ACC_WIDTH = 2*WIDTH + $clog2(N);

    logic clk;
    logic reset;

    logic [WIDTH-1:0] a_in;
    logic [WIDTH-1:0] b_in_1;
    logic [WIDTH-1:0] b_in_3;

    logic [ACC_WIDTH-1:0] c_in;
    logic beta;
    logic alpha;

    logic [ACC_WIDTH-1:0] c_out;
    logic valid;
    logic done;

    int tick = 0;

    //хардкодим матрицу b
    logic [WIDTH-1:0] b1 [0:3];
    logic [WIDTH-1:0] b2 [0:3];
    logic [WIDTH-1:0] b3 [0:3];
    logic [WIDTH-1:0] b4 [0:3];

    logic [WIDTH-1:0] a1 [0:3];
    logic [WIDTH-1:0] a2 [0:3];
    logic [WIDTH-1:0] a3 [0:3];
    logic [WIDTH-1:0] a4 [0:3];

    initial begin 
        #10;
        $display("Load values!");
        b1[0] = 1; b1[1] = 2; b1[2] = 3; b1[3] = 4;
        b2[0] = 1; b2[1] = 2; b2[2] = 3; b2[3] = 4;
        b3[0] = 1; b3[1] = 2; b3[2] = 3; b3[3] = 4;
        b4[0] = 1; b4[1] = 2; b4[2] = 3; b4[3] = 4;

        a1[0] = 1; a1[1] = 2; a1[2] = 0; a1[3] = 1;
        a2[0] = 2; a2[1] = 1; a2[2] = 0; a2[3] = 0;
        a3[0] = 0; a3[1] = 0; a3[2] = 1; a3[3] = 2;
        a4[0] = 1; a4[1] = 0; a4[2] = 2; a4[3] = 1;
        $display("Loaded values!");
        #10;
    end

    gemmArray #(
        .WIDTH(WIDTH),
        .N(N),
        .ACC_WIDTH(ACC_WIDTH)
    ) array (
        .clk(clk),
        .reset(reset),
        .a_in(a_in),
        .b_in_1(b_in_1),
        .b_in_3(b_in_3),
        .c_in(c_in),
        .alpha(alpha),
        .beta(beta),
        .c_out(c_out)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    always @(posedge clk) begin
        if (!reset)
            tick <= tick + 1;
    end

    initial begin
        //Инициализация
        #20;
        $display("Reset all...");
        reset = 1;
        a_in = 0;
        c_in = 0;
        b_in_1 = 0;
        b_in_3 = 0;
        alpha = 0;
        beta = 0;
        #20;
        reset = 0;
        #20;
    end

    //Поток для входа 1.
    initial begin
        #60;
        $display("First values for ONE.");
        b_in_1 <= b2[0];
        #10;
 
        $display("First 3");
        for (integer i = 0; i < 3; i = i + 1) begin
            a_in <= a1[3-i];
            b_in_1 <= b2[i+1];
            #10;
        end

        //Такт 4, начало загрузки
        $display("Tact 4");
        alpha <= 1;
        beta <= 1;
        a_in <= a1[0];
        b_in_1 <= b1[0];
        c_in = 0;
        #10;

        // Три такта вычислений, b дозагружается
        $display("Last 3");
        for (integer i = 0; i < 3; i = i + 1) begin
            alpha <= 1;
            beta <= 0;
            a_in <= a2[3-i];
            b_in_1 <= b1[i+1];
            #10;
        end

        #300;
        $finish;
    end

    //Поток для входа 3
    initial begin 
        #100;
        b_in_3 <= b3[0];
        #10;
        for (integer i = 0; i < 3; i = i + 1) begin
            b_in_3 <= b3[i+1];
            #10;
        end
    end

    always @(posedge clk) begin
    if (!reset && valid) 
        $display("tick=%0d: c_out=%0d", tick, c_out);
    end

    initial begin
        $dumpfile("tb_gemmArray.vcd");
        $dumpvars(0, tb_gemmArray);
    end

endmodule