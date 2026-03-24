// top module

`default_nettype none

module top (
    input wire rst_n,           //negative reset
    input wire clk,             //clock
    input wire [1:0] cmd,       //IOs, 3 bits
    input wire [7:0] data_in,   //inputs, 8 bits

//could add 3 output bits for key_full, data_in_block_full, data_out_block_empty(for reading)
    output reg [7:0] data_out,  //outputs, 8 bits
    output wire data_top_valid //data ready for reading
);

// internal registers & wires
reg [79:0] key;         //key register
reg [63:0] data_in_block;  // data_in block
reg [63:0] data_out_block;  // data_out block
reg load_state; //state register for load operation
reg [2:0] state; // state for state machine
reg [7:0] reading; // reading state register

wire [79:0] key_w;
wire [63:0] data_in_w;
wire [63:0] data_out_w;
wire load_w;
wire data_out_valid;

assign key_w = key;
assign data_in_w = data_in_block;
assign load_w = load_state;
assign data_top_valid = state[2];

// instanciate present_encrypt module
present_encrypt i_present_encrypt (
    .idat(data_in_w),
    .key(key_w),
    .load(load_w),
    .clk(clk),
    .rst_n(rst_n),
    .odat(data_out_w),
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
        key <= 0;
        data_in_block <= 0;
        data_out_block <= 0;
        load_state <= 0;
        data_out <= 0;
        reading <= 0;
    end else begin
        state <= {reading[7], cmd};
        reading <= {reading[6:0], 1'b0};
        case(state)
            //IDLE: nop
            KEY_IN: begin
                load_state <= 0;
                key <= {key[71:0], data_in}; //load byte into key reg
            end
            DATA_IN: begin 
                load_state <= 0;
                data_in_block <= {data_in_block[55:0], data_in}; // load byte into data_in_block register
            end
            LOAD: load_state <= 1; 
            READ_BYTE: begin //read byte from data_out_block
                load_state <= 0;
                data_out <= data_out_block[63:56];
                data_out_block <= {data_out_block[55:0], 8'b0};
            end
            default: begin
                load_state <=0; //IDLE STATE, same as "0"
            end
        endcase
        if (data_out_valid) begin
            reading <= 8'b1111_1111;
            data_out_block <= data_out_w;      
        end
    end
end
endmodule
