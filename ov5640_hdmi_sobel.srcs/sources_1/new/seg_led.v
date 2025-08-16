
module seg_led(
    input                   clk    ,   //ʱ���ź�
    input                   rst_n  ,  //��λ�ź�

    input         [19:0]  data   , //6λ�����Ҫ��ʾ����ֵ

    output   reg  [5:0]   seg_sel,  //�����λѡ������������Ϊ���λ
    output   reg  [7:0]   seg_led  //����ܶ�ѡ
    );

//parameter define
localparam  MAX_NUM  = 50000 ; //����1ms����ļ���ֵ
localparam  point=6'b000000;
localparam  sign=0;
//reg define
reg    [23:0]      bcd_data_t    ;     //24λbcd��Ĵ���
reg    [15:0]      cnt_1ms       ;      //����ܶ�̬��ʾ������
reg                  cnt_1ms_flag  ;    //��־�źţ���־��cnt_1ms������1ms��
reg    [2:0]        cnt_sel       ;       //�����λѡ������
reg    [3:0]        bcd_data_disp ;  //��ǰ�������ʾ������
reg                  dot_disp      ;     //��ǰ�������ʾ��С����
                                 
//wire define         
wire   [23:0]      bcd_data      ; //24λbcd��     

//*****************************************************
//**                    main code
//*****************************************************


