module dffMy (
    input logic clk,
    input logic reset,
    input logic d_in,
    output reg q_out
);

always_ff @(posedge clk or posedge reset) begin
    if (reset)
       q_out <= 1'b0;
    else
        q_out <= d_in;
end

endmodule