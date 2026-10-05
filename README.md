# FPGA Spartan-6 XC6SLX9 Project

A custom FPGA system built on the **Xilinx Spartan-6 XC6SLX9** chip. The project integrates multiple classic controllers and modules into a single chip, creating a platform similar to a retro computer.

The system is written entirely in **Verilog HDL** and synthesized in **Xilinx ISE 14.7**. It provides a complete graphics and I/O platform: VGA output with framebuffer, text and sprite engines, PS/2 keyboard, UART, SD card support, and a custom CPU interface for issuing commands.

## Architecture Overview

The CPU communicates with the FPGA through a **parallel bus** with a **16-register memory map** (`ram[0]`…`ram[15]`). The interface supports two synchronization methods:

- **Interrupt-driven mode** — the FPGA asserts the `INT` line when an event occurs (e.g. command finished, UART data received, PS/2 key pressed). The CPU can then handle the event in its interrupt routine.
- **Polling mode** — the CPU periodically reads the status register `ram[15]` to check flags (busy, data ready, error). This is useful when interrupts are not available or not desired.

Both methods can be used simultaneously — the CPU can enable only selected interrupt sources via the interrupt enable register, and poll the rest.

## Features

### Graphics

- **VGA Controller** — generates standard 640x480@60Hz VGA signals (HSYNC, VSYNC, RGB) using a 25 MHz pixel clock.
- **SRAM Framebuffer** — external SRAM stores the entire 640x480 image at 8 bits per pixel (RGB332 color format). The controller handles both reading (for display) and writing (from CPU).
- **Text Engine** — 80x60 character mode with 8x8 pixel font. Supports cursor with adjustable height, color, and blinking. Fonts can be stored either in LUT (fast) or in BRAM (compact).
- **Sprite Engine** — 8 independent sprites, each 16x16 pixels with 8-bit color. Supports per-sprite transparency (color 0), horizontal/vertical flipping, and enable/disable control.

### Input / Output

- **PS/2 Keyboard** — full bidirectional PS/2 controller. Receives scan codes from the keyboard and decodes them to ASCII. Supports Caps Lock, Num Lock, and Scroll Lock with LED control. Handles extended keys (arrows, Insert, Delete, Home, End, Page Up/Down).
- **UART** — universal asynchronous receiver/transmitter with 5 selectable baud rates: 9600, 19200, 38400, 57600, and 115200 bps.
- **SD Card** — SD card controller operating in SPI mode. Supports card initialization (CMD0, CMD8, CMD55, ACMD41, CMD58), block read (CMD17), and block write (CMD24). Includes card presence detection via CD pin.

### CPU Interface

- **Parallel Bus** — the CPU is connected to the FPGA via a parallel address/data bus (5-bit address, 8-bit data) with chip enable (`CE_n`), output enable (`OE_n`), and write enable (`WE_n`) signals. A bidirectional buffer (`ENABLE`, `DIR`) controls the data flow direction.
- **Command Interface** — the CPU communicates with the FPGA through 16 memory-mapped registers (`ram[0]`…`ram[15]`). The CPU writes command parameters to `ram[1]`…`ram[n]`, then writes the command number to `ram[0]`. The FPGA executes the command and writes status to `ram[15]`.
- **Interrupt System** — the FPGA has a dedicated `INT` output line. Interrupt sources include: timer overflow, PS/2 data ready, UART RX/TX, command done, and RTS change. Each source can be individually enabled or masked via the interrupt enable register (`ram[18]`). Flags are stored in `ram[16]` and cleared via `ram[17]`.
- **Status Polling** — the status register `ram[15]` provides real-time information about the system state. The CPU can poll individual bits to check if a command is busy, if data is ready, or if an error occurred.
- **8-bit Timer** — configurable prescaler and reload value for periodic interrupts.
- **Pseudo-Random Generators** — 8-bit and 16-bit LFSR for random number generation.
- **Real-Time Clock** — Unix timestamp counter (32-bit) with 1-second resolution.

