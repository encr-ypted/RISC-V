module register_file (
    input logic clk,
    input logic rst,
    input logic we_i,
    input logic [4:0] rs1_addr_i,
    input logic [4:0] rs2_addr_i,
    input logic [31:0] write_data_i,
    input logic [4:0] write_addr_i,
    output logic [31:0] rs1_o,
    output logic [31:0] rs2_o
);

logic [31:0] reg_file [0:31];

always_ff @(posedge clk) begin
    if(rst) begin
        for (int i = 0; i < 32; i++) begin
            reg_file[i] <= 32'b0;
        end
    end else begin
        if (we_i && write_addr_i != 5'b0) begin
            reg_file[write_addr_i] <= write_data_i;
        end
    end
end

assign rs1_o = (rs1_addr_i == 5'b0) ? 32'b0 : reg_file[rs1_addr_i];
assign rs2_o = (rs2_addr_i == 5'b0) ? 32'b0 : reg_file[rs2_addr_i];

endmodule