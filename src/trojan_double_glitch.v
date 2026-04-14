`default_nettype none

module double_glitch (
    input   wire    [4:0]   round,
    input   wire    [2:0]   trigger,
    input   wire    [63:0]  data_in,

    output  wire    [63:0]  data_out
);

wire [63:0] mask [0:4];

assign mask[0] = 64'h0000_0000_0000_0000; // Mask=0000 (no fault)
assign mask[1] = 64'hf000_f000_f000_f000; // Mask=1000
assign mask[2] = 64'h0f00_0f00_0f00_0f00; // Mask=0100
assign mask[3] = 64'h00f0_00f0_00f0_00f0; // Mask=0010
assign mask[4] = 64'h000f_000f_000f_000f; // Mask=0001

assign data_out = (round == 30) ? data_in^mask[trigger] : data_in;


endmodule
