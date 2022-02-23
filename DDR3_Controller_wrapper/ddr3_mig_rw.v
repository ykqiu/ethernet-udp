`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/02/09 21:52:33
// Design Name: 
// Module Name: ddr3_mig_rw
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


module ddr3_mig_rw(
  input clk,
  input rst_n
    );
   parameter COL_WIDTH             = 10;
                                     // # of memory Column Address bits.
   parameter CS_WIDTH              = 1;
                                     // # of unique CS outputs to memory.
   parameter DM_WIDTH              = 2;
                                     // # of DM (data mask)
   parameter DQ_WIDTH              = 16;
                                     // # of DQ (data)
   parameter DQS_WIDTH             = 2;
   parameter DQS_CNT_WIDTH         = 1;
                                     // = ceil(log2(DQS_WIDTH))
   parameter DRAM_WIDTH            = 8;
                                     // # of DQ per DQS
   parameter ECC                   = "OFF";
   parameter RANKS                 = 1;
                                     // # of Ranks.
   parameter ODT_WIDTH             = 1;
                                     // # of ODT outputs to memory.
   parameter ROW_WIDTH             = 14;
                                     // # of memory Row Address bits.
   parameter ADDR_WIDTH            = 28;

  wire                               ddr3_reset_n;
  wire [DQ_WIDTH-1:0]                ddr3_dq;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n;
  wire [ROW_WIDTH-1:0]               ddr3_addr;
  wire [3-1:0]              ddr3_ba;
  wire                               ddr3_ras_n;
  wire                               ddr3_cas_n;
  wire                               ddr3_we_n;
  wire [1-1:0]               ddr3_cke;
  wire [1-1:0]                ddr3_ck_p;
  wire [1-1:0]                ddr3_ck_n;
    
  
  wire                               init_calib_complete;
  wire [(CS_WIDTH*1)-1:0] ddr3_cs_n;
    
  wire [DM_WIDTH-1:0]                ddr3_dm;
    
  wire [ODT_WIDTH-1:0]               ddr3_odt;
    
  
  reg [(CS_WIDTH*1)-1:0] ddr3_cs_n_tmp;
    
  reg [DM_WIDTH-1:0]                 ddr3_dm_tmp;
    
  reg [ODT_WIDTH-1:0]                ddr3_odt_tmp;

  reg [27:0] app_addr;
  wire [2:0] app_cmd;
  wire  app_en;
  reg [127:0] app_wdf_data;
  reg [127:0] rd_data;
  wire  app_wdf_end;
  wire  app_wdf_wren;
  wire [127:0] app_rd_data;
  wire  app_rd_data_end;
  wire  app_rd_data_valid;
  wire  app_rdy;
  wire  app_wdf_rdy;
  //reg  app_sr_req          
  //reg  app_ref_req         
  //reg  app_zq_req          
  //reg  app_sr_active       
  //reg  app_ref_ack         
  //reg  app_zq_ack          
  wire sys_clk_i;
  wire  ui_clk;
  wire  ui_clk_sync_rst;
  wire [15:0] app_wdf_mask;

  reg [1:0] state;
  reg [1:0] next_state;
  
  parameter IDLE = 2'b0;
  parameter WRITE = 2'b1;
  parameter READ = 2'b11;

  always @(posedge ui_clk or posedge ui_clk_sync_rst) begin
      if(ui_clk_sync_rst) begin
        state <= IDLE;
      end
      else begin
        state <= next_state;
      end
  end

  always @(*) begin
      next_state = state;
      case(state)
        IDLE:
          if(init_calib_complete) begin
            next_state = WRITE;
          end
        WRITE:
          if(app_wdf_data == 8'd255 && app_rdy && app_wdf_rdy) begin
            next_state = READ;
          end
        READ:
          if(app_addr == 255 * 8 && app_rdy) begin
            next_state = IDLE;
          end
        endcase
  end




  always @(posedge ui_clk or posedge ui_clk_sync_rst) begin
      if(ui_clk_sync_rst) begin
        app_wdf_data <= 128'b0;
      end
      else if(state == WRITE) begin
        if(app_rdy && app_wdf_rdy) begin
          app_wdf_data <= app_wdf_data + 1'b1;
        end
        else begin
          app_wdf_data <= app_wdf_data;
        end
      end
      else begin
        app_wdf_data <= 128'b0;
      end
  end

  always @(posedge ui_clk or posedge ui_clk_sync_rst) begin
      if(ui_clk_sync_rst) begin
        app_addr <= 28'b0;
      end
      else if(state == WRITE) begin
        if(app_rdy && app_wdf_rdy) begin
          if(app_addr == 8 * 255) begin
            app_addr <= 28'b0;
          end
          else begin
            app_addr <= app_addr + 'd8;
          end
        end
      end
      else if(state == READ) begin
        if(app_rdy) begin
          if(app_addr == 8 * 255) begin
            app_addr <= 28'b0;
          end
          else begin
            app_addr <= app_addr + 'd8;
          end
        end
      end
  end

  assign app_wdf_wren = (state == WRITE) && app_rdy && app_wdf_rdy;
  assign app_en = (state == WRITE)? app_rdy && app_wdf_rdy : (state == READ)? app_rdy : 1'b0;
  assign app_cmd = (state == READ) ? 3'd1 :3'd0;
  assign app_wdf_end = app_wdf_wren;
  assign app_wdf_mask = 16'b0;
  assign app_sr_req = 1'b0;
  assign app_ref_req = 1'b0;
  assign app_zq_req = 1'b0;

  clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1(sys_clk_i),     // output clk_out1
    // Status and control signals
    .resetn(rst_n), // input resetn
    .locked(),       // output locked
   // Clock in ports
    .clk_in1(clk));      // input clk_in1


      ddr3_ctrl u_ddr3_ctrl (

    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),  // output [13:0]		ddr3_addr
    .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
    .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
    .ddr3_dq                        (ddr3_dq),  // inout [15:0]		ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [1:0]		ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [1:0]		ddr3_dqs_p
    .init_calib_complete            (init_calib_complete),  // output			init_calib_complete
      
  .ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]		ddr3_cs_n
    .ddr3_dm                        (ddr3_dm),  // output [1:0]		ddr3_dm
    .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt
    // Application interface ports
    .app_addr                       (app_addr),  // input [27:0]		app_addr
    .app_cmd                        (app_cmd),  // input [2:0]		app_cmd
    .app_en                         (app_en),  // input				app_en
    .app_wdf_data                   (app_wdf_data),  // input [127:0]		app_wdf_data
    .app_wdf_end                    (app_wdf_end),  // input				app_wdf_end
    .app_wdf_wren                   (app_wdf_wren),  // input				app_wdf_wren
    .app_rd_data                    (app_rd_data),  // output [127:0]		app_rd_data
    .app_rd_data_end                (app_rd_data_end),  // output			app_rd_data_end
    .app_rd_data_valid              (app_rd_data_valid),  // output			app_rd_data_valid
    .app_rdy                        (app_rdy),  // output			app_rdy
    .app_wdf_rdy                    (app_wdf_rdy),  // output			app_wdf_rdy
    .app_sr_req                     (app_sr_req),  // input			app_sr_req
    .app_ref_req                    (app_ref_req),  // input			app_ref_req
    .app_zq_req                     (app_zq_req),  // input			app_zq_req
    .app_sr_active                  (app_sr_active),  // output			app_sr_active
    .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack
    .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack
    .ui_clk                         (ui_clk),  // output			ui_clk
    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst
    .app_wdf_mask                   (app_wdf_mask),  // input [15:0]		app_wdf_mask
    // System Clock Ports
    .sys_clk_i                       (sys_clk_i),
    .sys_rst                        (rst_n) // input sys_rst
    );

    ddr3_model u_comp_ddr3
      (
       .rst_n   (ddr3_reset_n),
       .ck      (ddr3_ck_p),
       .ck_n    (ddr3_ck_n),
       .cke     (ddr3_cke),
       .cs_n    (ddr3_cs_n),
       .ras_n   (ddr3_ras_n),
       .cas_n   (ddr3_cas_n),
       .we_n    (ddr3_we_n),
       .dm_tdqs (ddr3_dm),
       .ba      (ddr3_ba),
       .addr    (ddr3_addr),
       .dq      (ddr3_dq),
       .dqs     (ddr3_dqs_p),
       .dqs_n   (ddr3_dqs_n),
       .tdqs_n  (),
       .odt     (ddr3_odt)
       );
endmodule
