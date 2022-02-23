`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/02 16:53:40
// Design Name: 
// Module Name: UDP_RX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UDP_RX(
  input clk,
  input rst_n,
  input [7:0] rx_value,
  input rx_valid,
  output rx_done,
  output [7:0] rx_data,
  output reg [31:0] data_sum,
  output reg [10:0] word_cnt,
  output reg rx_en
    );
  parameter BOARD_MAC = 48'h00_11_22_33_44_55;
  parameter BPARD_IP = {8'd192,8'd168,8'd1,8'd123};
  parameter CRC_VALUE = 8'ha5;
  parameter IDLE = 0;
  parameter PREAMBLE = 1;
  parameter MAC_HEAD = 2;
  parameter IP_HEAD = 3;
  parameter UDP_HEAD = 4;
  parameter RX_DATA = 5;
  parameter RX_CRC = 6;
  parameter RX_END = 7;

  reg [2:0] state;
  reg [2:0] next_state;
  reg [10:0] cnt;
  reg cnt_clr;
  reg preamble_err;
  wire mac_head_en;
  wire mac_err;
  reg [47:0] mac_addr;
  wire ip_head_en;
  wire ip_err;
  wire udp_head_en;
  reg [3:0] ip_length;
  reg [31:0] ip_addr;
  wire ip_addr_ok;
  wire rx_data_en;
  wire rx_data_done;
  wire fifo_wr_en;
  reg fifo_rd_en;
  reg [10:0] fifo_pop_cnt;
  reg rx_crc_err;
  wire rx_crc_done;
  reg rx_crc_done_d;
  wire [7:0] dout;
  reg [7:0] rx_value_d;

  rx_data_fifo rx_fifo (
    .clk(clk),                  // input wire clk
    .rst(~rst_n),                  // input wire rst
    .din(rx_value),                  // input wire [7 : 0] din
    .wr_en(fifo_wr_en),              // input wire wr_en
    .rd_en(fifo_rd_en),              // input wire rd_en
    .dout(dout),                // output wire [7 : 0] dout
    .full(),                // output wire full
    .empty(),              // output wire empty
    .wr_rst_busy(),  // output wire wr_rst_busy
    .rd_rst_busy()  // output wire rd_rst_busy
  );

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        state <= IDLE;
      end
      else begin
        state <= next_state;
      end
    end


  always @(*) begin
    next_state = state;
    case(state)
      IDLE: begin
        if(rx_valid && rx_value == 8'h55) begin
          next_state = PREAMBLE;
          cnt_clr = 1'b1;
        end
      end
      PREAMBLE: begin
          cnt_clr = 1'b0;
        if(preamble_err) begin
          next_state = RX_END;
        end
        else if(mac_head_en) begin
          next_state = MAC_HEAD;
          cnt_clr = 1'b1;
        end
      end
      MAC_HEAD: begin
          cnt_clr = 1'b0;
        if(mac_err) begin
          next_state = RX_END;
        end
        else if(ip_head_en) begin
          next_state = IP_HEAD;
          cnt_clr = 1'b1;
        end
      end
      IP_HEAD: begin
          cnt_clr = 1'b0;
        if(ip_err) begin
          next_state = RX_END;
        end
        else if(udp_head_en) begin
          next_state = UDP_HEAD;
          cnt_clr = 1'b1;
        end
      end
      UDP_HEAD: begin
          cnt_clr = 1'b0;
        if(rx_data_en) begin
          next_state = RX_DATA;
          cnt_clr = 1'b1;
        end
      end
      RX_DATA: begin
          cnt_clr = 1'b0;
        if(rx_data_done) begin
          next_state = RX_CRC;
          cnt_clr = 1'b1;
        end
      end
      RX_CRC: begin
          cnt_clr = 1'b0;
        if(rx_crc_err) begin
          next_state = RX_END;
        end
        else if(rx_crc_done) begin
          next_state = IDLE;
          cnt_clr = 1'b1;
        end
      end
      RX_END: begin
        if(!rx_valid) begin
          next_state = IDLE;
        end
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        cnt <= 11'b0;
      end
      else if (cnt_clr) begin
        cnt <= 11'b0;
      end
      else if (rx_valid) begin
        cnt <= cnt + 1'b1;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        preamble_err <= 1'b0;
      end
      else if(state == PREAMBLE && rx_valid) begin
        if(cnt < 5'd6 && rx_value != 8'h55) begin
          preamble_err <= 1'b1;
        end
        else if(cnt == 5'd6 && rx_value != 8'hd5) begin
          preamble_err <= 1'b1;
        end
      end
      else begin
        preamble_err <= 1'b0;
      end
  end

  assign mac_head_en = (state == PREAMBLE && rx_valid && cnt == 5'd6 && rx_value == 8'hd5);

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        mac_addr <= 48'b0;
      end
      else if(state == MAC_HEAD && rx_valid && cnt < 6) begin
        mac_addr <= {mac_addr[39:0], rx_value};
      end
      else begin
        mac_addr <= 48'b0;
      end
  end

  assign ip_head_en = (state == MAC_HEAD && cnt == 13 && rx_valid);
  assign mac_err = (state == MAC_HEAD && cnt == 5'd6 && (mac_addr != BOARD_MAC & mac_addr != 48'hffffff));

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        ip_length <= 4'b0;
      end
      else if(state == IP_HEAD && rx_valid && cnt == 0) begin
        ip_length <= rx_value[3:0];
      end
      else begin
        ip_length <= ip_length;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        ip_addr <= 32'b0;
      end
      else if(state == IP_HEAD && rx_valid && cnt >=16 && cnt <= 19) begin
        ip_addr <= {ip_addr[23:0], rx_value};
      end
      else begin
        ip_addr <= 32'b0;
      end
  end

  assign ip_addr_ok = (rx_value == BPARD_IP[7:0] && ip_addr[23:0] == BPARD_IP[31:8]);
  assign udp_head_en = (ip_length == 5) ? (state == IP_HEAD && rx_valid && cnt == 19 && ip_addr_ok) : state == IP_HEAD && rx_valid && ((cnt == 19 + (ip_length - 5)*4));
  assign ip_err = (state == IP_HEAD && rx_valid && cnt == 19 && !ip_addr_ok);

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        word_cnt <= 11'b0;
      end
      else if(state == UDP_HEAD && rx_valid) begin
        if (cnt == 4) begin
          word_cnt[10:8] <= rx_value;
        end
        else if (cnt == 5) begin
          word_cnt[7:0] <= rx_value;
        end
      end
      else begin
        word_cnt <= word_cnt;
      end
  end

  assign rx_data_en = (state == UDP_HEAD && rx_valid && cnt == 7);

  assign fifo_wr_en = (state == RX_DATA && rx_valid && cnt < word_cnt);

  assign rx_data_done = (state == RX_DATA && rx_valid && cnt == word_cnt - 1);


  assign rx_crc_done = (state == RX_CRC && rx_valid && cnt == 3);

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rx_crc_err <= 1'b0;
      end
      else if(state == RX_CRC && rx_valid && rx_value != CRC_VALUE) begin
        rx_crc_err <= 1'b1;
      end
      else begin
        rx_crc_err <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        fifo_rd_en <= 1'b0;
      end
      else if(state == RX_CRC && rx_valid && cnt == 3) begin
        fifo_rd_en <= 1'b1;
      end
      else if (fifo_pop_cnt == word_cnt - 1)begin
        fifo_rd_en <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        fifo_pop_cnt <= 11'b0;
      end
      else if(fifo_rd_en) begin
        fifo_pop_cnt <= fifo_pop_cnt + 1'b1;
      end
      else if(!fifo_rd_en)begin
        fifo_pop_cnt <= 11'b0;
      end
      else begin
        fifo_pop_cnt <= fifo_pop_cnt;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rx_crc_done_d <= 1'b0;
      end
      else begin
        rx_crc_done_d <= rx_crc_done;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rx_en <= 1'b0;
      end
      else if(rx_crc_done_d & !rx_crc_err) begin
        rx_en <= 1'b1;
      end
      else if (fifo_pop_cnt == word_cnt)begin
        rx_en <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        data_sum <= 32'b0;
      end
      else if(state == RX_DATA && rx_valid) begin
        if(cnt == 0) begin
          data_sum <= 32'b0;
        end
        else if(cnt[0]) begin
          data_sum <= data_sum + {rx_value_d, rx_value};
        end
        else if(cnt == word_cnt - 1) begin
          data_sum <= data_sum + {rx_value, 8'b0};
        end
        else begin
          data_sum <= data_sum;
        end
      end
      else begin
        data_sum <= data_sum;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rx_value_d <= 8'b0;
      end
      else if(state == RX_DATA && rx_valid) begin
        rx_value_d <= rx_value;
      end
      else begin
        rx_value_d <= rx_value_d;
      end
  end

  assign rx_data = rx_en ? dout : 8'b0;
  assign rx_done = rx_crc_done_d;
endmodule
