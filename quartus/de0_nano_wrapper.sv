module de0_nano_wrapper(
    input  logic       CLOCK_50,
    input  logic [1:0] KEY,
    output logic [7:0] LED
);

cpu_top my_cpu (
    .clk(CLOCK_50),
    .rst(~KEY[0])
);

endmodule