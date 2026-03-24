//======================================================================
//
// Design Name:    PRESENT Block Cipher
// Module Name:    PRESENT_ENCRYPT
//
// Description:    PRESENT Encryption Module (top level)
//
// Dependencies:
//              present_encrypt_sbox.v
//              present_encrypt_pbox.v
//
// Language: Verilog 2001
// Author: Saied H. Khayat
// Date:   March 2011
// URL: https://github.com/saiedhk
//
// Copyright Notice: Free use of this library is permitted under the
// guidelines and in accordance with the MIT License (MIT).
// http://opensource.org/licenses/MIT
//
//======================================================================
`default_nettype none
`timescale 1ns/1ns

//`define DEBUG
`define PRINT_TEST_VECTORS

module present_encrypt (
        input wire [63:0]   idat,    // data input port
        input wire [79:0]   key,     // key input port
        input wire          load,    // data load command
        input wire          clk,     // clock
        input wire          rst_n,   // reset 
        output wire [63:0]   odat,     // data output port; should be register???
        output wire         odat_valid
    );

//---------wires, registers----------
reg  [79:0] kreg;               // key register
reg  [63:0] dreg;               // data register
reg  [4:0]  round;              // round counter, up to 32
wire [63:0] dat1,dat2,dat3;     // intermediate data
wire [79:0] kdat1,kdat2;        // intermediate subkey data


//---------combinational processes----------

assign dat1 = dreg ^ kreg[79:16];        // add round key
assign odat = dat1;                      // output ciphertext
assign odat_valid = (round == 0 && rst_n) ? 1 : 0;    // sets odat_valid if we are not in reset and rounds have looped to zero

// key update
assign kdat1        = {kreg[18:0], kreg[79:19]}; // rotate key 61 bits to the left
assign kdat2[14:0 ] = kdat1[14:0 ];
assign kdat2[19:15] = kdat1[19:15] ^ round;  // xor key data and round counter
assign kdat2[75:20] = kdat1[75:20];


//---------instantiations--------------------

// instantiate 16 substitution boxes (s-box) for encryption
genvar i;
generate
    for (i=0; i<64; i=i+4) begin: sbox_loop
       present_encrypt_sbox usbox( .odat(dat2[i+3:i]), .idat(odat[i+3:i]) );
    end
endgenerate

// instantiate pbox (p-layer)
present_encrypt_pbox upbox    ( .odat(dat3), .idat(dat2) );

// instantiate substitution box (s-box) for key expansion
present_encrypt_sbox usboxkey ( .odat(kdat2[79:76]), .idat(kdat1[79:76]) );


//---------sequential processes----------
// TODO: restructure as state machine

always @(posedge clk) begin
   if (!rst_n) begin
      // reset all internal registers 
      kreg <= 0;
      dreg <= 0;
      round <= 0;
   end else if (load) begin
      dreg <= idat;        // load data
      kreg <= key;         // load key
      round <= 1;          //set round counter to 1
   end else begin
      dreg <= dat3;        // update data register
      kreg <= kdat2;       // update key register
      round <= round + 1;  // update round counter
   end
end


////-------------------Debug stuff -------------------
//
//// To print key1 and key32
//`ifdef PRINT_KEY_VECTORS
//always @(posedge clk)
//begin
//   if (round==0)
//      $display("KEYVECTOR=> key1=%x  key32=%x",key,kreg);
//end
//`endif
//
//// To print test vectors at simulation time
//`ifdef PRINT_TEST_VECTORS
//always @(posedge clk)
//begin
//   if (round==0)
//      $display("TESTVECTOR=> ", $time, " plaintext=%x  key=%x  ciphertext=%x",idat,key,odat);
//end
//`endif
//
//// To inspect internal signals at simulation
//`ifdef DEBUG
//always @(posedge clk)
//begin
//      $display("D=> ", $time, " %d  %x  %x  %x  %x  %x  %x",round,idat,dreg,dat1,dat2,dat3,odat);
//      $display("K=> ", $time, " %d  %x  %x  %x",round,kreg,kdat1,kdat2);
//end
//`endif

endmodule
