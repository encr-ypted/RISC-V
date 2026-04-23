module pc (
    input logic clk,
    input logic rst,
    input logic [31:0] next_pc_i,
    output logic [31:0] pc_o
);

always_ff @(posedge clk) begin
    if (rst) begin
        pc_o <= 32'b0;
    end else begin
        pc_o <= next_pc_i;
    end
end

endmodule