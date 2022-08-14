enum logic [8:0] {
	KEY_ESC                 = 9'h076,
	KEY_1                   = 9'h016,
	KEY_2                   = 9'h01e,
	KEY_3                   = 9'h026,
	KEY_4                   = 9'h025,
	KEY_5                   = 9'h02e,
	KEY_6                   = 9'h036,
	KEY_7                   = 9'h03d,
	KEY_8                   = 9'h03e,
	KEY_9                   = 9'h046,
	KEY_0                   = 9'h045,
	KEY_MINUS               = 9'h04e,
	KEY_EQUAL               = 9'h055,
	KEY_BACKSPACE           = 9'h066,
	KEY_TAB                 = 9'h00d,
	KEY_Q                   = 9'h015,
	KEY_W                   = 9'h01d,
	KEY_E                   = 9'h024,
	KEY_R                   = 9'h02d,
	KEY_T                   = 9'h02c,
	KEY_Y                   = 9'h035,
	KEY_U                   = 9'h03c,
	KEY_I                   = 9'h043,
	KEY_O                   = 9'h044,
	KEY_P                   = 9'h04d,
	KEY_LEFTBRACE           = 9'h054,
	KEY_RIGHTBRACE          = 9'h05b,
	KEY_ENTER               = 9'h05a,
	KEY_LEFTCTRL            = 9'h014,
	KEY_A                   = 9'h01c,
	KEY_S                   = 9'h01b,
	KEY_D                   = 9'h023,
	KEY_F                   = 9'h02b,
	KEY_G                   = 9'h034,
	KEY_H                   = 9'h033,
	KEY_J                   = 9'h03b,
	KEY_K                   = 9'h042,
	KEY_L                   = 9'h04b,
	KEY_SEMICOLON           = 9'h04c,
	KEY_APOSTROPHE          = 9'h052,
	KEY_GRAVE               = 9'h00e,
	KEY_LEFTSHIFT           = 9'h012,
	KEY_BACKSLASH           = 9'h05d,
	KEY_Z                   = 9'h01a,
	KEY_X                   = 9'h022,
	KEY_C                   = 9'h021,
	KEY_V                   = 9'h02a,
	KEY_B                   = 9'h032,
	KEY_N                   = 9'h031,
	KEY_M                   = 9'h03a,
	KEY_COMMA               = 9'h041,
	KEY_DOT                 = 9'h049,
	KEY_SLASH               = 9'h04a,
	KEY_RIGHTSHIFT          = 9'h059,
	KEY_KPASTERISK          = 9'h07c,
	KEY_LEFTALT             = 9'h011,
	KEY_SPACE               = 9'h029,
	KEY_CAPSLOCK            = 9'h058,
	KEY_F1                  = 9'h005,
	KEY_F2                  = 9'h006,
	KEY_F3                  = 9'h004,
	KEY_F4                  = 9'h00c,
	KEY_F5                  = 9'h003,
	KEY_F6                  = 9'h00b,
	KEY_F7                  = 9'h083,
	KEY_F8                  = 9'h00a,
	KEY_F9                  = 9'h001,
	KEY_F10                 = 9'h009,
	KEY_NUMLOCK             = 9'h077,
	KEY_SCROLLLOCK          = 9'h07E,
	KEY_KP7                 = 9'h06c,
	KEY_KP8                 = 9'h075,
	KEY_KP9                 = 9'h07d,
	KEY_KPMINUS             = 9'h07b,
	KEY_KP4                 = 9'h06b,
	KEY_KP5                 = 9'h073,
	KEY_KP6                 = 9'h074,
	KEY_KPPLUS              = 9'h079,
	KEY_KP1                 = 9'h069,
	KEY_KP2                 = 9'h072,
	KEY_KP3                 = 9'h07a,
	KEY_KP0                 = 9'h070,
	KEY_KPDOT               = 9'h071,
	//KEY_ZENKAKU             = 9'h00e,
	KEY_102ND               = 9'h061,
	KEY_F11                 = 9'h078,
	KEY_F12                 = 9'h007,
	KEY_RO                  = 9'h013,
	// KEY_KATAKANA            = 9'h013,
	// KEY_HIRAGANA            = 9'h013,
	KEY_HENKAN              = 9'h064,
	KEY_MUHENKAN            = 9'h067,
	KEY_KPENTER             = 9'h15A,
	KEY_RIGHTCTRL           = 9'h114,
	KEY_KPSLASH             = 9'h14A,
	KEY_SYSRQ               = 9'h0E2,
	KEY_RIGHTALT            = 9'h111,
	KEY_HOME                = 9'h16C,
	KEY_UP                  = 9'h175,
	KEY_PAGEUP              = 9'h17D,
	KEY_LEFT                = 9'h16B,
	KEY_RIGHT               = 9'h174,
	KEY_END                 = 9'h169,
	KEY_DOWN                = 9'h172,
	KEY_PAGEDOWN            = 9'h17A,
	KEY_INSERT              = 9'h170,
	KEY_DELETE              = 9'h171,
	KEY_PAUSE               = 9'h0E1,
	KEY_YEN                 = 9'h06a,
	KEY_LEFTMETA            = 9'h11F,
	KEY_RIGHTMETA           = 9'h127,
	KEY_COMPOSE             = 9'h12F
	//KEY_INT_BS              = 9'h05D
} ps2_scancodes;

