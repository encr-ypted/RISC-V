module instruction_memory #(
 parameter int NUM_WORDS = 1024
) (
    input logic clk,
    input logic [31:0] addr_i,
    output logic [31:0] data_o
);

localparam int ADDR_W = $clog2(NUM_WORDS);

logic [31:0] memory [0:NUM_WORDS-1];

logic [ADDR_W-1:0] word_addr;
assign word_addr = addr_i[ADDR_W+1:2];


always_ff @(posedge clk) begin
    data_o <= memory[word_addr];
end

initial begin
    $readmemh("program.hex", memory);
end

endmodule