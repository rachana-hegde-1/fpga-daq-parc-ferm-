
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
        .TIMEOUT_CYCLES(20)
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
            @(negedge clk);
            rpm_pulse = 0;
        end
    endtask

    task check;
        input condition;
        input [8*80-1:0] message;
        begin
            if (condition)
                $display("PASS: %0s", message);
            else begin
                $display("FAIL: %0s", message);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waves/rpm_period_measure.vcd");
        $dumpvars(0, tb_rpm_period_measure);

        // Reset check
        repeat (2) @(negedge clk);
        check(period_count == 0, "period_count starts at zero during reset");
        check(measurement_valid == 0, "measurement_valid starts low");

        rst_n = 1;
        repeat (2) @(negedge clk);

        // First pulse establishes a reference.
        send_pulse();

        // A second pulse should produce a measurement.
        repeat (9) @(negedge clk);
        send_pulse();

        // Allow nonblocking assignments to settle.
        @(negedge clk);
        check(measurement_valid == 0,
              "measurement_valid returns low after its pulse");
        check(period_count > 0,
              "a period measurement was captured");

        // No further pulses: wait for timeout.
        wait (pulse_timeout == 1'b1);
        check(pulse_timeout == 1,
              "missing pulses trigger timeout");

        // Let timeout clear and establish a new reference pulse.
        @(negedge clk);
        @(negedge clk);
        send_pulse();

        // Send another pulse before timeout.
        repeat (5) @(negedge clk);
        send_pulse();

        @(negedge clk);
        check(period_count > 0,
              "measurement resumes after timeout");

        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\nTESTS FAILED: %0d error(s)", errors);

        $finish;
    end

    initial begin
        #2000;
        $display("FAIL: Simulation watchdog expired");
        $finish;
    end

endmodule
