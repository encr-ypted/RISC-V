module data_memory #(
 parameter int NUM_WORDS = 1024
) (
    input logic clk,
    input logic we_i,
    input logic [3:0] be_i,
    input logic [31:0] addr_i,
    input logic [31:0] data_i,
    output logic [31:0] data_o
);

localparam int ADDR_W = $clog2(NUM_WORDS);

logic [31:0] memory [0:NUM_WORDS-1];

logic [ADDR_W-1:0] word_addr;
assign word_addr = addr_i[ADDR_W+1:2];
//logic [1:0] byte_offset = addr_i[1:0];

always_ff @(posedge clk) begin
    data_o <= memory[word_addr];

    if (we_i) begin
        if (be_i[0]) memory[word_addr][7:0] <= data_i[7:0];
        if (be_i[1]) memory[word_addr][15:8] <= data_i[15:8];
        if (be_i[2]) memory[word_addr][23:16] <= data_i[23:16];
        if (be_i[3]) memory[word_addr][31:24] <= data_i[31:24];
    end
end

endmodule

