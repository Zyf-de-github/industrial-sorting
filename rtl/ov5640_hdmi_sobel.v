
module ov5640_hdmi_sobel(    
    input                 sys_clk      ,  //ϵͳʱ��
    input                 sys_rst_n    ,  //ϵͳ��λ���͵�ƽ��Ч
    input                 key0         ,
    input                 key1         ,
    input                 key2         ,
    //����ͷ�ӿ�                       
    input                 cam_pclk     ,  //cmos ��������ʱ��
    input                 cam_vsync    ,  //cmos ��ͬ���ź�
    input                 cam_href     ,  //cmos ��ͬ���ź�
    input   [7:0]         cam_data     ,  //cmos ����
    output                cam_rst_n    ,  //cmos ��λ�źţ��͵�ƽ��Ч
    output                cam_pwdn     ,  //��Դ����ģʽѡ�� 0������ģʽ 1����Դ����ģʽ
    output                cam_scl      ,  //cmos SCCB_SCL��
    inout                 cam_sda      ,  //cmos SCCB_SDA��       
    // DDR3                            
    inout   [15:0]        ddr3_dq      ,  //DDR3 ����
    inout   [1:0]         ddr3_dqs_n   ,  //DDR3 dqs��
    inout   [1:0]         ddr3_dqs_p   ,  //DDR3 dqs��  
    output  [13:0]        ddr3_addr    ,  //DDR3 ��ַ   
    output  [2:0]         ddr3_ba      ,  //DDR3 banck ѡ��
    output                ddr3_ras_n   ,  //DDR3 ��ѡ��
    output                ddr3_cas_n   ,  //DDR3 ��ѡ��
    output                ddr3_we_n    ,  //DDR3 ��дѡ��
    output                ddr3_reset_n ,  //DDR3 ��λ
    output  [0:0]         ddr3_ck_p    ,  //DDR3 ʱ����
    output  [0:0]         ddr3_ck_n    ,  //DDR3 ʱ�Ӹ�
    output  [0:0]         ddr3_cke     ,  //DDR3 ʱ��ʹ��
    output  [0:0]         ddr3_cs_n    ,  //DDR3 Ƭѡ
    output  [1:0]         ddr3_dm      ,  //DDR3_dm
    output  [0:0]         ddr3_odt     ,  //DDR3_odt									                            
    //hdmi�ӿ�                           
    output                tmds_clk_p   ,  // TMDS ʱ��ͨ��
    output                tmds_clk_n   ,
    output  [2:0]         tmds_data_p  ,  // TMDS ����ͨ��
    output  [2:0]         tmds_data_n  ,
    output                tmds_oen     ,  // TMDS ���ʹ��
    
    output    [5:0]  seg_sel  ,        //�����λѡ�ź�
    output    [7:0]  seg_led  ,        //����ܶ�ѡ�ź�
    output   reg     [3:0]  led,
    output   reg     out1,  //k17 ��
    output   reg     out2,  //l14 �е�
    output   reg     out3   //l15 ����
    
    );     
                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS�ֱ���--��
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS�ֱ���--��	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; //CMOS�ֱ���--��
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;    										   
							   
//wire define                          
wire         clk_50m                   ;  //50mhzʱ��
wire         locked                    ;  //ʱ�������ź�
wire         rst_n                     ;  //ȫ�ָ�λ 								    
wire         cam_init_done             ;  //����ͷ��ʼ�����
wire         i2c_done                  ;  //I2C�Ĵ�����������ź�
wire         i2c_dri_clk               ;  //I2C����ʱ��								    
wire         wr_en                     ;  //DDR3������ģ��дʹ��
wire  [15:0] wr_data                   ;  //DDR3������ģ��д����
wire         rdata_req                 ;  //DDR3������ģ���ʹ��
wire  [15:0] rd_data                   ;  //DDR3������ģ�������
wire         cmos_frame_valid          ;  //������Чʹ���ź�
wire         init_calib_complete       ;  //DDR3��ʼ�����init_calib_complete
wire         sys_init_done             ;  //ϵͳ��ʼ�����(DDR��ʼ��+����ͷ��ʼ��)
wire         clk_200m                  ;  //ddr3�ο�ʱ��
wire         cmos_frame_vsync          ;  //���֡��Ч��ͬ���ź�
wire         cmos_frame_href           ;  //���֡��Ч��ͬ���ź� 
wire  [10:0] pixel_xpos                ;  //���ص������
wire  [10:0] pixel_ypos                ;  //���ص�������   
wire  [15:0] out_rgb                  ;  //������ͼ������
wire         out_frame_vsync          ;  //�����ĳ��ź�
wire         out_frame_de             ;  //������������Чʹ�� 

