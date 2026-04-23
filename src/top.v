// top module

`default_nettype none

module top (
    input wire rst_n,           // negative reset
    input wire clk,             // clock
    input wire [1:0] cmd,       // IOs, 2 bits for 
    input wire [7:0] data_in,   // inputs, 8 bits

// could add 3 output bits for key_full, r_data_in_full, r_data_out_empty(for reading)
    output reg [7:0] data_out,  // outputs, 8 bits
    output reg data_top_valid  // data ready for reading
);

// internal registers & wires
reg [79:0] r_key;         //key register
reg [63:0] r_data_in;  // data_in register
reg [63:0] r_data_in_bak;  // backup of data_in register
reg [63:0] r_data_out;  // data_out register
reg r_load;
reg [2:0] trigger;
reg data_out_valid;

wire [63:0] w_data_out;  // data_out wire


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
    LOAD = 3;


// CODE
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_key <= 0;
        r_data_in <= 0;
        r_data_in_bak <= 0;
        r_data_out <= 0;
        data_out <= 0;
        data_top_valid <= 0;
        r_load <= 0;
        trigger <= 0;
    end else begin
        data_out <= r_data_out[63:56];
        r_data_out <= {r_data_out[55:0], 8'b0};
        data_top_valid <= data_out_valid;
        case(cmd)
            //IDLE: nop
            KEY_IN: begin
                r_load <= 0;
                r_key <= {r_key[71:0], data_in}; //load byte into key reg
            end
            DATA_IN: begin 
                r_load <= 0;
                r_data_in <= {r_data_in[55:0], data_in}; // load byte into r_data_in register
            end
            LOAD: begin
                r_load <= 1;
                if ((r_data_in == r_data_in_bak) && (r_data_in_bak != 0)) begin
                    // set trigger, 0 means no fault
                    trigger <= ( trigger == 3'd4 ) ? 3'd0 : trigger + 1;
                end else begin
                    r_data_in_bak <= r_data_in;
                end
            end 
            default: begin
                r_load <= 0; //IDLE STATE, same as "0"
            end
        endcase
        if (data_out_valid) begin
            r_data_out <= w_data_out;      
        end
    end
end
endmodule
