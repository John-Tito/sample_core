// ---------------------------------------------------------------------------------------
// Copyright (c) 2024 john_tito All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ---------------------------------------------------------------------------------------
// +FHEADER-------------------------------------------------------------------------------
// Author        : john_tito
// Module Name   : sample_core_tb
// ---------------------------------------------------------------------------------------
// Revision      : 1.0
// Description   : File Created
// ---------------------------------------------------------------------------------------
// Synthesizable : Yes
// Clock Domains : clk
// Reset Strategy: sync reset
// -FHEADER-------------------------------------------------------------------------------

// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sample_core_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;
    localparam integer TBYTES = 1;
    localparam integer PRE_SAMPLES = 4;  // 采样点数
    localparam integer POST_SAMPLES = 4;  // 采样点数

    localparam integer MASTER_DLY_TIME = 8;
    localparam integer SLAVE_DLY_TIME = 4;
    localparam integer TRIG_DLY_TIME = 8;

    localparam REAL_TRIG = 1;
    localparam REAL_MASTER = 1;
    localparam REAL_SLAVE = 1;

    // Ports
    reg                 clk = 0;
    reg                 rst = 0;
    reg  [        31:0] cfg_pre_sample_num = 0;
    reg  [        31:0] cfg_post_sample_num = 0;

    reg  [TBYTES*8-1:0] s_tdata = 0;
    reg                 s_tvalid = 0;
    reg                 trig_in = 1'b0;
    reg                 m_tready = 1'b0;
    wire                s_tready;

    sample_core #(
        .TBYTES(TBYTES)
    ) sample_core_inst (
        .clk                (clk),
        .rst                (rst),
        .cfg_pre_sample_num (cfg_pre_sample_num),
        .cfg_post_sample_num(cfg_post_sample_num),
        .sample_clr         (1'b0),
        .sample_en          (1'b1),
        .sample_busy        (),
        .sample_done        (),
        .trig_in            (trig_in),
        .trig_out           (),
        .s_tdata            (s_tdata),
        .s_tvalid           (s_tvalid),
        .s_tready           (s_tready),
        .m_tdata            (),
        .m_tvalid           (),
        .m_tready           (m_tready),
        .m_tlast            ()
    );


    reg  [7:0] master_dly_cnt;
    reg  [7:0] trig_dly_cnt;
    reg  [7:0] slave_dly_cnt;
    wire       s_active;
    wire       m_active;
    wire       master_update;

    assign s_active      = s_tvalid & s_tready;
    assign master_update = (master_dly_cnt == (MASTER_DLY_TIME - 1)) || (REAL_MASTER == 0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            master_dly_cnt <= 0;
        end else begin
            if (s_active) begin
                master_dly_cnt <= 0;
            end else begin
                if (!s_tvalid && (master_dly_cnt < (MASTER_DLY_TIME - 1))) begin
                    master_dly_cnt <= master_dly_cnt + 1;
                end else begin
                    master_dly_cnt <= 0;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_tvalid <= 1'b0;
        end else begin
            if (REAL_MASTER) begin
                if (s_active) begin
                    s_tvalid <= 1'b0;
                end else if (master_update) begin
                    s_tvalid <= 1'b1;
                end
            end else begin
                s_tvalid <= 1'b1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            trig_dly_cnt <= 0;
        end else begin
            if (master_update) begin
                if ((REAL_TRIG == 1) && (trig_dly_cnt < (TRIG_DLY_TIME - 1))) begin
                    trig_dly_cnt <= trig_dly_cnt + 1;
                end else begin
                    trig_dly_cnt <= 0;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            trig_in <= 1'b0;
        end else begin
            if (REAL_TRIG == 1) begin
                trig_in <= (trig_dly_cnt == (TRIG_DLY_TIME - 1));
            end else begin
                trig_in <= 1'b1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            slave_dly_cnt <= 0;
        end else begin
            if (m_active) begin
                slave_dly_cnt <= 0;
            end else begin
                if ((REAL_SLAVE == 1) && (slave_dly_cnt < (SLAVE_DLY_TIME - 1))) begin
                    slave_dly_cnt <= slave_dly_cnt + 1;
                end else begin
                    slave_dly_cnt <= 0;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_tready <= 0;
        end else begin
            if (REAL_SLAVE == 1) begin
                m_tready <= (slave_dly_cnt == (SLAVE_DLY_TIME - 1));
            end else begin
                m_tready <= 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_tdata <= 0;
        end else begin
            if (s_active) begin
                s_tdata <= s_tdata + 1;
            end
        end
    end

    initial begin
        begin
            wait (~rst);
            #100;
            cfg_pre_sample_num  = PRE_SAMPLES;
            cfg_post_sample_num = POST_SAMPLES;
            #100;
            #1000000;
            $finish;
        end
    end

    always #5 clk = !clk;

    // reset block
    initial begin
        rst = 1'b1;
        #(TIMEPERIOD * 32);
        rst = 1'b0;
    end

    // record block
    initial begin
        $dumpfile("sim/test_tb.vcd");
        $dumpvars(0, sample_core_tb);
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