wire   [10:0] led_data                   ;
reg    [30:0] cnt_led;
reg           flag_led;

//*****************************************************
//**                    main code
//*****************************************************

//��ʱ�������������λ�����ź�
assign  rst_n = sys_rst_n & locked;

//ϵͳ��ʼ����ɣ�DDR3��ʼ�����
assign  sys_init_done = init_calib_complete;

//ʱ�ӷ�Ƶ������flag_cnt����
always@(posedge clk_50m or negedge rst_n)begin
    if(!rst_n)begin
        cnt_led<=0;
        end   
    else if(cnt_led<50000000)begin
        cnt_led<=cnt_led+1;
        end
    else if(cnt_led>=50000000)begin
        cnt_led<=0;
        flag_led<=1;
        end
    else begin
        cnt_led<=cnt_led;
        flag_led<=0;
        end
end

//��ʾled
always@(posedge clk_50m or negedge rst_n)begin
    if(!rst_n)begin
        led<=4'b0000;
        out1<=0;
        out2<=0;
        out3<=0;
    end   
    else if(flag_led)begin
        if(led_data<=5)begin
            led<=4'b0100;//����ͼ��
            if(~key2)begin
                out1<=0;
                out2<=0;
                out3<=1;
            end
            else begin
                out1<=0;
                out2<=0;
                out3<=0;
            end
        end
        else if(led_data>5&&led_data<=30)begin
            led<=4'b0010;//�е�ͼ��
            if(~key2)begin
                out1<=0;
                out2<=1;
                out3<=0;
            end
            else begin
                out1<=0;
                out2<=0;
                out3<=0;
            end
        end
        else if(led_data>30)begin
            led<=4'b0001;//��ͼ��
            if(~key2)begin
                out1<=1;
                out2<=0;
                out3<=0;
            end
            else begin
                out1<=0;
                out2<=0;
                out3<=0;
            end
        end
        else begin
        led<=4'b0000;
        out1<=0;
        out2<=0;
        out3<=0;
        end   
        //����ֵ��С������ʶ�𣬺��������㷨�Ż�
    end
     else begin
     led<=led;
     out1<=0;
     out2<=0;
     out3<=0;
     end
end



 //ov5640 ����
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk ),
    .cam_vsync         (cam_vsync),
    .cam_href          (cam_href ),
    .cam_data          (cam_data ),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn ),
    .cam_scl           (cam_scl  ),
    .cam_sda           (cam_sda  ),
    
    .capture_start     (init_calib_complete),
    .cmos_h_pixel      (H_CMOS_DISP),
    .cmos_v_pixel      (V_CMOS_DISP),
    .total_h_pixel     (TOTAL_H_PIXEL),
    .total_v_pixel     (TOTAL_V_PIXEL),
    .cmos_frame_vsync  (cmos_frame_vsync),
    .cmos_frame_href   (cmos_frame_href),
    .cmos_frame_valid  (cmos_frame_valid),
    .cmos_frame_data   (wr_data)
    );   

 //ͼ����ģ��
vip u_vip(
    //module clock
    .clk              (cam_pclk),          // ʱ���ź�
    .rst_n            (rst_n ),            // ��λ�źţ�����Ч��
    .key0             (key0),
    .key1             (key1),
    //ͼ����ǰ�����ݽӿ�
    .pre_frame_vsync  (cmos_frame_vsync),
    .pre_frame_href   (cmos_frame_href),
    .pre_frame_de     (cmos_frame_valid),
    .pre_rgb          (wr_data),
    //ͼ���������ݽӿ�
    .out_frame_vsync (out_frame_vsync),  // �����ĳ��ź�
    .out_frame_href  ( ),                 // ���������ź�
    .out_frame_de    (out_frame_de),     // ������������Чʹ�� 
    .out_rgb         (out_rgb),          // ������ͼ������
    .answer          (led_data)

);  


seg_led u_seg_led(
    .clk           (clk_50m  ),       //ʱ���ź�
    .rst_n         (rst_n),       //��λ�ź�
    .data          (led_data ),       //��ʾ����ֵ
    
    .seg_sel       (seg_sel  ),       //λѡ
    .seg_led       (seg_led  )        //��ѡ
);



