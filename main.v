//==============================================================================
// main.v - G³ówny modu³ projektu FPGA
//------------------------------------------------------------------------------
// Opis:
//   Modu³ ³¹czy wszystkie podmodu³y projektu:
//     - vga_timing      : generator sygna³ów VGA 640x480@60Hz
//     - sram_ctrl       : kontroler SRAM (framebuffer 640x480x8bpp)
//     - text_engine     : silnik tekstowy 80x60
//     - text_ram_core   : bufor tekstowy (BRAM)
//     - cpu_ram         : interfejs komend CPU <-> FPGA
//     - sd_spi          : kontroler karty SD w trybie SPI
//     - sprite_engine   : silnik sprite'ów 8x 16x16
//     - uart            : kontroler UART (w cpu_ram)
//     - ps2_keyboard    : kontroler klawiatury PS/2 (w cpu_ram)
//
// Zegar:
//   clk   = 50 MHz (wejœcie)
//   clk25 = 25 MHz (dzielnik /2, dla VGA i wiêkszoœci modu³ów)
//
// Reset:
//   n_RST = zewnêtrzny pin resetu (aktywny 0)
//   rst_n = wewnêtrzny reset (start 100 ms + soft_reset z cpu_ram) AND n_RST
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module main
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar 50 MHz
    input  wire        n_RST,           // reset zewnêtrzny (aktywny 0)

    //--------------------------------------------------
    // VGA
    //--------------------------------------------------
    output wire        hsync,           // synchronizacja pozioma
    output wire        vsync,           // synchronizacja pionowa
    output reg  [2:0]  red,             // sygna³ czerwony (3 bity)
    output reg  [2:0]  green,           // sygna³ zielony (3 bity)
    output reg  [1:0]  blue,            // sygna³ niebieski (2 bity)

    //--------------------------------------------------
    // SRAM (framebuffer)
    //--------------------------------------------------
    output wire [18:0] sram_addr,       // adres SRAM
    inout  wire [7:0]  sram_data,       // dane SRAM
    output wire        sram_ce_n,       // chip enable (aktywny 0)
    output wire        sram_oe_n,       // output enable (aktywny 0)
    output wire        sram_we_n,       // write enable (aktywny 0)
    output wire        sram_lb_n,       // lower byte (aktywny 0)
    output wire        sram_ub_n,       // upper byte (aktywny 0)

    //--------------------------------------------------
    // Interfejs CPU (magistrala)
    //--------------------------------------------------
    input  wire [4:0]  RAM_ADDR,        // adres rejestru CPU
    inout  wire [7:0]  RAM_DATA,        // dane CPU
    input  wire        RAM_CE,          // chip enable (aktywny 0)
    input  wire        RAM_OE,          // output enable (aktywny 0)
    input  wire        RAM_WE,          // write enable (aktywny 0)
    output wire        ENABLE,          // sterowanie buforem
    output wire        DIR,             // kierunek bufora
    output wire        INT,             // przerwanie

    //--------------------------------------------------
    // PS/2
    //--------------------------------------------------
    inout  wire        PS2_CLK,         // linia zegara PS/2
    inout  wire        PS2_DATA,        // linia danych PS/2

    //--------------------------------------------------
    // UART
    //--------------------------------------------------
    input  wire        RXD,             // linia RX
    output wire        TXD,             // linia TX
    input  wire        RTS,             // linia RTS

    //--------------------------------------------------
    // Debug
    //--------------------------------------------------
    output wire [7:0]  debug_port,      // port debug

    //--------------------------------------------------
    // Karta SD (SPI)
    //--------------------------------------------------
    output wire        SD_CS,           // chip select
    output wire        SD_CLK,          // zegar SPI
    output wire        SD_MOSI,         // master out, slave in
    input  wire        SD_MISO,         // master in, slave out
    input  wire        SD_CD,           // detekcja karty (0 = obecna)
    output wire        SD_VCC           // zasilanie karty SD
);

