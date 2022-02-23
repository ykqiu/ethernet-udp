`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/10 22:00:20
// Design Name: 
// Module Name: UDP_TX
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


module UDP_TX(
  input clk,
  input rst_n,
  input tx_start_en,
  input [7:0] tx_value,
  input [10:0] word_cnt,
  input [31:0] data_sum,
  output reg tx_done,
  output reg tx_req,
  output reg [7:0] tx_data,
  output reg tx_valid
    );
  parameter BOARD_MAC = 48'h00_11_22_33_44_55;
  parameter DES_MAC = 48'hff_ff_ff_ff_ff_ff;
  parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd123};
  parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};

  reg start_d;
  wire start_pos;
  reg [2:0] state;
  reg [2:0] next_state;
  reg [10:0] cnt;
  reg [10:0] udp_length;
  reg cnt_clr;
  reg mac_head_en;
  reg ip_head_en;
  reg udp_head_en;
  reg tx_data_en;
  reg tx_idle_en;
  reg tx_crc_en;
  reg [7:0] ip_head [19:0];
  reg [19:0] check_sum;
  reg [31:0] udp_check_sum;
  parameter IDLE = 0;
  parameter PREAMBLE = 1;
  parameter MAC_HEAD = 2;
  parameter IP_HEAD = 3;
  parameter UDP_HEAD = 4;
  parameter TX_DATA = 5;
  parameter TX_CRC = 6;

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        state <= IDLE;
      end
      else begin
        state <= next_state;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        cnt <= 11'b0;
      end
      else if (cnt_clr) begin
        cnt <= 11'b0;
      end
      else begin
        cnt <= cnt + 1'b1;
      end
    end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        start_d <= 1'b0;
      end
      else begin
        start_d <= tx_start_en;
      end
  end

  assign start_pos = ({start_d, tx_start_en} == 2'b01);

  always @(*) begin
    next_state = state;
    case(state)
      IDLE: begin
        if(start_pos) begin
          next_state = PREAMBLE;
          cnt_clr = 1'b1;
        end
      end
      PREAMBLE: begin
        cnt_clr = 1'b0;
        if(mac_head_en) begin
          next_state = MAC_HEAD;
          cnt_clr = 1'b1;
        end
      end
      MAC_HEAD: begin
        cnt_clr = 1'b0;
        if(ip_head_en) begin
          next_state = IP_HEAD;
          cnt_clr = 1'b1;
        end
      end
      IP_HEAD: begin
        cnt_clr = 1'b0;
        if(udp_head_en) begin
          next_state = UDP_HEAD;
          cnt_clr = 1'b1;
        end
      end
      UDP_HEAD: begin
        cnt_clr = 1'b0;
        if(tx_data_en) begin
          next_state = TX_DATA;
          cnt_clr = 1'b1;
        end
      end
      TX_DATA: begin
        cnt_clr = 1'b0;
        if(tx_crc_en) begin
          next_state = TX_CRC;
          cnt_clr = 1'b1;
        end
      end
      TX_CRC: begin
        cnt_clr = 1'b0;
        if(tx_idle_en) begin
          next_state = IDLE;
          cnt_clr = 1'b1;
        end
      end
    endcase
  end


  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_data <= 8'b0;
      end
      else begin
        case(state)
          PREAMBLE: begin
            if(cnt < 7) begin
              tx_data <= 8'h55;
            end
            else if (cnt == 7) begin
              tx_data <= 8'hd5;
            end
          end
          MAC_HEAD: begin
            if(cnt < 6) begin
              tx_data <= DES_MAC[47 - 8*cnt -: 8];
            end
            else if(cnt >= 6 && cnt < 12) begin
              tx_data <= BOARD_MAC[47 - 8*cnt + 48 -: 8];
            end
            else if(cnt == 12) begin
              tx_data <= 8'h08;
            end
            else if(cnt == 13) begin
              tx_data <= 8'h00;
            end
          end
          IP_HEAD: begin
            tx_data <= ip_head[cnt];
          end
          UDP_HEAD: begin
            if(cnt == 0) begin
              tx_data <= 8'h12;
            end
            else if(cnt == 1) begin
              tx_data <= 8'h34;
            end
            else if(cnt == 2) begin
              tx_data <= 8'h12;
            end
            else if(cnt == 3) begin
              tx_data <= 8'h34;
            end
            else if(cnt == 4) begin
              tx_data <= {5'b0, udp_length[10:8]};
            end
            else if(cnt == 5) begin
              tx_data <= udp_length[7:0];
            end
            else if(cnt == 6) begin
              tx_data <= udp_check_sum[15:8];
            end
            else if(cnt == 7) begin
              tx_data <= udp_check_sum[7:0];
            end
          end
          TX_DATA: begin
            tx_data <= tx_value;
          end
          TX_CRC: begin
            if(cnt == 0) begin
              tx_data <= 8'ha5;
            end
            if(cnt == 1) begin
              tx_data <= 8'ha6;
            end
            if(cnt == 2) begin
              tx_data <= 8'ha7;
            end
            if(cnt == 3) begin
              tx_data <= 8'ha8;
            end
          end
        endcase
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        mac_head_en <= 1'b0;
      end
      else if(state == PREAMBLE && cnt == 6) begin
        mac_head_en <= 1'b1;
      end
      else begin
        mac_head_en <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        ip_head_en <= 1'b0;
      end
      else if(state == MAC_HEAD && cnt == 12) begin
        ip_head_en <= 1'b1;
      end
      else begin
        ip_head_en <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        udp_head_en <= 1'b0;
      end
      else if(state == IP_HEAD && cnt == 18) begin
        udp_head_en <= 1'b1;
      end
      else begin
        udp_head_en <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_data_en <= 1'b0;
      end
      else if(state == UDP_HEAD && cnt == 6) begin
        tx_data_en <= 1'b1;
      end
      else begin
        tx_data_en <= 1'b0;
      end
    end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_crc_en <= 1'b0;
      end
      else if(state == TX_DATA && cnt == word_cnt - 2) begin
        tx_crc_en <= 1'b1;
      end
      else begin
        tx_crc_en <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_req <= 1'b0;
      end
      else if(state == UDP_HEAD && cnt >= 6) begin
        tx_req <= 1'b1;
      end
      else if(state == TX_DATA && cnt < word_cnt - 2) begin
        tx_req <= 1'b1;
      end
      else if(state == TX_DATA && cnt == word_cnt - 2) begin
        tx_req <= 1'b0;
      end
      else begin
        tx_req <= 1'b0;
      end
    end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_idle_en <= 1'b0;
      end
      else if(state == TX_CRC && cnt == 2) begin
        tx_idle_en <= 1'b1;
      end
      else begin
        tx_idle_en <= 1'b0;
      end
    end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_done <= 1'b0;
      end
      else if(state == TX_CRC && cnt == 3) begin
        tx_done <= 1'b1;
      end
      else begin
        tx_done <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_valid <= 1'b0;
      end
      else if(state != IDLE) begin
        tx_valid <= 1'b1;
      end
      else begin
        tx_valid <= 1'b0;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        ip_head[0] <= 8'h45;
        ip_head[1] <= 8'h0;
        {ip_head[2], ip_head[3]} <= 16'b0;
        {ip_head[4], ip_head[5]} <= 16'h0;
        {ip_head[6], ip_head[7]} <= 16'h4000;
        ip_head[8] <= 8'h40;
        ip_head[9] <= 8'h11;
        {ip_head[10], ip_head[11]} <= 16'h0;
        {ip_head[12], ip_head[13], ip_head[14], ip_head[15]} <= BOARD_IP;
        {ip_head[16], ip_head[17], ip_head[18], ip_head[19]} <= DES_IP;
      end
      else if(state == IP_HEAD) begin
        if(cnt == 0) begin
          {ip_head[2], ip_head[3]} <= word_cnt + 5'd28;
          {ip_head[4], ip_head[5]} <= {ip_head[4], ip_head[5]} + 1'b1;
        end
        else if(cnt == 3) begin
          {ip_head[10], ip_head[11]} <= ~check_sum;
        end
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        check_sum <= 20'b0;
      end
      else if(state == IP_HEAD) begin
        if(cnt == 1) begin
          check_sum <= {ip_head[0], ip_head[1]}
                       + {ip_head[2], ip_head[3]}
                       + {ip_head[4], ip_head[5]}
                       + {ip_head[6], ip_head[7]}
                       + {ip_head[8], ip_head[9]}
                       + {ip_head[10], ip_head[11]}
                       + {ip_head[12], ip_head[13]}
                       + {ip_head[14], ip_head[15]}
                       + {ip_head[16], ip_head[17]}
                       + {ip_head[18], ip_head[19]};
        end
        else if(cnt == 2) begin
          check_sum <= check_sum[19:16] + check_sum[15:0];
        end
      end
      else begin
        check_sum <= check_sum;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        udp_check_sum <= 32'b0;
      end
      else if(state == UDP_HEAD) begin
        if(cnt == 0) begin
          udp_check_sum <= {ip_head[12], ip_head[13]} + {ip_head[14], ip_head[15]}+ {ip_head[16], ip_head[17]} + {ip_head[18], ip_head[19]};
        end
        else if(cnt == 1) begin
          udp_check_sum <= udp_check_sum + 16'h11 + {5'b0, udp_length} + 16'h1234 + 16'h1234 + {5'b0, udp_length};
        end
        else if(cnt == 2) begin
          udp_check_sum <= udp_check_sum + data_sum;
        end
        else if(cnt == 3) begin
          udp_check_sum <= udp_check_sum[31:16] + udp_check_sum[15:0];
        end
        else if(cnt == 4) begin
          udp_check_sum <= udp_check_sum[31:16] + udp_check_sum[15:0];
        end
        else if(cnt == 5) begin
          udp_check_sum <= ~udp_check_sum;
        end
        else begin
          udp_check_sum <= udp_check_sum;
        end
      end
      else begin
        udp_check_sum <= udp_check_sum;
      end
  end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        udp_length <= 11'b0;
      end
      else if(state == UDP_HEAD && cnt == 0) begin
        udp_length <= word_cnt + 'd8;
      end
      else begin
        udp_length <= udp_length;
      end
  end
endmodule
