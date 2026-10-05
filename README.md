
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
