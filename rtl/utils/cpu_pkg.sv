package cpu_pkg;

typedef struct packed {
    logic [31:0] pc;
    logic [31:0] instruction;
} if_id_packet_t;

typedef struct packed {
    logic[31:0] pc;
    logic [31:0] immediate;
    logic [31:0] rs1;
    logic [31:0] rs2;
    logic [4:0]  rd_addr;
    logic [2:0]  funct3;

    logic [3:0]  alu_op_sel;
    logic [1:0]  result_src;
    logic [1:0]  pc_sel;
    logic        alu_b_src;
    logic        mem_write;
    logic        reg_write;
    logic        is_jalr;
} id_ex_packet_t;

typedef struct packed {
    logic [31:0] incremented_pc;
    logic [31:0] alu_result;
    logic [31:0] rs2;
    logic [4:0]  rd_addr;

    logic [1:0]  result_src;
    logic        mem_write;
    logic        reg_write;
} ex_mem_packet_t;

typedef struct packed {
    logic [31:0] incremented_pc;
    logic [31:0] alu_result;
    logic [31:0] mem_data;
    logic [4:0]  rd_addr;

    logic [1:0]  result_src;
    logic        reg_write;
} mem_wb_packet_t;

endpackage