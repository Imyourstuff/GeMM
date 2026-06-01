module regEnable #(
    parameter WIDTH = 8) (
    input logic [WIDTH-1:0] d_in,
    input logic clk,
    input logic enable,
    input logic reset,
    output reg [WIDTH-1:0] q_out
);

always @(posedge clk or posedge reset) begin
    if (reset)
        q_out <= {WIDTH{1'b0}};
    else if (enable)
        q_out <= d_in;
end

endmodule