`default_nettype none
module orionkeyboard
(
input				clk,
input				reset,
output              res_k,
output              turb_10,
output              turb_5,
output              turb_2,
output              rom_s,
output              cpm_s,

input				ps2_clk,
input				ps2_data,

input		[7:0]	rk_kb_scan,
output		[7:0]	rk_kb_out,
output      [1:0]   pref,
output				key_rus_lat,
output				key_us,
output				key_ss,

input				ind_rus_lat,

output		[7:0]	rk_kbo,
output              key_int,
input               ask_int


);

assign			key_rus_lat	=	caps;
assign			key_us		=	ctrl;
assign			key_ss		=	shift;
assign          res_k       =   res_key;
assign          turb_10     =   turbo10;
assign          turb_5      =   turbo5;
assign          turb_2      =   turbo2;
assign          rom_s       =   rom;
assign          cpm_s       =   cpm;



assign	rk_kbo	=	rk_kb;
assign  key_int =   keyb_int;
assign  pref    =   prefix;

reg		[7:0]	rk_kb;

reg				shift	=	1'b1;
reg				ctrl	=	1'b1;
reg				caps	=	1'b1;
reg             res_key =   1'b0;
reg             turbo10 =   1'b0;
reg             turbo5  =   1'b0;
reg             turbo2  =   1'b0;
reg             rom     =   1'b0;
reg             cpm     =   1'b0;

reg				ex_code	= 0;	
reg		[3:0]	state = 0;
reg				press_release;
reg				strobe;
reg             keyb_int =  1'b0;
reg     [1:0]   prefix = 2'b00; 

always @(posedge clk) begin
	if (reset) begin
		shift			<= 1;
		ctrl			<= 1;
		caps			<= 1;
		state			<= 0;
		res_key         <= 0;
		cpm             <= 0;
	end 
	else begin
		case (state)
		0: begin
			if (ps2dsr) begin
					ps2rden <= 1;
					state <= 1;
					end
			end
		1:	begin
				state <= 2;
				ps2rden <= 0;
			end
		2:	begin
				ps2rden <= 0;
				if (ps2q == 8'hF0) begin
					state <= 6;
				end
				else if (ps2q == 8'hE0) begin
						ex_code	<= 1;
						state <= 0;
					end
							else	begin
									state <= 4;
									end
			end		
		4:	begin
			if ((ps2q == 8'h12) && ex_code) begin
				ex_code <= 0;
				state <= 0;
			end
				else
					rk_kb <= ps2q;
					prefix<=ex_code? 1 : 0;
					keyb_int<=1'b1;					
					case(ps2q)
						8'h12, 8'h59:	shift		<= 1'b0;		//шифт нажат
						8'h14:			ctrl		<= 1'b0;		//контрол нажат
						8'h58:			caps		<= 1'b0;		//капс -руслат
						8'h7e:          res_key     <= 1'b1;        //reset
						8'h07:          turbo10     <= 1'b1;        //turbo10
						8'h78:          turbo5      <= 1'b1;        //turbo5
						8'h09:          turbo2      <= 1'b1;        //turbo2
						8'h01:          rom         <= 1'b1;        //rom_sel
						8'h0a:          cpm         <= 1'b1;        //cp/m sel
						default: begin
									press_release	<= 1'b1; 
									strobe	<=	1'b1;
						end
					endcase
			state <= 5;
			end
		5:	begin
			strobe	<=	1'b0;
			keyb_int<=  0;
			state	<=	0;
			ex_code <=  0;
			end
			
		6:	begin
				if (ps2dsr) begin
					ps2rden <= 1;
					state <= 7;
				end
			end
			
		7:	begin
				ps2rden <= 0;
				state <= 8;
			end
			
		8:	begin
			if (ps2q == 8'hE0) begin
				ex_code <= 1'b1;
				state <=  6;
				end
			else	begin	
					state <= 9;
					end
			end
		9:	begin
				if ((ps2q == 8'h12) && ex_code) begin
					ex_code <= 0;
					state <= 6;
				end
			else
			    rk_kb <= ps2q;
			    prefix<=2;
				case(ps2q)
					8'h12, 8'h59:	shift			<= 1'b1;  
					8'h14:			ctrl			<= 1'b1;
					8'h58:			caps		 	<= 1'b1;
					8'h7e:          res_key         <= 1'b0;        //reset
					8'h07:          turbo10         <= 1'b0;        //turbo10
					8'h78:          turbo5          <= 1'b0;        //turbo5
					8'h09:          turbo2          <= 1'b0;        //turbo2
					8'h01:          rom             <= 1'b0;        //rom_sel
					8'h0a:          cpm             <= 1'b0;        //cp/m sel
					default: 
						begin
						press_release	<= 1'b0;
						strobe	<=	1'b1;
						keyb_int<=  1'b1;
						end
				endcase
				state <= 10;
			end
		10:	begin
			ex_code <=  0;
			strobe	<=	1'b0;
			keyb_int<=  0;
			state	<=	0;
			end
		endcase
	end
end


assign	rk_kb_out = ~(8'h00 |   ((rk_kb_scan[0]==1'b0)? keymatrix[0]: 8'h0) |
								((rk_kb_scan[1]==1'b0)? keymatrix[7]: 8'h0) |
								((rk_kb_scan[2]==1'b0)? keymatrix[6]: 8'h0) |
								((rk_kb_scan[3]==1'b0)? keymatrix[5]: 8'h0) |
								((rk_kb_scan[4]==1'b0)? keymatrix[4]: 8'h0) |
								((rk_kb_scan[5]==1'b0)? keymatrix[3]: 8'h0) |
								((rk_kb_scan[6]==1'b0)? keymatrix[2]: 8'h0) |
								((rk_kb_scan[7]==1'b0)? keymatrix[1]: 8'h0) );

reg		[7:0]	keymatrix[0:7];

always	@(posedge	clk)
begin
	if (reset) begin
		keymatrix[0]	<= 8'h0;
		keymatrix[1]	<= 8'h0;
		keymatrix[2]	<= 8'h0;
		keymatrix[3]	<= 8'h0;
		keymatrix[4]	<= 8'h0;
		keymatrix[5]	<= 8'h0;
		keymatrix[6]	<= 8'h0;
		keymatrix[7]	<= 8'h0;
	end

	else	begin
				if (strobe) begin
					case ({ex_code, rk_kb[7:0]})
					9'h16c:	keymatrix[0][0]	<= press_release; //Home
					9'h171:	keymatrix[0][1]	<= press_release; //Delete
					9'h076:	keymatrix[0][2]	<= press_release; //Esc
					9'h005:	keymatrix[0][3]	<= press_release; //F1
					9'h006:	keymatrix[0][4]	<= press_release; //F2
					9'h004:	keymatrix[0][5]	<= press_release; //F3 
					9'h00c:	keymatrix[0][6]	<= press_release; //F4
					9'h003:	keymatrix[0][7]	<= press_release; //F5

					9'h022:	keymatrix[1][0]	<= press_release; //X
					9'h035:	keymatrix[1][1]	<= press_release; //Y
					9'h01a:	keymatrix[1][2]	<= press_release; //Z
					9'h054:	keymatrix[1][3]	<= press_release; //{
					9'h05d:	keymatrix[1][4]	<= press_release; //backslash
					9'h05b:	keymatrix[1][5]	<= press_release; //}
					9'h00e:	keymatrix[1][6]	<= press_release; //`
					9'h029:	keymatrix[1][7]	<= press_release; //Space
                                   
					9'h04d:	keymatrix[2][0]	<= press_release; //P
					9'h015:	keymatrix[2][1]	<= press_release; //Q
					9'h02d:	keymatrix[2][2]	<= press_release; //R
					9'h01b:	keymatrix[2][3]	<= press_release; //S
					9'h02c:	keymatrix[2][4]	<= press_release; //T
					9'h03c:	keymatrix[2][5]	<= press_release; //U
					9'h02a:	keymatrix[2][6]	<= press_release; //V
					9'h01d:	keymatrix[2][7]	<= press_release; //W
                                   
					9'h033:	keymatrix[3][0]	<= press_release; //H
					9'h043:	keymatrix[3][1]	<= press_release; //I
					9'h03b:	keymatrix[3][2]	<= press_release; //J
					9'h042:	keymatrix[3][3]	<= press_release; //K
					9'h04b:	keymatrix[3][4]	<= press_release; //L
					9'h03a:	keymatrix[3][5]	<= press_release; //M
					9'h031:	keymatrix[3][6]	<= press_release; //N
					9'h044:	keymatrix[3][7]	<= press_release; //O
                                   
					9'h052:	keymatrix[4][0]	<= press_release; //'
					9'h01c:	keymatrix[4][1]	<= press_release; //A
					9'h032:	keymatrix[4][2]	<= press_release; //B
					9'h021:	keymatrix[4][3]	<= press_release; //C
					9'h023:	keymatrix[4][4]	<= press_release; //D
					9'h024:	keymatrix[4][5]	<= press_release; //E
					9'h02b:	keymatrix[4][6]	<= press_release; //F
					9'h034:	keymatrix[4][7]	<= press_release; //G
                                   
					9'h04c:	keymatrix[5][2]	<= press_release; //;:
					9'h07c:	keymatrix[5][2]	<= press_release; // ;:
					9'h04e:	keymatrix[5][3]	<= press_release; //-_
					9'h079:	keymatrix[5][3]	<= press_release; // -_
					9'h041:	keymatrix[5][4]	<= press_release; //,<
					9'h055:	keymatrix[5][5]	<= press_release; //=+
					9'h07b:	keymatrix[5][5]	<= press_release; // =+
					9'h049:	keymatrix[5][6]	<= press_release; //.>
					9'h071:	keymatrix[5][6]	<= press_release; // .>
					9'h04a:	keymatrix[5][7]	<= press_release; // /?
					9'h14a:	keymatrix[5][7]	<= press_release; //  /?
                                   
					9'h045:	keymatrix[6][0]	<= press_release; //0
		            9'h070:	keymatrix[6][0]	<= press_release; // 0
			        9'h016:	keymatrix[6][1]	<= press_release; //1
			        9'h069:	keymatrix[6][1]	<= press_release; // 1
			        9'h01e:	keymatrix[6][2]	<= press_release; //2
			        9'h072:	keymatrix[6][2]	<= press_release; // 2
			        9'h026:	keymatrix[6][3]	<= press_release; //3
			        9'h07a:	keymatrix[6][3]	<= press_release; // 3
			        9'h025:	keymatrix[6][4]	<= press_release; //4
			        9'h06b:	keymatrix[6][4]	<= press_release; // 4
			        9'h02e:	keymatrix[6][5]	<= press_release; //5
			        9'h073:	keymatrix[6][5]	<= press_release; // 5
			        9'h036:	keymatrix[6][6]	<= press_release; //6
			        9'h074:	keymatrix[6][6]	<= press_release; // 6
			        9'h03d:	keymatrix[6][7]	<= press_release; //7
			        9'h06c:	keymatrix[6][7]	<= press_release; // 7
			        9'h03e:	keymatrix[5][0]	<= press_release; //8
			        9'h075:	keymatrix[5][0]	<= press_release; // 8
			        9'h046:	keymatrix[5][1]	<= press_release; //9
			        9'h07d:	keymatrix[5][1]	<= press_release; // 9			        

					9'h00d:	keymatrix[7][0]	<= press_release; //Tab
					9'h170:	keymatrix[7][1]	<= press_release; //Insert
		            9'h05a:	keymatrix[7][2]	<= press_release; //Enter
		            9'h15a:	keymatrix[7][2]	<= press_release; // Enter
					9'h066:	keymatrix[7][3]	<= press_release; //Backspace
					9'h16b:	keymatrix[7][4]	<= press_release; //Left 
					9'h175:	keymatrix[7][5]	<= press_release; //Up
					9'h174:	keymatrix[7][6]	<= press_release; //Right
					9'h172:	keymatrix[7][7]	<= press_release; //Down


					endcase
				end
		end

end




reg				ps2rden;
wire	[7:0]	ps2q;	
wire			ps2dsr;	
	
	
ps2_keyboard ps2_keyboard(
	.clk							(clk),
	.reset							(reset),
	.ps2_clk_i						(ps2_clk),
	.ps2_data_i						(ps2_data),
//	.rx_extended					(),
	.rx_released					(),
	.rx_shift_key_on				(),
	.rx_scan_code					(ps2q),
	.rx_ascii						(),
	.rx_data_ready					(ps2dsr),       // rx_read_o
	.rx_read						(ps2rden),       // rx_read_ack_i
//	.tx_data						(),
//	.tx_write						(),
//	.tx_write_ack_o					(),
//	.tx_error_no_keyboard_ack		(),

//	.translate						()
  );

endmodule
