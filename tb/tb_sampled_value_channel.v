`timescale 1ns/1ps

module tb_sampled_value_channel;

    reg clk = 0;
    reg rst_n = 0;
    reg [15:0] sample_in = 0;
    reg sample_valid = 0;

    wire [15:0] sample_out;
    wire measurement_valid;

    integer errors = 0;

    sampled_value_channel #(
        .DATA_WIDTH(16)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .sample_out(sample_out),
        .measurement_valid(measurement_valid)
    );

    always #5 clk = ~clk;

    task submit_sample;
        input [15:0] value;
        begin
            @(negedge clk);
            sample_in = value;
            sample_valid = 1'b1;

            @(negedge clk);
            sample_valid = 1'b0;

            #1;
            if (sample_out !== value || measurement_valid !== 1'b1) begin
                $display("FAIL: expected %0d, got %0d, valid=%b",
                         value, sample_out, measurement_valid);
                errors = errors + 1;
            end else begin
                $display("PASS: captured sample %0d", sample_out);
            end

            @(negedge clk);
            #1;
            if (measurement_valid !== 1'b0) begin
                $display("FAIL: valid did not clear");
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        submit_sample(16'd95);
        submit_sample(16'd420);
        submit_sample(16'd275);

        @(negedge clk);
        rst_n = 1'b0;
        #1;

        if (sample_out !== 16'd0 ||
            measurement_valid !== 1'b0) begin
            $display("FAIL: reset did not clear outputs");
            errors = errors + 1;
        end else begin
            $display("PASS: reset clears outputs");
        end

        if (errors == 0)
            $display("ALL SAMPLED CHANNEL CHECKS PASSED");
        else
            $fatal(1, "SAMPLED CHANNEL CHECKS FAILED: %0d", errors);

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "FAIL: simulation watchdog expired");
    end

endmodule
