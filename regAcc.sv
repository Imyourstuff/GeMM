module regAcc #(
    parameter   WIDTH = 8,
                N = 4,
                ACC_WIDTH  = 2 * WIDTH + $clog2(N)    
    ) 
(
    input logic [ACC_WIDTH-1:0] d_in,
    input logic reset,
    input logic clk,
    output reg [ACC_WIDTH-1:0] q_out
);

always @(posedge clk or posedge reset) begin
    if (reset)
    begin
        q_out <= {WIDTH{1'b0}};
    end else begin
        q_out <= d_in;
    end
end


endmodule

