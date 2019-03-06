////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	flashdrvr.cpp
//
// Project:	ArrowZip, a demonstration of the Arrow MAX1000 FPGA board
//
// Purpose:	Flash driver.  Encapsulates the erasing and programming (i.e.
//		writing) necessary to set the values in a flash device.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2015-2019, Gisselquist Technology, LLC
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
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <strings.h>
#include <ctype.h>
#include <string.h>
#include <signal.h>
#include <assert.h>

#include "port.h"
#include "design.h"
#include "regdefs.h"
#include "hexbus.h"
#include "flashdrvr.h"
#include "byteswap.h"

#ifndef	FLASH_UNKNOWN
#define	FLASH_UNKNOWN	0
#endif

#define	MICRON_FLASHID	0x20ba1810

#define	CFG_USERMODE	(1<<12)
#ifdef	QSPI_FLASH
#error	QSPI_FLASH is defined
#define	CFG_QSPEED	(1<<11)
#endif
#ifdef	DSPI_FLASH
#define	CFG_DSPEED (1<<10)
#endif
#define	CFG_WEDIR	(1<<9)
#define	CFG_USER_CS_n	(1<<8)

static const unsigned	F_RESET = (CFG_USERMODE|0x0ff),
			F_EMPTY = (CFG_USERMODE|0x000),
			F_WRR   = (CFG_USERMODE|0x001),
			F_PP    = (CFG_USERMODE|0x002),
			F_QPP   = (CFG_USERMODE|0x032),
			F_READ  = (CFG_USERMODE|0x003),
			F_WRDI  = (CFG_USERMODE|0x004),
			F_RDSR1 = (CFG_USERMODE|0x005),
			F_WREN  = (CFG_USERMODE|0x006),
			F_MFRID = (CFG_USERMODE|0x09f),
			F_SE    = (CFG_USERMODE|0x0d8),
			F_END   = (CFG_USERMODE|CFG_USER_CS_n);


const	bool	HIGH_SPEED = false;

#ifdef	R_FLASHSCOPE // Scope for the eqspi flash driver
# define SETSCOPE m_fpga->writeio(R_FLASHSCOPE, 8180)
#else
# define SETSCOPE
#endif

FLASHDRVR::FLASHDRVR(DEVBUS *fpga) : m_fpga(fpga),
		m_debug(false), m_id(FLASH_UNKNOWN) {
}

unsigned FLASHDRVR::flashid(void) {
#ifndef	FLASH_ACCESS
printf("No flash\n");
	return FLASH_UNKNOWN;
#else
	unsigned	r;
	if (m_id != FLASH_UNKNOWN)
		return m_id;

// printf("Getting ID\n");
	take_offline();

	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0x9f);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0x00);
	r = m_fpga->readio(R_FLASHCFG) & 0x0ff;
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0x00);
	r = (r<<8) | (m_fpga->readio(R_FLASHCFG) & 0x0ff);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0x00);
	r = (r<<8) | (m_fpga->readio(R_FLASHCFG) & 0x0ff);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0x00);
	r = (r<<8) | (m_fpga->readio(R_FLASHCFG) & 0x0ff);
	m_id = r;
	place_online();


// printf("flash ID returning %08x\n", m_id);
	return m_id;
#endif
}

void	FLASHDRVR::take_offline(void) {
#ifdef	R_FLASHCFG
// printf("Take offline\n");
	m_fpga->writeio(R_FLASHCFG, F_END);
	m_fpga->writeio(R_FLASHCFG, F_RESET);
	m_fpga->writeio(R_FLASHCFG, F_RESET);
	m_fpga->writeio(R_FLASHCFG, F_RESET);
	m_fpga->writeio(R_FLASHCFG, F_RESET);
	m_fpga->writeio(R_FLASHCFG, F_RESET);
	m_fpga->writeio(R_FLASHCFG, F_RESET);
	m_fpga->writeio(R_FLASHCFG, F_END);
#endif
}


