module forwarding_unit(
    input logic [4:0] wb_rd_addr,
    input logic wb_reg_write,

    input logic [4:0] mem_rd_addr,
    input logic mem_reg_write,

    input logic [4:0] ex_rs1_addr,
    input logic [4:0] ex_rs2_addr,

    output logic [1:0] forward_rs1, //00 - No forward, 01 - MEM stage Forward, 10 - WB stage Forward
    output logic [1:0] forward_rs2
);


always_comb begin
    forward_rs1 = 2'b00;
    forward_rs2 = 2'b00;


    if (mem_reg_write && (ex_rs1_addr == mem_rd_addr) && (mem_rd_addr != 5'd0)) begin
        forward_rs1 = 2'b01;
    end else if (wb_reg_write && (ex_rs1_addr == wb_rd_addr) && (wb_rd_addr != 5'd0)) begin
        forward_rs1 = 2'b10;
    end

    if (mem_reg_write && (ex_rs2_addr == mem_rd_addr) && (mem_rd_addr != 5'd0)) begin
        forward_rs2 = 2'b01;
    end else if (wb_reg_write && (ex_rs2_addr == wb_rd_addr) && (wb_rd_addr != 5'd0)) begin
        forward_rs2 = 2'b10;
    end
end

endmodule