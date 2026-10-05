//==============================================================================
// rom_font.v - Pamięć fontów znaków ASCII (8x8)
//------------------------------------------------------------------------------
// Opis:
//   Moduł przechowuje bitmapy znaków ASCII 8x8 (256 znaków).
//   Każdy znak to 8 wierszy po 8 bitów (64 bity).
//
// Wersje:
//   - USE_FONT_IN_LUT : fonty w LUT (case kombinacyjny, szybkie)
//   - bez define      : fonty w BRAM (font_rom_ip, wolniejsze)
//
// Adresowanie:
//   {ascii, row} - 11-bitowy adres (8 bitów ASCII + 3 bity wiersza)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

`include "config.vh"

`ifdef USE_FONT_IN_LUT

//==============================================================================
// WERSJA 1: FONTY W LUT
//------------------------------------------------------------------------------
// Fonty zaimplementowane jako funkcja kombinacyjna (case).
// Adresowanie natychmiastowe - brak opóźnienia RAM.
//==============================================================================
module font_rom
(
    //--------------------------------------------------
    // Wejścia
    //--------------------------------------------------
    input  wire [7:0] ascii,            // kod ASCII znaku
    input  wire [2:0] row,              // numer wiersza bitmapy (0..7)

    //--------------------------------------------------
    // Wyjście
    //--------------------------------------------------
    output reg  [7:0] pixels            // 8 bitów bitmapy wiersza
);

