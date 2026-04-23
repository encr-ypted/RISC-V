module control_unit(
    input logic [31:0] instruction_i,

    output logic [3:0] alu_op_sel_o,
    output logic alu_b_src_o,

    output logic mem_write_o,
    output logic reg_write_o,

    output logic [1:0] result_src_o, //0: ALU, 01: Memory, 10: PC+4
    output logic [1:0] pc_sel_o, //use this instead 00 - non, 01 branch, 10, jump
    output logic is_jalr_o,

    output logic [31:0] immediate_o
);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instruction_i[6:0];
assign funct3 = instruction_i[14:12];
assign funct7 = instruction_i[31:25];

always_comb begin
    alu_b_src_o = 1'b0; // 0: b src is register, 1: is immediate
    alu_op_sel_o = 4'b0;
    result_src_o = 2'b0;
    reg_write_o  = 1'b0;
    mem_write_o  = 1'b0;
    pc_sel_o = 2'b00;
    immediate_o  = 32'b0;
    is_jalr_o = 1'b0;

    case (opcode)
        7'b0110011: begin // R type Instructions
            reg_write_o = 1'b1;

            case ({funct7, funct3})
                {7'b0000000, 3'b000}: alu_op_sel_o = 4'b0000; //ADD
                {7'b0100000, 3'b000}: alu_op_sel_o = 4'b0001; //SUB
                {7'b0000000, 3'b111}: alu_op_sel_o = 4'b0010; //AND
                {7'b0000000, 3'b110}: alu_op_sel_o = 4'b0011; //OR
                {7'b0000000, 3'b100}: alu_op_sel_o = 4'b0100; //XOR
                {7'b0000000, 3'b001}: alu_op_sel_o = 4'b0101; //SLL
                {7'b0000000, 3'b101}: alu_op_sel_o = 4'b0110; //SRL
                {7'b0100000, 3'b101}: alu_op_sel_o = 4'b0111; //SRA
                {7'b0000000, 3'b010}: alu_op_sel_o = 4'b1000; //SLT
                {7'b0000000, 3'b011}: alu_op_sel_o = 4'b1001; //SLTU
                default: alu_op_sel_o = 4'b0000;
            endcase
        end 7'b0010011: begin // I type ALU Instructions
            reg_write_o = 1'b1;
            alu_b_src_o = 1'b1;
            immediate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};

            case(funct3)
                3'b000: alu_op_sel_o = 4'b0000; // ADDI
                3'b010: alu_op_sel_o = 4'b1000; // SLTI
                3'b011: alu_op_sel_o = 4'b1001; // SLTIU
                3'b100: alu_op_sel_o = 4'b0100; // XORI
                3'b110: alu_op_sel_o = 4'b0011; // ORI
                3'b111: alu_op_sel_o = 4'b0010; // ANDI
                3'b001: alu_op_sel_o = 4'b0101; // SLLI
                3'b101: begin // SRLI or SRAI
                    if (funct7 == 7'b0100000) alu_op_sel_o = 4'b0111; // SRAI
                    else                      alu_op_sel_o = 4'b0110; // SRLI
                end

                default: alu_op_sel_o = 4'b0000;
            endcase


        end 7'b0000011: begin // I type Load Instructions
            alu_b_src_o = 1'b1;
            reg_write_o = 1'b1;
            result_src_o = 2'b01;
            alu_op_sel_o = 4'b0000;
            immediate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};


        end 7'b0100011: begin // S type Store Instructions
            alu_b_src_o = 1'b1;
            mem_write_o = 1'b1;
            alu_op_sel_o = 4'b0000;

            immediate_o = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
        end 7'b1100011: begin // B type branch Instrucitons
            alu_op_sel_o = 4'b0001;
            pc_sel_o = 2'b01;

            immediate_o  = {{20{instruction_i[31]}}, instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0};
        end 7'b1101111: begin // J type Jump and Link
            reg_write_o  = 1'b1;
            result_src_o = 2'b10;
            pc_sel_o = 2'b10;

            immediate_o  = {{12{instruction_i[31]}}, instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0};
        end 7'b1100111: begin // I type Jump and Link Register
            reg_write_o  = 1'b1;
            alu_b_src_o  = 1'b1;
            alu_op_sel_o = 4'b0000;
            result_src_o = 2'b10;
            pc_sel_o = 2'b10;
            is_jalr_o = 1'b1;

            immediate_o  = {{20{instruction_i[31]}}, instruction_i[31:20]};

        end 7'b0110111: begin // U type Load Upper Immediate
            reg_write_o  = 1'b1;
            alu_b_src_o  = 1'b1;
            alu_op_sel_o = 4'b0000; // ADD

            immediate_o  = {instruction_i[31:12], 12'b0};
        end default: begin
        end
    endcase
end

endmodule