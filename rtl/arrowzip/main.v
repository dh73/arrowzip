`timescale	1ps / 1ps
////////////////////////////////////////////////////////////////////////////////
//
// Filename:	./main.v
//
// Project:	ArrowZip, a demonstration of the Arrow MAX1000 FPGA board
//
// DO NOT EDIT THIS FILE!
// Computer Generated: This file is computer generated by AUTOFPGA. DO NOT EDIT.
// DO NOT EDIT THIS FILE!
//
// CmdLine:	../../../autofpga/trunk/sw/autofpga ../../../autofpga/trunk/sw/autofpga -d -o . global.txt bkram.txt buserr.txt clock.txt zipscope.txt rtclight.txt pic.txt pwrcount.txt spio.txt version.txt hbconsole.txt zipbones.txt dlyarbiter.txt
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2018, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
`default_nettype	none
//
//
// Here is a list of defines which may be used, post auto-design
// (not post-build), to turn particular peripherals (and bus masters)
// on and off.  In particular, to turn off support for a particular
// design component, just comment out its respective `define below.
//
// These lines are taken from the respective @ACCESS tags for each of our
// components.  If a component doesn't have an @ACCESS tag, it will not
// be listed here.
//
// First, the independent access fields for any bus masters
`define	WBUBUS_MASTER
`define	INCLUDE_ZIPCPU
// And then for the independent peripherals
`define	WATCHDOG_ACCESS
`define	BUSTIMER_ACCESS
`define	BUSCONSOLE_ACCESS
`define	BUSPIC_ACCESS
`define	RTC_ACCESS
`define	BKRAM_ACCESS
`define	SPIO_ACCESS
//
// End of dependency list
//
//
//
//
// Finally, we define our main module itself.  We start with the list of
// I/O ports, or wires, passed into (or out of) the main function.
//
// These fields are copied verbatim from the respective I/O port lists,
// from the fields given by @MAIN.PORTLIST
//
module	main(i_clk, i_reset,
		// UART/host to wishbone interface
		i_uart_rx, o_uart_tx, o_hb_err,
		// SPIO interface
		i_btn, o_led);
//
// Any parameter definitions
//
// These are drawn from anything with a MAIN.PARAM definition.
// As they aren't connected to the toplevel at all, it would
// be best to use localparam over parameter, but here we don't
// check
	//
	//
	// UART interface
	//
	//
	// Baudrate : 1000000
	// Clock    : 80000000
	localparam [23:0] BUSUART = 24'h50;	// 1000000 baud
	//
	//
	// Variables/definitions needed by the ZipCPU BUS master
	//
	//
	// A 32-bit address indicating where teh ZipCPU should start running
	// from
	localparam	RESET_ADDRESS = 32'h00008000;
	//
	// The number of valid bits on the bus
	localparam	ZIP_ADDRESS_WIDTH = 14;	// Zip-CPU address width
	//
	// ZIP_START_HALTED
	//
	// A boolean, indicating whether or not the ZipCPU be halted on startup?
	localparam	ZIP_START_HALTED=1'b1;
//
// The next step is to declare all of the various ports that were just
// listed above.  
//
// The following declarations are taken from the values of the various
// @MAIN.IODECL keys.
//
	input	wire		i_clk;
// verilator lint_off UNUSED
	input	wire		i_reset;
	// verilator lint_on UNUSED
	input	wire		i_uart_rx;
	output	wire		o_uart_tx;
	output	wire		o_hb_err;
	// SPIO interface
	input	wire		i_btn;
	output	wire	[7:0]	o_led;
	// Make Verilator happy ... defining bus wires for lots of components
	// often ends up with unused wires lying around.  We'll turn off
	// Verilator's lint warning here that checks for unused wires.
	// verilator lint_off UNUSED



	//
	// Declaring interrupt lines
	//
	// These declarations come from the various components values
	// given under the @INT.<interrupt name>.WIRE key.
	//
	wire	bustimer_int;	// bustimer.INT.TMC.WIRE
	wire	uarttxf_int;	// console.INT.UARTTXF.WIRE
	wire	uartrxf_int;	// console.INT.UARTRXF.WIRE
	wire	uarttx_int;	// console.INT.UARTTX.WIRE
	wire	uartrx_int;	// console.INT.UARTRX.WIRE
	wire	rtc_int;	// rtc.INT.RTC.WIRE
	wire	zipscope_int;	// zipscope.INT.ZIPSCOPE.WIRE
	wire	spio_int;	// spio.INT.SPIO.WIRE


	//
	// Component declarations
	//
	// These declarations come from the @MAIN.DEFNS keys found in the
	// various components comprising the design.
	//
// Looking for string: MAIN.DEFNS
	// UART interface
	wire	[7:0]	hb_rx_data, hb_tx_data;
	wire		hb_rx_stb;
	wire		hb_tx_stb, hb_tx_busy;

	wire	w_ck_uart, w_uart_tx;
	// Definitions for the WB-UART converter.  We really only need one
	// (more) non-bus wire--one to use to select if we are interacting
	// with the ZipCPU or not.
	wire	[0:0]	wbubus_dbg;
`ifndef	INCLUDE_ZIPCPU
	//
	// The bus-console depends upon the zip_dbg wires.  If there is no
	// ZipCPU defining them, we'll need to define them here anyway.
	//
	wire		zip_dbg_ack, zip_dbg_stall;
	wire	[31:0]	zip_dbg_data;
