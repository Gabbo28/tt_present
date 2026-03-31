`timescale 1ns/1ns
`default_nettype none

module double_glitch (
    input   wire    [4:0]   round,
    input   wire    [1:0]   trigger,
    input   wire    [63:0]  data_in,

    output  wire    [63:0]  data_out
);

reg [63:0] mask_1 = 64'hf000_f000_f000_f000; // Mask=1000
reg [63:0] mask_2 = 64'h0f00_0f00_0f00_0f00; // Mask=0100

assign data_out = (round == 30 && trigger[1]) ? ((trigger[0]) ? (data_in^mask_2) : (data_in^mask_1) ) : data_in;

endmodule