//��20λ2������ת��Ϊ8421bcd��(��ʹ��4λ����������ʾ1λʮ��������
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        bcd_data_t <= 24'b0;
    else begin
        if (bcd_data[23:20] || point[5]) //�����ʾ����Ϊ6λʮ������
            bcd_data_t <= bcd_data; //����λ��������ܶ���ֵ
        else if(bcd_data[19:16] || point[4]) begin//�����ʾ����Ϊ5λʮ�������������5λ����ܸ�ֵ
			   bcd_data_t[19:0] <= bcd_data[19:0];
            if(sign)                    
                bcd_data_t[23:20] <= 4'd11; //�����Ҫ��ʾ���ţ������λ����6λ��Ϊ����λ
            else
                bcd_data_t[23:20] <= 4'd10; //����Ҫ��ʾ����ʱ�����6λ����ʾ�κ��ַ�
        end
        else if (bcd_data[15:12] || point[3]) begin
            bcd_data_t[15:0] <= bcd_data[15:0];
            bcd_data_t[23:20] <= 4'd10; //��6λ����ʾ�κ��ַ�
            if(sign)             //�����Ҫ��ʾ���ţ������λ����5λ��Ϊ����λ
                bcd_data_t[19:16] <= 4'd11;
            else                 //����Ҫ��ʾ����ʱ�����5λ����ʾ�κ��ַ�
                bcd_data_t[19:16] <= 4'd10;
        end
        else if (bcd_data[11:8] || point[2]) begin
            bcd_data_t[11:0] <= bcd_data[11:0];
                             //��6��5λ����ʾ�κ��ַ�
            bcd_data_t[23:16] <= {2{4'd10}};
            if(sign)         //�����Ҫ��ʾ���ţ������λ����4λ��Ϊ����λ
                bcd_data_t[15:12] <= 4'd11;
            else             //����Ҫ��ʾ����ʱ�����4λ����ʾ�κ��ַ�
                bcd_data_t[15:12] <= 4'd10;
        end        
        else if (bcd_data[7:4] || point[1]) begin
            bcd_data_t[7:0] <= bcd_data[7:0];
                         //��6��5��4λ����ʾ�κ��ַ�
            bcd_data_t[23:12] <= {3{4'd10}};
            if(sign)     //�����Ҫ��ʾ���ţ������λ����3λ��Ϊ����λ
                bcd_data_t[11:8]  <= 4'd11;
            else         //����Ҫ��ʾ����ʱ�����3λ����ʾ�κ��ַ�
                bcd_data_t[11:8] <=  4'd10;
        end        
        else begin
            bcd_data_t[3:0] <= bcd_data[3:0];
                         //��6��5λ����ʾ�κ��ַ�
            bcd_data_t[23:8] <= {4{4'd10}};
            if(sign)     //�����Ҫ��ʾ���ţ������λ����2λ��Ϊ����λ
                bcd_data_t[7:4] <= 4'd11;
            else         //����Ҫ��ʾ����ʱ�����2λ����ʾ�κ��ַ�
                bcd_data_t[7:4] <= 4'd10;
        end
    end 
end

//ÿ�������������������ʱ�Ӽ���ʱ���1ms�����һ��ʱ�����ڵ������ź�
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

//cnt_sel��0������5������ѡ��ǰ������ʾ״̬�������
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

//���������λѡ�źţ�ʹ6λ�����������ʾ
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seg_sel  <= 6'b111111;              //λѡ�źŵ͵�ƽ��Ч
        bcd_data_disp <= 4'b0;
		  dot_disp <= 1'b1;                   //����������ܣ��͵�ƽ��ͨ
    end
    else begin
            case (cnt_sel)
                3'd0 :begin
                    seg_sel  <= 6'b111110;  //��ʾ��������λ
                    bcd_data_disp <= bcd_data_t[3:0] ;  //��ʾ������
						  dot_disp <= ~point[0];
                end
                3'd1 :begin
                    seg_sel  <= 6'b111101;  //��ʾ����ܵ�1λ
                    bcd_data_disp <= bcd_data_t[7:4] ;
						  dot_disp <= ~point[1];
                end
                3'd2 :begin
                    seg_sel  <= 6'b111011;  //��ʾ����ܵ�2λ
                    bcd_data_disp <= bcd_data_t[11:8];
						  dot_disp <= ~point[2];
                end
                3'd3 :begin
                    seg_sel  <= 6'b110111;  //��ʾ����ܵ�3λ
                    bcd_data_disp <= bcd_data_t[15:12];
						  dot_disp <= ~point[3];
                end
                3'd4 :begin
                    seg_sel  <= 6'b101111;  //��ʾ����ܵ�4λ
                    bcd_data_disp <= bcd_data_t[19:16];
						  dot_disp <= ~point[4];
                end
                3'd5 :begin
                    seg_sel  <= 6'b011111;  //��ʾ��������λ
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

//��������ܶ�ѡ�źţ���ʾ�ַ�
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        seg_led <= 8'hff;
    else begin
        case (bcd_data_disp)
            4'd0 : seg_led <= {dot_disp,7'b1000000}; //��ʾ���� 0
            4'd1 : seg_led <= {dot_disp,7'b1111001}; //��ʾ���� 1
            4'd2 : seg_led <= {dot_disp,7'b0100100}; //��ʾ���� 2
            4'd3 : seg_led <= {dot_disp,7'b0110000}; //��ʾ���� 3
            4'd4 : seg_led <= {dot_disp,7'b0011001}; //��ʾ���� 4
            4'd5 : seg_led <= {dot_disp,7'b0010010}; //��ʾ���� 5
            4'd6 : seg_led <= {dot_disp,7'b0000010}; //��ʾ���� 6
            4'd7 : seg_led <= {dot_disp,7'b1111000}; //��ʾ���� 7
            4'd8 : seg_led <= {dot_disp,7'b0000000}; //��ʾ���� 8
            4'd9 : seg_led <= {dot_disp,7'b0010000}; //��ʾ���� 9
            4'd10: seg_led <= 8'b11111111;         //����ʾ�κ��ַ�
            4'd11: seg_led <= 8'b10111111;         //��ʾ����(-)
            default:seg_led <= 8'hff;
        endcase
    end
end

//����������תBCDģ��
binary2bcd u_binary2bcd(  
    .sys_clk        (clk     ),
    .sys_rst_n     (rst_n   ),
                
    .data            (data    ),
    .bcd_data     (bcd_data)
    );

endmodule 
