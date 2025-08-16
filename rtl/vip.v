
module vip(
    //module clock
    input           clk            ,    // 时钟信号
    input           rst_n          ,    // 复位信号（低有效）

    //图像处理前的数据接口
    input           pre_frame_vsync,
    input           pre_frame_href ,
    input           pre_frame_de   ,
    input           key0           ,
    input           key1           ,    
    input    [15:0] pre_rgb        ,

    //图像处理后的数据接口
    output reg        out_frame_vsync,   // 场同步信号
    output reg        out_frame_href ,   // 行同步信号
    output reg        out_frame_de   ,   // 数据输入使能
    output reg [15:0] out_rgb        ,    // RGB565颜色数据
    output reg [19:0] answer   
);


//parameter define
parameter  SOBEL_THRESHOLD = 128; //sobel阈值


wire   binar_frame_vsync;
wire   binar_frame_href;
wire   binar_frame_de;
wire   monoc;
wire   sobel_frame_vsync;
wire   sobel_frame_href; 
wire   sobel_frame_de;  
wire   sobel_img_bit;    

//wire define
wire   [ 7:0]         img_y;
wire   [ 7:0]         post_img_y;
wire                  pe_frame_vsync;
wire                  pe_frame_href;
wire                  pe_frame_clken;
wire                  ycbcr_vsync;
wire                  ycbcr_href;
wire                  ycbcr_de;
wire                  post_img_bit;


reg [19:0]  cnt_d;
reg [19:0]  cnt_d0;
reg [19:0]  cnt_d1;
reg [19:0]  cnt_s;
reg [19:0]  cnt_s0;
reg [19:0]  cnt_s1;

ila_0 u_ila_0 (
	.clk(clk), // input wire clk

	.probe0(out_frame_vsync), // input wire [0:0]  probe0  
	.probe1(out_frame_href ), // input wire [0:0]  probe1 
	.probe2(out_frame_de   ), // input wire [0:0]  probe2 
	.probe3(out_rgb        ), // input wire [15:0]  probe3 
	.probe4(answer         ), // input wire [19:0]  probe4 
	.probe5(cnt_d1), // input wire [19:0]  probe5 
	.probe6(cnt_s1) // input wire [19:0]  probe6
);

//*****************************************************
//**                    main code
//*****************************************************

//视频信号选择
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_rgb<=0;
        out_frame_vsync<=0;
        out_frame_href <=0;
        out_frame_de   <=0;
    end   
    else if(~key0)begin
        out_rgb <= {16{monoc}};
        out_frame_vsync<=binar_frame_vsync    ;
        out_frame_href <=binar_frame_href     ;
        out_frame_de   <=binar_frame_de       ;
    end
    else if(~key1)begin
        out_rgb = {16{~sobel_img_bit}}      ;             
        out_frame_vsync<=sobel_frame_vsync  ;                   
        out_frame_href <=sobel_frame_href   ;                   
        out_frame_de   <=sobel_frame_de     ;                   
    end
    else begin
        out_rgb<=0;
        out_frame_vsync<=0;
        out_frame_href <=0;
        out_frame_de   <=0;
    end  
end

//////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////计算逻辑///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

//面积计数
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_s<=0;
		cnt_s0<=0;
    end   
    else if(key0==0&(~out_rgb)&(~out_frame_vsync))begin
       cnt_s<=cnt_s+1;
	   cnt_s0<=cnt_s;
    end
    else if(key0==0&out_frame_vsync)begin
       cnt_s<=0;
	   cnt_s0<=cnt_s;
    end
    else begin
       cnt_s<=cnt_s;
	   cnt_s0<=cnt_s;
    end
end

//周长计数
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_d<=0;
		cnt_d0<=0;
    end   
    else if(key1==0&(~out_rgb)&(~out_frame_vsync))begin
       cnt_d<=cnt_d+1;
	   cnt_d0<=cnt_d;
    end
    else if(key1==0&out_frame_vsync)begin
       cnt_d<=0;
	   cnt_d0<=cnt_d;
    end
    else begin
       cnt_d<=cnt_d;
	   cnt_d0<=cnt_d;
    end
end

//周长缓存
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_d1<=0;
    end   
    else if(cnt_d0&(~cnt_d))begin
       cnt_d1<=cnt_d0;
    end
    else begin
        cnt_d1<=cnt_d1;
    end
end

//面积缓存
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_s1<=0;
    end   
    else if(cnt_s0&(~cnt_s))begin
       cnt_s1<=cnt_s0;
    end
    else begin
        cnt_s1<=cnt_s1;
    end
end

//结果输出
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        answer<=0;
    end   
    else if((cnt_s1/cnt_d1)>100)begin
        answer<=answer;
    end
    else begin
        answer<=(answer+cnt_s1/cnt_d1)/2;
    end
end





////周长计算
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        cnt_d<=0;
//    end   
//    else if(({16{~sobel_img_bit}}==0)&(sobel_frame_vsync==1)&(sobel_frame_href==1))begin
//        cnt_d<=cnt_d+1;
//    end
//    else if(sobel_frame_vsync==0)begin
//        cnt_d<=0;
//    end
//    else begin
//        cnt_d<=cnt_d;
//    end
//end

