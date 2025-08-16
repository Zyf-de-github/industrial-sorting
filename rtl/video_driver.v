
module video_driver(
    input           	pixel_clk	,
    input           	sys_rst_n	,
		
    //RGB接口	
    output  reg      	video_hs	,    //行同步信号
    output  reg      	video_vs	,    //场同步信号
    output  reg      	video_de	,    //数据使能
    output  reg[15:0]  video_rgb	,    //RGB565颜色数据
    output	reg			data_req 	,
	
    input   	[15:0]  pixel_data	,   //像素点数据
    input               key2        ,
    input       [3:0]   led         ,
    output  reg	[10:0]  pixel_xpos_o	,   //像素点横坐标
    output  reg	[10:0]  pixel_ypos_o      //像素点纵坐标
);

//parameter define

//1024*768 分辨率时序参数,60fps
parameter  H_SYNC   =  11'd136;  //行同步
parameter  H_BACK   =  11'd160;  //行显示后沿
parameter  H_DISP   =  11'd1024; //行有效数据
parameter  H_FRONT  =  11'd24;   //行显示前沿
parameter  H_TOTAL  =  11'd1344; //行扫描周期

parameter  V_SYNC   =  11'd6;    //场同步
parameter  V_BACK   =  11'd29;   //场显示后沿
parameter  V_DISP   =  11'd768;  //场有效数据
parameter  V_FRONT  =  11'd3;    //场显示前沿
parameter  V_TOTAL  =  11'd806;  //场扫描周期

//reg define
reg  [11:0] cnt_h;
reg  [11:0] cnt_v;
reg       	video_en;
reg	[10:0]  pixel_xpos;
reg	[10:0]  pixel_ypos;


reg   [127:0] char0[31:0];  //圆
reg   [127:0] char3[31:0];  //三角
reg   [127:0] char4[31:0];  //正方形







always @(posedge pixel_clk) begin//简单样本
    char0[0 ]  <= 128'h00000000000000000000000000000000;
    char0[1 ]  <= 128'h00000000000000000000000000000000;
    char0[2 ]  <= 128'h03803800008002000200008000010000;
    char0[3 ]  <= 128'h03C03C0000FFFF80038300E00001C000;
    char0[4 ]  <= 128'h0787783800C00300030180C000018000;
    char0[5 ]  <= 128'h07FFFFFC00C003000300C18000018000;
    char0[6 ]  <= 128'h0E70E60000C003000300E10000018000;
    char0[7 ]  <= 128'h1C79C78000FFFF000300620000018000;
    char0[8 ]  <= 128'h183B838000C003000310423000018030;
    char0[9 ]  <= 128'h33B3030000C003003FFFFFF81FFFFFF8;
    char0[10]  <= 128'h61E0007000C00300030008000003A000;
    char0[11]  <= 128'h0CEFFFF800C00300030008000007A000;
    char0[12]  <= 128'h0FF6007000FFFF00030008000007A000;
    char0[13]  <= 128'h0F60007000D0030003800820000D9000;
    char0[14]  <= 128'h0E183870001000000743FFF0000D9000;
    char0[15]  <= 128'h0E1FFC70003800000770080000198800;
    char0[16]  <= 128'h0E1C3870007000200730080000198C00;
    char0[17]  <= 128'h0E1C3870007FFFF00F10080000318400;
    char0[18]  <= 128'h0E1C387000C30C300B10080000618600;
    char0[19]  <= 128'h0E1C3870018618601B00081800C18300;
    char0[20]  <= 128'h0E1FF87003061860131FFFFC00C181C0;
    char0[21]  <= 128'h0E1C3870060C386013000800018180E0;
    char0[22]  <= 128'h0E1C3870081830602300080002018678;
    char0[23]  <= 128'h0E1C3870003060604300080004FFFF3E;
    char0[24]  <= 128'h0E1FF8700060E0400300080008018010;
    char0[25]  <= 128'h0E1C38700080C0C00300080030018000;
    char0[26]  <= 128'h0E1C0070070380C00300080040018000;
    char0[27]  <= 128'h0E000FF0080620C00300080000018000;
    char0[28]  <= 128'h0E000FF0001C1F800300080000018000;
    char0[29]  <= 128'h0E0001E0006007800300080000018000;
    char0[30]  <= 128'h0E0000C0018002000300100000018000;
    char0[31]  <= 128'h00000000000000000000000000000000;
end

