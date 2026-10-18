
`timescale 1ns/1ps

module tb_rpm_period_measure;

    reg clk = 0;
    reg rst_n = 0;
    reg rpm_pulse = 0;

    wire [31:0] period_count;
    wire measurement_valid;
    wire pulse_timeout;

    integer errors = 0;

    rpm_period_measure #(
        .COUNTER_WIDTH(32),
        .TIMEOUT_CYCLES(100)
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
            @(negedge clk);
            rpm_pulse = 1;
            repeat (2) @(negedge clk);
            rpm_pulse = 0;
        end
    endtask

    always @(posedge clk) begin
    if (rst_n && (dut.rising_edge || measurement_valid ||
                  pulse_timeout)) begin
        $display(
            "t=%0t rising_edge=%b cycle_count=%0d period_count=%0d valid=%b timeout=%b",
            $time, dut.rising_edge, dut.cycle_count,
            period_count, measurement_valid, pulse_timeout
        );
    end
    end

    initial begin
        $dumpfile("waves/rpm_period_measure.vcd");
        $dumpvars(0, tb_rpm_period_measure);

        repeat (3) @(negedge clk);
        rst_n = 1;

        // First pulse establishes the reference.
        repeat (3) @(negedge clk);
        send_pulse();

        // Wait a known interval before the second pulse.
        repeat (10) @(negedge clk);
        send_pulse();

        // Wait for the measurement notification.
        wait (measurement_valid === 1'b1);
        #1;

        $display("DEBUG: period_count=%0d valid=%b timeout=%b",
                 period_count, measurement_valid, pulse_timeout);

        if (period_count == 13) begin
    $display("PASS: exact period count is 13");
end else begin
    $display("FAIL: expected 13, got %0d", period_count);
    errors = errors + 1;
end
        // Wait for valid to clear before testing timeout.
        @(negedge clk);
        wait (pulse_timeout === 1'b1);
        $display("PASS: timeout detected");

        if (errors == 0)
            $display("ALL DIAGNOSTIC CHECKS PASSED");
        else
            $display("DIAGNOSTIC CHECKS FAILED: %0d", errors);

        $finish;
    end

    initial begin
    #5000;
    $fatal(1, "FAIL: simulation watchdog expired");
end

endmodule
