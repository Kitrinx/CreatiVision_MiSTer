//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S = 1;
assign AUDIO_L = AUDIO_R;
assign AUDIO_MIX = 0;

assign LED_DISK = (cart_download | bootrom_download | text_download) & ~ioctl_wait;
assign LED_POWER = 0;
assign LED_USER = kb_matrix ? ~pia_ca2 : ~pa_out[6];

assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////



`include "build_id.v"
localparam CONF_STR = {
	"CreatiVision;;",
	"-;",
	"F1,rombin,Load Cartridge;",
	"FC2,rombin,Load Bios;",
	"F3,bas,Load BASIC;",
	"-;",
	"O[14:13],System Type,CreatiVision,Laser 2001,Custom;",
	"h1O[16:15],ZeroPage RAM,1k,4k,Mirrored 4k;",
	"h1O[18:17],Extra RAM,None,$4000,Both;",
	"h1O[19],Input Matrix,CreatiVision,Laser 2001;",
	"O[7],Video Region,NTSC,PAL;",
	"-;",
	"P1,Audio & Video;",
	"P1-;",
	"P1O[1],Border,Off,On;",
	"d0P1O[6],Vertical Crop,Disabled,216p(5x);",
	"d0P1O[12:9],Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;",
	"P1O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O[3:2],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"P1O[5:4],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"R8,Remove Cart;",
	"R0,Reset;",
	"J0,B,A,select,start;",
	"jn,B,A,Select,Start;",
	"jp,Y,B,Select,Start;",
	"V,v",`BUILD_DATE
};

wire forced_scandoubler;
wire [15:0] joystick_0, joystick_1;
wire  [1:0] buttons;
wire [127:0] status;
wire [10:0] ps2_key;

wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;
wire ioctl_wr;
wire ioctl_download;
wire ioctl_wait;
wire [21:0] gamma_bus;

wire clk_sys;
wire clk_vid; // Make a different clock to seperate intent in case the video rate needs change
wire clock_locked;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.gamma_bus(gamma_bus),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[14],en216p}),

	.ps2_key(ps2_key),
	.joystick_0(joystick_0),
	.joystick_1(joystick_1),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index)
);
///////////////////////   CLOCKS   ///////////////////////////////

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys)
);

assign clk_vid = clk_sys;

wire reset = RESET | status[0] | status[8] | buttons[1] | cart_download | bootrom_download;

//////////////////////////////////////////////////////////////////


wire [7:0] R,G,B;
wire HSync;
wire VSync;
wire HBlank;
wire VBlank;
wire ce_pix;
wire [7:0] video;
wire border = status[1];

wire [7:0] bootrom_dout, cart_dout;
wire [15:0] cpu_addr_bus;

wire bootrom_download = ioctl_download && ((ioctl_index[7:6] == 0 &&ioctl_index[5:0] == 0) || ioctl_index[5:0] == 2);
wire cart_download = ioctl_download && ((ioctl_index[7:6] == 1 &&ioctl_index[5:0] == 0) || ioctl_index[5:0] == 1);
wire text_download = ioctl_download && ioctl_index[5:0] == 3;

reg [15:0] cart_mask = 0;
reg [15:0] bios_mask = 0;

always @(posedge clk_sys) begin
	if (cart_download && ioctl_wr)
		cart_mask <= ioctl_addr[15:0];
	if (status[8])
		cart_mask <= '0;
end

always @(posedge clk_sys)
	if (bootrom_download && ioctl_wr)
		bios_mask <= ioctl_addr[15:0];

wire [1:0] cart_wr;
wire [7:0] cart_din;

logic tape_adc;
logic tape_adc_act;

ltc2308_tape #(.CLK_RATE(42954545)) ltc2308_tape
(
	.clk(clk_sys),
	.reset(reset),
	.ADC_BUS(ADC_BUS),
	.dout(tape_adc),
	.active(tape_adc_act)
);

// 16kb system ROM
spram #(.addr_width(14), .mem_name("ROM")) bootrom
(
	.clock          (clk_sys),
	.address        (bootrom_download ? ioctl_addr : (cpu_addr_bus[13:0] & bios_mask[13:0])),
	.data           (ioctl_dout),
	.enable         (1),
	.wren           (bootrom_download & ioctl_wr),
	.q              (bootrom_dout),
	.cs             (1)
);

