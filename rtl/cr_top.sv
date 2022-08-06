module creativision
(
	input clk,
	input reset,
	input [7:0] pb_in,
	input nmi,
	input pal,
	input [15:0] key_mask,
	input [7:0] rom_do,
	input [7:0] boot_do,
	input [15:0] rom_size,
	input border,
	output [7:0] pa_out,
	output [7:0] cart_dout,
	output [1:0] cart_write,
	output [15:0] rom_addr,
	output [15:0] audio,
	output [7:0] red,
	output [7:0] green,
	output [7:0] blue,
	output VSync,
	output HSync,
	output VBlank,
	output HBlank,
	output logic ce_pix
);

logic [15:0] cpu_addr_bus;
logic cpu_rwn;
logic irq_n;
logic phi1, phi2;
logic [7:0] cpu_dout, data_bus, open_bus, sys_ram_dout, vdp_dout, audio_dout, pia_dout;
logic sys_ram_cs_n, vdp_rcs_n, vdp_wcs_n, pia_cs_n, bootrom_cs_n, cart_cs_n, arb_1_cs_n;
logic rom_csn_0, rom_csn_1, rom_csn_2;
logic phi_toggle = 0;
logic [1:0] vid_div;
logic [4:0] phi_div;
logic ce_vid, ce_vid_tog;
logic [15:0] rom1_mask, rom2_mask, rom1_pre, rom2_pre;
integer phi_int;

wire [15:0] rom_size_plus_1 = rom_size + 1'd1;
logic [1:0] ram_en;
// clk_sys = 23.28 ns * 100 per tick
// 4mhz (cpu clk * 2 for each phase) = 250 ns * 100 per tick

// Clock enables
always_ff @(posedge clk) begin
	phi1 <= 0;
	phi2 <= 0;
	ce_pix <= 0;
	ram_en <= 2'b00;

	// FIXME: CPU divider should be exactly 4MHz (2MHz CPU clock)
	// but this keeps stuff synced and is only 2.4% too slow
	phi_div <= phi_div + 1'd1;
	// if (phi_div == 10) begin
	// 	phi_toggle <= ~phi_toggle;
	// 	phi_div <= 0;
	// 	phi1 <= ~phi_toggle;
	// 	phi2 <= phi_toggle;
	// end

	phi_int <= phi_int + 2328;
	if (phi_int >= 25000) begin
		phi_int <= (phi_int - 25000) + 2328;
		phi_toggle <= ~phi_toggle;
		phi1 <= ~phi_toggle;
		phi2 <= phi_toggle;
	end

	// Video dividers
	vid_div <= vid_div + 1'd1;
	ce_vid <= &vid_div;
	if (ce_vid) begin
		ce_vid_tog <= ~ce_vid_tog;
		ce_pix <= ce_vid_tog;
	end

	if (phi1)
		open_bus <= data_bus;

	// The cart mappers are too basic to even make a new file
	case (rom_size_plus_1)
		16'h1000: begin // 4k
			rom1_mask <= 14'h0FFF;
			rom2_mask <= 14'h3FFF;
			rom1_pre <= 15'h0000;
			rom2_pre <= 15'h4000;
			ram_en <= 2'b10;
		end

		16'h1800: begin // 6k
			rom1_mask <= cpu_addr_bus[12:0] < 16'h1000 ? 14'h07FF : 14'h0FFF;
			rom2_mask <= 14'h3FFF;
			rom1_pre <= cpu_addr_bus[12:0] < 16'h1000 ? 15'h1000 : 15'h0000;
			rom2_pre <= 15'h4000;
			ram_en <= 2'b10;
		end

		16'h2000: begin // 8k
			rom1_mask <= 14'h1FFF;
			rom2_mask <= 14'h3FFF;
			rom1_pre <= 15'h0000;
			rom2_pre <= 15'h4000;
			ram_en <= 2'b10;
		end

		16'h2800: begin // 10k
			rom1_mask <= 14'h1FFF;
			rom2_mask <= 14'h0FFF;
			rom1_pre <= 15'h0000;
			rom2_pre <= 15'h2000;
		end

		16'h3000: begin // 12k
			rom1_mask <= 14'h1FFF;
			rom2_mask <= 14'h0FFF;
			rom1_pre <= 15'h0000;
			rom2_pre <= 15'h2000;
		end

		16'h4000: begin // 16k
			rom1_mask <= 14'h0000;
			rom2_mask <= 14'h0000;
			rom1_pre <= cpu_addr_bus ^ 16'h2000;
			rom2_pre <= 15'h0000;
		end

		16'h4800: begin // 18k
			rom1_mask <= 14'h0000;
			rom2_mask <= 14'h07FF;
			rom1_pre <= cpu_addr_bus ^ 16'h2000;
			rom2_pre <= 15'h4000;
		end

		default: begin // ??? I guess just hope it's a power of two
			rom1_mask <= 14'h3FFF;
			rom2_mask <= 14'h3FFF;
			rom1_pre <= 14'h0000;
			rom2_pre <= 15'h4000;
			ram_en <= 2'b11;
		end
	endcase