`endif
	// Console definitions
	wire	w_console_rx_stb, w_console_tx_stb, w_console_busy;
	wire	[6:0]	w_console_rx_data, w_console_tx_data;
`include "builddate.v"
	// ZipSystem/ZipCPU connection definitions
	// All we define here is a set of scope wires
	wire	[31:0]	zip_debug;
	wire		zip_trigger;
	wire		zip_halted;
	// A reset wire for the ZipCPU
	wire		cpu_reset;
	reg	[14-1:0]	r_buserr_addr;
	// Bus arbiter's internal lines
	wire		hb_dwbi_cyc, hb_dwbi_stb, hb_dwbi_we,
			hb_dwbi_ack, hb_dwbi_stall, hb_dwbi_err;
	wire	[(14-1):0]	hb_dwbi_addr;
	wire	[31:0]	hb_dwbi_odata, hb_dwbi_idata;
	wire	[3:0]	hb_dwbi_sel;
	wire	bus_interrupt;
	reg	[31:0]	r_pwrcount_data;
	// Definitions in support of the GPS driven RTC
	wire	rtc_ppd;
	reg	r_rtc_ack;


	//
	// Declaring interrupt vector wires
	//
	// These declarations come from the various components having
	// PIC and PIC.MAX keys.
	//
	wire	[14:0]	bus_int_vector;
	//
	//
	// Define bus wires
	//
	//

	// Bus wb
	// Wishbone master wire definitions for bus: wb
	wire		wb_cyc, wb_stb, wb_we, wb_stall, wb_err,
			wb_none_sel;
	reg		wb_many_ack;
	wire	[13:0]	wb_addr;
	wire	[31:0]	wb_data;
	reg	[31:0]	wb_idata;
	wire	[3:0]	wb_sel;
	reg		wb_ack;

	// Wishbone slave definitions for bus wb(SIO), slave buserr
	wire		buserr_sel, buserr_ack, buserr_stall;
	wire	[31:0]	buserr_data;

	// Wishbone slave definitions for bus wb(SIO), slave buspic
	wire		buspic_sel, buspic_ack, buspic_stall;
	wire	[31:0]	buspic_data;

	// Wishbone slave definitions for bus wb(SIO), slave pwrcount
	wire		pwrcount_sel, pwrcount_ack, pwrcount_stall;
	wire	[31:0]	pwrcount_data;

	// Wishbone slave definitions for bus wb(SIO), slave spio
	wire		spio_sel, spio_ack, spio_stall;
	wire	[31:0]	spio_data;

	// Wishbone slave definitions for bus wb(SIO), slave version
	wire		version_sel, version_ack, version_stall;
	wire	[31:0]	version_data;

	// Wishbone slave definitions for bus wb(DIO), slave bustimer
	wire		bustimer_sel, bustimer_ack, bustimer_stall;
	wire	[31:0]	bustimer_data;

	// Wishbone slave definitions for bus wb(DIO), slave watchdog
	wire		watchdog_sel, watchdog_ack, watchdog_stall;
	wire	[31:0]	watchdog_data;

	// Wishbone slave definitions for bus wb(DIO), slave rtc
	wire		rtc_sel, rtc_ack, rtc_stall;
	wire	[31:0]	rtc_data;

	// Wishbone slave definitions for bus wb, slave zipscope
	wire		zipscope_sel, zipscope_ack, zipscope_stall;
	wire	[31:0]	zipscope_data;

	// Wishbone slave definitions for bus wb, slave console
	wire		console_sel, console_ack, console_stall;
	wire	[31:0]	console_data;

	// Wishbone slave definitions for bus wb, slave wb_sio
	wire		wb_sio_sel, wb_sio_ack, wb_sio_stall;
	wire	[31:0]	wb_sio_data;

	// Wishbone slave definitions for bus wb, slave wb_dio
	wire		wb_dio_sel, wb_dio_ack, wb_dio_stall;
	wire	[31:0]	wb_dio_data;

	// Wishbone slave definitions for bus wb, slave bkram
	wire		bkram_sel, bkram_ack, bkram_stall;
	wire	[31:0]	bkram_data;

	// Bus zip
	// Wishbone master wire definitions for bus: zip
	wire		zip_cyc, zip_stb, zip_we, zip_stall, zip_err,
			zip_none_sel;
	reg		zip_many_ack;
	wire	[13:0]	zip_addr;
	wire	[31:0]	zip_data;
	reg	[31:0]	zip_idata;
	wire	[3:0]	zip_sel;
	reg		zip_ack;

	// Wishbone slave definitions for bus zip, slave zip_dwb
	wire		zip_dwb_sel, zip_dwb_ack, zip_dwb_stall, zip_dwb_err;
	wire	[31:0]	zip_dwb_data;

	// Bus hb
	// Wishbone master wire definitions for bus: hb
	wire		hb_cyc, hb_stb, hb_we, hb_stall, hb_err,
			hb_none_sel;
	reg		hb_many_ack;
	wire	[14:0]	hb_addr;
	wire	[31:0]	hb_data;
	reg	[31:0]	hb_idata;
	wire	[3:0]	hb_sel;
	reg		hb_ack;

	// Wishbone slave definitions for bus hb, slave hb_dwb
	wire		hb_dwb_sel, hb_dwb_ack, hb_dwb_stall, hb_dwb_err;
	wire	[31:0]	hb_dwb_data;

	// Wishbone slave definitions for bus hb, slave zip_dbg
	wire		zip_dbg_sel, zip_dbg_ack, zip_dbg_stall;
	wire	[31:0]	zip_dbg_data;


	//
	// Peripheral address decoding
	//
	//
	//
	//
	// Select lines for bus: wb
	//
	// Address width: 14
	// Data width:    32
	//
	//
	
	assign	      buserr_sel = ((wb_sio_sel)&&(wb_addr[ 2: 0] ==  3'h0));
 // 0x0000
	assign	      buspic_sel = ((wb_sio_sel)&&(wb_addr[ 2: 0] ==  3'h1));
 // 0x0004
	assign	    pwrcount_sel = ((wb_sio_sel)&&(wb_addr[ 2: 0] ==  3'h2));
 // 0x0008
	assign	        spio_sel = ((wb_sio_sel)&&(wb_addr[ 2: 0] ==  3'h3));
 // 0x000c
	assign	     version_sel = ((wb_sio_sel)&&(wb_addr[ 2: 0] ==  3'h4));
 // 0x0010
	assign	    bustimer_sel = ((wb_dio_sel)&&((wb_addr[ 4: 3] &  2'h3) ==  2'h0));
 // 0x0000
	assign	    watchdog_sel = ((wb_dio_sel)&&((wb_addr[ 4: 3] &  2'h3) ==  2'h1));
 // 0x0020
	assign	         rtc_sel = ((wb_dio_sel)&&((wb_addr[ 4: 3] &  2'h3) ==  2'h2));
 // 0x0040 - 0x005f
	assign	    zipscope_sel = ((wb_addr[13:10] &  4'hf) ==  4'h1); // 0x1000 - 0x1007
	assign	     console_sel = ((wb_addr[13:10] &  4'hf) ==  4'h2); // 0x2000 - 0x200f
	assign	      wb_sio_sel = ((wb_addr[13:10] &  4'hf) ==  4'h3); // 0x3000 - 0x301f
//x2	Was a master bus as well
	assign	      wb_dio_sel = ((wb_addr[13:10] &  4'hf) ==  4'h4); // 0x4000 - 0x407f
//x2	Was a master bus as well
	assign	       bkram_sel = ((wb_addr[13:10] &  4'h8) ==  4'h8); // 0x8000 - 0xffff
	//

	//
	//
	//
	// Select lines for bus: zip
	//
	// Address width: 14
	// Data width:    32
	//
	//
	
	assign	     zip_dwb_sel = (zip_cyc); // Only one peripheral on this bus
	//

	//
	//
	//
	// Select lines for bus: hb
	//
	// Address width: 15
	// Data width:    32
	//
	//
	
	assign	      hb_dwb_sel = ((hb_addr[14:14] &  1'h1) ==  1'h0); // 0x0000 - 0xffff
//x2	Was a master bus as well
	assign	     zip_dbg_sel = ((hb_addr[14:14] &  1'h1) ==  1'h1); // 0x10000 - 0x10007
	//

	//
	// BUS-LOGIC for wb
	//
	assign	wb_none_sel = (wb_stb)&&({
				zipscope_sel,
				console_sel,
				wb_sio_sel,
				wb_dio_sel,
				bkram_sel} == 0);

	//
	// many_ack
	//
	// It is also a violation of the bus protocol to produce multiple
	// acks at once and on the same clock.  In that case, the bus
	// can't decide which result to return.  Worse, if someone is waiting
	// for a return value, that value will never come since another ack
	// masked it.
	//
	// The other error that isn't tested for here, no would I necessarily
	// know how to test for it, is when peripherals return values out of
	// order.  Instead, I propose keeping that from happening by
	// guaranteeing, in software, that two peripherals are not accessed
	// immediately one after the other.
	//
	always @(posedge i_clk)
		case({		zipscope_ack,
				console_ack,
				wb_sio_ack,
				wb_dio_ack,
				bkram_ack})
			5'b00000: wb_many_ack <= 1'b0;
			5'b10000: wb_many_ack <= 1'b0;
			5'b01000: wb_many_ack <= 1'b0;
			5'b00100: wb_many_ack <= 1'b0;
			5'b00010: wb_many_ack <= 1'b0;
			5'b00001: wb_many_ack <= 1'b0;
			default: wb_many_ack <= (wb_cyc);
		endcase

	assign	wb_sio_stall = 1'b0;
	initial r_wb_sio_ack = 1'b0;
	always	@(posedge i_clk)
		r_wb_sio_ack <= (wb_stb)&&(wb_sio_sel);
	assign	wb_sio_ack = r_wb_sio_ack;
	reg	r_wb_sio_ack;
	reg	[31:0]	r_wb_sio_data;
	always	@(posedge i_clk)
		// mask        = 00000007
		// lgdw        = 2
		// unused_lsbs = 0
		casez( wb_addr[2:0] )
			3'h0: r_wb_sio_data <= buserr_data;
			3'h1: r_wb_sio_data <= buspic_data;
			3'h2: r_wb_sio_data <= pwrcount_data;
			3'h3: r_wb_sio_data <= spio_data;
			default: r_wb_sio_data <= version_data;
		endcase
	assign	wb_sio_data = r_wb_sio_data;

	assign	wb_dio_stall = 1'b0;
	reg	[1:0]	r_wb_dio_ack;
	always	@(posedge i_clk)
		r_wb_dio_ack <= { r_wb_dio_ack[0], (wb_stb)&&(wb_dio_sel) };
	assign	wb_dio_ack = r_wb_dio_ack[1];
	reg	[31:0]	r_wb_dio_data;
	always	@(posedge i_clk)
		casez({		bustimer_ack,
				watchdog_ack	}) // rtc default
			2'b1?: r_wb_dio_data <= bustimer_data;
			2'b01: r_wb_dio_data <= watchdog_data;
			default: r_wb_dio_data <= rtc_data;

		endcase
	assign	wb_dio_data = r_wb_dio_data;

	//
	// Finally, determine what the response is from the wb bus
	// bus
	//
	//
	//
	// wb_ack
	//
	// The returning wishbone ack is equal to the OR of every component that
	// might possibly produce an acknowledgement, gated by the CYC line.
	//
	// To return an ack here, a component must have a @SLAVE.TYPE tag.
	// Acks from any @SLAVE.TYPE of SINGLE and DOUBLE components have been
	// collected together (above) into wb_sio_ack and wb_dio_ack
	// respectively, which will appear ahead of any other device acks.
	//
	always @(posedge i_clk)
		wb_ack <= (wb_cyc)&&(|{ zipscope_ack,
				console_ack,
				wb_sio_ack,
				wb_dio_ack,
				bkram_ack });
	//
	// wb_idata
	//
	// This is the data returned on the bus.  Here, we select between a
	// series of bus sources to select what data to return.  The basic
	// logic is simply this: the data we return is the data for which the
	// ACK line is high.
	//
	// The last item on the list is chosen by default if no other ACK's are
	// true.  Although we might choose to return zeros in that case, by
	// returning something we can skimp a touch on the logic.
	//
	// Any peripheral component with a @SLAVE.TYPE value will be listed
	// here.
	//
	always @(posedge i_clk)
	begin
		casez({		zipscope_ack,
				console_ack,
				wb_sio_ack,
				wb_dio_ack	})
			4'b1???: wb_idata <= zipscope_data;
			4'b01??: wb_idata <= console_data;
			4'b001?: wb_idata <= wb_sio_data;
			4'b0001: wb_idata <= wb_dio_data;
			default: wb_idata <= bkram_data;
		endcase
	end
	assign	wb_stall =	((zipscope_sel)&&(zipscope_stall))
				||((console_sel)&&(console_stall))
				||((wb_sio_sel)&&(wb_sio_stall))
				||((wb_dio_sel)&&(wb_dio_stall))
				||((bkram_sel)&&(bkram_stall));

	assign wb_err = ((wb_stb)&&(wb_none_sel))||(wb_many_ack);
	//
	// BUS-LOGIC for zip
	//
	assign	zip_none_sel = 1'b0;
	always @(*)
		zip_many_ack = 1'b0;
	assign	zip_err = zip_dwb_err;
	assign	zip_stall = zip_dwb_stall;
	always @(*)
		zip_ack = zip_dwb_ack;
	always @(*)
		zip_idata = zip_dwb_data;
	//
	// BUS-LOGIC for hb
	//
	assign	hb_none_sel = (hb_stb)&&({
				hb_dwb_sel,
				zip_dbg_sel} == 0);

	//
	// many_ack
	//
	// It is also a violation of the bus protocol to produce multiple
	// acks at once and on the same clock.  In that case, the bus
	// can't decide which result to return.  Worse, if someone is waiting
	// for a return value, that value will never come since another ack
	// masked it.
	//
	// The other error that isn't tested for here, no would I necessarily
	// know how to test for it, is when peripherals return values out of
	// order.  Instead, I propose keeping that from happening by
	// guaranteeing, in software, that two peripherals are not accessed
	// immediately one after the other.
	//
	always @(posedge i_clk)
		case({		hb_dwb_ack,
				zip_dbg_ack})
			2'b00: hb_many_ack <= 1'b0;
			2'b10: hb_many_ack <= 1'b0;
			2'b01: hb_many_ack <= 1'b0;
			default: hb_many_ack <= (hb_cyc);
		endcase

	//
	// Finally, determine what the response is from the hb bus
	// bus
	//
	//
	//
	// hb_ack
	//
	// The returning wishbone ack is equal to the OR of every component that
	// might possibly produce an acknowledgement, gated by the CYC line.
	//
	// To return an ack here, a component must have a @SLAVE.TYPE tag.
	// Acks from any @SLAVE.TYPE of SINGLE and DOUBLE components have been
	// collected together (above) into hb_sio_ack and hb_dio_ack
	// respectively, which will appear ahead of any other device acks.
	//
	always @(posedge i_clk)
		hb_ack <= (hb_cyc)&&(|{ hb_dwb_ack,
				zip_dbg_ack });
	//
	// hb_idata
	//
	// This is the data returned on the bus.  Here, we select between a
	// series of bus sources to select what data to return.  The basic
	// logic is simply this: the data we return is the data for which the
	// ACK line is high.
	//
	// The last item on the list is chosen by default if no other ACK's are
	// true.  Although we might choose to return zeros in that case, by
	// returning something we can skimp a touch on the logic.
	//
	// Any peripheral component with a @SLAVE.TYPE value will be listed
	// here.
	//
	always @(posedge i_clk)
		if (hb_dwb_ack)
			hb_idata <= hb_dwb_data;
		else
			hb_idata <= zip_dbg_data;
	assign	hb_stall =	((hb_dwb_sel)&&(hb_dwb_stall))
				||((zip_dbg_sel)&&(zip_dbg_stall));

	assign hb_err = ((hb_stb)&&(hb_none_sel))||(hb_many_ack)||((hb_dwb_err));
	//
	// Declare the interrupt busses
	//
	// Interrupt busses are defined by anything with a @PIC tag.
	// The @PIC.BUS tag defines the name of the wire bus below,
	// while the @PIC.MAX tag determines the size of the bus width.
	//
	// For your peripheral to be assigned to this bus, it must have an
	// @INT.NAME.WIRE= tag to define the wire name of the interrupt line,
	// and an @INT.NAME.PIC= tag matching the @PIC.BUS tag of the bus
	// your interrupt will be assigned to.  If an @INT.NAME.ID tag also
	// exists, then your interrupt will be assigned to the position given
	// by the ID# in that tag.
	//
	assign	bus_int_vector = {
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		1'b0,
		spio_int,
		zipscope_int,
		rtc_int,
		uartrx_int,
		uarttx_int,
		uartrxf_int,
		uarttxf_int,
		bustimer_int
	};


	//
	//
	// Now we turn to defining all of the parts and pieces of what
	// each of the various peripherals does, and what logic it needs.
	//
	// This information comes from the @MAIN.INSERT and @MAIN.ALT tags.
	// If an @ACCESS tag is available, an ifdef is created to handle
	// having the access and not.  If the @ACCESS tag is `defined above
	// then the @MAIN.INSERT code is executed.  If not, the @MAIN.ALT
	// code is exeucted, together with any other cleanup settings that
	// might need to take place--such as returning zeros to the bus,
	// or making sure all of the various interrupt wires are set to
	// zero if the component is not included.
	//
`ifdef	WATCHDOG_ACCESS
	ziptimer
		watchdogi(i_clk, i_reset, 1'b1,
			wb_cyc, (wb_stb)&&(watchdog_sel), wb_we, wb_data,
				watchdog_ack, watchdog_stall,
				watchdog_data, cpu_reset);
`else	// WATCHDOG_ACCESS

	// In the case that there is no watchdog peripheral responding on the wb bus
	reg	r_watchdog_ack;
	initial	r_watchdog_ack = 1'b0;
	always @(posedge i_clk)	r_watchdog_ack <= (wb_stb)&&(watchdog_sel);
	assign	watchdog_ack   = r_watchdog_ack;
	assign	watchdog_stall = 0;
	assign	watchdog_data  = 0;

`endif	// WATCHDOG_ACCESS

`ifdef	BUSTIMER_ACCESS
	ziptimer
		bustimeri(i_clk, i_reset, 1'b1,
			wb_cyc, (wb_stb)&&(bustimer_sel), wb_we, wb_data,
				bustimer_ack, bustimer_stall,
				bustimer_data, bustimer_int);
`else	// BUSTIMER_ACCESS

	// In the case that there is no bustimer peripheral responding on the wb bus
	reg	r_bustimer_ack;
	initial	r_bustimer_ack = 1'b0;
	always @(posedge i_clk)	r_bustimer_ack <= (wb_stb)&&(bustimer_sel);
	assign	bustimer_ack   = r_bustimer_ack;
	assign	bustimer_stall = 0;
	assign	bustimer_data  = 0;

	assign	bustimer_int = 1'b0;	// bustimer.INT.TMC.WIRE
`endif	// BUSTIMER_ACCESS

`ifdef	WBUBUS_MASTER
	// The Host USB interface, to be used by the WB-UART bus
	rxuartlite	#(BUSUART) rcv(i_clk, i_uart_rx,
				hb_rx_stb, hb_rx_data);
	txuartlite	#(BUSUART) txv(i_clk,
				hb_tx_stb,
				hb_tx_data,
				o_uart_tx,
				hb_tx_busy);

`ifdef	INCLUDE_ZIPCPU
`else
	assign	zip_dbg_ack   = 1'b0;
	assign	zip_dbg_stall = 1'b0;
	assign	zip_dbg_data  = 0;
`endif
`ifndef	BUSPIC_ACCESS
	wire	bus_interrupt;
	assign	bus_interrupt = 1'b0;
`endif
	wire	[29:0]	hb_tmp_addr;
	hbconsole genbus(i_clk, hb_rx_stb, hb_rx_data,
			hb_cyc, hb_stb, hb_we, hb_tmp_addr, hb_data, hb_sel,
			hb_ack, hb_stall, hb_err, hb_idata,
			bus_interrupt,
			hb_tx_stb, hb_tx_data, hb_tx_busy,
			//
			w_console_tx_stb, w_console_tx_data, w_console_busy,
			w_console_rx_stb, w_console_rx_data,
			o_hb_err);
	assign	hb_addr= hb_tmp_addr[(15-1):0];
`else	// WBUBUS_MASTER

	// In the case that nothing drives the hb bus ...
	assign	hb_cyc = 1'b0;
	assign	hb_stb = 1'b0;
	assign	hb_we  = 1'b0;
	assign	hb_sel = 0;
	assign	hb_addr= 0;
	assign	hb_data= 0;
	// verilator lint_off UNUSED
	wire	[35:0]	unused_bus_hb;
	assign	unused_bus_hb = { hb_ack, hb_stall, hb_err, hb_data };
	// verilator lint_on  UNUSED

`endif	// WBUBUS_MASTER

`ifdef	BUSCONSOLE_ACCESS
	console consolei(i_clk, 1'b0,
 			wb_cyc, (wb_stb)&&(console_sel), wb_we,
				wb_addr[1:0], wb_data,
 			console_ack, console_stall, console_data,
			w_console_tx_stb, w_console_tx_data, w_console_busy,
			w_console_rx_stb, w_console_rx_data,
			uartrx_int, uarttx_int, uartrxf_int, uarttxf_int);
`else	// BUSCONSOLE_ACCESS
	assign	w_console_tx_stb  = 1'b0;
	assign	w_console_tx_data = 7'h7f;

	// In the case that there is no console peripheral responding on the wb bus
	reg	r_console_ack;
	initial	r_console_ack = 1'b0;
	always @(posedge i_clk)	r_console_ack <= (wb_stb)&&(console_sel);
	assign	console_ack   = r_console_ack;
	assign	console_stall = 0;
	assign	console_data  = 0;

	assign	uarttxf_int = 1'b0;	// console.INT.UARTTXF.WIRE
	assign	uartrxf_int = 1'b0;	// console.INT.UARTRXF.WIRE
	assign	uarttx_int = 1'b0;	// console.INT.UARTTX.WIRE
	assign	uartrx_int = 1'b0;	// console.INT.UARTRX.WIRE
`endif	// BUSCONSOLE_ACCESS

	assign	version_data = `DATESTAMP;
	assign	version_ack = 1'b0;
	assign	version_stall = 1'b0;
`ifdef	INCLUDE_ZIPCPU
	//
	//
	// The ZipCPU/ZipSystem BUS master
	//
	//
	zipbones #(RESET_ADDRESS,ZIP_ADDRESS_WIDTH,10,ZIP_START_HALTED)
		swic(i_clk, cpu_reset,
			// Zippys wishbone interface
			zip_cyc, zip_stb, zip_we, zip_addr, zip_data, zip_sel,
					zip_ack, zip_stall, zip_idata, zip_err,
			bus_interrupt, zip_halted,
			// Debug wishbone interface
			(hb_cyc), ((hb_stb)&&(zip_dbg_sel)),hb_we,
			hb_addr[0],
			hb_data, zip_dbg_ack, zip_dbg_stall, zip_dbg_data,
			zip_debug);
	assign	zip_trigger = zip_debug[0];
`else	// INCLUDE_ZIPCPU

	// In the case that nothing drives the zip bus ...
	assign	zip_cyc = 1'b0;
	assign	zip_stb = 1'b0;
	assign	zip_we  = 1'b0;
	assign	zip_sel = 0;
	assign	zip_addr= 0;
	assign	zip_data= 0;
	// verilator lint_off UNUSED
	wire	[35:0]	unused_bus_zip;
	assign	unused_bus_zip = { zip_ack, zip_stall, zip_err, zip_data };
	// verilator lint_on  UNUSED

`endif	// INCLUDE_ZIPCPU

	always @(posedge i_clk)
		if (wb_err)
			r_buserr_addr <= wb_addr;
	assign	buserr_data = { {(32-2-14){1'b0}},
			r_buserr_addr, 2'b00 };
`ifdef	INCLUDE_ZIPCPU
	//
	//
	// And an arbiter to decide who gets access to the bus
	//
	//
	// Clock speed = 80000000 Hz
	wbpriarbiter #(32,14)	bus_arbiter(i_clk,
		// The Zip CPU bus master --- gets the priority slot
		zip_cyc, zip_stb, zip_we, zip_addr, zip_data, zip_sel,
			zip_dwb_ack, zip_dwb_stall, zip_dwb_err,
		// The UART interface master
		(hb_cyc)&&(hb_dwb_sel),
			(hb_stb)&&(hb_dwb_sel),
			hb_we,
			hb_addr[(14-1):0],
			hb_data, hb_sel,
			hb_dwb_ack, hb_dwb_stall, hb_dwb_err,
		// Common bus returns
		hb_dwbi_cyc, hb_dwbi_stb, hb_dwbi_we, hb_dwbi_addr, hb_dwbi_odata, hb_dwbi_sel,
			hb_dwbi_ack, hb_dwbi_stall, hb_dwbi_err);

	// And because the ZipCPU and the Arbiter can create an unacceptable
	// delay, we often fail timing.  So, we add in a delay cycle
`else
	// If no ZipCPU, no delay arbiter is needed
	assign	hb_dwbi_cyc   = hb_cyc;
	assign	hb_dwbi_stb   = hb_stb;
	assign	hb_dwbi_we    = hb_we;
	assign	hb_dwbi_addr  = hb_addr[(14-1):0];
	assign	hb_dwbi_odata = hb_data;
	assign	hb_dwbi_sel   = hb_sel;
	assign	hb_dwb_ack    = hb_dwbi_ack;
	assign	hb_dwb_stall  = hb_dwbi_stall;
	assign	hb_dwb_err    = hb_dwbi_err;
	assign	hb_dwb_data   = hb_dwbi_idata;
`endif	// INCLUDE_ZIPCPU

`ifdef	WBUBUS_MASTER
`ifdef	INCLUDE_ZIPCPU
`define	BUS_DELAY_NEEDED
`endif
`endif
`ifdef	BUS_DELAY_NEEDED
	busdelay #(14)	hb_dwbi_delay(i_clk, i_reset,
		hb_dwbi_cyc, hb_dwbi_stb, hb_dwbi_we, hb_dwbi_addr, hb_dwbi_odata, hb_dwbi_sel,
			hb_dwbi_ack, hb_dwbi_stall, hb_dwbi_idata, hb_dwbi_err,
		wb_cyc, wb_stb, wb_we, wb_addr, wb_data, wb_sel,
			wb_ack, wb_stall, wb_idata, wb_err);
`else
	// If one of the two, the ZipCPU or the WBUBUS, isn't here, then we
	// don't need the bus delay, and we can go directly from the bus driver
	// to the bus itself
	//
	assign	wb_cyc    = hb_dwbi_cyc;
	assign	wb_stb    = hb_dwbi_stb;
	assign	wb_we     = hb_dwbi_we;
	assign	wb_addr   = hb_dwbi_addr;
	assign	wb_data   = hb_dwbi_odata;
	assign	wb_sel    = hb_dwbi_sel;
	assign	hb_dwbi_ack   = wb_ack;
	assign	hb_dwbi_stall = wb_stall;
	assign	hb_dwbi_err   = wb_err;
	assign	hb_dwbi_idata = wb_idata;
`endif
	assign	hb_dwb_data = hb_dwbi_idata;
`ifdef	INCLUDE_ZIPCPU
	assign	zip_dwb_data = hb_dwbi_idata;
`endif
`ifdef	BUSPIC_ACCESS
	//
	// The BUS Interrupt controller
	//
	icontrol #(15)	buspici(i_clk, 1'b0, (wb_stb)&&(buspic_sel),
			wb_data, buspic_data, bus_int_vector, bus_interrupt);
`else	// BUSPIC_ACCESS

	// In the case that there is no buspic peripheral responding on the wb bus
	reg	r_buspic_ack;
	initial	r_buspic_ack = 1'b0;
	always @(posedge i_clk)	r_buspic_ack <= (wb_stb)&&(buspic_sel);
	assign	buspic_ack   = r_buspic_ack;
	assign	buspic_stall = 0;
	assign	buspic_data  = 0;

`endif	// BUSPIC_ACCESS

	initial	r_pwrcount_data = 32'h0;
	always @(posedge i_clk)
	if (r_pwrcount_data[31])
		r_pwrcount_data[30:0] <= r_pwrcount_data[30:0] + 1'b1;
	else
		r_pwrcount_data[31:0] <= r_pwrcount_data[31:0] + 1'b1;
	assign	pwrcount_data = r_pwrcount_data;
`ifdef	RTC_ACCESS
	rtclight	#(32'h0035afe5) thertc(i_clk,
		wb_cyc, (wb_stb)&&(rtc_sel), wb_we,
			wb_addr[2:0], wb_data,
		rtc_data, rtc_int, rtc_ppd);
	assign	rtc_stall = 1'b0;
	initial	r_rtc_ack = 1'b0;
	always @(posedge i_clk)
		r_rtc_ack <= (wb_stb)&&(rtc_sel);
	assign	rtc_ack = r_rtc_ack;
`else	// RTC_ACCESS

	// In the case that there is no rtc peripheral responding on the wb bus
	reg	r_rtc_ack;
	initial	r_rtc_ack = 1'b0;
	always @(posedge i_clk)	r_rtc_ack <= (wb_stb)&&(rtc_sel);
	assign	rtc_ack   = r_rtc_ack;
	assign	rtc_stall = 0;
	assign	rtc_data  = 0;

	assign	rtc_int = 1'b0;	// rtc.INT.RTC.WIRE
`endif	// RTC_ACCESS

`ifdef	BKRAM_ACCESS
	memdev #(.LGMEMSZ(15), .EXTRACLOCK(1))
		bkrami(i_clk,
			(wb_cyc), (wb_stb)&&(bkram_sel), wb_we,
				wb_addr[(15-3):0], wb_data, wb_sel,
				bkram_ack, bkram_stall, bkram_data);
`else	// BKRAM_ACCESS

	// In the case that there is no bkram peripheral responding on the wb bus
	reg	r_bkram_ack;
	initial	r_bkram_ack = 1'b0;
	always @(posedge i_clk)	r_bkram_ack <= (wb_stb)&&(bkram_sel);
	assign	bkram_ack   = r_bkram_ack;
	assign	bkram_stall = 0;
	assign	bkram_data  = 0;

`endif	// BKRAM_ACCESS

	wbscope #(.LGMEM(9), .SYNCHRONOUS(1)) zipscopei(
		i_clk, 1'b1, zip_trigger, zip_debug,
		i_clk, wb_cyc,
		  ((wb_stb)&&(zipscope_sel)), wb_we, wb_addr[0], wb_data,
		zipscope_ack, zipscope_stall, zipscope_data,
		zipscope_int);
`ifdef	SPIO_ACCESS
	spio #(.NBTN(1), .NLEDS(8)) thespio(i_clk,
		wb_cyc, (wb_stb)&&(spio_sel), wb_we, wb_data, wb_sel,
			spio_ack, spio_stall, spio_data,
		i_btn, o_led, spio_int);
`else	// SPIO_ACCESS
	assign	o_led = 8'h0;

	// In the case that there is no spio peripheral responding on the wb bus
	reg	r_spio_ack;
	initial	r_spio_ack = 1'b0;
	always @(posedge i_clk)	r_spio_ack <= (wb_stb)&&(spio_sel);
	assign	spio_ack   = r_spio_ack;
	assign	spio_stall = 0;
	assign	spio_data  = 0;

	assign	spio_int = 1'b0;	// spio.INT.SPIO.WIRE
`endif	// SPIO_ACCESS

	//
	//
	//


endmodule // main.v