always @*
begin
    pixels = 8'h00;

    case(ascii)
    8'h00: begin // 0x00 'NUL'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h01: begin // 0x01 'SOH'
        case(row)
            3'd0: pixels = 8'b01111110;
            3'd1: pixels = 8'b10000001;
            3'd2: pixels = 8'b10100101;
            3'd3: pixels = 8'b10000001;
            3'd4: pixels = 8'b10111101;
            3'd5: pixels = 8'b10011001;
            3'd6: pixels = 8'b10000001;
            3'd7: pixels = 8'b01111110;
        endcase
    end

    8'h02: begin // 0x02 'STX'
        case(row)
            3'd0: pixels = 8'b01111110;
            3'd1: pixels = 8'b11111111;
            3'd2: pixels = 8'b11011011;
            3'd3: pixels = 8'b11111111;
            3'd4: pixels = 8'b11000011;
            3'd5: pixels = 8'b11100111;
            3'd6: pixels = 8'b11111111;
            3'd7: pixels = 8'b01111110;
        endcase
    end

    8'h03: begin // 0x03 'ETX'
        case(row)
            3'd0: pixels = 8'b01101100;
            3'd1: pixels = 8'b11111110;
            3'd2: pixels = 8'b11111110;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b00111000;
            3'd6: pixels = 8'b00010000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h04: begin // 0x04 'EOT'
        case(row)
            3'd0: pixels = 8'b00010000;
            3'd1: pixels = 8'b00111000;
            3'd2: pixels = 8'b01111100;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b00111000;
            3'd6: pixels = 8'b00010000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h05: begin // 0x05 'ENQ'
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01111100;
            3'd2: pixels = 8'b00111000;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00111000;
            3'd7: pixels = 8'b01111100;
        endcase
    end

    8'h06: begin // 0x06 'ACK'
        case(row)
            3'd0: pixels = 8'b00010000;
            3'd1: pixels = 8'b00010000;
            3'd2: pixels = 8'b00111000;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00111000;
            3'd7: pixels = 8'b01111100;
        endcase
    end

    8'h07: begin // 0x07 'BEL'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00111100;
            3'd4: pixels = 8'b00111100;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h08: begin // 0x08 'BS'
        case(row)
            3'd0: pixels = 8'b11111111;
            3'd1: pixels = 8'b11111111;
            3'd2: pixels = 8'b11100111;
            3'd3: pixels = 8'b11000011;
            3'd4: pixels = 8'b11000011;
            3'd5: pixels = 8'b11100111;
            3'd6: pixels = 8'b11111111;
            3'd7: pixels = 8'b11111111;
        endcase
    end

    8'h09: begin // 0x09 'TAB'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00111100;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01000010;
            3'd4: pixels = 8'b01000010;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b00111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h0A: begin // 0x0A 'LF'
        case(row)
            3'd0: pixels = 8'b11111111;
            3'd1: pixels = 8'b11000011;
            3'd2: pixels = 8'b10011001;
            3'd3: pixels = 8'b10111101;
            3'd4: pixels = 8'b10111101;
            3'd5: pixels = 8'b10011001;
            3'd6: pixels = 8'b11000011;
            3'd7: pixels = 8'b11111111;
        endcase
    end

    8'h0B: begin // 0x0B 'VT'
        case(row)
            3'd0: pixels = 8'b00001111;
            3'd1: pixels = 8'b00000111;
            3'd2: pixels = 8'b00001111;
            3'd3: pixels = 8'b01111101;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b01111000;
        endcase
    end

    8'h0C: begin // 0x0C 'FF'
        case(row)
            3'd0: pixels = 8'b00111100;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b00111100;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'h0D: begin // 0x0D 'CR'
        case(row)
            3'd0: pixels = 8'b00111111;
            3'd1: pixels = 8'b00110011;
            3'd2: pixels = 8'b00111111;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b01110000;
            3'd6: pixels = 8'b11110000;
            3'd7: pixels = 8'b11100000;
        endcase
    end

    8'h0E: begin // 0x0E 'SO'
        case(row)
            3'd0: pixels = 8'b01111111;
            3'd1: pixels = 8'b01100011;
            3'd2: pixels = 8'b01111111;
            3'd3: pixels = 8'b01100011;
            3'd4: pixels = 8'b01100011;
            3'd5: pixels = 8'b01100111;
            3'd6: pixels = 8'b11100110;
            3'd7: pixels = 8'b11000000;
        endcase
    end

    8'h0F: begin // 0x0F 'SI'
        case(row)
            3'd0: pixels = 8'b10011001;
            3'd1: pixels = 8'b01011010;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b11100111;
            3'd4: pixels = 8'b11100111;
            3'd5: pixels = 8'b00111100;
            3'd6: pixels = 8'b01011010;
            3'd7: pixels = 8'b10011001;
        endcase
    end

    8'h10: begin // 0x10 'DLE'
        case(row)
            3'd0: pixels = 8'b10000000;
            3'd1: pixels = 8'b11100000;
            3'd2: pixels = 8'b11111000;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b11100000;
            3'd6: pixels = 8'b10000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h11: begin // 0x11 'DC1'
        case(row)
            3'd0: pixels = 8'b00000010;
            3'd1: pixels = 8'b00001110;
            3'd2: pixels = 8'b00111110;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b00111110;
            3'd5: pixels = 8'b00001110;
            3'd6: pixels = 8'b00000010;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h12: begin // 0x12 'DC2'
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00111100;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b01111110;
            3'd6: pixels = 8'b00111100;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'h13: begin // 0x13 'DC3'
        case(row)
            3'd0: pixels = 8'b01100110;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b01100110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h14: begin // 0x14 'DC4'
        case(row)
            3'd0: pixels = 8'b01111111;
            3'd1: pixels = 8'b11011011;
            3'd2: pixels = 8'b11011011;
            3'd3: pixels = 8'b01111011;
            3'd4: pixels = 8'b00011011;
            3'd5: pixels = 8'b00011011;
            3'd6: pixels = 8'b00011011;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h15: begin // 0x15 'NAK'
        case(row)
            3'd0: pixels = 8'b00111110;
            3'd1: pixels = 8'b01100011;
            3'd2: pixels = 8'b00111000;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b01101100;
            3'd5: pixels = 8'b00111000;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b01111000;
        endcase
    end

    8'h16: begin // 0x16 'SYN'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b01111110;
            3'd5: pixels = 8'b01111110;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h17: begin // 0x17 'ETB'
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00111100;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b01111110;
            3'd5: pixels = 8'b00111100;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b11111111;
        endcase
    end

    8'h18: begin // 0x18 'CAN'
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00111100;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h19: begin // 0x19 'EM'
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b01111110;
            3'd5: pixels = 8'b00111100;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h1A: begin // 0x1A 'SUB'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h1B: begin // 0x1B 'ESC'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h1C: begin // 0x1C 'FS'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b11111110;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h1D: begin // 0x1D 'GS'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00100100;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b11111111;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b00100100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h1E: begin // 0x1E 'RS'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b01111110;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b11111111;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h1F: begin // 0x1F 'US'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11111111;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b01111110;
            3'd4: pixels = 8'b00111100;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h20: begin // 0x20 'SPACE'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h21: begin // 0x21 '!'
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b01111000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h22: begin // 0x22 '"'
        case(row)
            3'd0: pixels = 8'b01101100;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h23: begin // 0x23 '#'
        case(row)
            3'd0: pixels = 8'b01101100;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b11111110;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b01101100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h24: begin // 0x24 '$'
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b01111100;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b11111000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h25: begin // 0x25 '%'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h26: begin // 0x26 '&'
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b00111000;
            3'd3: pixels = 8'b01110110;
            3'd4: pixels = 8'b11011100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01110110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h27: begin // 0x27 '''
        case(row)
            3'd0: pixels = 8'b01100000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h28: begin // 0x28 '('
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b01100000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h29: begin // 0x29 ')'
        case(row)
            3'd0: pixels = 8'b01100000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01100000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h2A: begin // 0x2A '*'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b11111111;
            3'd4: pixels = 8'b00111100;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h2B: begin // 0x2B '+'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h2C: begin // 0x2C ','
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b01100000;
        endcase
    end

    8'h2D: begin // 0x2D '-'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h2E: begin // 0x2E '.'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h2F: begin // 0x2F '/'
        case(row)
            3'd0: pixels = 8'b00000110;
            3'd1: pixels = 8'b00001100;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b10000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h30: begin // 0x30 '0'
        case(row)
            3'd0: pixels = 8'b01111100;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b11001110;
            3'd3: pixels = 8'b11011110;
            3'd4: pixels = 8'b11110110;
            3'd5: pixels = 8'b11100110;
            3'd6: pixels = 8'b01111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h31: begin // 0x31 '1'
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b01110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h32: begin // 0x32 '2'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00111000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h33: begin // 0x33 '3'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00111000;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h34: begin // 0x34 '4'
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00111100;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b00001100;
            3'd6: pixels = 8'b00011110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h35: begin // 0x35 '5'
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b11000000;
            3'd2: pixels = 8'b11111000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h36: begin // 0x36 '6'
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b11111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h37: begin // 0x37 '7'
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h38: begin // 0x38 '8'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h39: begin // 0x39 '9'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b01110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h3A: begin // 0x3A ':'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h3B: begin // 0x3B ';'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b01100000;
        endcase
    end

    8'h3C: begin // 0x3C '<'
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h3D: begin // 0x3D '='
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111100;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b11111100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h3E: begin // 0x3E '>'
        case(row)
            3'd0: pixels = 8'b01100000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01100000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h3F: begin // 0x3F '?'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h40: begin // 0x40 '@'
        case(row)
            3'd0: pixels = 8'b01111100;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b11011110;
            3'd3: pixels = 8'b11011110;
            3'd4: pixels = 8'b11011110;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h41: begin // 0x41 'A'
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b01111000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11111100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h42: begin // 0x42 'B'
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h43: begin // 0x43 'C'
        case(row)
            3'd0: pixels = 8'b00111100;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b00111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h44: begin // 0x44 'D'
        case(row)
            3'd0: pixels = 8'b11111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b11111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h45: begin // 0x45 'E'
        case(row)
            3'd0: pixels = 8'b11111110;
            3'd1: pixels = 8'b01100010;
            3'd2: pixels = 8'b01101000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b01101000;
            3'd5: pixels = 8'b01100010;
            3'd6: pixels = 8'b11111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h46: begin // 0x46 'F'
        case(row)
            3'd0: pixels = 8'b11111110;
            3'd1: pixels = 8'b01100010;
            3'd2: pixels = 8'b01101000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b01101000;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b11110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h47: begin // 0x47 'G'
        case(row)
            3'd0: pixels = 8'b00111100;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b11001110;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b00111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h48: begin // 0x48 'H'
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h49: begin // 0x49 'I'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h4A: begin // 0x4A 'J'
        case(row)
            3'd0: pixels = 8'b00011110;
            3'd1: pixels = 8'b00001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h4B: begin // 0x4B 'K'
        case(row)
            3'd0: pixels = 8'b11100110;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b01101100;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11100110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h4C: begin // 0x4C 'L'
        case(row)
            3'd0: pixels = 8'b11110000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b01100000;
            3'd4: pixels = 8'b01100010;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h4D: begin // 0x4D 'M'
        case(row)
            3'd0: pixels = 8'b11000110;
            3'd1: pixels = 8'b11101110;
            3'd2: pixels = 8'b11111110;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b11010110;
            3'd5: pixels = 8'b11000110;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h4E: begin // 0x4E 'N'
        case(row)
            3'd0: pixels = 8'b11000110;
            3'd1: pixels = 8'b11100110;
            3'd2: pixels = 8'b11110110;
            3'd3: pixels = 8'b11011110;
            3'd4: pixels = 8'b11001110;
            3'd5: pixels = 8'b11000110;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h4F: begin // 0x4F 'O'
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b11000110;
            3'd3: pixels = 8'b11000110;
            3'd4: pixels = 8'b11000110;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b00111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h50: begin // 0x50 'P'
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b11110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h51: begin // 0x51 'Q'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11011100;
            3'd5: pixels = 8'b01111000;
            3'd6: pixels = 8'b00011100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h52: begin // 0x52 'R'
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b01101100;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11100110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h53: begin // 0x53 'S'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11100000;
            3'd3: pixels = 8'b01110000;
            3'd4: pixels = 8'b00011100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h54: begin // 0x54 'T'
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b10110100;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h55: begin // 0x55 'U'
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h56: begin // 0x56 'V'
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h57: begin // 0x57 'W'
        case(row)
            3'd0: pixels = 8'b11000110;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b11000110;
            3'd3: pixels = 8'b11010110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b11101110;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h58: begin // 0x58 'X'
        case(row)
            3'd0: pixels = 8'b11000110;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b00111000;
            3'd4: pixels = 8'b00111000;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h59: begin // 0x59 'Y'
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h5A: begin // 0x5A 'Z'
        case(row)
            3'd0: pixels = 8'b11111110;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b10001100;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00110010;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h5B: begin // 0x5B '['
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b01100000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h5C: begin // 0x5C '\'
        case(row)
            3'd0: pixels = 8'b11000000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b00000110;
            3'd6: pixels = 8'b00000010;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h5D: begin // 0x5D ']'
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h5E: begin // 0x5E '^'
        case(row)
            3'd0: pixels = 8'b00010000;
            3'd1: pixels = 8'b00111000;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b11000110;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h5F: begin // 0x5F '_'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b11111111;
        endcase
    end

    8'h60: begin // 0x60 '`'
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h61: begin // 0x61 'a'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01110110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h62: begin // 0x62 'b'
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11011100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h63: begin // 0x63 'c'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h64: begin // 0x64 'd'
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01110110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h65: begin // 0x65 'e'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11111100;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h66: begin // 0x66 'f'
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b11110000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b11110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h67: begin // 0x67 'g'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110110;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00001100;
            3'd7: pixels = 8'b11111000;
        endcase
    end

    8'h68: begin // 0x68 'h'
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b01110110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11100110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h69: begin // 0x69 'i'
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h6A: begin // 0x6A 'j'
        case(row)
            3'd0: pixels = 8'b00001100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b01111000;
        endcase
    end

    8'h6B: begin // 0x6B 'k'
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b01111000;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b11100110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h6C: begin // 0x6C 'l'
        case(row)
            3'd0: pixels = 8'b01110000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h6D: begin // 0x6D 'm'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b11010110;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h6E: begin // 0x6E 'n'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h6F: begin // 0x6F 'o'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h70: begin // 0x70 'p'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11011100;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b01100000;
            3'd7: pixels = 8'b11110000;
        endcase
    end

    8'h71: begin // 0x71 'q'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110110;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00001100;
            3'd7: pixels = 8'b00011110;
        endcase
    end

    8'h72: begin // 0x72 'r'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11011100;
            3'd3: pixels = 8'b01110110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b11110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h73: begin // 0x73 's'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111100;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b01111000;
            3'd5: pixels = 8'b00001100;
            3'd6: pixels = 8'b11111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h74: begin // 0x74 't'
        case(row)
            3'd0: pixels = 8'b00010000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01111100;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110100;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h75: begin // 0x75 'u'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01110110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h76: begin // 0x76 'v'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h77: begin // 0x77 'w'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11000110;
            3'd3: pixels = 8'b11010110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b11111110;
            3'd6: pixels = 8'b01101100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h78: begin // 0x78 'x'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11000110;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b00111000;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h79: begin // 0x79 'y'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00001100;
            3'd7: pixels = 8'b11111000;
        endcase
    end

    8'h7A: begin // 0x7A 'z'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111100;
            3'd3: pixels = 8'b10011000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b01100100;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h7B: begin // 0x7B '{'
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b11100000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00011100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h7C: begin // 0x7C '|'
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h7D: begin // 0x7D '}'
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b00011100;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b11100000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h7E: begin // 0x7E '~'
        case(row)
            3'd0: pixels = 8'b01110110;
            3'd1: pixels = 8'b11011100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h7F: begin // 0x7F 'DEL'
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00010000;
            3'd2: pixels = 8'b00111000;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b11000110;
            3'd5: pixels = 8'b11000110;
            3'd6: pixels = 8'b11111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h80: begin // 0x80
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b01111000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00001100;
            3'd7: pixels = 8'b01111000;
        endcase
    end

    8'h81: begin // 0x81
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h82: begin // 0x82
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11111100;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h83: begin // 0x83
        case(row)
            3'd0: pixels = 8'b01111110;
            3'd1: pixels = 8'b11000011;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b00000110;
            3'd4: pixels = 8'b00111110;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b00111111;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h84: begin // 0x84
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h85: begin // 0x85
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h86: begin // 0x86
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h87: begin // 0x87
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b01111000;
            3'd6: pixels = 8'b00001100;
            3'd7: pixels = 8'b00111000;
        endcase
    end

    8'h88: begin // 0x88
        case(row)
            3'd0: pixels = 8'b01111110;
            3'd1: pixels = 8'b11000011;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b01111110;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b00111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h89: begin // 0x89
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11111100;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h8A: begin // 0x8A
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11111100;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h8B: begin // 0x8B
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h8C: begin // 0x8C
        case(row)
            3'd0: pixels = 8'b01111100;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b00111000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h8D: begin // 0x8D
        case(row)
            3'd0: pixels = 8'b11100000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h8E: begin // 0x8E
        case(row)
            3'd0: pixels = 8'b11000110;
            3'd1: pixels = 8'b00111000;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b11000110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b11000110;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h8F: begin // 0x8F
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11111100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h90: begin // 0x90
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111100;
            3'd3: pixels = 8'b01100000;
            3'd4: pixels = 8'b01111000;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h91: begin // 0x91
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111111;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b01111111;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111111;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h92: begin // 0x92
        case(row)
            3'd0: pixels = 8'b00111110;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h93: begin // 0x93
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h94: begin // 0x94
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h95: begin // 0x95
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11100000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h96: begin // 0x96
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h97: begin // 0x97
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11100000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h98: begin // 0x98
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00001100;
            3'd7: pixels = 8'b11111000;
        endcase
    end

    8'h99: begin // 0x99
        case(row)
            3'd0: pixels = 8'b11000011;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b00111100;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h9A: begin // 0x9A
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h9B: begin // 0x9B
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b01111110;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'h9C: begin // 0x9C
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01100100;
            3'd3: pixels = 8'b11110000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b11100110;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'h9D: begin // 0x9D
        case(row)
            3'd0: pixels = 8'b11001100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b11111100;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00110000;
        endcase
    end

    8'h9E: begin // 0x9E
        case(row)
            3'd0: pixels = 8'b11111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11111010;
            3'd4: pixels = 8'b11000110;
            3'd5: pixels = 8'b11001111;
            3'd6: pixels = 8'b11000110;
            3'd7: pixels = 8'b11000111;
        endcase
    end

    8'h9F: begin // 0x9F
        case(row)
            3'd0: pixels = 8'b00001110;
            3'd1: pixels = 8'b00011011;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00111100;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b11011000;
            3'd7: pixels = 8'b01110000;
        endcase
    end

    8'hA0: begin // 0xA0
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b01111100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA1: begin // 0xA1
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA2: begin // 0xA2
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00011100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b01111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA3: begin // 0xA3
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00011100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA4: begin // 0xA4
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11111000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA5: begin // 0xA5
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11101100;
            3'd4: pixels = 8'b11111100;
            3'd5: pixels = 8'b11011100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA6: begin // 0xA6
        case(row)
            3'd0: pixels = 8'b00111100;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b00111110;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b01111110;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA7: begin // 0xA7
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b00111000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA8: begin // 0xA8
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b01100000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hA9: begin // 0xA9
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hAA: begin // 0xAA
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b00001100;
            3'd5: pixels = 8'b00001100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hAB: begin // 0xAB
        case(row)
            3'd0: pixels = 8'b11000011;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11011110;
            3'd4: pixels = 8'b00110011;
            3'd5: pixels = 8'b01100110;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00001111;
        endcase
    end

    8'hAC: begin // 0xAC
        case(row)
            3'd0: pixels = 8'b11000011;
            3'd1: pixels = 8'b11000110;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11011011;
            3'd4: pixels = 8'b00110111;
            3'd5: pixels = 8'b01101111;
            3'd6: pixels = 8'b11001111;
            3'd7: pixels = 8'b00000011;
        endcase
    end

    8'hAD: begin // 0xAD
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hAE: begin // 0xAE
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00110011;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b00110011;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hAF: begin // 0xAF
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b00110011;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hB0: begin // 0xB0
        case(row)
            3'd0: pixels = 8'b00100010;
            3'd1: pixels = 8'b10001000;
            3'd2: pixels = 8'b00100010;
            3'd3: pixels = 8'b10001000;
            3'd4: pixels = 8'b00100010;
            3'd5: pixels = 8'b10001000;
            3'd6: pixels = 8'b00100010;
            3'd7: pixels = 8'b10001000;
        endcase
    end

    8'hB1: begin // 0xB1
        case(row)
            3'd0: pixels = 8'b01010101;
            3'd1: pixels = 8'b10101010;
            3'd2: pixels = 8'b01010101;
            3'd3: pixels = 8'b10101010;
            3'd4: pixels = 8'b01010101;
            3'd5: pixels = 8'b10101010;
            3'd6: pixels = 8'b01010101;
            3'd7: pixels = 8'b10101010;
        endcase
    end

    8'hB2: begin // 0xB2
        case(row)
            3'd0: pixels = 8'b11011011;
            3'd1: pixels = 8'b01110111;
            3'd2: pixels = 8'b11011011;
            3'd3: pixels = 8'b11101110;
            3'd4: pixels = 8'b11011011;
            3'd5: pixels = 8'b01110111;
            3'd6: pixels = 8'b11011011;
            3'd7: pixels = 8'b11101110;
        endcase
    end

    8'hB3: begin // 0xB3
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hB4: begin // 0xB4
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hB5: begin // 0xB5
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b11111000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hB6: begin // 0xB6
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b11110110;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hB7: begin // 0xB7
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hB8: begin // 0xB8
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hB9: begin // 0xB9
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b11110110;
            3'd3: pixels = 8'b00000110;
            3'd4: pixels = 8'b11110110;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hBA: begin // 0xBA
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b00110110;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hBB: begin // 0xBB
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111110;
            3'd3: pixels = 8'b00000110;
            3'd4: pixels = 8'b11110110;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hBC: begin // 0xBC
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b11110110;
            3'd3: pixels = 8'b00000110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hBD: begin // 0xBD
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b11111110;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hBE: begin // 0xBE
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b11111000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hBF: begin // 0xBF
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hC0: begin // 0xC0
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hC1: begin // 0xC1
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hC2: begin // 0xC2
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hC3: begin // 0xC3
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hC4: begin // 0xC4
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hC5: begin // 0xC5
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hC6: begin // 0xC6
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011111;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hC7: begin // 0xC7
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b00110111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hC8: begin // 0xC8
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110111;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hC9: begin // 0xC9
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00111111;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hCA: begin // 0xCA
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b11110111;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hCB: begin // 0xCB
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11110111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hCC: begin // 0xCC
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110111;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hCD: begin // 0xCD
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hCE: begin // 0xCE
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b11110111;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11110111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hCF: begin // 0xCF
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hD0: begin // 0xD0
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hD1: begin // 0xD1
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hD2: begin // 0xD2
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hD3: begin // 0xD3
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b00111111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hD4: begin // 0xD4
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011111;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011111;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hD5: begin // 0xD5
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00011111;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hD6: begin // 0xD6
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00111111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hD7: begin // 0xD7
        case(row)
            3'd0: pixels = 8'b00110110;
            3'd1: pixels = 8'b00110110;
            3'd2: pixels = 8'b00110110;
            3'd3: pixels = 8'b00110110;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00110110;
            3'd6: pixels = 8'b00110110;
            3'd7: pixels = 8'b00110110;
        endcase
    end

    8'hD8: begin // 0xD8
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hD9: begin // 0xD9
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b11111000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hDA: begin // 0xDA
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00011111;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hDB: begin // 0xDB
        case(row)
            3'd0: pixels = 8'b11111111;
            3'd1: pixels = 8'b11111111;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b11111111;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b11111111;
            3'd6: pixels = 8'b11111111;
            3'd7: pixels = 8'b11111111;
        endcase
    end

    8'hDC: begin // 0xDC
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b11111111;
            3'd5: pixels = 8'b11111111;
            3'd6: pixels = 8'b11111111;
            3'd7: pixels = 8'b11111111;
        endcase
    end

    8'hDD: begin // 0xDD
        case(row)
            3'd0: pixels = 8'b11110000;
            3'd1: pixels = 8'b11110000;
            3'd2: pixels = 8'b11110000;
            3'd3: pixels = 8'b11110000;
            3'd4: pixels = 8'b11110000;
            3'd5: pixels = 8'b11110000;
            3'd6: pixels = 8'b11110000;
            3'd7: pixels = 8'b11110000;
        endcase
    end

    8'hDE: begin // 0xDE
        case(row)
            3'd0: pixels = 8'b00001111;
            3'd1: pixels = 8'b00001111;
            3'd2: pixels = 8'b00001111;
            3'd3: pixels = 8'b00001111;
            3'd4: pixels = 8'b00001111;
            3'd5: pixels = 8'b00001111;
            3'd6: pixels = 8'b00001111;
            3'd7: pixels = 8'b00001111;
        endcase
    end

    8'hDF: begin // 0xDF
        case(row)
            3'd0: pixels = 8'b11111111;
            3'd1: pixels = 8'b11111111;
            3'd2: pixels = 8'b11111111;
            3'd3: pixels = 8'b11111111;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE0: begin // 0xE0
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01110110;
            3'd3: pixels = 8'b11011100;
            3'd4: pixels = 8'b11001000;
            3'd5: pixels = 8'b11011100;
            3'd6: pixels = 8'b01110110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE1: begin // 0xE1
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b01111000;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11111000;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11111000;
            3'd6: pixels = 8'b11000000;
            3'd7: pixels = 8'b11000000;
        endcase
    end

    8'hE2: begin // 0xE2
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11111100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11000000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b11000000;
            3'd6: pixels = 8'b11000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE3: begin // 0xE3
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11111110;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b01101100;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b01101100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE4: begin // 0xE4
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE5: begin // 0xE5
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b11011000;
            3'd4: pixels = 8'b11011000;
            3'd5: pixels = 8'b11011000;
            3'd6: pixels = 8'b01110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE6: begin // 0xE6
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b01100110;
            3'd2: pixels = 8'b01100110;
            3'd3: pixels = 8'b01100110;
            3'd4: pixels = 8'b01100110;
            3'd5: pixels = 8'b01111100;
            3'd6: pixels = 8'b01100000;
            3'd7: pixels = 8'b11000000;
        endcase
    end

    8'hE7: begin // 0xE7
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b01110110;
            3'd2: pixels = 8'b11011100;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hE8: begin // 0xE8
        case(row)
            3'd0: pixels = 8'b11111100;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01111000;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b01111000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b11111100;
        endcase
    end

    8'hE9: begin // 0xE9
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b11000110;
            3'd3: pixels = 8'b11111110;
            3'd4: pixels = 8'b11000110;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b00111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hEA: begin // 0xEA
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b11000110;
            3'd3: pixels = 8'b11000110;
            3'd4: pixels = 8'b01101100;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b11101110;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hEB: begin // 0xEB
        case(row)
            3'd0: pixels = 8'b00011100;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b01111100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b01111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hEC: begin // 0xEC
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b11011011;
            3'd4: pixels = 8'b11011011;
            3'd5: pixels = 8'b01111110;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hED: begin // 0xED
        case(row)
            3'd0: pixels = 8'b00000110;
            3'd1: pixels = 8'b00001100;
            3'd2: pixels = 8'b01111110;
            3'd3: pixels = 8'b11011011;
            3'd4: pixels = 8'b11011011;
            3'd5: pixels = 8'b01111110;
            3'd6: pixels = 8'b01100000;
            3'd7: pixels = 8'b11000000;
        endcase
    end

    8'hEE: begin // 0xEE
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01100000;
            3'd2: pixels = 8'b11000000;
            3'd3: pixels = 8'b11111000;
            3'd4: pixels = 8'b11000000;
            3'd5: pixels = 8'b01100000;
            3'd6: pixels = 8'b00111000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hEF: begin // 0xEF
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b11001100;
            3'd2: pixels = 8'b11001100;
            3'd3: pixels = 8'b11001100;
            3'd4: pixels = 8'b11001100;
            3'd5: pixels = 8'b11001100;
            3'd6: pixels = 8'b11001100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF0: begin // 0xF0
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b11111100;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b11111100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF1: begin // 0xF1
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b11111100;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00110000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF2: begin // 0xF2
        case(row)
            3'd0: pixels = 8'b01100000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b01100000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF3: begin // 0xF3
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b01100000;
            3'd3: pixels = 8'b00110000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b11111100;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF4: begin // 0xF4
        case(row)
            3'd0: pixels = 8'b00001110;
            3'd1: pixels = 8'b00011011;
            3'd2: pixels = 8'b00011011;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00011000;
            3'd6: pixels = 8'b00011000;
            3'd7: pixels = 8'b00011000;
        endcase
    end

    8'hF5: begin // 0xF5
        case(row)
            3'd0: pixels = 8'b00011000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00011000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b11011000;
            3'd6: pixels = 8'b11011000;
            3'd7: pixels = 8'b01110000;
        endcase
    end

    8'hF6: begin // 0xF6
        case(row)
            3'd0: pixels = 8'b00110000;
            3'd1: pixels = 8'b00110000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b11111100;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00110000;
            3'd6: pixels = 8'b00110000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF7: begin // 0xF7
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b01110110;
            3'd2: pixels = 8'b11011100;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b01110110;
            3'd5: pixels = 8'b11011100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF8: begin // 0xF8
        case(row)
            3'd0: pixels = 8'b00111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b00111000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hF9: begin // 0xF9
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00011000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hFA: begin // 0xFA
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00011000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hFB: begin // 0xFB
        case(row)
            3'd0: pixels = 8'b00001111;
            3'd1: pixels = 8'b00001100;
            3'd2: pixels = 8'b00001100;
            3'd3: pixels = 8'b00001100;
            3'd4: pixels = 8'b11101100;
            3'd5: pixels = 8'b01101100;
            3'd6: pixels = 8'b00111100;
            3'd7: pixels = 8'b00011100;
        endcase
    end

    8'hFC: begin // 0xFC
        case(row)
            3'd0: pixels = 8'b01111000;
            3'd1: pixels = 8'b01101100;
            3'd2: pixels = 8'b01101100;
            3'd3: pixels = 8'b01101100;
            3'd4: pixels = 8'b01101100;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hFD: begin // 0xFD
        case(row)
            3'd0: pixels = 8'b01110000;
            3'd1: pixels = 8'b00011000;
            3'd2: pixels = 8'b00110000;
            3'd3: pixels = 8'b01100000;
            3'd4: pixels = 8'b01111000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hFE: begin // 0xFE
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00111100;
            3'd3: pixels = 8'b00111100;
            3'd4: pixels = 8'b00111100;
            3'd5: pixels = 8'b00111100;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    8'hFF: begin // 0xFF
        case(row)
            3'd0: pixels = 8'b00000000;
            3'd1: pixels = 8'b00000000;
            3'd2: pixels = 8'b00000000;
            3'd3: pixels = 8'b00000000;
            3'd4: pixels = 8'b00000000;
            3'd5: pixels = 8'b00000000;
            3'd6: pixels = 8'b00000000;
            3'd7: pixels = 8'b00000000;
        endcase
    end

    default:
        pixels = 8'h00;

    endcase
end

endmodule

`else

//==============================================================================
// WERSJA 2: FONTY W RAM
//------------------------------------------------------------------------------
// Fonty przechowywane w BRAM (font_rom_ip).
// Adresowanie: {ascii, row} - 11 bitów.
//==============================================================================

module font_rom
(
    //--------------------------------------------------
    // Wejścia
    //--------------------------------------------------
    input  wire       clk,              // zegar 25 MHz
    input  wire [7:0] ascii,            // kod ASCII znaku
    input  wire [2:0] row,              // numer wiersza bitmapy (0..7)

    //--------------------------------------------------
    // Wyjście
    //--------------------------------------------------
    output wire [7:0] pixels            // 8 bitów bitmapy wiersza
);

font_rom_ip font_mem
(
    .clka  (clk),
    .addra ({ascii,row}),
    .douta (pixels)
);

endmodule
`endif