## Technical Specification

| Parameter | Value |
|---|---|
| FPGA chip | Xilinx Spartan-6 XC6SLX9 |
| Package | TQFP-144 |
| Language | Verilog HDL |
| IDE | Xilinx ISE 14.7 |
| Main clock | 50 MHz |
| VGA pixel clock | 25 MHz |
| VGA resolution | 640x480 @ 60 Hz |
| Color depth | 8 bpp (RGB332) |
| Text mode | 80x60 characters |
| Sprite count | 8 sprites, 16x16 px each |
| Framebuffer | External SRAM, 307,200 bytes |
| CPU bus | Parallel, 5-bit address, 8-bit data |
| Interrupts | 8 sources, individually maskable |
| Configuration memory | SPI Flash 32 MB |
| JTAG cable | Digilent JTAG-SMT2 (10 MHz) |
| Bitstream format | MCS (Intel HEX) |
| Bitstream size | 340,884 bytes (~333 kB) |

## Schematic

A complete schematic of the project is available as a PDF file:

📄 **[Download Schematic (PDF)](./FPGA_VGA.pdf)**

The schematic includes:
- FPGA pin assignments
- External SRAM connections
- VGA output connector
- PS/2 keyboard connector
- UART interface
- SD card slot
- Power supply section
- JTAG programming header
- CPU parallel bus connector
- Interrupt line (INT)

## How to Build

1. **Install Xilinx ISE 14.7** (WebPACK edition is sufficient for Spartan-6).
2. **Open the project** — create a new project in ISE, add all `.v` files.
3. **Add constraints** — provide a `.ucf` file with pin assignments for your board.
4. **Synthesize** the design (XST).
5. **Implement** the design (Translate, Map, Place & Route).
6. **Generate the bitstream** (`.bit` file).
7. **Program the FPGA** — either via JTAG (direct) or write to SPI Flash (for autonomous boot).

## How to Use

The system is controlled by a custom CPU through a simple command interface.

### Command Execution Flow

1. **Write parameters** to registers `ram[1]` … `ram[9]`.
2. **Write command number** to `ram[0]` — this starts execution.
3. **FPGA executes the command** — the busy flag in `ram[15]` is set.
4. **Wait for completion** — either poll `ram[15]` bit 0, or wait for the `INT` line.
5. **Read result** from `ram[15]` (status) or specific registers.

### Interrupt Handling

1. **Enable interrupts** — write mask to `ram[18]`.
2. **Wait for INT** — the FPGA asserts the `INT` line when an enabled event occurs.
3. **Read flags** — read `ram[16]` to see which interrupt fired.
4. **Handle event** — perform the required action.
5. **Clear flags** — write `1` to the corresponding bits in `ram[17]`.

### Polling Mode

1. **Issue command** — write command number to `ram[0]`.
2. **Poll status** — read `ram[15]` in a loop until bit 0 (VGA busy) becomes 0.
3. **Check result** — read specific registers (e.g. `ram[10]` for SD R1 response).

### Example: Clear Framebuffer


## Memory Map (CPU Registers)

| Register | Name | Description |
|---|---|---|
| `ram[0]` | `REG_COMMAND` | Command number (write = start) |
| `ram[1]` | `REG_XPOS_TXT` | Text cursor X position |
| `ram[2]` | `REG_YPOS_TXT` | Text cursor Y position |
| `ram[3]` | `REG_CHAR_ASCII` | ASCII character code |
| `ram[4]` | `REG_CHAR_ATTR` | Character attribute (color) |
| `ram[5]`…`ram[9]` | `REG_PARAM1`…`REG_PARAM5` | Command parameters |
| `ram[10]` | `REG_SD` | SD card R1 response |
| `ram[11]` | `REG_CFG` | UART configuration |
| `ram[12]` | `REG_UART_DATA` | UART data register |
| `ram[13]` | `REG_PS2_DATA` | PS/2 key code |
| `ram[14]` | `REG_CURSOR_CTRL` | Cursor control register |
| `ram[15]` | `REG_STATUS_VGA` | Status register |

