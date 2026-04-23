module cpu_top(
    input logic clk,
    input logic rst
);

// Data Path Wires
logic [31:0] instruction;
logic [31:0] current_pc_value;
logic [31:0] next_pc_value;
logic [31:0] incremented_pc_value;
logic [31:0] target_address;
logic [31:0] rs1, rs2;
logic [31:0] alu_result;
logic [31:0] alu_b;
logic [31:0] data;
logic [31:0] write_register_data;
logic [31:0] immediate;

// 2. Control Signals
logic [3:0]  alu_op_sel;
logic [1:0]  result_src;
logic [1:0]  pc_sel;
logic        alu_src_b;
logic        mem_write;
logic        reg_write;
logic        is_jalr;

// 3. Status flags
logic alu_lt;
logic alu_lt_unsigned;
logic alu_zero;
logic branch_taken;


pc pc(
.clk(clk),
.rst(rst),
.pc_o(current_pc_value),
.next_pc_i(next_pc_value)
);


instruction_memory imem(
.addr_i(current_pc_value),
.data_o(instruction)
);



control_unit cu(
.instruction_i(instruction),
.alu_op_sel_o(alu_op_sel),
.alu_src_b_o(alu_src_b),

.mem_write_o(mem_write),
.reg_write_o(reg_write),

.result_src_o(result_src),
.pc_sel_o(pc_sel),

.is_jalr_o(is_jalr),
.immediate_o(immediate)
);


register_file reg_file(
.clk(clk),
.rst(rst),
.we_i(reg_write),
.rs1_addr_i(instruction[19:15]),
.rs2_addr_i(instruction[24:20]),
.write_addr_i(instruction[11:7]),
.write_data_i(write_register_data),
.rs1_o(rs1),
.rs2_o(rs2)
);

assign alu_b = alu_src_b ? immediate : rs2;

alu alu(
.a_i(rs1),
.b_i(alu_b),
.opsel_i(alu_op_sel),
.result_o(alu_result),
.zero_o(alu_zero),
.lt_o(alu_lt),
.lt_unsigned_o(alu_lt_unsigned)
);


branch_unit bu(
.branch_i(pc_sel[0]),
.alu_zero_i(alu_zero),
.alu_lt_i(alu_lt),
.alu_lt_unsigned_i(alu_lt_unsigned),
.func3_i(instruction[14:12]),
.take_branch_o(branch_taken)
);


data_memory dmem(
.clk(clk),
.we_i(mem_write),
.be_i(4'b1111),
.addr_i(alu_result),
.data_i(rs2),
.data_o(data)
);

always_comb begin
    case (result_src)
        2'b00: write_register_data = alu_result;
        2'b01: write_register_data = data;
        2'b10: write_register_data = incremented_pc_value;
        default: write_register_data = 32'b0;
    endcase
end



assign incremented_pc_value = current_pc_value + 32'd4;
assign target_address = (is_jalr) ? {alu_result[31:1], 1'b0} : (current_pc_value + immediate);

always_comb begin
    case (pc_sel)
        2'b00: next_pc_value = incremented_pc_value; // Normal
        2'b01: next_pc_value = branch_taken ? target_address : incremented_pc_value; // Branch
        2'b10: next_pc_value = target_address; // Jump
        default: next_pc_value = incremented_pc_value;
    endcase
end

endmodule