
module seg_led(
    input                   clk    ,   //时钟信号
    input                   rst_n  ,  //复位信号

    input         [19:0]  data   , //6位数码管要显示的数值

    output   reg  [5:0]   seg_sel,  //数码管位选，最左侧数码管为最高位
    output   reg  [7:0]   seg_led  //数码管段选
    );

//parameter define
localparam  MAX_NUM  = 50000 ; //计数1ms所需的计数值
localparam  point=6'b000000;
localparam  sign=0;
//reg define
reg    [23:0]      bcd_data_t    ;     //24位bcd码寄存器
reg    [15:0]      cnt_1ms       ;      //数码管动态显示计数器
reg                  cnt_1ms_flag  ;    //标志信号（标志着cnt_1ms计数达1ms）
reg    [2:0]        cnt_sel       ;       //数码管位选计数器
reg    [3:0]        bcd_data_disp ;  //当前数码管显示的数据
reg                  dot_disp      ;     //当前数码管显示的小数点
                                 
//wire define         
wire   [23:0]      bcd_data      ; //24位bcd码     

//*****************************************************
//**                    main code
//*****************************************************


//将20位2进制数转换为8421bcd码(即使用4位二进制数表示1位十进制数）
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        bcd_data_t <= 24'b0;
    else begin
        if (bcd_data[23:20] || point[5]) //如果显示数据为6位十进制数
            bcd_data_t <= bcd_data; //所有位数的数码管都赋值
        else if(bcd_data[19:16] || point[4]) begin//如果显示数据为5位十进制数，则给低5位数码管赋值
			   bcd_data_t[19:0] <= bcd_data[19:0];
            if(sign)                    
                bcd_data_t[23:20] <= 4'd11; //如果需要显示负号，则最高位（第6位）为符号位
            else
                bcd_data_t[23:20] <= 4'd10; //不需要显示负号时，则第6位不显示任何字符
        end
        else if (bcd_data[15:12] || point[3]) begin
            bcd_data_t[15:0] <= bcd_data[15:0];
            bcd_data_t[23:20] <= 4'd10; //第6位不显示任何字符
            if(sign)             //如果需要显示负号，则最高位（第5位）为符号位
                bcd_data_t[19:16] <= 4'd11;
            else                 //不需要显示负号时，则第5位不显示任何字符
                bcd_data_t[19:16] <= 4'd10;
        end
        else if (bcd_data[11:8] || point[2]) begin
            bcd_data_t[11:0] <= bcd_data[11:0];
                             //第6、5位不显示任何字符
            bcd_data_t[23:16] <= {2{4'd10}};
            if(sign)         //如果需要显示负号，则最高位（第4位）为符号位
                bcd_data_t[15:12] <= 4'd11;
            else             //不需要显示负号时，则第4位不显示任何字符
                bcd_data_t[15:12] <= 4'd10;
        end        
        else if (bcd_data[7:4] || point[1]) begin
            bcd_data_t[7:0] <= bcd_data[7:0];
                         //第6、5、4位不显示任何字符
            bcd_data_t[23:12] <= {3{4'd10}};
            if(sign)     //如果需要显示负号，则最高位（第3位）为符号位
                bcd_data_t[11:8]  <= 4'd11;
            else         //不需要显示负号时，则第3位不显示任何字符
                bcd_data_t[11:8] <=  4'd10;
        end        
        else begin
            bcd_data_t[3:0] <= bcd_data[3:0];
                         //第6、5位不显示任何字符
            bcd_data_t[23:8] <= {4{4'd10}};
            if(sign)     //如果需要显示负号，则最高位（第2位）为符号位
                bcd_data_t[7:4] <= 4'd11;
            else         //不需要显示负号时，则第2位不显示任何字符
                bcd_data_t[7:4] <= 4'd10;
        end
    end 
end

//每当计数器对数码管驱动时钟计数时间达1ms，输出一个时钟周期的脉冲信号
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        cnt_1ms <= 13'b0;
        cnt_1ms_flag <= 1'b0;
     end
    else if (cnt_1ms < MAX_NUM - 1'b1) begin
        cnt_1ms <= cnt_1ms + 1'b1;
        cnt_1ms_flag <= 1'b0;
     end
    else begin
        cnt_1ms <= 13'b0;
        cnt_1ms_flag <= 1'b1;
     end
end

//cnt_sel从0计数到5，用于选择当前处于显示状态的数码管
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0)
        cnt_sel <= 3'b0;
    else if(cnt_1ms_flag) begin
        if(cnt_sel < 3'd5)
            cnt_sel <= cnt_sel + 1'b1;
        else
            cnt_sel <= 3'b0;
    end
    else
        cnt_sel <= cnt_sel;
end

//控制数码管位选信号，使6位数码管轮流显示
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seg_sel  <= 6'b111111;              //位选信号低电平有效
        bcd_data_disp <= 4'b0;
		  dot_disp <= 1'b1;                   //共阳极数码管，低电平导通
    end
    else begin
            case (cnt_sel)
                3'd0 :begin
                    seg_sel  <= 6'b111110;  //显示数码管最低位
                    bcd_data_disp <= bcd_data_t[3:0] ;  //显示的数据
						  dot_disp <= ~point[0];
                end
                3'd1 :begin
                    seg_sel  <= 6'b111101;  //显示数码管第1位
                    bcd_data_disp <= bcd_data_t[7:4] ;
						  dot_disp <= ~point[1];
                end
                3'd2 :begin
                    seg_sel  <= 6'b111011;  //显示数码管第2位
                    bcd_data_disp <= bcd_data_t[11:8];
						  dot_disp <= ~point[2];
                end
                3'd3 :begin
                    seg_sel  <= 6'b110111;  //显示数码管第3位
                    bcd_data_disp <= bcd_data_t[15:12];
						  dot_disp <= ~point[3];
                end
                3'd4 :begin
                    seg_sel  <= 6'b101111;  //显示数码管第4位
                    bcd_data_disp <= bcd_data_t[19:16];
						  dot_disp <= ~point[4];
                end
                3'd5 :begin
                    seg_sel  <= 6'b011111;  //显示数码管最高位
                    bcd_data_disp <= bcd_data_t[23:20];
						  dot_disp <= ~point[5];
                end
                default :begin
                    seg_sel  <= 6'b111111;
                    bcd_data_disp <= 4'b0;
						  dot_disp <= 1;
                end
            endcase
   end
end

//控制数码管段选信号，显示字符
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        seg_led <= 8'hff;
    else begin
        case (bcd_data_disp)
            4'd0 : seg_led <= {dot_disp,7'b1000000}; //显示数字 0
            4'd1 : seg_led <= {dot_disp,7'b1111001}; //显示数字 1
            4'd2 : seg_led <= {dot_disp,7'b0100100}; //显示数字 2
            4'd3 : seg_led <= {dot_disp,7'b0110000}; //显示数字 3
            4'd4 : seg_led <= {dot_disp,7'b0011001}; //显示数字 4
            4'd5 : seg_led <= {dot_disp,7'b0010010}; //显示数字 5
            4'd6 : seg_led <= {dot_disp,7'b0000010}; //显示数字 6
            4'd7 : seg_led <= {dot_disp,7'b1111000}; //显示数字 7
            4'd8 : seg_led <= {dot_disp,7'b0000000}; //显示数字 8
            4'd9 : seg_led <= {dot_disp,7'b0010000}; //显示数字 9
            4'd10: seg_led <= 8'b11111111;         //不显示任何字符
            4'd11: seg_led <= 8'b10111111;         //显示负号(-)
            default:seg_led <= 8'hff;
        endcase
    end
end

//例化二进制转BCD模块
binary2bcd u_binary2bcd(  
    .sys_clk        (clk     ),
    .sys_rst_n     (rst_n   ),
                
    .data            (data    ),
    .bcd_data     (bcd_data)
    );

endmodule 
