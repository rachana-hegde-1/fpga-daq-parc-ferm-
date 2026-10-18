
`timescale 1ns/1ps

module rpm_period_measure #(
    parameter integer COUNTER_WIDTH = 32,
    parameter integer TIMEOUT_CYCLES = 1000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rpm_pulse,

    output reg  [COUNTER_WIDTH-1:0] period_count,
    output reg  measurement_valid,
    output reg  pulse_timeout
);

    reg rpm_pulse_d;
    reg [COUNTER_WIDTH-1:0] cycle_count;

    wire rising_edge = rpm_pulse & ~rpm_pulse_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rpm_pulse_d     <= 1'b0;
            cycle_count     <= {COUNTER_WIDTH{1'b0}};
            period_count    <= {COUNTER_WIDTH{1'b0}};
            measurement_valid <= 1'b0;
            pulse_timeout   <= 1'b0;
        end else begin
            rpm_pulse_d <= rpm_pulse;
            measurement_valid <= 1'b0;
            pulse_timeout <= 1'b0;

            if (rising_edge) begin
                if (cycle_count != 0) begin
                    period_count <= cycle_count;
                    measurement_valid <= 1'b1;
                end
                cycle_count <= {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
            end else if (cycle_count >= TIMEOUT_CYCLES) begin
                cycle_count <= {COUNTER_WIDTH{1'b0}};
                pulse_timeout <= 1'b1;
            end else if (cycle_count != 0) begin
                cycle_count <= cycle_count + 1'b1;
            end else begin
                cycle_count <= {COUNTER_WIDTH{1'b0}};
            end
        end
    end

endmodule