always @(posedge pixel_clk) begin//普通样本
    char3[0 ]  <= 128'h00000000000000000000000000000000;
    char3[1 ]  <= 128'h00000000000000000000000000000000;
    char3[2 ]  <= 128'h00700C00000000400200008000010000;
    char3[3 ]  <= 128'h003C1F00080FFFE0038300E00001C000;
    char3[4 ]  <= 128'h001E1C000C0001E0030180C000018000;
    char3[5 ]  <= 128'h001E3830060083000300C18000018000;
    char3[6 ]  <= 128'h000E3078070074000300E10000018000;
    char3[7 ]  <= 128'h1FFFFFFC030038000300620000018000;
    char3[8 ]  <= 128'h0C1E7800021018200310423000018030;
    char3[9 ]  <= 128'h031E79E0001FFFF83FFFFFF81FFFFFF8;
    char3[10]  <= 128'h039E79E000181030030008000003A000;
    char3[11]  <= 128'h01DE7BC000181030030008000007A000;
    char3[12]  <= 128'h01FE7B8001181030030008000007A000;
    char3[13]  <= 128'h00FE7F187F9FFFF003800820000D9000;
    char3[14]  <= 128'h00DE7E3C031810300743FFF0000D9000;
    char3[15]  <= 128'h7FFFFFFE031810300770080000198800;
    char3[16]  <= 128'h30000000031810300730080000198C00;
    char3[17]  <= 128'h00000000031810300F10080000318400;
    char3[18]  <= 128'h01C00380031FFFF00B10080000618600;
    char3[19]  <= 128'h01FFFFC0031810301B00081800C18300;
    char3[20]  <= 128'h01E0078003181030131FFFFC00C181C0;
    char3[21]  <= 128'h01E007800318103013000800018180E0;
    char3[22]  <= 128'h01E00780031810302300080002018678;
    char3[23]  <= 128'h01FFFF80031810304300080004FFFF3E;
    char3[24]  <= 128'h01E00780031811F00300080008018010;
    char3[25]  <= 128'h01E007800C9000600300080030018000;
    char3[26]  <= 128'h01E00780386000000300080040018000;
    char3[27]  <= 128'h01E00780703E000E0300080000018000;
    char3[28]  <= 128'h01FFFF80200FFFF80300080000018000;
    char3[29]  <= 128'h01E007800000FFF00300080000018000;
    char3[30]  <= 128'h01C00700000000000300100000018000;
    char3[31]  <= 128'h00000000000000000000000000000000;     
end

always @(posedge pixel_clk) begin//复杂样本
    char4[0 ]  <= 128'h00000000000000000000000000000000;      
    char4[1 ]  <= 128'h00000000000000000000000000000000;      
    char4[2 ]  <= 128'h00700000000800000200008000010000;      
    char4[3 ]  <= 128'h00780020000C0000038300E00001C000;      
    char4[4 ]  <= 128'h00F00070000C0000030180C000018000;      
    char4[5 ]  <= 128'h00FFFFF8000C08000300C18000018000;      
    char4[6 ]  <= 128'h01C00000000FFC000300E10000018000;      
    char4[7 ]  <= 128'h03C0000003F818000300620000018000;      
    char4[8 ]  <= 128'h07C00380001818000310423000018030;      
    char4[9 ]  <= 128'h0EFFFFC0001818103FFFFFF81FFFFFF8;      
    char4[10]  <= 128'h1CF003C000101810030008000003A000;      
    char4[11]  <= 128'h38F0038000301810030008000007A000;      
    char4[12]  <= 128'h30FFFF8000601810030008000007A000;
    char4[13]  <= 128'h00F0038000C0183803800820000D9000;
    char4[14]  <= 128'h00F003800181CFF80743FFF0000D9000;
    char4[15]  <= 128'h00F00380030180000770080000198800;
    char4[16]  <= 128'h00FFFF800C0180000730080000198C00;
    char4[17]  <= 128'h00FC0380300180300F10080000318400;
    char4[18]  <= 128'h00FC03003FFFFFF80B10080000618600;
    char4[19]  <= 128'h003FFF80100180001B00081800C18300;
    char4[20]  <= 128'h007807C000018000131FFFFC00C181C0;
    char4[21]  <= 128'h00FC0F000021900013000800018180E0;
    char4[22]  <= 128'h00EE1E0000718C002300080002018678;
    char4[23]  <= 128'h01C77C0000E187004300080004FFFF3E;
    char4[24]  <= 128'h0383F800018181C00300080008018010;
    char4[25]  <= 128'h0E01E000030180E00300080030018000;
    char4[26]  <= 128'h0C07F800060180700300080040018000;
    char4[27]  <= 128'h001F7F00080180300300080000018000;
    char4[28]  <= 128'h007C1FFE301F80100300080000018000;
    char4[29]  <= 128'h07F007FE000700000300080000018000;
    char4[30]  <= 128'h3F000078000200000300100000018000;
    char4[31]  <= 128'h00000000000000000000000000000000;