`include "config.vh"

//==============================================================================
// 1. PALETA KOLORÓW KURSORA (RGB332)
//------------------------------------------------------------------------------
// Funkcja zwracaj¹ca kolor kursora na podstawie indeksu (0..7).
//==============================================================================

function [7:0] cursor_palette;
    input [2:0] idx;
    begin
        case (idx)
            3'd0: cursor_palette = 8'b000_000_00;  // Inwersja (placeholder)
            3'd1: cursor_palette = 8'b000_000_00;  // Czarny
            3'd2: cursor_palette = 8'b111_000_00;  // Czerwony
            3'd3: cursor_palette = 8'b000_111_00;  // Zielony
            3'd4: cursor_palette = 8'b000_000_11;  // Niebieski
            3'd5: cursor_palette = 8'b111_111_00;  // ¯ó³ty
            3'd6: cursor_palette = 8'b000_111_11;  // Cyjan
            3'd7: cursor_palette = 8'b111_111_11;  // Bia³y
        endcase
    end
endfunction

//==============================================================================
// 2. PO£¥CZENIA GLOBALNE
//------------------------------------------------------------------------------
// Sygna³y wspó³dzielone miêdzy modu³ami.
//==============================================================================

//--------------------------------------------------
// UART - multiplekser TXD
//--------------------------------------------------
wire soft_reset;                        // reset programowy z cpu_ram
wire uart_enable;                       // 1 = UART pod³¹czony do TXD
wire uart_txd_int;                      // TXD z cpu_ram

assign TXD = uart_enable ? uart_txd_int : 1'bz;

//--------------------------------------------------
// Zegar i reset
//--------------------------------------------------
reg  clk25 = 1'b0;                      // zegar 25 MHz (dzielnik /2)
wire rst_n;                             // finalny reset (wewnêtrzny AND zewnêtrzny)
reg  rst_n_reg = 1'b0;                  // wewnêtrzny reset aktywny stanem niskim
reg  [22:0] reset_counter = 23'd0;      // licznik resetu startowego
reg  soft_reset_latch;                  // flaga trwania soft_reset

//--------------------------------------------------
// VGA - wspó³rzêdne i video_on
//--------------------------------------------------
wire [9:0] x;                           // wspó³rzêdna X
wire [9:0] y;                           // wspó³rzêdna Y
wire [9:0] x_txt;                       // wspó³rzêdna X dla tekstu
wire [8:0] y_txt;                       // wspó³rzêdna Y dla tekstu
wire       video_on;                    // 1 = aktywny obszar obrazu

//--------------------------------------------------
// Framebuffer - interfejs zapisu
//--------------------------------------------------
wire        wr_req;                     // ¿¹danie zapisu
wire [18:0] wr_addr;                    // adres zapisu
wire [7:0]  wr_data;                    // dane zapisu
wire        wr_done;                    // zapis zakoñczony
wire [7:0]  pixel;                      // piksel odczytany z SRAM
wire        clear_done;                 // czyszczenie SRAM zakoñczone

//--------------------------------------------------
// Bufor tekstowy
//--------------------------------------------------
wire [7:0]  text_pixel;                 // kolor piksela tekstu
wire        text_enable;                // 1 = piksel nale¿y do znaku
wire [12:0] txt_addr;                   // adres odczytu bufora tekstowego
wire [15:0] txt_data;                   // dane odczytane z bufora
wire        txt_we;                     // zapis z cpu_ram
wire [12:0] txt_addr_cpu;               // adres zapisu z cpu_ram
wire [15:0] txt_data_cpu;               // dane zapisu z cpu_ram

//--------------------------------------------------
// Kursor tekstowy
//--------------------------------------------------
wire [7:0]  cursor_ctrl;                // rejestr kontrolny kursora
wire [12:0] cursor_index;               // indeks kursora w buforze
wire        cursor_pixel;               // 1 = piksel nale¿y do kursora
wire        cursor_blink;               // 1 = kursor widoczny (miganie)

assign cursor_blink = !cursor_ctrl[7] || (cursor_ctrl[6] ? blink_cnt[24] : blink_cnt[25]);

//--------------------------------------------------
// Sprite Engine
//--------------------------------------------------
wire        spr_we;                     // zapis do BRAM (z cpu_ram)
wire [11:0] spr_addr;                   // adres w BRAM
wire [7:0]  spr_data;                   // dane do BRAM
wire [7:0]  sprite_pixel;               // kolor piksela sprite'a
wire        sprite_enable;              // 1 = piksel nale¿y do sprite'a

wire [9:0]  spr_x_0,  spr_x_1,  spr_x_2,  spr_x_3;
wire [9:0]  spr_x_4,  spr_x_5,  spr_x_6,  spr_x_7;

wire [8:0]  spr_y_0,  spr_y_1,  spr_y_2,  spr_y_3;
wire [8:0]  spr_y_4,  spr_y_5,  spr_y_6,  spr_y_7;

wire [3:0]  spr_ctrl_0,  spr_ctrl_1,  spr_ctrl_2,  spr_ctrl_3;
wire [3:0]  spr_ctrl_4,  spr_ctrl_5,  spr_ctrl_6,  spr_ctrl_7;

//--------------------------------------------------
// Karta SD (SPI)
//--------------------------------------------------
wire        sd_present_w;               // 1 = karta w gnieŸdzie
wire [8:0]  sd_data_addr;               // adres bufora SD
wire [7:0]  sd_data_in;                 // dane zapisu bufora SD
wire        sd_data_we;                 // zezwolenie na zapis bufora SD
wire [7:0]  sd_data_out;                // dane odczytu bufora SD
wire        sd_start;                   // impuls startu komendy SD
wire [5:0]  sd_cmd;                     // numer komendy SD
wire [31:0] sd_arg;                     // argument komendy SD
wire [7:0]  sd_crc;                     // CRC komendy SD
wire        sd_busy;                    // 1 = SD zajête
wire        sd_done;                    // 1 = SD zakoñczy³o
wire [7:0]  sd_r1;                      // odpowiedŸ R1 z karty
wire        sd_power_on;                // 1 = zasilanie SD w³¹czone

//--------------------------------------------------
// Framebuffer blank
//--------------------------------------------------
wire fb_blank;                          // 1 = framebuffer widoczny

//--------------------------------------------------
// Optymalizacja kursora - wybór koloru bez case
//--------------------------------------------------
wire [2:0] cur_sel = cursor_ctrl[5:3];
wire [7:0] cur_pal = cursor_palette(cur_sel);
wire [7:0] cur_rgb = (cur_sel == 3'd0) ? ~text_pixel : cur_pal;

//--------------------------------------------------
// Multiplekser bufora tekstowego (demo vs CPU)
//--------------------------------------------------
wire        txt_we_mux;
wire [12:0] txt_addr_cpu_mux;
wire [15:0] txt_data_cpu_mux;

`ifdef USE_DEMO_TXT
    wire        demo_active;
    wire        demo_we;
    wire [12:0] demo_addr;
    wire [15:0] demo_data;

    assign txt_we_mux       = demo_active ? demo_we   : txt_we;
    assign txt_addr_cpu_mux = demo_active ? demo_addr : txt_addr_cpu;
    assign txt_data_cpu_mux = demo_active ? demo_data : txt_data_cpu;
