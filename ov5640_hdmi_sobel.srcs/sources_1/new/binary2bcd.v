`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/09 18:06:29
// Design Name: 
// Module Name: binary2bcd
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


  module binary2bcd(
      input   wire             sys_clk,
      input   wire             sys_rst_n,
      input   wire    [19:0]   data,
      
      output  reg     [23:0]   bcd_data        //显示的值
  );
  //parameter define
  parameter   CNT_SHIFT_NUM = 7'd20;  			//由data的位宽决定
  //parameter  data=123456;
 //reg define
 reg [6:0]       cnt_shift;         				//移位判断计数器
 reg [43:0]      data_shift;        				//移位判断数据寄存器，
 reg             shift_flag;        				//移位判断标志信号
 
 //*****************************************************
 //**                    main code                      
 //*****************************************************
 
 //cnt_shift计数
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         cnt_shift <= 7'd0;
     else if((cnt_shift == CNT_SHIFT_NUM + 1) && (shift_flag))
         cnt_shift <= 7'd0;
     else if(shift_flag)
         cnt_shift <= cnt_shift + 1'b1;
     else
         cnt_shift <= cnt_shift;
 end
 
 //data_shift 计数器为0时赋初值，计数器为1~CNT_SHIFT_NUM时进行移位操作
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         data_shift <= 44'd0;
     else if(cnt_shift == 7'd0)
         data_shift <= {24'b0,data};
     else if((cnt_shift <= CNT_SHIFT_NUM)&&(!shift_flag))begin
         data_shift[23:20] <= (data_shift[23:20] > 4) 
         ? (data_shift[23:20] + 2'd3):(data_shift[23:20]);
         data_shift[27:24] <= (data_shift[27:24] > 4) 
         ? (data_shift[27:24] + 2'd3):(data_shift[27:24]);
         data_shift[31:28] <= (data_shift[31:28] > 4) 
         ? (data_shift[31:28] + 2'd3):(data_shift[31:28]);
         data_shift[35:32] <= (data_shift[35:32] > 4) 
         ? (data_shift[35:32] + 2'd3):(data_shift[35:32]);
         data_shift[39:36] <= (data_shift[39:36] > 4) 
         ? (data_shift[39:36] + 2'd3):(data_shift[39:36]);
         data_shift[43:40] <= (data_shift[43:40] > 4) 
         ? (data_shift[43:40] + 2'd3):(data_shift[43:40]);
         end
     else if((cnt_shift <= CNT_SHIFT_NUM)&&(shift_flag))
         data_shift <= data_shift << 1;
     else
         data_shift <= data_shift;
 end
 
 //shift_flag 移位判断标志信号，用于控制移位判断的先后顺序
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         shift_flag <= 1'b0;
     else
         shift_flag <= ~shift_flag;
 end
 
 //当计数器等于CNT_SHIFT_NUM时，移位判断操作完成，整体输出
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         bcd_data <= 24'd0;
     else if(cnt_shift == CNT_SHIFT_NUM + 1)
         bcd_data <= data_shift[43:20];
     else
         bcd_data <= bcd_data;
 end
 
 endmodule
