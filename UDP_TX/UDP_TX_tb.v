`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/18 22:18:09
// Design Name: 
// Module Name: UDP_TX_tb
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


module UDP_TX_tb();


reg          clk;
reg          rst_n;
reg          tx_start_en;
reg   [7:0]  tx_value;
reg   [10:0] word_cnt;
reg   [31:0] data_sum;

wire         tx_done;
wire         tx_req;
wire   [7:0] tx_data;
wire         tx_valid;


always #10 clk = ~clk;
initial begin
  clk = 0;
  tx_start_en = 0;
  tx_value = 0;
  word_cnt = 15;
  data_sum = 32'h12345678;
  rst_n = 1;
  #40 rst_n = 0; #20 rst_n = 1;
  @(posedge clk);
  #1 tx_start_en = 1;
  wait(tx_done == 1);
  tx_start_en = 0;
  #2000;

  @(posedge clk);
  #1 tx_start_en = 1;
  wait(tx_done == 1);
  tx_start_en = 0;
  #2000;
end

  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        tx_value <= 8'b0;
      end
      else if(tx_req) begin
        tx_value <= tx_value + 1'b1;
      end
      else begin
        tx_value <= tx_value;
      end
  end

UDP_TX U_UDP_TX_0
(  .clk         ( clk         ),
   .rst_n       ( rst_n       ),
   .tx_start_en ( tx_start_en ),
   .tx_value    ( tx_value    ),
   .word_cnt    ( word_cnt    ),
   .data_sum    ( data_sum    ),
   .tx_done     ( tx_done     ),
   .tx_req      ( tx_req      ),
   .tx_data     ( tx_data     ),
   .tx_valid    ( tx_valid    ));



endmodule