`else
    assign txt_we_mux       = txt_we;
    assign txt_addr_cpu_mux = txt_addr_cpu;
    assign txt_data_cpu_mux = txt_data_cpu;
`endif

//==============================================================================
// 3. DEMO (opcjonalne przez USE_DEMO_TXT)
//==============================================================================

`ifdef USE_DEMO_TXT
demo_start demo
(
    .clk    (clk25),
    .rst_n  (rst_n),
    .active (demo_active),
    .we     (demo_we),
    .addr   (demo_addr),
    .data   (demo_data)
);
`endif

//==============================================================================
// 4. RESET I ZEGAR 25 MHz
//------------------------------------------------------------------------------
// Reset wewnêtrzny:
//   - przez pierwsze 100 ms po starcie: rst_n = 0
//   - po 100 ms: rst_n = 1
//   - soft_reset z cpu_ram: ponowny reset na 100 ms
//==============================================================================

always @(posedge clk)
begin
    if(soft_reset)
    begin
        reset_counter    <= 23'd0;
        rst_n_reg        <= 1'b0;
        soft_reset_latch <= 1'b1;
    end
    else if(soft_reset_latch)
    begin
        if(reset_counter < 23'd4999999)
        begin
            reset_counter <= reset_counter + 1'b1;
            rst_n_reg     <= 1'b0;
        end
        else
        begin
            rst_n_reg        <= 1'b1;
            soft_reset_latch <= 1'b0;
        end
    end
    else if(reset_counter < 23'd4999999)
    begin
        reset_counter <= reset_counter + 1'b1;
        rst_n_reg     <= 1'b0;
    end
    else
    begin
        rst_n_reg <= 1'b1;
    end
end

// Dzielnik przez 2: 50 MHz -> 25 MHz.
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        clk25 <= 1'b0;
    else
        clk25 <= ~clk25;
end

// Reset finalny = wewnêtrzny AND zewnêtrzny (n_RST)
assign rst_n = rst_n_reg & n_RST;

//==============================================================================
// 5. VGA TIMING
//==============================================================================

vga_timing vga
(
    .clk       (clk25),
    .rst_n     (rst_n),
    .hsync     (hsync),
    .vsync     (vsync),
    .x         (x),
    .y         (y),
    .x_txt     (x_txt),
    .y_txt     (y_txt),
    .video_on  (video_on)
);

// Adres piksela w framebufferze: pixel_addr = y * 640 + x
wire [18:0] pixel_addr;
assign pixel_addr = ({9'd0, y} << 9) + ({9'd0, y} << 7) + {9'd0, x};

//==============================================================================
// 6. SRAM FRAMEBUFFER
//==============================================================================

sram_ctrl sram
(
    .clk        (clk25),
    .rst_n      (rst_n),
    .pixel_addr (pixel_addr),
    .pixel      (pixel),
    .wr_req     (wr_req),
    .wr_addr    (wr_addr),
    .wr_data    (wr_data),
    .wr_done    (wr_done),
    .clear_done (clear_done),
    .sram_addr  (sram_addr),
    .sram_data  (sram_data),
    .ce_n       (sram_ce_n),
    .oe_n       (sram_oe_n),
    .we_n       (sram_we_n),
    .lb_n       (sram_lb_n),
    .ub_n       (sram_ub_n)
);

//==============================================================================
// 7. BUFOR TEKSTOWY
//==============================================================================

text_engine text
(
    .clk           (clk25),
    .x_txt         (x_txt),
    .y_txt         (y_txt),
    .text_pixel    (text_pixel),
    .text_enable   (text_enable),
    .txt_data      (txt_data),
    .txt_addr      (txt_addr),
    .cursor_height (cursor_ctrl[2:0]),
    .cursor_index  (cursor_index),
    .cursor_pixel  (cursor_pixel)
);

// Bufor tekstowy (BRAM)
text_ram_core txt_ram
(
    .clka  (clk25),
    .wea   (txt_we_mux),
    .addra (txt_addr_cpu_mux),
    .dina  (txt_data_cpu_mux),
    .clkb  (clk25),
    .addrb (txt_addr),
    .doutb (txt_data)
);

//==============================================================================
// 8. CPU_RAM - INTERFEJS KOMEND CPU <-> FPGA
//==============================================================================

cpu_ram ram
(
    // Zegar i reset
    .clk           (clk25),
    .rst_n         (rst_n),

    // Sterowanie buforem magistrali
    .ENABLE        (ENABLE),
    .DIR           (DIR),

    // Magistrala CPU
    .addr          (RAM_ADDR),
    .data          (RAM_DATA),
    .CE_n          (RAM_CE),
    .OE_n          (RAM_OE),
    .WE_n          (RAM_WE),

    // Framebuffer
    .wr_req        (wr_req),
    .wr_addr       (wr_addr),
    .wr_data       (wr_data),
    .wr_done       (wr_done),

    // Bufor tekstowy
    .txt_we        (txt_we),
    .txt_addr      (txt_addr_cpu),
    .txt_data      (txt_data_cpu),
    .cursor_index  (cursor_index),
    .cursor_ctrl   (cursor_ctrl),

    // Przerwanie
    .INT           (INT),

    // PS/2
    .ps2_clk       (PS2_CLK),
    .ps2_data      (PS2_DATA),

    // UART
    .uart_rxd      (RXD),
    .uart_txd      (uart_txd_int),
    .uart_enable   (uart_enable),
    .RTS           (RTS),

    // Debug i reset programowy
    .debug_port    (debug_port),
    .soft_reset    (soft_reset),

    // Karta SD
    .sd_start        (sd_start),
    .sd_cmd          (sd_cmd),
    .sd_arg          (sd_arg),
    .sd_crc          (sd_crc),
    .sd_busy         (sd_busy),
    .sd_done         (sd_done),
    .sd_r1           (sd_r1),
    .sd_present_in   (sd_present_w),
    .sd_data_addr    (sd_data_addr),
    .sd_data_in      (sd_data_in),
    .sd_data_we      (sd_data_we),
    .sd_data_out     (sd_data_out),
    .SD_VCC          (SD_VCC),
    .sd_power_on     (sd_power_on),

    // Sprite Engine
    .spr_we        (spr_we),
    .spr_addr      (spr_addr),
    .spr_data      (spr_data),
    .spr_x_0       (spr_x_0),
    .spr_x_1       (spr_x_1),
    .spr_x_2       (spr_x_2),
    .spr_x_3       (spr_x_3),
    .spr_x_4       (spr_x_4),
    .spr_x_5       (spr_x_5),
    .spr_x_6       (spr_x_6),
    .spr_x_7       (spr_x_7),
    .spr_y_0       (spr_y_0),
    .spr_y_1       (spr_y_1),
    .spr_y_2       (spr_y_2),
    .spr_y_3       (spr_y_3),
    .spr_y_4       (spr_y_4),
    .spr_y_5       (spr_y_5),
    .spr_y_6       (spr_y_6),
    .spr_y_7       (spr_y_7),
    .spr_ctrl_0    (spr_ctrl_0),
    .spr_ctrl_1    (spr_ctrl_1),
    .spr_ctrl_2    (spr_ctrl_2),
    .spr_ctrl_3    (spr_ctrl_3),
    .spr_ctrl_4    (spr_ctrl_4),
    .spr_ctrl_5    (spr_ctrl_5),
    .spr_ctrl_6    (spr_ctrl_6),
    .spr_ctrl_7    (spr_ctrl_7),

    // Framebuffer blank
    .fb_blank      (fb_blank)
);

//==============================================================================
// 9. SD_SPI - KONTROLER KARTY SD
//==============================================================================

sd_spi u_sd_spi
(
    .clk            (clk25),
    .rst_n          (rst_n),
    .sd_power_on    (sd_power_on),
    .start          (sd_start),
    .cmd            (sd_cmd),
    .arg            (sd_arg),
    .crc            (sd_crc),
    .busy           (sd_busy),
    .done           (sd_done),
    .r1             (sd_r1),
    .sd_present_out (sd_present_w),
    .data_addr      (sd_data_addr),
    .data_in        (sd_data_in),
    .data_we        (sd_data_we),
    .data_out       (sd_data_out),
    .SD_CS          (SD_CS),
    .SD_CLK         (SD_CLK),
    .SD_MOSI        (SD_MOSI),
    .SD_MISO        (SD_MISO),
    .SD_CD          (SD_CD)
);

//==============================================================================
// 10. SPRITE ENGINE
//==============================================================================

sprite_engine u_sprite_engine
(
    .clk           (clk25),
    .rst_n         (rst_n),

    // Z vga_timing
    .x             (x),
    .y             (y[8:0]),        // rzutowanie na 9 bitów
    .video_on      (video_on),

    // Rejestry konfiguracji X
    .spr_x_0       (spr_x_0),
    .spr_x_1       (spr_x_1),
    .spr_x_2       (spr_x_2),
    .spr_x_3       (spr_x_3),
    .spr_x_4       (spr_x_4),
    .spr_x_5       (spr_x_5),
    .spr_x_6       (spr_x_6),
    .spr_x_7       (spr_x_7),

    // Rejestry konfiguracji Y
    .spr_y_0       (spr_y_0),
    .spr_y_1       (spr_y_1),
    .spr_y_2       (spr_y_2),
    .spr_y_3       (spr_y_3),
    .spr_y_4       (spr_y_4),
    .spr_y_5       (spr_y_5),
    .spr_y_6       (spr_y_6),
    .spr_y_7       (spr_y_7),

    // Rejestry kontrolne (flip_x, flip_y, enable)
    .spr_ctrl_0    (spr_ctrl_0),
    .spr_ctrl_1    (spr_ctrl_1),
    .spr_ctrl_2    (spr_ctrl_2),
    .spr_ctrl_3    (spr_ctrl_3),
    .spr_ctrl_4    (spr_ctrl_4),
    .spr_ctrl_5    (spr_ctrl_5),
    .spr_ctrl_6    (spr_ctrl_6),
    .spr_ctrl_7    (spr_ctrl_7),

    // Zapis do BRAM (Port A) z cpu_ram
    .spr_we        (spr_we),
    .spr_addr      (spr_addr),
    .spr_data      (spr_data),

    // Wyjœcie
    .sprite_pixel  (sprite_pixel),
    .sprite_enable (sprite_enable)
);

//==============================================================================
// 11. BLINK KURSORA
//------------------------------------------------------------------------------
// Licznik do migania kursora tekstowego.
//==============================================================================

reg [25:0] blink_cnt;

always @(posedge clk25 or negedge rst_n)
begin
    if(!rst_n)
        blink_cnt <= 26'd0;
    else
        blink_cnt <= blink_cnt + 26'd1;
end

//==============================================================================
// 12. SK£ADANIE OBRAZU RGB
//------------------------------------------------------------------------------
// Priorytety:
//   1. Kursor tekstowy (kolor + inwersja)
//   2. Tekst
//   3. Sprite
//   4. Framebuffer
//==============================================================================

always @(posedge clk25 or negedge rst_n)
begin
    if(!rst_n)
    begin
        red   <= 3'b000;
        green <= 3'b000;
        blue  <= 2'b00;
    end
    else if(!clear_done || !video_on)
    begin
        red   <= 3'b000;
        green <= 3'b000;
        blue  <= 2'b00;
    end
    else
    begin
        // PRIORYTET 1: Kursor
        if(cursor_pixel && cursor_blink)
        begin
            red   <= cur_rgb[7:5];
            green <= cur_rgb[4:2];
            blue  <= cur_rgb[1:0];
        end
        // PRIORYTET 2: Tekst
        else if(text_enable)
        begin
            red   <= text_pixel[7:5];
            green <= text_pixel[4:2];
            blue  <= text_pixel[1:0];
        end
        // PRIORYTET 3: Sprite
        else if(sprite_enable)
        begin
            red   <= sprite_pixel[7:5];
            green <= sprite_pixel[4:2];
            blue  <= sprite_pixel[1:0];
        end
        // PRIORYTET 4: Framebuffer
        else
        begin
            if(fb_blank)
            begin
                red   <= pixel[7:5];
                green <= pixel[4:2];
                blue  <= pixel[1:0];
            end
            else
            begin
                red   <= 3'b000;
                green <= 3'b000;
                blue  <= 2'b00;
            end
        end
    end
end

endmodule