end

// All of these are mirrored in their respective ranges
// 0000 - 03FF - 1kb RAM
// 1000 - 1003 - PIA including SN76489
// 2000 - 2001 - VDP TM9918A Read
// 3000 - 3001 - VDP TM9918A Write
// 4000 - 7FFF - Cart ROM 2
// 8000 - BFFF - Cart ROM 1
// C000 - FFFF - BIOS ROM (laser bios is 16k). Some writes here for centronics printer?

assign cart_dout = cpu_dout;
assign cart_write = {~cpu_rwn & ~rom_csn_2 & ram_en[1], ~cpu_rwn & ~rom_csn_1 & ram_en[0]};
assign bootrom_cs_n = rom_csn_0;
assign cart_cs_n = rom_csn_1 & rom_csn_2;
assign rom_addr = ~rom_csn_2 ? (rom2_pre | (cpu_addr_bus[13:0] & rom2_mask[13:0])) : ~rom_csn_1 ?
	(rom1_pre | (cpu_addr_bus[13:0] & rom1_mask[13:0])) :
	cpu_addr_bus[13:0];

// Bus Aribtation
assign data_bus =
	~cpu_rwn ? cpu_dout :
	~sys_ram_cs_n ? sys_ram_dout :
	~pia_cs_n ? pia_dout :
	~vdp_rcs_n ? vdp_dout :
	~bootrom_cs_n ? boot_do :
	~cart_cs_n ? rom_do :
	open_bus;

l74ls139 arb_0
(
	.e_n            (0),
	.a0             (cpu_addr_bus[14]),
	.a1             (cpu_addr_bus[15]),
	.o0             (arb_1_cs_n),
	.o1             (rom_csn_2),
	.o2             (rom_csn_1),
	.o3             (rom_csn_0)
);

l74ls139 arb_1
(
	.e_n            (arb_1_cs_n),
	.a0             (cpu_addr_bus[12]),
	.a1             (cpu_addr_bus[13]),
	.o0             (sys_ram_cs_n),
	.o1             (pia_cs_n),
	.o2             (vdp_rcs_n),
	.o3             (vdp_wcs_n)
);

