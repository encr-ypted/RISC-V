module cpu_top(
    input logic clk,
    input logic rst
);

logic [31:0] next_pc_value;
logic [31:0] target_address;
logic flush_pipeline;



// FETCH STAGE WIRES
logic [31:0] if_instruction;
logic [31:0] if_pc;

// DECODE STAGE WIRES
logic [31:0] id_pc;
logic [31:0] id_instruction;
logic [31:0] id_immediate;
logic [3:0] id_alu_op_sel;
logic [1:0] id_result_src;
logic [1:0] id_pc_sel;
logic       id_alu_b_src;
logic       id_mem_write;
logic       id_reg_write;
logic       id_is_jalr;
logic [31:0] id_rs1, id_rs2;

logic [4:0] id_rd_addr;
logic [2:0] id_funct3;

// EXECUTE STAGE WIRES
logic [31:0] ex_pc;
logic [3:0] ex_alu_op_sel;
logic [1:0] ex_result_src;
logic [31:0] ex_alu_result;
logic [31:0] ex_alu_b;
logic [1:0] ex_pc_sel;
logic       ex_alu_b_src;
logic       ex_mem_write;
logic       ex_reg_write;
logic       ex_is_jalr;
logic [31:0] ex_rs1, ex_rs2;
logic [31:0] ex_immediate;
logic ex_alu_lt;
logic ex_alu_lt_unsigned;
logic ex_alu_zero;
logic ex_branch_taken;
logic [31:0] ex_incremented_pc;
logic [4:0] ex_rd_addr;
logic [2:0] ex_funct3;


// MEMORY ACCESS STAGE WIRES
logic [1:0] mem_result_src;
logic       mem_mem_write;
logic       mem_reg_write;
logic [31:0] mem_rs2;
logic [31:0] mem_data;
logic [31:0] mem_incremented_pc;
logic [4:0] mem_rd_addr;

// WRITEBACK STAGE WIRES
logic [31:0] wb_incremented_pc;
logic       wb_reg_write;
logic [31:0] wb_data;
logic [4:0] wb_rd_addr;
logic[31:0] wb_alu_result;

pc pc(
.clk(clk),
.rst(rst),
.pc_o(if_pc),
.next_pc_i(next_pc_value) //come back at the end
);


instruction_memory imem(
.addr_i(if_pc),
.data_o(if_instruction)
);




//Pipeline register (Fetch to Decode Boundary)
pipeline_reg #(
.DATA_WIDTH(64)
) if_id_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(flush_pipeline),
.d({if_pc, if_instruction}),
.q({id_pc, id_instruction})
);

control_unit cu(
.instruction_i(id_instruction),
.alu_op_sel_o(id_alu_op_sel),
.alu_b_src_o(id_alu_b_src),

.mem_write_o(id_mem_write),
.reg_write_o(id_reg_write),

.result_src_o(id_result_src),
.pc_sel_o(id_pc_sel),

.is_jalr_o(id_is_jalr),
.immediate_o(id_immediate)
);

assign id_rd_addr = id_instruction[11:7];
assign id_funct3 = id_instruction[14:12];


//Pipeline register (Decode to Execute Boundary)
pipeline_reg #(
.DATA_WIDTH(148)
) id_ex_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(flush_pipeline),
.d({id_pc, id_funct3, id_immediate, id_alu_op_sel, id_result_src, id_pc_sel, id_alu_b_src, id_mem_write, id_reg_write, id_is_jalr, id_rs1, id_rs2, id_rd_addr}),
.q({ex_pc, ex_funct3, ex_immediate, ex_alu_op_sel, ex_result_src, ex_pc_sel, ex_alu_b_src, ex_mem_write, ex_reg_write, ex_is_jalr, ex_rs1, ex_rs2, ex_rd_addr})
);


assign ex_alu_b = ex_alu_b_src ? ex_immediate : ex_rs2;

alu alu(
.a_i(ex_rs1),
.b_i(ex_alu_b),
.opsel_i(ex_alu_op_sel),
.result_o(ex_alu_result),
.zero_o(ex_alu_zero),
.lt_o(ex_alu_lt),
.lt_unsigned_o(ex_alu_lt_unsigned)
);

assign ex_incremented_pc = ex_pc + 32'd4;

branch_unit bu(
.branch_i(ex_pc_sel[0]),
.alu_zero_i(ex_alu_zero),
.alu_lt_i(ex_alu_lt),
.alu_lt_unsigned_i(ex_alu_lt_unsigned),
.func3_i(ex_funct3),
.take_branch_o(ex_branch_taken)
);


//Pipeline register (Execute to Mem Boundary)
pipeline_reg #(
.DATA_WIDTH(105)
) ex_mem_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(1'b0),
.d({ex_incremented_pc, ex_result_src, ex_mem_write, ex_reg_write, ex_rs2, ex_alu_result, ex_rd_addr}),
.q({mem_incremented_pc, mem_result_src, mem_mem_write, mem_reg_write, mem_rs2, mem_alu_result, mem_rd_addr})
);


data_memory dmem(
.clk(clk),
.we_i(mem_mem_write),
.be_i(4'b1111),
.addr_i(mem_alu_result),
.data_i(mem_rs2),
.data_o(mem_data)
);


//Pipeline register (Mem to Writeback Boundary)
pipeline_reg #(
.DATA_WIDTH(104)
) mem_wb_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(1'b0),
.d({mem_incremented_pc, mem_result_src, mem_reg_write, mem_alu_result, mem_data, mem_rd_addr}),
.q({wb_incremented_pc, wb_result_src, wb_reg_write, wb_alu_result, wb_data, wb_rd_addr})
);

logic [31:0] wb_register_data;


register_file reg_file(
.clk(clk),
.rst(rst),
.we_i(wb_reg_write),
.rs1_addr_i(id_instruction[19:15]),
.rs2_addr_i(id_instruction[24:20]),
.write_addr_i(wb_rd_addr),
.write_data_i(wb_register_data),
.rs1_o(id_rs1),
.rs2_o(id_rs2)
);


always_comb begin
    case (wb_result_src)
        2'b00: wb_register_data = wb_alu_result;
        2'b01: wb_register_data = wb_data;
        2'b10: wb_register_data = wb_incremented_pc;
        default: wb_register_data = 32'b0;
    endcase
end


assign target_address = (ex_is_jalr) ? {ex_alu_result[31:1], 1'b0} : (ex_pc + ex_immediate);

always_comb begin
    case (ex_pc_sel)
        2'b00: next_pc_value = ex_incremented_pc; // Normal
        2'b01: next_pc_value = ex_branch_taken ? target_address : ex_incremented_pc; // Branch
        2'b10: next_pc_value = target_address; // Jump
        default: next_pc_value = ex_incremented_pc_value;
    endcase
end

assign flush_pipeline = (ex_pc_sel == 2'b10) || ((ex_pc_sel == 2'b01) && ex_branch_taken);

endmodule