ddr3_top u_ddr3_top (
    .rst_n               (rst_n),                     //��λ,����Ч
    .init_calib_complete (init_calib_complete),       //ddr3��ʼ������ź�    
    //ddr3�ӿ��ź�       
    .app_addr_rd_min     (28'd0),                     //��DDR3����ʼ��ַ
    .app_addr_rd_max     (V_CMOS_DISP*H_CMOS_DISP),   //��DDR3�Ľ�����ַ
    .rd_bust_len         (H_CMOS_DISP[10:3]),         //��DDR3�ж�����ʱ��ͻ������
    .app_addr_wr_min     (28'd0),                     //дDDR3����ʼ��ַ
    .app_addr_wr_max     (V_CMOS_DISP*H_CMOS_DISP),   //дDDR3�Ľ�����ַ
    .wr_bust_len         (H_CMOS_DISP[10:3]),         //��DDR3��д����ʱ��ͻ������   
    // DDR3 IO�ӿ�              
    .ddr3_dq             (ddr3_dq),                   //DDR3 ����
    .ddr3_dqs_n          (ddr3_dqs_n),                //DDR3 dqs��
    .ddr3_dqs_p          (ddr3_dqs_p),                //DDR3 dqs��  
    .ddr3_addr           (ddr3_addr),                 //DDR3 ��ַ   
    .ddr3_ba             (ddr3_ba),                   //DDR3 banck ѡ��
    .ddr3_ras_n          (ddr3_ras_n),                //DDR3 ��ѡ��
    .ddr3_cas_n          (ddr3_cas_n),                //DDR3 ��ѡ��
    .ddr3_we_n           (ddr3_we_n),                 //DDR3 ��дѡ��
    .ddr3_reset_n        (ddr3_reset_n),              //DDR3 ��λ
    .ddr3_ck_p           (ddr3_ck_p),                 //DDR3 ʱ����
    .ddr3_ck_n           (ddr3_ck_n),                 //DDR3 ʱ�Ӹ�  
    .ddr3_cke            (ddr3_cke),                  //DDR3 ʱ��ʹ��
    .ddr3_cs_n           (ddr3_cs_n),                 //DDR3 Ƭѡ
    .ddr3_dm             (ddr3_dm),                   //DDR3_dm
    .ddr3_odt            (ddr3_odt),                  //DDR3_odt
     // System Clock Ports                            
    .sys_clk_i           (clk_200m),   
    // Reference Clock Ports                         
    .clk_ref_i           (clk_200m), 
    //�û�                                            
    .ddr3_read_valid     (1'b1),                      //DDR3 ��ʹ��
    .ddr3_pingpang_en    (1'b1),                      //DDR3 ƹ�Ҳ���ʹ��
    .wr_clk              (cam_pclk),                  //дʱ��
    .wr_load             (out_frame_vsync),          //����Դ�����ź�   
	.wr_en               (out_frame_de),             //������Чʹ���ź�
    .wrdata              (out_rgb),                  //��Ч���� 
    .rd_clk              (pixel_clk),                 //��ʱ�� 
    .rd_load             (rd_vsync),                  //���Դ�����ź�    
    .rddata              (rd_data),                   //rfifo�������
    .rdata_req           (rdata_req)                  //������������   
     );                    

 clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1              (clk_200m),     
    .clk_out2              (clk_50m),
    .clk_out3              (pixel_clk_5x),
    .clk_out4              (pixel_clk),
    // Status and control signals
    .reset                 (~sys_rst_n), 
    .locked                (locked),       
   // Clock in ports
    .clk_in1               (sys_clk)
    );     
 
//HDMI������ʾģ��    
hdmi_top u_hdmi_top(
    .pixel_clk            (pixel_clk),
    .pixel_clk_5x         (pixel_clk_5x),    
    .sys_rst_n            (sys_init_done & rst_n),
    //hdmi�ӿ�                
    .tmds_clk_p           (tmds_clk_p),    // TMDS ʱ��ͨ��
    .tmds_clk_n           (tmds_clk_n),
    .tmds_data_p          (tmds_data_p),   // TMDS ����ͨ��
    .tmds_data_n          (tmds_data_n),
    .tmds_oen             (tmds_oen),      // TMDS ���ʹ��
    //�û��ӿ� 
    .video_vs             (rd_vsync),      //HDMI���ź�     
    .pixel_xpos           (pixel_xpos),    //���ص������
    .pixel_ypos           (pixel_ypos),          
    .data_in              (rd_data),       //�������� 
    .data_req             (rdata_req),     //������������   
    .led                  (led),
    .key2                 (key2)
);   

endmodule