end

//*****************************************************
//**                    main code
//*****************************************************

//assign video_de  = video_en;
//assign video_hs  = ( cnt_h < H_SYNC ) ? 1'b0 : 1'b1;  //行同步信号赋值
//assign video_vs  = ( cnt_v < V_SYNC ) ? 1'b0 : 1'b1;  //场同步信号赋值

//使能RGB数据输出
always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)begin
		video_en <= 1'b0;
		pixel_xpos_o=0;
        pixel_ypos_o=0;
    end
	else begin
		video_en <= data_req;
		pixel_xpos_o<=pixel_xpos;
        pixel_ypos_o<=pixel_ypos;
	end
end


always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)begin
		video_de<=0;
	end
	else begin
		video_de<=video_en;
		if(cnt_h < H_SYNC)begin
		  video_hs<=0;
		end
		else begin
		  video_hs<=1;
		end
		if(cnt_v < V_SYNC)begin
		  video_vs<=0;
		end
		else begin
		  video_vs<=1;
		end
    end
end


//RGB565数据输出
//assign video_rgb = video_de ? ((
//                              (pixel_ypos>=5)&&
//                              (pixel_ypos<=36)&&
//                              (pixel_xpos<=137)&&
//                              (pixel_xpos>=10)&&
//                              (char0[pixel_ypos-5][128-(pixel_xpos-10)]!=0) 
//                              )?16'b0111100010010011:pixel_data) : 16'd0;

always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) begin
	   video_rgb<=0;
	end
    else if(video_de)begin
        if(~key2)begin
            case(led)
                3'b001:begin// 简单图像
                       if((pixel_ypos>=5)&&(pixel_ypos<=36)&&(pixel_xpos<=137)&&(pixel_xpos>=10)&&(char0[pixel_ypos-5][128-(pixel_xpos-10)]!=0))begin
                       video_rgb<=16'b0111100010010011;
                       end
                       else begin
                       video_rgb<=pixel_data;
                       end
                 end
                 3'b010:begin//中等图像
                       if((pixel_ypos>=5)&&(pixel_ypos<=36)&&(pixel_xpos<=137)&&(pixel_xpos>=10)&&(char3[pixel_ypos-5][128-(pixel_xpos-10)]!=0))begin
                       video_rgb<=16'b0111100010010011;
                       end
                       else begin
                       video_rgb<=pixel_data;
                       end                
                 end
                 3'b100:begin//复杂图像
                       if((pixel_ypos>=5)&&(pixel_ypos<=36)&&(pixel_xpos<=137)&&(pixel_xpos>=10)&&(char4[pixel_ypos-5][128-(pixel_xpos-10)]!=0))begin
                       video_rgb<=16'b0111100010010011;
                       end
                       else begin
                       video_rgb<=pixel_data;
                       end
                 end
             endcase
        end
        else begin
        video_rgb<=pixel_data;
        end
    end
end


//请求像素点颜色数据输入
always @(posedge pixel_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		data_req <= 1'b0;
	else if(((cnt_h >= H_SYNC + H_BACK - 2'd2) && (cnt_h < H_SYNC + H_BACK + H_DISP - 2'd2))
                  && ((cnt_v >= V_SYNC + V_BACK) && (cnt_v < V_SYNC + V_BACK+V_DISP)))
		data_req <= 1'b1;
	else
		data_req <= 1'b0;
end

//像素点x坐标
always@ (posedge pixel_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pixel_xpos <= 11'd0;
    else if(data_req)
        pixel_xpos <= cnt_h + 2'd2 - H_SYNC - H_BACK ;
    else 
        pixel_xpos <= 11'd0;
end
    
//像素点y坐标	
always@ (posedge pixel_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pixel_ypos <= 11'd0;
    else if((cnt_v >= (V_SYNC + V_BACK)) && (cnt_v < (V_SYNC + V_BACK + V_DISP)))
        pixel_ypos <= cnt_v + 1'b1 - (V_SYNC + V_BACK) ;
    else 
        pixel_ypos <= 11'd0;
end

//行计数器对像素时钟计数
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_h <= 11'd0;
    else begin
        if(cnt_h < H_TOTAL - 1'b1)
            cnt_h <= cnt_h + 1'b1;
        else 
            cnt_h <= 11'd0;
    end
end

//场计数器对行计数
always @(posedge pixel_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_v <= 11'd0;
    else if(cnt_h == H_TOTAL - 1'b1) begin
        if(cnt_v < V_TOTAL - 1'b1)
            cnt_v <= cnt_v + 1'b1;
        else 
            cnt_v <= 11'd0;
    end
end

endmodule