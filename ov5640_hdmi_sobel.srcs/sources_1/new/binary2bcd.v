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
      
      output  reg     [23:0]   bcd_data        //��ʾ��ֵ
  );
  //parameter define
  parameter   CNT_SHIFT_NUM = 7'd20;  			//��data��λ�����
  //parameter  data=123456;
 //reg define
 reg [6:0]       cnt_shift;         				//��λ�жϼ�����
 reg [43:0]      data_shift;        				//��λ�ж����ݼĴ�����
 reg             shift_flag;        				//��λ�жϱ�־�ź�
 
 //*****************************************************
 //**                    main code                      
 //*****************************************************
 
 //cnt_shift����
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
 
 //data_shift ������Ϊ0ʱ����ֵ��������Ϊ1~CNT_SHIFT_NUMʱ������λ����
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
 
 //shift_flag ��λ�жϱ�־�źţ����ڿ�����λ�жϵ��Ⱥ�˳��
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         shift_flag <= 1'b0;
     else
         shift_flag <= ~shift_flag;
 end
 
 //������������CNT_SHIFT_NUMʱ����λ�жϲ�����ɣ��������
 always@(posedge sys_clk or negedge sys_rst_n)begin
     if(!sys_rst_n)
         bcd_data <= 24'd0;
     else if(cnt_shift == CNT_SHIFT_NUM + 1)
         bcd_data <= data_shift[43:20];
     else
         bcd_data <= bcd_data;
 end
 
 endmodule
