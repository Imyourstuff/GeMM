module gemmArray #(
    parameter WIDTH = 8,
    parameter N = 4,
    parameter ACC_WIDTH = 2*WIDTH + $clog2(N)
)(
    input logic                     clk,
    input logic                     reset,

    input logic [WIDTH-1:0]         a_in,
    input logic [WIDTH-1:0]         b_in_1,
    input logic [WIDTH-1:0]         b_in_3,
    input logic [ACC_WIDTH-1:0]     c_in,

    // theta[0]=alpha, theta[1]=beta
    input logic [1:0]               theta,

    output logic [ACC_WIDTH-1:0]     c_out,
    output logic                     done
);

    logic [WIDTH-1:0] a_chain [0:N];
    logic [ACC_WIDTH-1:0] c_chain [0:N];

    logic [WIDTH-1:0] b_to_pe  [0:N-1];
    logic [WIDTH-1:0] b_out_pe [0:N-1];

    logic alpha_chain [0:N];
    logic beta_chain  [0:N];

    assign a_chain[0] = a_in;
    assign c_chain[0] = c_in;

    assign alpha_chain[0] = theta[0];
    assign beta_chain [0] = theta[1];

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : b_route

            if (i < ((N + 1) / 2)) begin : left_half
                assign b_to_pe[i] = (i == 0) ? b_in_1 : b_out_pe[i-1];

            end else begin : right_half
                assign b_to_pe[i] = (i == N-1) ? b_in_3 : b_out_pe[i+1];

            end
        end
    endgenerate

    generate
        for (i = 0; i < N; i++) begin : pe_array
            localparam int PE_ID = i;
            processingElement #(
                .WIDTH     (WIDTH),
                .N         (N),
                .ACC_WIDTH (ACC_WIDTH),
                .MODE      (0),
                .ID        (PE_ID)
            )
            generic_pe (
                .clk   (clk),
                .reset (reset),

                .alpha (alpha_chain[i]),
                .beta  (beta_chain[i]),

                .a (a_chain[i]),
                .b (b_to_pe[i]),
                .c (c_chain[i]),

                .a_j2 (a_chain[i+1]),
                .b_j2 (b_out_pe[i]),
                .alpha_j1 (alpha_chain[i+1]),
                .beta_j1 (beta_chain[i+1]),
                .c_j1 (c_chain[i+1])
            );
        end
    endgenerate

    assign c_out = c_chain[N];

    assign done = alpha_chain[N];

endmodule