### Interrupt Registers

| Register | Name | Description |
|---|---|---|
| `ram[16]` | `REG_INT_FLAGS` | Active interrupt flags |
| `ram[17]` | `REG_CLEAR_FLAGS` | Write 1 to clear flag |
| `ram[18]` | `REG_INT_ENABLE` | Interrupt enable mask |

## Status Register (ram[15])

| Bit | Name | Description |
|---|---|---|
| 0 | `STATUS_VGA` | 0 = idle, 1 = busy |
| 1 | `STATUS_PS2` | 1 = new PS/2 key code ready |
| 2 | `STATUS_UART_RXD` | 1 = UART data received |
| 3 | `STATUS_UART_TXD` | 1 = UART transmission in progress |
| 4 | `STATUS_SD` | 1 = SD operation finished |
| 5 | `STATUS_SD_PRESENT` | 1 = SD card inserted |
| 6 | `STATUS_SD_POWER` | 1 = SD card power enabled |
| 7 | (reserved) | — |

## Interrupt Sources

| Bit | Name | Description |
|---|---|---|
| 0 | `IRQ_TIMER8_OVF` | 8-bit timer overflow |
| 1 | `IRQ_TIMER8_CMP` | 8-bit timer compare match |
| 2 | `IRQ_PS2` | PS/2 key code ready |
| 3 | `IRQ_UART_RX` | UART data received |
| 4 | `IRQ_UART_TX` | UART transmission finished |
| 5 | `IRQ_CMD_DONE` | Long command finished |
| 6 | `IRQ_RTS` | RTS line changed |
| 7 | (reserved) | — |

## License

**All Rights Reserved.**
**Copyright (c) 2026 Ryszard Paluch. All rights reserved.**

### What you CAN do

- ✅ **View** the source code.
- ✅ **Read** and **study** the source code.
- ✅ **Use** the source code for **personal, non-commercial, educational purposes only**.
- ✅ **Fork** the repository on GitHub (as required by GitHub Terms of Service).
- ✅ **Reference** this project in academic or educational work (with proper attribution).

### What you CANNOT do

- ❌ **You CANNOT use this code in any commercial product or service.**
- ❌ **You CANNOT copy, modify, or create derivative works** based on this code.
- ❌ **You CANNOT redistribute, sublicense, or publish** this code in any form.
- ❌ **You CANNOT use this code in any project, repository, or product** that is publicly distributed.
- ❌ **You CANNOT use this code in any product that is sold, licensed, or monetized** in any way.
- ❌ **You CANNOT remove or alter** this license, copyright notice, or author information.
- ❌ **You CANNOT claim authorship** of this code or any part of it.
- ❌ **You CANNOT use this code in any project that competes** with the author's commercial interests.
- ❌ **You CANNOT use this code for any purpose** other than personal study, without prior written permission.

### Requests for permission

To request permission for any use not explicitly permitted above, contact the author:

**Ryszard Paluch**
- Email: [rick1961pl@gmail.com](mailto:rick1961pl@gmail.com)
- GitHub: [@rick1961pl-ops](https://github.com/rick1961pl-ops)

All requests are reviewed individually. **Permission is granted only in writing (email) and only for the specific use described in the request.** The author reserves the right to refuse permission or to grant it under additional conditions (e.g. royalty fees, attribution requirements).

### No warranty

THIS CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE CODE OR THE USE OR OTHER DEALINGS IN THE CODE.

## Author

**Ryszard Paluch**
- GitHub: [@rick1961pl-ops](https://github.com/rick1961pl-ops)
- Email: [rick1961pl@gmail.com](mailto:rick1961pl@gmail.com)
- Year: 2026
