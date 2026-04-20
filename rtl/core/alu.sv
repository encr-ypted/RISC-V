module alu(
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic [3:0] opsel_i,
    output logic [31:0] result_o,
    output logic zero_o
);

always_comb begin
    case(opsel_i)
        4'b0000: result_o = a_i + b_i; // ADD
        4'b0001: result_o = a_i - b_i; // SUB
        4'b0010: result_o = a_i & b_i; // AND
        4'b0011: result_o = a_i | b_i; // OR
        4'b0100: result_o = a_i ^ b_i; // XOR
        4'b0101: result_o = a_i << b_i[4:0]; // SLL
        4'b0110: result_o = a_i >> b_i[4:0]; // SRL
        4'b0111: result_o = signed'(a_i) >>> b_i[4:0]; // SRA
        4'b1000: result_o = (signed'(a_i) < signed'(b_i)) ? 32'd1 : 32'd0; // SLT
        4'b1001: result_o = (a_i < b_i) ? 32'd1 : 32'd0; // SLTU
        default: result_o = 32'b0;
    endcase
end

assign zero_o = (result_o == 32'b0);

endmodule