`timescale 1ns/1ps

module sampled_value_channel #(
    parameter integer DATA_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] sample_in,
    input  wire                  sample_valid,

    output reg  [DATA_WIDTH-1:0] sample_out,
    output reg                   measurement_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_out        <= {DATA_WIDTH{1'b0}};
            measurement_valid <= 1'b0;
        end else begin
            // Default: valid is a one-cycle notification.
            measurement_valid <= 1'b0;

            if (sample_valid) begin
                sample_out        <= sample_in;
                measurement_valid <= 1'b1;
            end
        end
    end

endmodule