module cv_keyboard
(
	input              clk,
	input              reset,
	input              laser,
	input        [8:0] ps2_key, // MSB represents extended or not extended
	input              ps2_keydown,
	input              ps2_strobe,
	input        [7:0] joy1,
	input        [7:0] joy2,
	input        [7:0] select_a,
	input        [7:0] select_b,
	output logic [7:0] code_a,
	output logic [7:0] code_b
);

reg [511:0] KT; // Keyboard state

wire [7:0] joy_mask_1 = {~joy1[5], 1'b1, ~joy1[1], 1'b1, ~joy1[3], ~joy1[0], ~joy1[2], 1'b1};
wire [7:0] joy_kb_mask_1 = {~joy1[4], ~joy1[6], 3'b111, ~joy1[6], 2'b11};
wire [7:0] joy_mask_2 = {~joy2[5], 1'b1, ~joy2[1], 1'b1, ~joy2[2], ~joy2[0], ~joy2[3], 1'b1};
wire [7:0] joy_kb_mask_2 = {~joy2[4], ~joy2[6], 3'b111, ~joy2[6], 2'b11};

always_ff @(posedge clk) begin
	reg last_strobe;
	if (ps2_strobe != last_strobe) begin
		KT[ps2_key[8:0]] <= ps2_keydown;
		last_strobe <= ps2_strobe;
	end

	case (select_a[3:0])
		4'b1101: code_b <= 8'hFF &
			(KT[KEY_Z]          ? 8'hf5 : 8'hFF) &
			(KT[KEY_A]          ? 8'hee : 8'hFF) &
			(KT[KEY_Q]          ? 8'he7 : 8'hFF) &
			(KT[KEY_2]          ? 8'hcf : 8'hFF) &
			(KT[KEY_X]          ? 8'hed : 8'hFF) &
			(KT[KEY_S]          ? 8'hde : 8'hFF) &
			(KT[KEY_W]          ? 8'hf3 : 8'hFF) &
			(KT[KEY_3]          ? 8'h9f : 8'hFF) &
			(KT[KEY_C]          ? 8'hdd : 8'hFF) &
			(KT[KEY_D]          ? 8'hbe : 8'hFF) &
			(KT[KEY_E]          ? 8'heb : 8'hFF) &
			(KT[KEY_4]          ? 8'hd7 : 8'hFF) &
			(KT[KEY_V]          ? 8'hbd : 8'hFF) &
			(KT[KEY_F]          ? 8'hfc : 8'hFF) &
			(KT[KEY_R]          ? 8'hdb : 8'hFF) &
			(KT[KEY_5]          ? 8'hb7 : 8'hFF) &
			(KT[KEY_B]          ? 8'hf9 : 8'hFF) &
			(KT[KEY_G]          ? 8'hfa : 8'hFF) &
			(KT[KEY_T]          ? 8'hbb : 8'hFF) &
			(KT[KEY_6]          ? 8'haf : 8'hFF) &
			(KT[KEY_LEFTSHIFT]  ? 8'h7f : 8'hFF) &
			(KT[KEY_BACKSPACE]  ? 8'hf6 : 8'hFF) &
			joy_kb_mask_1;

		4'b0111: code_b <= 8'hFF &
			(KT[KEY_MINUS]      ? 8'h7f : 8'hFF) &
			(KT[KEY_LEFTBRACE]  ? 8'hf5 : 8'hFF) & // This is actually colon
			(KT[KEY_P]          ? 8'hee : 8'hFF) &
			(KT[KEY_SEMICOLON]  ? 8'he7 : 8'hFF) &
			(KT[KEY_SLASH]      ? 8'hcf : 8'hFF) &
			(KT[KEY_0]          ? 8'hed : 8'hFF) &
			(KT[KEY_O]          ? 8'hde : 8'hFF) &
			(KT[KEY_L]          ? 8'hf3 : 8'hFF) &
			(KT[KEY_DOT]        ? 8'h9f : 8'hFF) &
			(KT[KEY_9]          ? 8'hdd : 8'hFF) &
			(KT[KEY_I]          ? 8'hbe : 8'hFF) &
			(KT[KEY_K]          ? 8'heb : 8'hFF) &
			(KT[KEY_COMMA]      ? 8'hd7 : 8'hFF) &
			(KT[KEY_8]          ? 8'hbd : 8'hFF) &
			(KT[KEY_U]          ? 8'hfc : 8'hFF) &
			(KT[KEY_J]          ? 8'hdb : 8'hFF) &
			(KT[KEY_M]          ? 8'hb7 : 8'hFF) &
			(KT[KEY_7]          ? 8'hf9 : 8'hFF) &
			(KT[KEY_Y]          ? 8'hfa : 8'hFF) &
			(KT[KEY_H]          ? 8'hbb : 8'hFF) &
			(KT[KEY_N]          ? 8'haf : 8'hFF) &
			(KT[KEY_ENTER]      ? 8'hf6 : 8'hFF) &
			joy_kb_mask_2;

		4'b1011: code_b <= 8'hFF &
			(KT[KEY_TAB]        ? 8'h7f : 8'hFF) &
			(KT[KEY_SPACE]      ? 8'hf3 : 8'hFF) &
			joy_mask_2;

		4'b1110: code_b <= 8'hFF &
			(KT[KEY_RIGHTSHIFT] ? 8'h7f : 8'hFF) &
			(KT[KEY_APOSTROPHE] ? 8'h7f : 8'hFF) &
			(KT[KEY_DOWN]       ? 8'hfd : 8'hFF) &
			(KT[KEY_UP]         ? 8'hf7 : 8'hFF) &
			(KT[KEY_LEFT]       ? 8'hdf : 8'hFF) &
			(KT[KEY_RIGHT]      ? 8'hfb : 8'hFF) &
			(KT[KEY_1]          ? 8'hf3 : 8'hFF) &
			joy_mask_1;

		default: code_b <= 8'hFF;
	endcase

	// äöå

	case (select_b)
		8'b1111_1110: code_a <= 8'hFF &
			(KT[KEY_DOT]        ? 8'b1111_1011 : 8'hFF) & // .
			(KT[KEY_ENTER]      ? 8'b1111_0111 : 8'hFF) & // return
			(KT[KEY_3]          ? 8'b1110_1111 : 8'hFF) & // 3
			(KT[KEY_E]          ? 8'b1101_1111 : 8'hFF) & // e
			(KT[KEY_S]          ? 8'b1011_1111 : 8'hFF) & // s
			(KT[KEY_X]          ? 8'b0111_1111 : 8'hFF);  // x

		8'b1111_1101: code_a <= 8'hFF &
			(KT[KEY_RIGHTBRACE] ? 8'b1111_1011 : 8'hFF) & // ä
			(KT[KEY_SEMICOLON]  ? 8'b1111_0111 : 8'hFF) & // ;
			(KT[KEY_2]          ? 8'b1110_1111 : 8'hFF) & // 2
			(KT[KEY_W]          ? 8'b1101_1111 : 8'hFF) & // w
			(KT[KEY_A]          ? 8'b1011_1111 : 8'hFF) & // a
			(KT[KEY_Z]          ? 8'b0111_1111 : 8'hFF);  // z

		8'b1111_1011: code_a <= 8'hFF &
			(KT[KEY_I]          ? 8'b1111_1110 : 8'hFF) & // i
			(KT[KEY_SLASH]      ? 8'b1111_1011 : 8'hFF) & // /
			(KT[KEY_APOSTROPHE] ? 8'b1111_0111 : 8'hFF) & // å
			(KT[KEY_1]          ? 8'b1110_1111 : 8'hFF) & // 1
			(KT[KEY_Q]          ? 8'b1101_1111 : 8'hFF) & // q
			(KT[KEY_LEFTCTRL]   ? 8'b1011_1111 : 8'hFF) & // ctrl
			(KT[KEY_LEFTSHIFT]  ? 8'b0111_1111 : 8'hFF);  // shift

		8'b1111_0111: code_a <= 8'hFF &
			(KT[KEY_N]          ? 8'b1111_1110 : 8'hFF) & // n
			(KT[KEY_X]          ? 8'b1111_1101 : 8'hFF) & // x
			(KT[KEY_BACKSLASH]  ? 8'b1111_1011 : 8'hFF) & // ö
			(KT[KEY_LEFTBRACE]  ? 8'b1111_0111 : 8'hFF) & // :
			(KT[KEY_4]          ? 8'b1110_1111 : 8'hFF) & // 4
			(KT[KEY_R]          ? 8'b1101_1111 : 8'hFF) & // r
			(KT[KEY_D]          ? 8'b1011_1111 : 8'hFF) & // d
			(KT[KEY_C]          ? 8'b0111_1111 : 8'hFF);  // c

		8'b1110_1111: code_a <= 8'hFF &
			(KT[KEY_COMMA]      ? 8'b1111_1011 : 8'hFF) & // ,
			(KT[KEY_P]          ? 8'b1111_0111 : 8'hFF) & // p
			(KT[KEY_5]          ? 8'b1110_1111 : 8'hFF) & // 5
			(KT[KEY_T]          ? 8'b1101_1111 : 8'hFF) & // t
			(KT[KEY_F]          ? 8'b1011_1111 : 8'hFF) & // f
			(KT[KEY_V]          ? 8'b0111_1111 : 8'hFF);  // v

		8'b1101_1111: code_a <= 8'hFF &
			(KT[KEY_J]          ? 8'b1111_1110 : 8'hFF) & // j
			(KT[KEY_L]          ? 8'b1111_1011 : 8'hFF) & // l
			(KT[KEY_0]          ? 8'b1111_0111 : 8'hFF) & // 0
			(KT[KEY_6]          ? 8'b1110_1111 : 8'hFF) & // 6
			(KT[KEY_Y]          ? 8'b1101_1111 : 8'hFF) & // y
			(KT[KEY_G]          ? 8'b1011_1111 : 8'hFF) & // g
			(KT[KEY_B]          ? 8'b0111_1111 : 8'hFF);  // b

		8'b1011_1111: code_a <= 8'hFF &
			(KT[KEY_S]          ? 8'b1111_1101 : 8'hFF) & // s
			(KT[KEY_K]          ? 8'b1111_1011 : 8'hFF) & // k
			(KT[KEY_9]          ? 8'b1111_0111 : 8'hFF) & // 9
			(KT[KEY_7]          ? 8'b1110_1111 : 8'hFF) & // 7
			(KT[KEY_U]          ? 8'b1101_1111 : 8'hFF) & // u
			(KT[KEY_H]          ? 8'b1011_1111 : 8'hFF) & // h
			(KT[KEY_N]          ? 8'b0111_1111 : 8'hFF);  // n

		8'b0111_1111: code_a <= 8'hFF &
			(KT[KEY_X]          ? 8'b1111_1110 : 8'hFF) & // x
			(KT[KEY_N]          ? 8'b1111_1101 : 8'hFF) & // n
			(KT[KEY_SPACE]      ? 8'b1111_1011 : 8'hFF) & // space
			(KT[KEY_O]          ? 8'b1111_0111 : 8'hFF) & // o
			(KT[KEY_8]          ? 8'b1110_1111 : 8'hFF) & // 8
			(KT[KEY_I]          ? 8'b1101_1111 : 8'hFF) & // i
			(KT[KEY_J]          ? 8'b1011_1111 : 8'hFF) & // j
			(KT[KEY_M]          ? 8'b0111_1111 : 8'hFF);  // m

		default: code_a <= 8'hFF;
	endcase
	if (reset)
		KT <= '0;
end


endmodule

module text_writer
(
	input clk,
	input reset,
	input [7:0] ascii_byte,
	input strobe,
	output logic input_wait,
	output logic [10:0] ps2_key
);

typedef enum logic [2:0] {
	STATE_IDLE       = 3'b000,
	STATE_CHOOSE     = 3'b001,
	STATE_SHIFT_DOWN = 3'b010,
	STATE_SHIFT_UP   = 3'b011,
	STATE_KEY_DOWN   = 3'b100,
	STATE_KEY_UP     = 3'b101,
	STATE_WAIT       = 3'b110
} writer_state_t;

parameter cycles_per_key_change = 2155454;

integer key_timer;
reg [8:0] code;
reg has_shift;

writer_state_t state = STATE_IDLE;

always @(posedge clk) begin
	reg old_strobe;
	if (key_timer)
		key_timer <= key_timer - 1;

	old_strobe <= strobe;
	case (state)
		STATE_IDLE: begin
			input_wait <= 0;
			if (~old_strobe && strobe) begin
				state <= STATE_CHOOSE;
				input_wait <= 1;
				case (ascii_byte)
					"A": begin has_shift <= 0; code <= KEY_A; end
					"B": begin has_shift <= 0; code <= KEY_B; end
					"C": begin has_shift <= 0; code <= KEY_C; end
					"D": begin has_shift <= 0; code <= KEY_D; end
					"E": begin has_shift <= 0; code <= KEY_E; end
					"F": begin has_shift <= 0; code <= KEY_F; end
					"G": begin has_shift <= 0; code <= KEY_G; end
					"H": begin has_shift <= 0; code <= KEY_H; end
					"I": begin has_shift <= 0; code <= KEY_I; end
					"J": begin has_shift <= 0; code <= KEY_J; end
					"K": begin has_shift <= 0; code <= KEY_K; end
					"L": begin has_shift <= 0; code <= KEY_L; end
					"M": begin has_shift <= 0; code <= KEY_M; end
					"N": begin has_shift <= 0; code <= KEY_N; end
					"O": begin has_shift <= 0; code <= KEY_O; end
					"P": begin has_shift <= 0; code <= KEY_P; end
					"Q": begin has_shift <= 0; code <= KEY_Q; end
					"R": begin has_shift <= 0; code <= KEY_R; end
					"S": begin has_shift <= 0; code <= KEY_S; end
					"T": begin has_shift <= 0; code <= KEY_T; end
					"U": begin has_shift <= 0; code <= KEY_U; end
					"V": begin has_shift <= 0; code <= KEY_V; end
					"W": begin has_shift <= 0; code <= KEY_W; end
					"X": begin has_shift <= 0; code <= KEY_X; end
					"Y": begin has_shift <= 0; code <= KEY_Y; end
					"Z": begin has_shift <= 0; code <= KEY_Z; end
					"1": begin has_shift <= 0; code <= KEY_1; end
					"2": begin has_shift <= 0; code <= KEY_2; end
					"3": begin has_shift <= 0; code <= KEY_3; end
					"4": begin has_shift <= 0; code <= KEY_4; end
					"5": begin has_shift <= 0; code <= KEY_5; end
					"6": begin has_shift <= 0; code <= KEY_6; end
					"7": begin has_shift <= 0; code <= KEY_7; end
					"8": begin has_shift <= 0; code <= KEY_8; end
					"9": begin has_shift <= 0; code <= KEY_9; end
					"0": begin has_shift <= 0; code <= KEY_0; end
					":": begin has_shift <= 0; code <= KEY_LEFTBRACE; end
					";": begin has_shift <= 0; code <= KEY_SEMICOLON; end
					"/": begin has_shift <= 0; code <= KEY_SLASH; end
					".": begin has_shift <= 0; code <= KEY_DOT; end
					",": begin has_shift <= 0; code <= KEY_COMMA; end
					"-": begin has_shift <= 0; code <= KEY_MINUS; end
					" ": begin has_shift <= 0; code <= KEY_SPACE; end
					// Shifted keys
					"!":  begin has_shift <= 1; code <= KEY_1; end   // 1
					"\"": begin has_shift <= 1; code <= KEY_2; end  // 2
					"#":  begin has_shift <= 1; code <= KEY_3; end   // 3
					"$":  begin has_shift <= 1; code <= KEY_4; end   // 4
					"\%": begin has_shift <= 1; code <= KEY_5; end  // 5
					"&":  begin has_shift <= 1; code <= KEY_6; end   // 6
					"'":  begin has_shift <= 1; code <= KEY_7; end   // 7
					"(":  begin has_shift <= 1; code <= KEY_8; end   // 8
					")":  begin has_shift <= 1; code <= KEY_9; end   // 9
					"@":  begin has_shift <= 1; code <= KEY_0; end   // 0
					"*":  begin has_shift <= 1; code <= KEY_LEFTBRACE; end   // :
					"=":  begin has_shift <= 1; code <= KEY_MINUS; end   // -
					"+":  begin has_shift <= 1; code <= KEY_SEMICOLON; end   // ;
					"<":  begin has_shift <= 1; code <= KEY_COMMA; end   // ,
					">":  begin has_shift <= 1; code <= KEY_DOT; end   // .
					"?":  begin has_shift <= 1; code <= KEY_SLASH; end   // /
					8'h0A: begin has_shift <= 1; code <= KEY_ENTER; end // New Line
					default: code <= 9'd0; // NOP
				endcase
			end
		end

		STATE_CHOOSE: begin
			if (code == 0) begin
				state <= STATE_IDLE;
			end else if (has_shift) begin
				state <= STATE_SHIFT_DOWN;
			end else begin
				state <= STATE_KEY_DOWN;
			end
		end

		STATE_SHIFT_DOWN: begin
			ps2_key[8:0] <= KEY_LEFTSHIFT;
			ps2_key[9] <= 1;
			ps2_key[10] <= ~ps2_key[10];
			key_timer <= cycles_per_key_change;
			state <= STATE_KEY_DOWN;
		end

		STATE_KEY_DOWN: begin
			if (key_timer == 0) begin
				ps2_key[8:0] <= code;
				ps2_key[9] <= 1;
				ps2_key[10] <= ~ps2_key[10];
				key_timer <= cycles_per_key_change;
				state <= STATE_KEY_UP;
			end
		end

		STATE_KEY_UP: begin
			if (key_timer == 0) begin
				ps2_key[8:0] <= code;
				ps2_key[9] <= 0;
				ps2_key[10] <= ~ps2_key[10];
				key_timer <= cycles_per_key_change;
				state <= has_shift ? STATE_SHIFT_UP : STATE_WAIT;
			end
		end

		STATE_SHIFT_UP: begin
			if (key_timer == 0) begin
				ps2_key[8:0] <= KEY_LEFTSHIFT;
				ps2_key[9] <= 0;
				ps2_key[10] <= ~ps2_key[10];
				key_timer <= cycles_per_key_change;
				state <= STATE_WAIT;
			end
		end

		STATE_WAIT: begin
			if (key_timer == 0) begin
				state <= STATE_IDLE;
			end
		end
	endcase
	if (reset)
		input_wait <= 0;
end

endmodule