`timescale 1ns/1ps
module tb_rpm_period_measure;
reg clk = 0;
    reg rst_n = 0;
    reg rpm_pulse = 0;
wire [31:0] period_count;
    wire measurement_valid;
    wire pulse_timeout;
rpm_period_measure #(
        .COUNTER_WIDTH(32),
        .TIMEOUT_CYCLES(1000)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rpm_pulse(rpm_pulse),
        .period_count(period_count),
        .measurement_valid(measurement_valid),
        .pulse_timeout(pulse_timeout)
    );
    always #5 clk = ~clk;
task send_pulse;
        begin
            rpm_pulse = 1;
            #10;
            rpm_pulse = 0;
        end
    endtask
initial begin
        $dumpfile("waves/rpm_period_measure.vcd");
        $dumpvars(0, tb_rpm_period_measure);
#20;
        rst_n = 1;
// First pulse establishes the starting point.
        #20;
        send_pulse();
// Second pulse arrives after a known interval.
        #90;
        send_pulse();
#30;
       if (period_count == 10)
    $display("PASS: Expected period count of 10");
else
    $display("FAIL: Expected 10, got %0d", period_count);

if (measurement_valid == 0)
    $display("PASS: Valid signal returned low");
else
    $display("FAIL: Valid signal should be low after its pulse");
#20;
        $finish;
    end
endmodule