// 6502A clocked at 2MHz.
T65 m6502
(
	.Mode           (2'b00),
	.BCD_en         (1'b1),
	.Res_n          (~reset),
	.Enable         (phi1),
	.Clk            (clk),
	.Rdy            (1),
	.Abort_n        (1),
	.IRQ_n          (irq_n),
	.NMI_n          (~nmi),
	.SO_n           (1),
	.R_W_n          (cpu_rwn),
	.A              (cpu_addr_bus),
	.DI             (data_bus),
	.DO             (cpu_dout)
);

// 1kb system ram
spram #(.addr_width(10), .mem_name("SYS")) sysram
(
	.clock          (clk),
	.address        (cpu_addr_bus[9:0]),
	.data           (cpu_dout),
	.enable         (1),
	.wren           (~cpu_rwn & ~sys_ram_cs_n),
	.q              (sys_ram_dout),
	.cs             (1)
);

// VDP
logic [13:0] vdp_addr_bus;
logic vdp_wren;
logic [7:0] vdp_ram_dout;
logic [7:0] vdp_ram_din;
logic HSync_n, VSync_n;

assign HSync = ~HSync_n;
assign VSync = ~VSync_n;

vdp18_core #(.compat_rgb_g(0)) vdp
(
	.clk_i          (clk),
	.clk_en_10m7_i  (ce_vid),
	.reset_n_i      (~reset),
	.is_pal_g       (pal),
	.csr_n_i        (vdp_rcs_n),
	.csw_n_i        (vdp_wcs_n),
	.mode_i         (cpu_addr_bus[0]),
	.int_n_o        (irq_n),
	.cd_i           (cpu_dout),
	.cd_o           (vdp_dout),
	.vram_we_o      (vdp_wren),
	.vram_a_o       (vdp_addr_bus),
	.vram_d_o       (vdp_ram_din),
	.vram_d_i       (vdp_ram_dout),
	.border_i       (border),
	.col_o          (),
	.rgb_r_o        (red),
	.rgb_g_o        (green),
	.rgb_b_o        (blue),
	.hsync_n_o      (HSync_n),
	.vsync_n_o      (VSync_n),
	.blank_n_o      (),
	.hblank_o       (HBlank),
	.vblank_o       (VBlank),
	.comp_sync_n_o  ()
);

// 16kb video ram
spram #(.addr_width(14), .mem_name("VID")) vidram
(
	.clock          (clk),
	.address        (vdp_addr_bus),
	.data           (vdp_ram_din),
	.enable         (1),
	.wren           (vdp_wren),
	.q              (vdp_ram_dout),
	.cs             (1)
);

logic audio_cs_n;
logic audio_rdy;
logic [7:0] pia_pb, pia_pa;
logic [7:0] pb_ddr;
wire [7:0] undriven_mask = ~pb_ddr & pb_in; // PB is pulled up if undriven.
wire [7:0] pb_mask = (pb_ddr & pia_pb) | undriven_mask;
logic cb2_oe;
logic pia_cb2;

assign pa_out = pia_pa;

pia6520 pia
(
	.data_out       (pia_dout),
	.data_in        (cpu_dout),
	.addr           (cpu_addr_bus[1:0]),
	.strobe         (~pia_cs_n),
	.we             (~cpu_rwn && ~pia_cs_n),
	.irq            (),
	.porta_out      (pia_pa),
	.porta_in       (pia_pa),
	.portb_out      (pia_pb),
	.portb_in       (pb_mask),
	.DDRB           (pb_ddr),
	.ca1_in         (1),
	.ca2_out        (),
	.ca2_in         (1),
	.cb1_in         (audio_rdy),
	.cb2_out        (pia_cb2),
	.cb2_in         (audio_cs_n),
	.cb2_oe         (cb2_oe),
	.clk            (clk),
	.clk_ena        (phi2),
	.reset          (reset)
);

assign audio_cs_n = cb2_oe ? pia_cb2 : 1'b1;

// always_comb begin
// 	portb_in = 8'b1111_1111;
// 	if (~pia_pa[0]) begin          // Joystick 1
// 		portb_in = {~joy1[5], 1'b1, ~joy1[1], 1'b1, ~joy1[3], ~joy1[0], ~joy1[2], 1'b1};
// 	end else if (~pia_pa[1]) begin // Keypad 1
// 		portb_in = {~joy1[4], ~joy1[6], 3'b111, ~joy1[6], 2'b11};
// 	end else if (~pia_pa[2]) begin // Joystick 2
// 		portb_in = {~joy2[5], 1'b1, ~joy2[1], 1'b1, ~joy2[2], ~joy2[0], ~joy2[3], 1'b1};
// 	end else if (~pia_pa[3]) begin // Keypad 2
// 		portb_in = {~joy2[4], ~joy2[6], 3'b111, ~joy2[6], 2'b11};
// 	end
// end

jt89 sn76489
(
	.rst                (reset),
	.clk                (clk),
	.clk_en             (phi2),
	.wr_n               (audio_rdy),
	.cs_n               (audio_cs_n),
	.din                (pb_mask),
	.ready              (audio_rdy),
	.sound              (audio[15:5])
);

assign audio[4:0] = 5'b00000;

endmodule

// Simple combinational logic
module l74ls139
(
	input e_n, // Enable
	input a0,
	input a1,
	output o0,
	output o1,
	output o2,
	output o3
);

	always_comb begin
		case ({a1, a0})
			2'b00: {o3, o2, o1, o0} = e_n ? 4'b1111 : ~{1'b0, 1'b0, 1'b0, 1'b1};
			2'b01: {o3, o2, o1, o0} = e_n ? 4'b1111 : ~{1'b0, 1'b0, 1'b1, 1'b0};
			2'b10: {o3, o2, o1, o0} = e_n ? 4'b1111 : ~{1'b0, 1'b1, 1'b0, 1'b0};
			2'b11: {o3, o2, o1, o0} = e_n ? 4'b1111 : ~{1'b1, 1'b0, 1'b0, 1'b0};
		endcase
	end

endmodule