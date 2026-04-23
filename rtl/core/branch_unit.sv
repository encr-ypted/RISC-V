module branch_unit(
    input logic branch_i,
    input logic alu_zero_i,
    input logic alu_lt_i,
    input logic alu_lt_unsigned_i,
    input logic [2:0] func3_i,

    output logic take_branch_o
);


logic condition_met;

always_comb begin
    condition_met = 1'b0;

    case(func3_i)
        3'b000: condition_met = alu_zero_i; // BE
        3'b001: condition_met = ~alu_zero_i; // BNE
        3'b100: condition_met = alu_lt_i; // BLT
        3'b101: condition_met = ~alu_lt_i; // BGE
        3'b110: condition_met = alu_lt_unsigned_i; // BLTU
        3'b111: condition_met = ~alu_lt_unsigned_i; // BGEU
        default: condition_met = 1'b0;
    endcase
end

assign take_branch_o = branch_i && condition_met;

endmodule