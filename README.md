
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

## License

**All Rights Reserved.**

This source code is the exclusive property of **Ryszard Paluch**.
You may view and study it for personal, non-commercial, educational purposes only.

Any other use — including commercial use, modification, redistribution,
or use in other projects — requires prior written permission from the author.

See the `LICENSE` file for full terms.

## Author

**Ryszard Paluch**
- GitHub: [@rick1961pl-ops](https://github.com/rick1961pl-ops)
- Year: 2026
