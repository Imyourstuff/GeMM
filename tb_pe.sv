`timescale 1ns/1ps

module tb_pe;
    localparam WIDTH = 8;
    localparam N = 2;
    localparam ACC_WIDTH = 2 * WIDTH + $clog2(N); // 18 бит
    localparam MODE = 0;  // 0 = unsigned, 1 = signed
    localparam ID = 0;

    logic                       clk;
    logic                       reset;
    logic                       alpha;
    logic                       beta;
    logic [WIDTH-1:0]           a;
    logic [WIDTH-1:0]           b;
    logic [ACC_WIDTH-1:0]       c;

    logic [WIDTH-1:0]           a_j2;
    logic [WIDTH-1:0]           b_j2;
    logic                       alpha_j1;
    logic                       beta_j1;
    logic [ACC_WIDTH-1:0]       c_j1;

    processingElement #(
        .WIDTH(WIDTH),
        .N(N),
        .ACC_WIDTH(ACC_WIDTH),
        .MODE(MODE),
        .ID(ID)
    ) pe (
        .clk      (clk),
        .reset    (reset),
        .alpha    (alpha),
        .beta     (beta),
        .a        (a),
        .b        (b),
        .c        (c),
        .a_j2     (a_j2),
        .b_j2     (b_j2),
        .alpha_j1 (alpha_j1),
        .beta_j1  (beta_j1),
        .c_j1     (c_j1)
    );

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    initial begin
        $display("PE TestBench start.");
        $display("Parameters: WIDTH=%0d, N=%0d, ACC_WIDTH=%0d, MODE=%0d, ID=%0d",
                 WIDTH, N, ACC_WIDTH, MODE, ID);

        $display("=== FLUSH PHASE ===");
        reset = 1; #20; reset = 0; #10;

        // Прогон нулей для очистки конвейера
        alpha = 0; beta = 0; a = 0; b = 0; c = 0;
        for (integer i = 0; i < 10; i++) begin
            #10;
        end

        #2;
        reset = 0;
        #1;

        //Init + load new A and B with t=(1,1)
        $display("\n1. Init + load new A and B with t=(1,1).");
        alpha = 1; 
        beta = 1;
        a = 8'd10; 
        b = 8'd5; 
        c = 18'd0;
        #2;
        $display("  Input: a=%0d, b=%0d, c=%0d | α=%b, β=%b", a, b, c, alpha, beta);
        $display("  Output: a_j2=%0d, b_j2=%0d, c_j1=%0d", a_j2, b_j2, c_j1);

        //Test t=(1,0), A is reused, B is loaded
        $display("\n2. Test t=(1,0), A is reused, B is loaded.");
        alpha = 1; 
        beta = 0;
        a = 8'd20;  //Should not be in R5
        b = 8'd3;
        c = 18'd50; //Accumulated summ
        #2;
        $display("  Input: a=%0d (ignored), b=%0d, c=%0d | α=%b, β=%b", a, b, c, alpha, beta);

        //Cyclical B, new A is loaded. t = (0,1)
        $display("\n3. Cyclical B, new A is loaded. t = (0,1)");
        alpha = 0; 
        beta = 1;
        a = 8'd7;
        b = 8'd0;  //Ignored, taking old
        c = 18'd100;
        #2;
        $display("  Input: a=%0d, b=%0d (Ignored), c=%0d | α=%b, β=%b", a, b, c, alpha, beta);

        //Cyclical B + old A, t = (0,0)
        $display("\n[Тест 4] Режим (α,β)=(0,0) — полное переиспользование");
        alpha = 0; 
        beta = 0;
        a = 8'd99;  // Ignored
        b = 8'd99;  // Ignored
        c = 18'd200;
        #2;
        $display("  Input: a=%0d, b=%0d (Ignored), c=%0d | α=%b, β=%b", a, b, c, alpha, beta);


        #40;
        $display("\nFinished!");
        $finish;
    end

    //initial begin
    //    $dumpfile("tb_pe_waveform.vcd");
    //    $dumpvars();
    //end

endmodule