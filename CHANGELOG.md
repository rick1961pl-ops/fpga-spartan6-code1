# Changelog

A list of changes, new features, and fixes in the FPGA Spartan-6 XC6SLX9 project.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- (future changes go here)

## [1.1.0] - 2026-10-10

Version 1.1 introduces three new graphics commands and expands SRAM to a full 16-bit data width, enabling on-the-fly switching between graphics buffers.

### Added

- `CMD_DRAW_LINE` (23) — draws lines using Bresenham's algorithm, with optional thickness and dashed style.
- `CMD_SET_BUF_LB` (32) — switches the active graphics buffer to the lower SRAM byte (LB).
- `CMD_SET_BUF_UB` (33) — switches the active graphics buffer to the upper SRAM byte (UB).

### Changed

- SRAM data bus expanded from 8 bits (`sram_data[7:0]`) to 16 bits (`sram_data[15:0]`).
- UCF file — uncommented pin assignments for the upper SRAM byte (D8–D15).
- SRAM controller (`sram_ctrl.v`) — added the `buf_sel` input for switching between the lower and upper bytes.
- CPU interface (`cpu_ram.v`) — added the `buf_sel` output and support for the new commands.

### Fixed

- Bug in `cpu_ram.v` (`thick_step`) that caused stray pixels when drawing thick lines — used `$unsigned` casting instead of truncating the sign bits.
- Bug in `thick_begin` — added clearing of `wr_req` before starting a new thickness block.

### Notes

- Default buffer after FPGA reset: **LB** (`buf_sel = 0`).
- The contents of the upper SRAM byte are undefined at power-up. Before drawing, it is recommended to clear the buffer using the `CMD_CLEAR_FRAMEBUFFER` command.
- Technical details of the new commands are available on the [CPU Control](https://retro.aurora.com.pl/cpu-control.html) page.
- CPU-side ATMega demo code (v1.1) is available for download: [atmega_demo-v1.1.zip](https://retro.aurora.com.pl/downloads/atmega_demo-v1.1.zip).

## [1.0.0] - 2026-10-06

First public release.

### Added

- **VGA Controller** — generates standard 640x480@60Hz VGA signals (HSYNC, VSYNC, RGB) using a 25 MHz pixel clock.
- **SRAM Framebuffer** — external SRAM stores the entire 640x480 image at 8 bits per pixel (RGB332 color format).
- **Text Engine** — 80x60 character mode with 8x8 pixel font. Supports cursor with adjustable height, color, and blinking. Fonts can be stored either in LUT (fast) or in BRAM (compact).
- **Sprite Engine** — 8 independent sprites, each 16x16 pixels with 8-bit color. Supports per-sprite transparency (color 0), horizontal/vertical flipping, and enable/disable control.
- **PS/2 Keyboard** — full bidirectional PS/2 controller. Receives scan codes from the keyboard and decodes them to ASCII. Supports Caps Lock, Num Lock, and Scroll Lock with LED control. Handles extended keys (arrows, Insert, Delete, Home, End, Page Up/Down).
- **UART** — universal asynchronous receiver/transmitter with 5 selectable baud rates: 9600, 19200, 38400, 57600, and 115200 bps.
- **SD Card** — SD card controller operating in SPI mode. Supports card initialization (CMD0, CMD8, CMD55, ACMD41, CMD58), block read (CMD17), and block write (CMD24). Includes card presence detection via CD pin.
- **Parallel Bus** — the CPU is connected to the FPGA via a parallel address/data bus (5-bit address, 8-bit data) with chip enable (`CE_n`), output enable (`OE_n`), and write enable (`WE_n`) signals.
- **Command Interface** — the CPU communicates with the FPGA through 16 memory-mapped registers (`ram[0]`...`ram[15]`).
- **Interrupt System** — the FPGA has a dedicated `INT` output line. Interrupt sources include: timer overflow, PS/2 data ready, UART RX/TX, command done, and RTS change.
- **8-bit Timer** — configurable prescaler and reload value for periodic interrupts.
- **Pseudo-Random Generators** — 8-bit and 16-bit LFSR for random number generation.
- **Real-Time Clock** — Unix timestamp counter (32-bit) with 1-second resolution.
- **PCB schematic** — complete schematic available as a PDF file.
- **Photos** — photos of the assembled board and bare PCB.
- **License** — Source Available / Non-Commercial license.

### Technical

- FPGA chip: Xilinx Spartan-6 XC6SLX9 (TQFP-144)
- IDE: Xilinx ISE 14.7
- Main clock: 50 MHz
- VGA pixel clock: 25 MHz
- VGA resolution: 640x480 @ 60 Hz
- Color depth: 8 bpp (RGB332)
- Text mode: 80x60 characters
- Sprite count: 8 sprites, 16x16 px each
- Framebuffer: external SRAM, 307,200 bytes
- CPU bus: parallel, 5-bit address, 8-bit data
- Interrupts: 8 sources, individually maskable
- Configuration memory: SPI Flash 32 MB
- JTAG cable: Digilent JTAG-SMT2 (10 MHz)
- Bitstream format: MCS (Intel HEX)
- Bitstream size: 340,884 bytes (~333 kB)

[Unreleased]: https://github.com/rick1961pl-ops/fpga-spartan6-code1/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/rick1961pl-ops/fpga-spartan6-code1/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rick1961pl-ops/fpga-spartan6-code1/releases/tag/v1.0.0
