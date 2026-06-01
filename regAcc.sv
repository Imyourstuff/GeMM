module regAcc #(
    parameter   WIDTH = 8,
                N = 4,
                ACC_WIDTH  = 2 * WIDTH + $clog2(N)    
    ) 
(
    input logic [ACC_WIDTH-1:0] d_in,
    input logic clk,
    output reg [ACC_WIDTH-1:0] q_out
);

always @(posedge clk) begin
    q_out <= d_in;
end

endmodule