// 32kb cart ROM
spram #(.addr_width(15), .mem_name("CART")) cartrom
(
	.clock          (clk_sys),
	.address        (cart_download ? ioctl_addr : cpu_addr_bus[14:0]),
	.data           (cart_download ? ioctl_dout : cart_din),
	.enable         (1),
	.wren           (cart_download ? (cart_download & ioctl_wr) : |cart_wr),
	.q              (cart_dout),
	.cs             (1)
);

wire [7:0] pa_out, pb_out;
wire [7:0] pa_in, pb_in;
wire pia_ca1, pia_ca2;

wire [1:0] bank_mode = status[14] && !status[18] ? {1'b0, status[17]} : 2'b11; // Default to RAM unless cart. Why not?
wire [1:0] page0_mode = status[14] ? status[16:15] : (status[13] ? 2'b10 : 2'b00);
wire kb_matrix = status[14] ? status[19] : status[13];
assign pia_ca1 = kb_matrix ? tape_adc : 1'b1;

creativision creativision
(
	.clk        (clk_sys),
	.rom_size   (cart_mask),
	.border     (border),
	.pal        (status[7]),
	.ca1_in     (pia_ca1),
	.ca2_out    (pia_ca2),
	.pa_out     (pa_out),
	.pb_out     (pb_out),
	.pa_in      (kb_matrix ? pa_in : {tape_adc, pa_out[6:0]}),
	.pb_in      (pb_in),
	.bank_mode  (bank_mode),
	.page0_mode (page0_mode),
	.nmi        (joystick_0[7] | joystick_1[7]),
	.reset      (reset),
	.cart_write (cart_wr),
	.cart_dout  (cart_din),
	.rom_do     (cart_dout),
	.boot_do    (bootrom_dout),
	.rom_addr   (cpu_addr_bus),
	.audio      (AUDIO_R),
	.red        (R),
	.green      (G),
	.blue       (B),
	.VSync      (VSync),
	.HSync      (HSync),
	.VBlank     (VBlank),
	.HBlank     (HBlank),
	.ce_pix     (ce_pix)
);

assign CLK_VIDEO = clk_vid;

wire [1:0] ar = status[122:121];
wire [3:0] vcopt = status[12:9];

wire [11:0] arx = (!ar) ? (border ? (status[7] ? 12'd2363 : 12'd142) : (status[7] ? 12'd512 : 12'd32)) : (ar - 1'd1);
wire [11:0] ary = (!ar) ? (border ? (status[7] ? 12'd1868 : 12'd105) : (status[7] ? 12'd279 : 12'd21)) : 12'd0;
wire [2:0] scale = status[3:2];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = (scale || forced_scandoubler);
assign VGA_SL = sl[1:0];

wire       vcrop_en = status[6];
reg  [4:0] voff;
reg en216p;

always @(posedge CLK_VIDEO) begin
	en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
	voff <= (vcopt < 6) ? {vcopt,1'b0} : ({vcopt,1'b0} - 5'd24);
end

wire vga_de;

video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? arx : (ar - 1'd1)),
	.ARY((!ar) ? ary : 12'd0),
	.CROP_SIZE((en216p & vcrop_en) ? 10'd216 : 10'd0),
	.CROP_OFF(voff),
	.SCALE(status[5:4])
);

wire freeze_sync;

video_mixer #(.LINE_LENGTH(372), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.*,

	.VGA_DE(vga_de),
	.hq2x(scale==1),
	.HSync(HSync),
	.HBlank(HBlank),
	.VSync(VSync),
	.VBlank(VBlank),

	.R(R),
	.G(G),
	.B(B)
);

wire [10:0] text_key;

// 0x1800 big-endian 2 byte line sizes
// 0x1400 big-endian 2 byte line sizes
// FIXME: 0x1C00 to vram could probably be written directly filtering 0x0A newlines
text_writer text_entry
(
	.clk            (clk_sys),
	.reset          (reset),
	.ascii_byte     (ioctl_dout),
	.strobe         (ioctl_wr),
	.input_wait     (ioctl_wait),
	.ps2_key        (text_key)
);

cv_keyboard keyboard_from_hell
(
	.clk            (clk_sys),
	.reset          (reset),
	.ps2_key        (text_download ? text_key[8:0] : ps2_key[8:0]),
	.ps2_keydown    (text_download ? text_key[9]   : ps2_key[9]),
	.ps2_strobe     (text_download ? text_key[10]  : ps2_key[10]),
	.joy1           (joystick_0),
	.joy2           (joystick_1),
	.select_a       (pa_out),
	.select_b       (pb_out),
	.code_b         (pb_in),
	.code_a         (pa_in)
);


endmodule
