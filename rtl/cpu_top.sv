import cpu_pkg::*;

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

if_id_packet_t if_id_in, if_id_out;

assign if_id_in.pc = if_pc;
assign if_id_in.instruction = if_instruction;


//Pipeline register (Fetch to Decode Boundary)
pipeline_reg #(
.DATA_WIDTH($bits(if_id_packet_t))
) if_id_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(flush_pipeline),
.d(if_id_in),
.q(if_id_out)
);

assign id_pc = if_id_out.pc;
assign id_instruction = if_id_out.instruction;

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

id_ex_packet_t id_ex_in, id_ex_out;
assign id_ex_in.pc = id_pc;
assign id_ex_in.immediate = id_immediate;
assign id_ex_in.rs1 = id_rs1;
assign id_ex_in.rs2 = id_rs2;
assign id_ex_in.rd_addr = id_rd_addr;
assign id_ex_in.funct3 = id_funct3;
assign id_ex_in.alu_op_sel = id_alu_op_sel;
assign id_ex_in.result_src = id_result_src;
assign id_ex_in.pc_sel = id_pc_sel;
assign id_ex_in.alu_b_src = id_alu_b_src;
assign id_ex_in.mem_write = id_mem_write;
assign id_ex_in.reg_write = id_reg_write;
assign id_ex_in.is_jalr = id_is_jalr;

//Pipeline register (Decode to Execute Boundary)
pipeline_reg #(
.DATA_WIDTH($bits(id_ex_packet_t))
) id_ex_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(flush_pipeline),
.d(id_ex_in),
.q(id_ex_out)
);

assign ex_pc         = id_ex_out.pc;
assign ex_immediate  = id_ex_out.immediate;
assign ex_rs1        = id_ex_out.rs1;
assign ex_rs2        = id_ex_out.rs2;
assign ex_rd_addr    = id_ex_out.rd_addr;
assign ex_funct3     = id_ex_out.funct3;
assign ex_alu_op_sel = id_ex_out.alu_op_sel;
assign ex_result_src = id_ex_out.result_src;
assign ex_pc_sel     = id_ex_out.pc_sel;
assign ex_alu_b_src  = id_ex_out.alu_b_src;
assign ex_mem_write  = id_ex_out.mem_write;
assign ex_reg_write  = id_ex_out.reg_write;
assign ex_is_jalr    = id_ex_out.is_jalr;

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

ex_mem_packet_t ex_mem_in, ex_mem_out;

assign ex_mem_in.incremented_pc = ex_incremented_pc;
assign ex_mem_in.alu_result = ex_alu_result;
assign ex_mem_in.rs2 = ex_rs2;
assign ex_mem_in.rd_addr = ex_rd_addr;
assign ex_mem_in.mem_write = ex_mem_write;
assign ex_mem_in.reg_write = ex_reg_write;
assign ex_mem_in.result_src = ex_result_src;

//Pipeline register (Execute to Mem Boundary)
pipeline_reg #(
.DATA_WIDTH($bits(ex_mem_packet_t))
) ex_mem_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(1'b0),
.d(ex_mem_in),
.q(ex_mem_out)
);

assign mem_incremented_pc = ex_mem_out.incremented_pc;
assign mem_result_src     = ex_mem_out.result_src;
assign mem_mem_write      = ex_mem_out.mem_write;
assign mem_reg_write      = ex_mem_out.reg_write;
assign mem_rs2            = ex_mem_out.rs2;
assign mem_alu_result     = ex_mem_out.alu_result;
assign mem_rd_addr        = ex_mem_out.rd_addr;


data_memory dmem(
.clk(clk),
.we_i(mem_mem_write),
.be_i(4'b1111),
.addr_i(mem_alu_result),
.data_i(mem_rs2),
.data_o(mem_data)
);

mem_wb_packet_t mem_wb_in, mem_wb_out;

assign mem_wb_in.incremented_pc = mem_incremented_pc;
assign mem_wb_in.alu_result = mem_alu_result;
assign mem_wb_in.mem_data = mem_data;
assign mem_wb_in.rd_addr = mem_rd_addr;
assign mem_wb_in.result_src = mem_result_src;
assign mem_wb_in.reg_write = mem_reg_write;

//Pipeline register (Mem to Writeback Boundary)
pipeline_reg #(
.DATA_WIDTH($bits(mem_wb_packet_t))
) mem_wb_reg (
.clk(clk),
.rst(rst),
.en(1'b1),
.flush(1'b0),
.d(mem_wb_in),
.q(mem_wb_out)
);

assign wb_incremented_pc = mem_wb_out.incremented_pc;
assign wb_result_src     = mem_wb_out.result_src;
assign wb_reg_write      = mem_wb_out.reg_write;
assign wb_alu_result     = mem_wb_out.alu_result;
assign wb_data           = mem_wb_out.mem_data;
assign wb_rd_addr        = mem_wb_out.rd_addr;

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
        default: next_pc_value = ex_incremented_pc;
    endcase
end

assign flush_pipeline = (ex_pc_sel == 2'b10) || ((ex_pc_sel == 2'b01) && ex_branch_taken);

endmodule