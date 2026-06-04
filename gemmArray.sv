module gemmArray #(
    parameter WIDTH = 32,
    parameter N = 16,
    parameter ACC_WIDTH = 2*WIDTH + $clog2(N),
    parameter MODE = 0
)(
    input logic                     clk,
    input logic                     reset,

    input logic [WIDTH-1:0]         a_in,
    input logic [WIDTH-1:0]         b_in_1, //Для левой половины
    input logic [WIDTH-1:0]         b_in_3, //Для правой
    input logic [ACC_WIDTH-1:0]     c_in,

    input logic                     alpha,
    input logic                     beta,

    output logic [ACC_WIDTH-1:0]    c_out
);
    logic [WIDTH-1:0]       a_chain [0:N];
    logic [ACC_WIDTH-1:0]   c_chain [0:N];
    logic                   alpha_chain [0:N];
    logic                   beta_chain  [0:N];

    //Разделим логику на два потока. Для левой и правой половины
    //заведём разные наборы соединений и generate для наглядности
    logic [WIDTH-1:0]       b_chain_left  [0:N/2];
    logic [WIDTH-1:0]       b_chain_right [N/2:N];

    assign a_chain[0]     = a_in;
    assign c_chain[0]     = c_in;
    assign alpha_chain[0] = alpha;
    assign beta_chain[0]  = beta;

    //Проверить индексы.
    assign b_chain_left[0]  = b_in_1;
    assign b_chain_right[N] = b_in_3;

    generate
        genvar i;
        for (i = 0; i< N/2; i = i + 1) begin : gen_left
            processingElement #(
                .WIDTH     (WIDTH),
                .N         (N),
                .ACC_WIDTH (ACC_WIDTH),
                .MODE      (0),
                .ID        (i)
            ) u_pe_left (
                .clk      (clk),
                .reset    (reset),
                .alpha    (alpha_chain[i]),
                .beta     (beta_chain[i]),
                .a        (a_chain[i]),
                .b        (b_chain_left[i]),
                .c        (c_chain[i]),
                
                .a_j2     (a_chain[i+1]),
                .c_j1     (c_chain[i+1]),
                .b_j2     (b_chain_left[i+1]),
                .alpha_j1 (alpha_chain[i+1]),
                .beta_j1  (beta_chain[i+1])
            );
        end
    endgenerate

    generate
        genvar j;
        for (j = N/2; j < N; j = j + 1) begin : gen_right
            processingElement #(
                .WIDTH     (WIDTH),
                .N         (N),
                .ACC_WIDTH (ACC_WIDTH),
                .MODE      (0),
                .ID        (j)
            ) u_pe_right (
                .clk      (clk),
                .reset    (reset),
                .alpha    (alpha_chain[j]),
                .beta     (beta_chain[j]),
                .a        (a_chain[j]),
                .b        (b_chain_right[j+1]), //Проверить
                .c        (c_chain[j]),
                
                .a_j2     (a_chain[j+1]),
                .c_j1     (c_chain[j+1]),
                .b_j2     (b_chain_right[j]), //Проверить
                .alpha_j1 (alpha_chain[j+1]),
                .beta_j1  (beta_chain[j+1])
            );
        end
    endgenerate

    assign c_out = c_chain[N];
endmodule