void	FLASHDRVR::place_online(void) {
#ifdef	QSPI_FLASH
// printf("Place online\n");
	restore_quadio();
#elif	defined(DSPI_FLASH)
	restore_dualio();
// elif
//	No action required for normal SPI devices
#endif
}


void	FLASHDRVR::restore_dualio(void) {
#ifdef	DSPI_FLASH
	static const	uint32_t	DUAL_IO_READ     = CFG_USERMODE|0xbb;

	m_fpga->writeio(R_FLASHCFG, F_END);

	m_fpga->writeio(R_FLASHCFG, DUAL_IO_READ);
	// 3 address bytes
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_DSPEED | CFG_WEDIR);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_DSPEED | CFG_WEDIR);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_DSPEED | CFG_WEDIR);
	// Mode byte
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_DSPEED | CFG_WEDIR | 0xa0);
	// Read a dummy byte
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_DSPEED );
	// Read NDUMMY clocks worth
	for(int k=0; k<4; k++)
		m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_DSPEED );
	// Close the interface
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE);
	m_fpga->writeio(R_FLASHCFG, CFG_USER_CS_n);
#endif
}

void	FLASHDRVR::restore_quadio(void) {
#ifdef	QSPI_FLASH
	static	const	uint32_t	QUAD_IO_READ     = CFG_USERMODE|0xeb;

assert(0);

	m_fpga->writeio(R_FLASHCFG, F_END);
	if (MICRON_FLASHID == m_id) {
		// printf("MICRON-flash\n");
		// Need to enable XIP first for MICRON's flash
		//
		// This requires sending a write enable first
		m_fpga->writeio(R_FLASHCFG, F_WREN);
		m_fpga->writeio(R_FLASHCFG, F_END);

		// Then sending a 0xab, 0x81
		m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0x81);
		m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | 0xf3);
		m_fpga->writeio(R_FLASHCFG, F_END);
	}

	m_fpga->writeio(R_FLASHCFG, QUAD_IO_READ);
	// 3 address bytes
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_QSPEED | CFG_WEDIR);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_QSPEED | CFG_WEDIR);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_QSPEED | CFG_WEDIR);
	// Mode byte
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_QSPEED | CFG_WEDIR | 0xa0);
	// Read a dummy byte
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_QSPEED );
	// Read NDUMMY clocks worth
	for(int k=0; k<10; k++)
		m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | CFG_QSPEED );
	// Close the interface
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE);
	m_fpga->writeio(R_FLASHCFG, CFG_USER_CS_n);
#endif
}

void	FLASHDRVR::flwait(void) {
#ifdef	FLASH_ACCESS
	const	int	WIP = 1;	// Write in progress bit
	DEVBUS::BUSW	sr;

	m_fpga->writeio(R_FLASHCFG, F_END);
	m_fpga->writeio(R_FLASHCFG, F_RDSR1);
	do {
		m_fpga->writeio(R_FLASHCFG, F_EMPTY);
		sr = m_fpga->readio(R_FLASHCFG);
	} while(sr&WIP);
	m_fpga->writeio(R_FLASHCFG, F_END);
#endif
}