////周长计算
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        cnt_d<=0;
//        cnt_d0<=0;
//        flag_d<=0;
//    end   
//    else if(({16{~sobel_img_bit}}==0)&(sobel_frame_vsync==1)&(sobel_frame_href==1))begin
//        cnt_d<=cnt_d+1;
//        cnt_d0<=cnt_d;
//        flag_d<=0;
//    end
//    else if(sobel_frame_vsync==0)begin
//        cnt_d<=0;
//        cnt_d0<=cnt_d;
//    end
//    else begin
//        cnt_d<=cnt_d;
//        cnt_d0<=cnt_d;
//    end
//end

//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        cnt_d1<=0;
//        flag_d<=0;
//    end   
//    else if(cnt_d0&(~cnt_d))begin
//        cnt_d1=cnt_d0;
//        flag_d<=1;
//    end
//    else begin
//        cnt_d1<=cnt_d1;
//    end
//end


////面积计算
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        cnt_s<=0;
//        cnt_s0<=0;
//        flag_s<=0;
//    end   
//    else if(({16{monoc}}==0)&(binar_frame_vsync==1)&(binar_frame_href==1))begin
//        cnt_s<=cnt_s+1;
//        cnt_s0<=cnt_s;
//        flag_s<=0;
//    end
//    else if(binar_frame_vsync==0) begin
//        cnt_s<=0;
//        cnt_s0<=cnt_s;
//    end
//    else begin
//        cnt_s<=cnt_s;
//        cnt_s0<=cnt_s;
//    end
//end

//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        cnt_s1<=0;
//        flag_s<=0;
//    end   
//    else if(cnt_s0&(~cnt_s))begin
//        cnt_s1<=cnt_s0;
//        flag_s<=1;
//    end
//    else begin
//        cnt_s1<=cnt_s1;
//    end
//end

////输出面积比周长方
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)begin
//        answer<=0;
//    end   
//    else if(flag_d&flag_s)begin
//        answer<=cnt_s1/(cnt_d1*cnt_d1);
//    end
//    else
//        answer<=answer;
//end













//ila_0 your_instance_name (
//	.clk(clk), // input wire clk


//	.probe0(out_frame_vsync), // input wire [0:0]  probe0  
//	.probe1(out_frame_href ), // input wire [0:0]  probe1 
//	.probe2(out_frame_de   ), // input wire [0:0]  probe2 
//	.probe3(out_rgb        ), // input wire [15:0]  probe3 
//	.probe4(out_answer     ), // input wire [19:0]  probe4 
//	.probe5(cnt_d), // input wire [31:0]  probe5 
//	.probe6(cnt_d0), // input wire [31:0]  probe6 
//	.probe7(cnt_d1), // input wire [31:0]  probe7 
//	.probe8(cnt_s), // input wire [31:0]  probe8 
//	.probe9(cnt_s0), // input wire [31:0]  probe9 
//	.probe10(cnt_s1), // input wire [31:0]  probe10 
//	.probe11(flag_d), // input wire [0:0]  probe11 
//	.probe12(flag_s), // input wire [0:0]  probe12 
//	.probe13(answer ), // input wire [31:0]  probe13 
//	.probe14(out_answer) // input wire [19:0]  probe14
//);












//RGB转YCbCr模块
rgb2ycbcr u_rgb2ycbcr(
    //module clock
    .clk             (clk    ),            // 时钟信号
    .rst_n           (rst_n  ),            // 复位信号（低有效）
    //图像处理前的数据接口
    .pre_frame_vsync (pre_frame_vsync),    // vsync信号
    .pre_frame_href  (pre_frame_href ),    // href信号
    .pre_frame_de    (pre_frame_de   ),    // data enable信号
    .img_red         (pre_rgb[15:11] ),
    .img_green       (pre_rgb[10:5 ] ),
    .img_blue        (pre_rgb[ 4:0 ] ),
    //图像处理后的数据接口
    .post_frame_vsync(pe_frame_vsync),     // vsync信号
    .post_frame_href (pe_frame_href ),     // href信号
    .post_frame_de   (pe_frame_clken),     // data enable信号
    .img_y           (img_y),              //灰度数据
    .img_cb          (),
    .img_cr          ()
);

vip_sobel_edge_detector
    #(
    .SOBEL_THRESHOLD  (SOBEL_THRESHOLD)    //sobel阈值
    )
u_vip_sobel_edge_detector(
    .clk (clk),   
    .rst_n (rst_n),  
    
    //处理前数据
    .pre_frame_vsync (pe_frame_vsync),    //处理前帧有效信号
    .pre_frame_href  (pe_frame_href),     //处理前行有效信号
    .pre_frame_clken (pe_frame_clken),    //处理前图像使能信号
    .pre_img_y       (img_y),             //处理前输入灰度数据
    
    //处理后的数据
    .post_frame_vsync (sobel_frame_vsync), //处理后帧有效信号
    .post_frame_href  (sobel_frame_href),  //处理后行有效信号
    .post_frame_clken (sobel_frame_de),    //输出使能信号
    .post_img_bit     (sobel_img_bit)      //输出像素
);


//二值化模块
binarization  u_binarization(
    .clk         (clk),
    .rst_n       (rst_n),
    //图像处理前的数据接口     
    .ycbcr_vsync (pe_frame_vsync),
    .ycbcr_href  (pe_frame_href), 
    .ycbcr_de    (pe_frame_clken),
    .luminance   (img_y),
    //图像处理后的数据接口     
    .post_vsync  (binar_frame_vsync),
    .post_href   (binar_frame_href),
    .post_de     (binar_frame_de),
    .monoc       (monoc)                   //二值化后的数据
);

endmodule