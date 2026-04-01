// top module

`default_nettype none

module top (
    input wire rst_n,           // negative reset
    input wire clk,             // clock
    input wire [1:0] cmd,       // IOs, 2 bits for 
    input wire [7:0] data_in,   // inputs, 8 bits
    input wire [1:0] trigger,   // HW trojan trigger

    output reg [7:0] data_out,  // outputs, 8 bits
    output wire data_top_valid  // data ready for reading
);

// internal registers & wires
reg [79:0] r_key;       // key register
reg [63:0] r_data_in;   // data_in register
reg [63:0] r_data_out;  // data_out register
reg [2:0] state;        // state for state machine
reg [7:0] reading;      // reading state register
reg r_load;             // register for loading into present_encrypt module

wire data_out_valid;    // data out "is valid" wire
wire [63:0] w_data_out; // data_out wire

assign data_top_valid = state[2];

// instanciate present_encrypt module
present_encrypt i_present_encrypt (
    .idat(r_data_in),
    .key(r_key),
    .load(r_load),
    .clk(clk),
    .rst_n(rst_n),
    .trigger(trigger),
    .odat(w_data_out),
    .odat_valid(data_out_valid));

// state enum
localparam KEY_IN = 1,
    DATA_IN = 2,
    LOAD = 3,
    READ_BYTE = 4;

// CODE
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 0;
        r_key <= 0;
        r_data_in <= 0;
        r_data_out <= 0;
        reading <= 0;
        r_load <= 0;
    end else begin
        reading <= {reading[6:0], 1'b0};
        state <= {reading[7], cmd};
        case(state)
            //IDLE: nop
            KEY_IN: begin
                r_load <= 0;
                r_key <= {r_key[71:0], data_in};            // load byte into key reg
            end
            DATA_IN: begin 
                r_load <= 0;
                r_data_in <= {r_data_in[55:0], data_in};    // load byte into r_data_in register
            end
            LOAD: r_load <= 1; 
            READ_BYTE: begin    // read byte from r_data_out
                r_load <= 0;
                data_out <= r_data_out[63:56];
                r_data_out <= {r_data_out[55:0], 8'b0};
            end
            default: begin
                r_load <= 0;    // IDLE state
            end
        endcase
        if (data_out_valid) begin
            reading <= 8'b1111_1111;
            r_data_out <= w_data_out;      
        end
    end
end
endmodule
