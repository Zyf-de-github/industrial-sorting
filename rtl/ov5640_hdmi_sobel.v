
module ov5640_hdmi_sobel(    
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
    input                 key0         ,
    input                 key1         ,
    input                 key2         ,
    //摄像头接口                       
    input                 cam_pclk     ,  //cmos 数据像素时钟
    input                 cam_vsync    ,  //cmos 场同步信号
    input                 cam_href     ,  //cmos 行同步信号
    input   [7:0]         cam_data     ,  //cmos 数据
    output                cam_rst_n    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl      ,  //cmos SCCB_SCL线
    inout                 cam_sda      ,  //cmos SCCB_SDA线       
    // DDR3                            
    inout   [15:0]        ddr3_dq      ,  //DDR3 数据
    inout   [1:0]         ddr3_dqs_n   ,  //DDR3 dqs负
    inout   [1:0]         ddr3_dqs_p   ,  //DDR3 dqs正  
    output  [13:0]        ddr3_addr    ,  //DDR3 地址   
    output  [2:0]         ddr3_ba      ,  //DDR3 banck 选择
    output                ddr3_ras_n   ,  //DDR3 行选择
    output                ddr3_cas_n   ,  //DDR3 列选择
    output                ddr3_we_n    ,  //DDR3 读写选择
    output                ddr3_reset_n ,  //DDR3 复位
    output  [0:0]         ddr3_ck_p    ,  //DDR3 时钟正
    output  [0:0]         ddr3_ck_n    ,  //DDR3 时钟负
    output  [0:0]         ddr3_cke     ,  //DDR3 时钟使能
    output  [0:0]         ddr3_cs_n    ,  //DDR3 片选
    output  [1:0]         ddr3_dm      ,  //DDR3_dm
    output  [0:0]         ddr3_odt     ,  //DDR3_odt									                            
    //hdmi接口                           
    output                tmds_clk_p   ,  // TMDS 时钟通道
    output                tmds_clk_n   ,
    output  [2:0]         tmds_data_p  ,  // TMDS 数据通道
    output  [2:0]         tmds_data_n  ,
    output                tmds_oen     ,  // TMDS 输出使能
    
    output    [5:0]  seg_sel  ,        //数码管位选信号
    output    [7:0]  seg_led  ,        //数码管段选信号
    output   reg     [3:0]  led,
    output   reg     out1,  //k17 简单
    output   reg     out2,  //l14 中等
    output   reg     out3   //l15 复杂
    
    );     
                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS分辨率--列	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; //CMOS分辨率--行
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;    										   
							   
//wire define                          
wire         clk_50m                   ;  //50mhz时钟
wire         locked                    ;  //时钟锁定信号
wire         rst_n                     ;  //全局复位 								    
wire         cam_init_done             ;  //摄像头初始化完成
wire         i2c_done                  ;  //I2C寄存器配置完成信号
wire         i2c_dri_clk               ;  //I2C操作时钟								    
wire         wr_en                     ;  //DDR3控制器模块写使能
wire  [15:0] wr_data                   ;  //DDR3控制器模块写数据
wire         rdata_req                 ;  //DDR3控制器模块读使能
wire  [15:0] rd_data                   ;  //DDR3控制器模块读数据
wire         cmos_frame_valid          ;  //数据有效使能信号
wire         init_calib_complete       ;  //DDR3初始化完成init_calib_complete
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire         clk_200m                  ;  //ddr3参考时钟
wire         cmos_frame_vsync          ;  //输出帧有效场同步信号
wire         cmos_frame_href           ;  //输出帧有效行同步信号 
wire  [10:0] pixel_xpos                ;  //像素点横坐标
wire  [10:0] pixel_ypos                ;  //像素点纵坐标   
wire  [15:0] out_rgb                  ;  //处理后的图像数据
wire         out_frame_vsync          ;  //处理后的场信号
wire         out_frame_de             ;  //处理后的数据有效使能 

wire   [10:0] led_data                   ;
reg    [30:0] cnt_led;
reg           flag_led;

//*****************************************************
//**                    main code
//*****************************************************

//待时钟锁定后产生复位结束信号
assign  rst_n = sys_rst_n & locked;

//系统初始化完成：DDR3初始化完成
assign  sys_init_done = init_calib_complete;

//时钟分频，产生flag_cnt脉冲
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

//显示led
always@(posedge clk_50m or negedge rst_n)begin
    if(!rst_n)begin
        led<=4'b0000;
        out1<=0;
        out2<=0;
        out3<=0;
    end   
    else if(flag_led)begin
        if(led_data<=5)begin
            led<=4'b0100;//复杂图像
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
            led<=4'b0010;//中等图像
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
            led<=4'b0001;//简单图像
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
        //二阈值过小，不易识别，后续考虑算法优化
    end
     else begin
     led<=led;
     out1<=0;
     out2<=0;
     out3<=0;
     end
end



 //ov5640 驱动
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

 //图像处理模块
