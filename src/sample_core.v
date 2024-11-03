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
// Module Name   : sample_core
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

module sample_core #(
    parameter integer TBYTES = 8
) (
    input  wire                clk,
    input  wire                rst,
    // config
    input  wire [        31:0] cfg_pre_sample_num,   // 总采样点数
    input  wire [        31:0] cfg_post_sample_num,  // 总采样点数
    // sample control and state
    input  wire                sample_clr,           //
    input  wire                sample_en,            //
    output reg                 sample_busy,          //
    output reg                 sample_done,          //
    // trig
    input  wire                trig_in,              // 触发信号
    output reg                 trig_out,
    // sample data in
    input  wire [TBYTES*8-1:0] s_tdata,
    input  wire                s_tvalid,
    output reg                 s_tready,
    // sample data out
    output reg  [TBYTES*8-1:0] m_tdata,
    output reg                 m_tvalid,
    output reg                 m_tlast,
    input  wire                m_tready
);

    //
    localparam FSM_IDLE = 8'h00;
    localparam FSM_WAIT = 8'h01;
    localparam FSM_PRE = 8'h02;
    localparam FSM_POST = 8'h04;
    localparam FSM_END = 8'h05;

    reg  [ 7:0] c_state;  // 状态机初态
    reg  [ 7:0] n_state;  // 状态机次态

    reg  [31:0] pre_num;
    reg         pre_en;
    reg  [31:0] pre_cnt;
    wire        pre_cnt_almost_done;

    reg  [31:0] post_num;
    reg         post_en;
    reg  [31:0] post_cnt;
    wire        post_cnt_almost_done;

    wire        s_active;
    wire        m_active;

    assign s_active             = s_tvalid & s_tready;
    assign m_active             = m_tvalid & m_tready;

    assign pre_cnt_almost_done  = (pre_cnt + 1 >= pre_num);
    assign post_cnt_almost_done = (post_cnt + 1 >= post_num);

    // ***********************************************************************************
    // handle config
    // ***********************************************************************************

    // 锁存配置信息
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pre_num  <= 0;
            pre_en   <= 0;
            post_num <= 0;
            post_en  <= 0;
        end else begin
            case (n_state)
                FSM_IDLE: begin
                    pre_num  <= cfg_pre_sample_num;
                    pre_en   <= (cfg_pre_sample_num > 0);
                    post_num <= cfg_post_sample_num;
                    post_en  <= (cfg_post_sample_num > 0);
                end
                default: begin
                    pre_num  <= pre_num;
                    pre_en   <= pre_en;
                    post_num <= post_num;
                    post_en  <= post_en;
                end
            endcase
        end
    end

    // ***********************************************************************************
    // handle fsm
    // ***********************************************************************************

    // 状态更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= FSM_IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    // 状态跳转
    always @(*) begin : fsm_update
        if (rst || sample_clr) begin
            n_state = FSM_IDLE;
        end else begin
            case (c_state)
                FSM_IDLE: begin
                    if (sample_en == 1'b1) begin
                        case ({
                            pre_en, post_en
                        })
                            2'b01:   n_state = FSM_WAIT;
                            2'b10:   n_state = FSM_PRE;
                            2'b11:   n_state = FSM_PRE;
                            default: n_state = FSM_IDLE;
                        endcase
                    end else begin
                        n_state = FSM_IDLE;
                    end
                end
                FSM_WAIT: begin
                    if (s_active && trig_in) begin
                        n_state = FSM_POST;
                    end else begin
                        n_state = FSM_WAIT;
                    end
                end
                FSM_PRE: begin
                    if (s_active && pre_cnt_almost_done && trig_in) begin
                        if (post_en) begin
                            n_state = FSM_POST;
                        end else begin
                            n_state = FSM_END;
                        end
                    end else begin
                        n_state = FSM_PRE;
                    end
                end
                FSM_POST: begin
                    if (s_active && (post_cnt_almost_done)) begin
                        n_state = FSM_END;
                    end else begin
                        n_state = FSM_POST;
                    end
                end
                FSM_END: begin
                    if (m_active) begin
                        n_state = FSM_IDLE;
                    end else begin
                        n_state = FSM_END;
                    end
                end
                default: n_state = FSM_IDLE;
            endcase
        end
    end

    // ***********************************************************************************
    // handle state
    // ***********************************************************************************
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_busy <= 1'b1;
        end else begin
            case (n_state)
                FSM_IDLE: sample_busy <= 1'b0;
                default:  sample_busy <= 1'b1;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_done <= 1'b0;
        end else begin
            sample_done <= m_active & m_tlast;
        end
    end

    // ***********************************************************************************
    // handle counter
    // ***********************************************************************************
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pre_cnt <= 0;
        end else begin
            case (n_state)
                FSM_PRE: begin
                    if (s_active) begin
                        pre_cnt <= pre_cnt + 1;
                    end else begin
                        pre_cnt <= pre_cnt;
                    end
                end
                default: pre_cnt <= 0;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            post_cnt <= 0;
        end else begin
            case (n_state)
                FSM_POST: begin
                    // 此处为凑时序
                    // 若 pre_en 为 0 则可直接开始计数
                    // 若 pre_en 为 1 则跳过第一个计数
                    if (s_active && !(pre_en && pre_cnt_almost_done)) begin
                        post_cnt <= post_cnt + 1;
                    end else begin
                        post_cnt <= post_cnt;
                    end
                end
                default: post_cnt <= 0;
            endcase
        end
    end

    // ***********************************************************************************
    // handle data output
    // ***********************************************************************************
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_tdata  <= 0;
            m_tvalid <= 1'b0;
        end else begin
            case (n_state)
                FSM_PRE, FSM_POST, FSM_END: begin
                    if (s_active) begin
                        m_tdata  <= s_tdata;
                        m_tvalid <= s_tvalid;
                    end else if (m_active) begin
                        m_tdata  <= 0;
                        m_tvalid <= 1'b0;
                    end
                end
                default: begin
                    m_tdata  <= 0;
                    m_tvalid <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_tlast <= 1'b0;
        end else begin
            case (n_state)
                FSM_END: begin
                    m_tlast <= 1'b1;
                end
                default: begin
                    m_tlast <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        case (c_state)
            FSM_WAIT, FSM_PRE, FSM_POST: s_tready = (m_tready | ~m_tvalid);
            default:                     s_tready = 1'b0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            trig_out <= 1'b0;
        end else begin
            case (c_state)
                FSM_WAIT: begin
                    if (s_active) begin
                        trig_out <= trig_in;
                    end else if (m_active) begin
                        trig_out <= 1'b0;
                    end
                end
                FSM_PRE: begin
                    if (s_active) begin
                        trig_out <= pre_cnt_almost_done && trig_in;
                    end else if (m_active) begin
                        trig_out <= 1'b0;
                    end
                end
                FSM_POST, FSM_END: begin
                    if (m_active) begin
                        trig_out <= 1'b0;
                    end
                end
                default: trig_out <= 1'b0;
            endcase
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
