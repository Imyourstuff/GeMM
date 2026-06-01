module regChain #(
    parameter WIDTH = 8,
    parameter N = 4 
)(
    input logic clk,
    input logic reset,
    input logic [WIDTH-1:0] d_in,
    output logic [WIDTH-1:0] q_out
);

    //Провода для соединения регистров в genvar
    //Ширина width-1:0 по N штук
    logic [WIDTH-1:0] chained [0:N];

    assign chained[0] = d_in;

    genvar i;
    generate 
        for (i = 0; i < N; i = i + 1) begin : gen_reg
            regX #(.WIDTH(WIDTH)) u_reg (
                .d_in(chained[i]),
                .clk(clk),
                .reset(reset),
                .q_out(chained[i+1])
            );
        end
    endgenerate
    
    assign q_out = chained[N];

endmodule