vip u_vip(
    //module clock
    .clk              (cam_pclk),          // 时钟信号
    .rst_n            (rst_n ),            // 复位信号（低有效）
    .key0             (key0),
    .key1             (key1),
    //图像处理前的数据接口
    .pre_frame_vsync  (cmos_frame_vsync),
    .pre_frame_href   (cmos_frame_href),
    .pre_frame_de     (cmos_frame_valid),
    .pre_rgb          (wr_data),
    //图像处理后的数据接口
    .out_frame_vsync (out_frame_vsync),  // 处理后的场信号
    .out_frame_href  ( ),                 // 处理后的行信号
    .out_frame_de    (out_frame_de),     // 处理后的数据有效使能 
    .out_rgb         (out_rgb),          // 处理后的图像数据
    .answer          (led_data)

);  


seg_led u_seg_led(
    .clk           (clk_50m  ),       //时钟信号
    .rst_n         (rst_n),       //复位信号
    .data          (led_data ),       //显示的数值
    
    .seg_sel       (seg_sel  ),       //位选
    .seg_led       (seg_led  )        //段选
);



ddr3_top u_ddr3_top (
    .rst_n               (rst_n),                     //复位,低有效
    .init_calib_complete (init_calib_complete),       //ddr3初始化完成信号    
    //ddr3接口信号       
    .app_addr_rd_min     (28'd0),                     //读DDR3的起始地址
    .app_addr_rd_max     (V_CMOS_DISP*H_CMOS_DISP),   //读DDR3的结束地址
    .rd_bust_len         (H_CMOS_DISP[10:3]),         //从DDR3中读数据时的突发长度
    .app_addr_wr_min     (28'd0),                     //写DDR3的起始地址
    .app_addr_wr_max     (V_CMOS_DISP*H_CMOS_DISP),   //写DDR3的结束地址
    .wr_bust_len         (H_CMOS_DISP[10:3]),         //从DDR3中写数据时的突发长度   
    // DDR3 IO接口              
    .ddr3_dq             (ddr3_dq),                   //DDR3 数据
    .ddr3_dqs_n          (ddr3_dqs_n),                //DDR3 dqs负
    .ddr3_dqs_p          (ddr3_dqs_p),                //DDR3 dqs正  
    .ddr3_addr           (ddr3_addr),                 //DDR3 地址   
    .ddr3_ba             (ddr3_ba),                   //DDR3 banck 选择
    .ddr3_ras_n          (ddr3_ras_n),                //DDR3 行选择
    .ddr3_cas_n          (ddr3_cas_n),                //DDR3 列选择
    .ddr3_we_n           (ddr3_we_n),                 //DDR3 读写选择
    .ddr3_reset_n        (ddr3_reset_n),              //DDR3 复位
    .ddr3_ck_p           (ddr3_ck_p),                 //DDR3 时钟正
    .ddr3_ck_n           (ddr3_ck_n),                 //DDR3 时钟负  
    .ddr3_cke            (ddr3_cke),                  //DDR3 时钟使能
    .ddr3_cs_n           (ddr3_cs_n),                 //DDR3 片选
    .ddr3_dm             (ddr3_dm),                   //DDR3_dm
    .ddr3_odt            (ddr3_odt),                  //DDR3_odt
     // System Clock Ports                            
    .sys_clk_i           (clk_200m),   
    // Reference Clock Ports                         
    .clk_ref_i           (clk_200m), 
    //用户                                            
    .ddr3_read_valid     (1'b1),                      //DDR3 读使能
    .ddr3_pingpang_en    (1'b1),                      //DDR3 乒乓操作使能
    .wr_clk              (cam_pclk),                  //写时钟
    .wr_load             (out_frame_vsync),          //输入源更新信号   
	.wr_en               (out_frame_de),             //数据有效使能信号
    .wrdata              (out_rgb),                  //有效数据 
    .rd_clk              (pixel_clk),                 //读时钟 
    .rd_load             (rd_vsync),                  //输出源更新信号    
    .rddata              (rd_data),                   //rfifo输出数据
    .rdata_req           (rdata_req)                  //请求数据输入   
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
 
//HDMI驱动显示模块    
hdmi_top u_hdmi_top(
    .pixel_clk            (pixel_clk),
    .pixel_clk_5x         (pixel_clk_5x),    
    .sys_rst_n            (sys_init_done & rst_n),
    //hdmi接口                
    .tmds_clk_p           (tmds_clk_p),    // TMDS 时钟通道
    .tmds_clk_n           (tmds_clk_n),
    .tmds_data_p          (tmds_data_p),   // TMDS 数据通道
    .tmds_data_n          (tmds_data_n),
    .tmds_oen             (tmds_oen),      // TMDS 输出使能
    //用户接口 
    .video_vs             (rd_vsync),      //HDMI场信号     
    .pixel_xpos           (pixel_xpos),    //像素点横坐标
    .pixel_ypos           (pixel_ypos),          
    .data_in              (rd_data),       //数据输入 
    .data_req             (rdata_req),     //请求数据输入   
    .led                  (led),
    .key2                 (key2)
);   

endmodule