bool	FLASHDRVR::erase_sector(const unsigned sector, const bool verify_erase) {
#ifdef	FLASH_ACCESS
	unsigned	flashaddr = sector & 0x0ffffff;

	take_offline();

	// Write enable
	m_fpga->writeio(R_FLASHCFG, F_END);
	m_fpga->writeio(R_FLASHCFG, F_WREN);
	m_fpga->writeio(R_FLASHCFG, F_END);

	DEVBUS::BUSW	page[SZPAGEW];

	// printf("EREG before   : %08x\n", m_fpga->readio(R_QSPI_EREG));
	printf("Erasing sector: %06x\n", flashaddr);

	m_fpga->writeio(R_FLASHCFG, F_SE);
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | ((flashaddr>>16)&0x0ff));
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | ((flashaddr>> 8)&0x0ff));
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE | ((flashaddr    )&0x0ff));
	m_fpga->writeio(R_FLASHCFG, F_END);

	// Wait for the erase to complete
	flwait();

	// Turn quad-mode read back on, so we can read next
	place_online();

	// Now, let's verify that we erased the sector properly
	if (verify_erase) {
		if (m_debug)
			printf("Verifying the erase\n");
		for(int i=0; i<NPAGES; i++) {
			// printf("READI[%08x + %04x]\n", R_FLASH+flashaddr+i*SZPAGEB, SZPAGEW);
			m_fpga->readi(R_FLASH+flashaddr+i*SZPAGEB, SZPAGEW, page);
			for(int j=0; j<SZPAGEW; j++)
				if (page[j] != 0xffffffff) {
					unsigned rdaddr = R_FLASH+flashaddr+i*SZPAGEB;
					
					if (m_debug)
						printf("FLASH[%07x] = %08x, not 0xffffffff as desired (%06x + %d)\n",
							R_FLASH+flashaddr+i*SZPAGEB+(j<<2),
							page[j], rdaddr,(j<<2));
					return false;
				}
		}
		if (m_debug)
			printf("Erase verified\n");
	}

	return true;
#else
	return false; // No flash preset
#endif
}

bool	FLASHDRVR::page_program(const unsigned addr, const unsigned len,
		const char *data, const bool verify_write) {
#ifdef	FLASH_ACCESS
	DEVBUS::BUSW	buf[SZPAGEW], bswapd[SZPAGEW];
	unsigned	flashaddr = addr & 0x0ffffff;

	take_offline();

	assert(len > 0);
	assert(len <= PGLENB);
	assert(PAGEOF(addr)==PAGEOF(addr+len-1));

	if (len <= 0)
		return true;

	bool	empty_page = true;
	for(unsigned i=0; i<len; i+=4) {
		DEVBUS::BUSW v;
		v = buildword((const unsigned char *)&data[i]);
		bswapd[(i>>2)] = v;
		if (v != 0xffffffff)
			empty_page = false;
	}

	if (empty_page) {
		place_online();
		return true;
	}


	// Write enable
	m_fpga->writeio(R_FLASHCFG, F_END);
	m_fpga->writeio(R_FLASHCFG, F_WREN);
	m_fpga->writeio(R_FLASHCFG, F_END);

	//
	// Write the page
	//

	// Issue the command
	m_fpga->writeio(R_FLASHCFG, F_PP);
	// The address
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE|((flashaddr>>16)&0x0ff));
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE|((flashaddr>> 8)&0x0ff));
	m_fpga->writeio(R_FLASHCFG, CFG_USERMODE|((flashaddr    )&0x0ff));
	// Write the page data itself
	for(unsigned i=0; i<len; i++)
		m_fpga->writeio(R_FLASHCFG, 
			CFG_USERMODE | CFG_WEDIR | (data[i] & 0x0ff));
	m_fpga->writeio(R_FLASHCFG, F_END);

	printf("Writing page: 0x%08x - 0x%08x", addr, addr+len-1);
	if ((m_debug)&&(verify_write))
		fflush(stdout);
	else
		printf("\n");

	flwait();

	place_online();
	if (verify_write) {
		// printf("Attempting to verify page\n");
		// NOW VERIFY THE PAGE
		m_fpga->readi(addr, len>>2, buf);
		for(unsigned i=0; i<(len>>2); i++) {
			if (buf[i] != bswapd[i]) {
				printf("\nVERIFY FAILS[%d]: %08x\n", i, (i<<2)+addr);
				printf("\t(Flash[%d]) %08x != %08x (Goal[%08x])\n", 
					(i<<2), buf[i], bswapd[i], (i<<2)+addr);
				return false;
			}
		} if (m_debug)
			printf(" -- Successfully verified\n");
	} return true;
#else
	return false; // No flash present
#endif
}

#ifdef	R_QSPI_VCONF
#define	VCONF_VALUE	0xab
#define	VCONF_VALUE_ALT	0xa3
#endif

