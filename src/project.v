/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_present (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

// All output pins must be assigned. If not used, assign to 0.
assign uio_oe  = 8'b1111_1100; // Inputs: bits [1:0] for commands(, [7:6] for trigger); others are outputs
assign uio_out[7:3] = 5'b000; // assigning unused IOs defined as output to zero; uio_out[2] used for data_top_valid
assign uio_out[1:0] = 2'b00;

// List all unused inputs to prevent warnings
wire _unused = &{ena, uio_in[7:2], 1'b0};

top tt_top (
  .rst_n(rst_n),
  .clk(clk),
  .cmd(uio_in[1:0]),
  .data_in(ui_in),

  .data_out(uo_out),
  .data_top_valid(uio_out[2])
);

endmodule
