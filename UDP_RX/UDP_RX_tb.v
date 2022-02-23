`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/01/05 21:47:49
// Design Name: 
// Module Name: UDP_RX_tb
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


module UDP_RX_tb();


reg         clk;
reg         rst_n;
reg   [7:0] rx_value;
reg         rx_valid;

wire         rx_done;
wire   [7:0] rx_data;
wire         rx_en;


always #10 clk = ~clk;
initial begin
  clk = 0;
  rx_value = 0;
  rx_valid = 0;
  rst_n = 1;
  #40 rst_n = 0; #20 rst_n = 1;
  repeat (7) begin
  drive_udp_rx('h55);
  end
  drive_udp_rx('hd5);
//MAC
  drive_udp_rx('h00);
  drive_udp_rx('h11);
  drive_udp_rx('h22);
  drive_udp_rx('h33);
  drive_udp_rx('h44);
  drive_udp_rx('h55);
  drive_udp_rx('h34);
  drive_udp_rx('h56);
  drive_udp_rx('h78);
  drive_udp_rx('h34);
  drive_udp_rx('h56);
  drive_udp_rx('h78);
  drive_udp_rx('h34);
  drive_udp_rx('h56);
//IP
  drive_udp_rx('h76);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('d192);
  drive_udp_rx('d168);
  drive_udp_rx('d1);
  drive_udp_rx('d123);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
//UDP
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h00);
  drive_udp_rx('h0f);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
//DATA
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('ha5);
  drive_udp_rx('ha5);
  drive_udp_rx('ha5);
  drive_udp_rx('ha4);
  @ (posedge clk);
  #1;
  rx_valid = 0;

  repeat (7) begin
  drive_udp_rx('h55);
  end
  drive_udp_rx('hd5);
//MAC
  drive_udp_rx('h00);
  drive_udp_rx('h11);
  drive_udp_rx('h22);
  drive_udp_rx('h33);
  drive_udp_rx('h44);
  drive_udp_rx('h55);
  drive_udp_rx('h34);
  drive_udp_rx('h56);
  drive_udp_rx('h78);
  drive_udp_rx('h34);
  drive_udp_rx('h56);
  drive_udp_rx('h78);
  drive_udp_rx('h34);
  drive_udp_rx('h56);
//IP
  drive_udp_rx('h76);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('d192);
  drive_udp_rx('d168);
  drive_udp_rx('d1);
  drive_udp_rx('d123);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
//UDP
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h00);
  drive_udp_rx('h10);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
//DATA
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('h75);
  drive_udp_rx('h12);
  drive_udp_rx('h35);
  drive_udp_rx('h78);
  drive_udp_rx('ha5);
  drive_udp_rx('ha5);
  drive_udp_rx('ha5);
  drive_udp_rx('ha5);
  #50;
end

UDP_RX U_UDP_RX_0
(  .clk      ( clk      ),
   .rst_n    ( rst_n    ),
   .rx_value ( rx_value ),
   .rx_valid ( rx_valid ),
   .rx_done  ( rx_done  ),
   .rx_data  ( rx_data  ),
   .rx_en    ( rx_en    ));


  task drive_udp_rx (input bit[7:0] data);
    @ (posedge clk);
    #1;
    rx_valid = 1;
    rx_value = data;
  endtask
endmodule