bool	FLASHDRVR::verify_config(void) {
#ifndef	FLASH_ACCESS
	return false;
#endif
return true;
}

void	FLASHDRVR::set_config(void) {
	if (m_id == MICRON_FLASHID) {
		// There is some delay associated with these commands, but it
		// should be dwarfed by the communication delay.  If you wish
		// to do this on the device itself, you may need to use some
		// timers.
		//

		// take_offline();

		// Write Enable

		// Set the Enhanced Volatile Configuration Register
		// m_fpga->writeio(R_FLASHCFG, 0x81);
		// m_fpga->writeio(R_FLASHCFG, 0xa3);
		//
		// place_online();

		// Not necessary anymore, since the EVConf register setting
		// is now a part of our place_online() command
	}
}

bool	FLASHDRVR::write(const unsigned addr, const unsigned len,
		const char *data, const bool verify) {
#ifdef	FLASH_ACCESS

	flashid();

	assert(addr >= FLASHBASE);
	assert(addr+len <= FLASHBASE + FLASHLEN);

	if (!verify_config()) {
		set_config();
		if (!verify_config()) {
			printf("Invalid configuration, cannot program flash\n");
			return false;
		}
	}

	// Work through this one sector at a time.
	// If this buffer is equal to the sector value(s), go on
	// If not, erase the sector

	for(unsigned s=SECTOROF(addr); s<SECTOROF(addr+len+SECTORSZB-1);
			s+=SECTORSZB) {
		// Do we need to erase?
		bool	need_erase = false, need_program = false;
		unsigned newv = 0; // (s<addr)?addr:s;
		{
			char *sbuf = new char[SECTORSZB];
			const char *dp;	// pointer to our "desired" buffer
			unsigned	base,ln;

			base = (addr>s)?addr:s;
			ln=((addr+len>s+SECTORSZB)?(s+SECTORSZB):(addr+len))-base;
			m_fpga->readi(base, ln>>2, (uint32_t *)sbuf);
			byteswapbuf(ln>>2, (uint32_t *)sbuf);

			dp = &data[base-addr];
			SETSCOPE;
			for(unsigned i=0; i<ln; i++) {
				if ((sbuf[i]&dp[i]) != dp[i]) {
					if (m_debug) {
						printf("\nNEED-ERASE @0x%08x ... %08x != %08x (Goal)\n", 
							i+base-addr, sbuf[i], dp[i]);
					}
					need_erase = true;
					newv = (i&-4)+base;
					break;
				} else if ((sbuf[i] != dp[i])&&(newv == 0))
					newv = (i&-4)+base;
			}
		}

		if (newv == 0)
			continue; // This sector already matches

		// Erase the sector if necessary
		if (!need_erase) {
			if (m_debug) printf("NO ERASE NEEDED\n");
		} else {
			printf("ERASING SECTOR: %08x\n", s);
			if (!erase_sector(s, verify)) {
				printf("SECTOR ERASE FAILED!\n");
				return false;
			} newv = (s<addr) ? addr : s;
		}

		// Now walk through all of our pages in this sector and write
		// to them.
		for(unsigned p=newv; (p<s+SECTORSZB)&&(p<addr+len); p=PAGEOF(p+PGLENB)) {
			unsigned start = p, len = addr+len-start;

			// BUT! if we cross page boundaries, we need to clip
			// our results to the page boundary
			if (PAGEOF(start+len-1)!=PAGEOF(start))
				len = PAGEOF(start+PGLENB)-start;
			if (!page_program(start, len, &data[p-addr], verify)) {
				printf("WRITE-PAGE FAILED!\n");
				return false;
			}
		} if ((need_erase)||(need_program))
			printf("Sector 0x%08x: DONE%15s\n", s, "");
	}

	take_offline();

	m_fpga->writeio(R_FLASHCFG, F_WRDI);
	m_fpga->writeio(R_FLASHCFG, F_END);

	place_online();

	return true;
#else
	return false;
#endif
}
