# Changelog

A list of changes, new features, and fixes in the FPGA Spartan-6 XC6SLX9 project.

## Version 1.1

**Date:** 2026-10-10

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
