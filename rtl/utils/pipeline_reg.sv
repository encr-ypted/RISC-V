module pipeline_reg #(
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst,
    input logic en,
    input logic flush_i,
    input logic [DATA_WIDTH-1:0] d_i,
    output logic [DATA_WIDTH-1:0] q_o
);

always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        q_o <= 'b0;
    end else if (en) begin
        q_o <= d_i;
    end
end

endmodule