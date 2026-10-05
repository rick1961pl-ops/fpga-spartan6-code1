//==============================================================================
// text_engine.v - Silnik tekstowy 80x60 z kursorem
//------------------------------------------------------------------------------
// Opis:
//   Modu³ wyœwietla znaki tekstowe na ekranie VGA w trybie tekstowym 80x60.
//   Ka¿da komórka tekstowa to 16 bitów:
//     [7:0]  = kod ASCII znaku
//     [15:8] = kolor / atrybut znaku
//
//   Modu³ obs³uguje równie¿ kursor tekstowy (miganie, kolor, wysokoœæ).
//
// Wersje:
//   - USE_FONT_IN_LUT : fonty w LUT (szybsze, wiêcej zasobów)
//   - bez define      : fonty w RAM (wolniejsze, mniej zasobów)
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
// Fonty zaimplementowane jako funkcja kombinacyjna (case w font_rom).
// Adresowanie natychmiastowe - brak opóŸnienia RAM.
//==============================================================================

module text_engine
(
    //--------------------------------------------------
    // Zegar
    //--------------------------------------------------
    input  wire        clk,             // zegar 25 MHz

    //--------------------------------------------------
    // Wspó³rzêdne tekstu
    //--------------------------------------------------
    input  wire [9:0]  x_txt,           // wspó³rzêdna X (0..639)
    input  wire [8:0]  y_txt,           // wspó³rzêdna Y (0..479)

    //--------------------------------------------------
    // Wyjœcie piksela tekstu
    //--------------------------------------------------
    output reg  [7:0]  text_pixel,      // kolor piksela tekstu
    output reg         text_enable,     // 1 = piksel nale¿y do znaku

    //--------------------------------------------------
    // Bufor tekstowy
    //--------------------------------------------------
    input  wire [15:0] txt_data,        // dane z bufora (ASCII + atrybut)
    output wire [12:0] txt_addr,        // adres komórki tekstowej

    //--------------------------------------------------
    // Kursor
    //--------------------------------------------------
    input  wire [2:0]  cursor_height,   // wysokoœæ kursora (0 = wy³¹czony)
    input  wire [12:0] cursor_index,    // indeks kursora w buforze
    output reg         cursor_pixel     // 1 = piksel nale¿y do kursora
);

//==============================================================================
// 1. REJESTRY PIPELINE
//------------------------------------------------------------------------------
// OpóŸnienie sygna³ów dla kompensacji odczytu RAM.
//==============================================================================

reg [2:0]  pixel_y_r;                   // numer wiersza bitmapy (stopieñ 1)
reg [2:0]  pixel_y_rr;                  // numer wiersza bitmapy (stopieñ 2)
reg [15:0] txt_data_r;                  // dane tekstowe (stopieñ 1)
reg        cursor_here_r;               // czy znak pod kursorem (stopieñ 1)
reg        cursor_line_r;               // czy wiersz kursora (stopieñ 1)
reg        cursor_line_rr;              // czy wiersz kursora (stopieñ 2)

//==============================================================================
// 2. PIPELINE DANYCH TEKSTOWYCH I KURSORA
//==============================================================================

always @(posedge clk)
begin
    //--------------------------------------------------
    // Pierwszy stopieñ
    //--------------------------------------------------
    pixel_y_r     <= y_txt[2:0];
    txt_data_r    <= txt_data;
    cursor_here_r <= (txt_addr == cursor_index);

    cursor_line_r <=
        cursor_here_r &&
        (cursor_height != 3'd0) &&
        (pixel_y_r >= (4'd8 - {1'b0, cursor_height}));

    //--------------------------------------------------
    // Drugi stopieñ
    //--------------------------------------------------
    pixel_y_rr     <= pixel_y_r;
    cursor_line_rr <= cursor_line_r;
end

//==============================================================================
// 3. ADRESOWANIE BUFORA TEKSTOWEGO
//------------------------------------------------------------------------------
// char_x = X / 8 (numer kolumny 0..79)
// char_y = Y / 8 (numer wiersza 0..59)
//==============================================================================

wire [6:0] char_x;                      // numer kolumny tekstu
wire [5:0] char_y;                      // numer wiersza tekstu
wire [9:0] x_ascii;                     // X z kompensacj¹ opóŸnienia

// Kompensacja opóŸnienia odczytu RAM (fonty w LUT)
assign x_ascii = (x_txt < 10'd638) ? (x_txt + 10'd2) : 10'd0;

assign char_x = x_ascii[9:3];
assign char_y = y_txt[8:3];

wire [12:0] txt_addr_calc;
assign txt_addr_calc = char_y * 7'd80 + char_x;

// Ograniczenie adresu do obszaru 80 x 60 znaków
assign txt_addr =
    (char_x < 7'd80 && char_y < 6'd60) ?
        txt_addr_calc :
        13'd0;

//==============================================================================
// 4. FONT ROM
//==============================================================================

wire [7:0] bitmap;                      // bitmapa aktualnego wiersza

font_rom font
(
    .ascii  (txt_data_r[7:0]),          // kod ASCII znaku
    .row    (pixel_y_rr),               // numer wiersza bitmapy
    .pixels (bitmap)                    // 8 bitów bitmapy
);

//==============================================================================
// 5. WYŒWIETLANIE TEKSTU I KURSORA
//==============================================================================

always @(*)
begin
    text_enable  = 1'b0;
    text_pixel   = 8'h00;
    cursor_pixel = 1'b0;

    //--------------------------------------------------
    // Wyœwietlenie piksela znaku
    //--------------------------------------------------
    if (bitmap[7 - x_txt[2:0]])
    begin
        text_enable = 1'b1;
        text_pixel  = txt_data_r[15:8];
    end

    //--------------------------------------------------
    // Wyœwietlenie kursora
    //--------------------------------------------------
    if (cursor_line_rr)
    begin
        cursor_pixel = 1'b1;
    end
end

endmodule

`else

//==============================================================================
// WERSJA 2: FONTY W RAM
//------------------------------------------------------------------------------
// Fonty przechowywane w BRAM. Adresowanie z opóŸnieniem 1 taktu.
//==============================================================================

module text_engine
(
    //--------------------------------------------------
    // Zegar
    //--------------------------------------------------
    input  wire        clk,             // zegar 25 MHz

    //--------------------------------------------------
    // Wspó³rzêdne tekstu
    //--------------------------------------------------
    input  wire [9:0]  x_txt,           // wspó³rzêdna X (0..639)
    input  wire [8:0]  y_txt,           // wspó³rzêdna Y (0..479)

    //--------------------------------------------------
    // Wyjœcie piksela tekstu
    //--------------------------------------------------
    output reg  [7:0]  text_pixel,      // kolor piksela tekstu
    output reg         text_enable,     // 1 = piksel nale¿y do znaku

    //--------------------------------------------------
    // Bufor tekstowy
    //--------------------------------------------------
    input  wire [15:0] txt_data,        // dane z bufora (ASCII + atrybut)
    output wire [12:0] txt_addr,        // adres komórki tekstowej

    //--------------------------------------------------
    // Kursor
    //--------------------------------------------------
    input  wire [2:0]  cursor_height,   // wysokoœæ kursora (0 = wy³¹czony)
    input  wire [12:0] cursor_index,    // indeks kursora w buforze
    output reg         cursor_pixel     // 1 = piksel nale¿y do kursora
);

//==============================================================================
// 1. REJESTRY PIPELINE
//------------------------------------------------------------------------------
// OpóŸnienie sygna³ów dla kompensacji odczytu RAM fontów (1 takt).
//==============================================================================

reg [2:0]  pixel_y_r;                   // numer wiersza bitmapy (stopieñ 1)
reg [2:0]  x_txt_r;                     // X tekstu (stopieñ 1)
reg [15:0] txt_data_r;                  // dane tekstowe (stopieñ 1)
reg [15:0] txt_data_rr;                 // dane tekstowe (stopieñ 2)
reg        cursor_here_r;               // czy znak pod kursorem (stopieñ 1)
reg        cursor_line_r;               // czy wiersz kursora (stopieñ 1)
reg        cursor_line_rr;              // czy wiersz kursora (stopieñ 2)

//==============================================================================
// 2. PIPELINE DANYCH TEKSTOWYCH I KURSORA
//==============================================================================

always @(posedge clk)
begin
    pixel_y_r <= y_txt[2:0];
    x_txt_r   <= x_txt[2:0];

    txt_data_r  <= txt_data;
    txt_data_rr <= txt_data_r;

    cursor_here_r <= (txt_addr == cursor_index);

    cursor_line_r <=
        cursor_here_r &&
        (cursor_height != 3'd0) &&
        (pixel_y_r >= (4'd8 - {1'b0, cursor_height}));

    cursor_line_rr <= cursor_line_r;
end

//==============================================================================
// 3. ADRESOWANIE BUFORA TEKSTOWEGO
//------------------------------------------------------------------------------
// char_x = X / 8 (numer kolumny 0..79)
// char_y = Y / 8 (numer wiersza 0..59)
//==============================================================================

wire [6:0] char_x;                      // numer kolumny tekstu
wire [5:0] char_y;                      // numer wiersza tekstu
wire [9:0] x_ascii;                     // X z kompensacj¹ opóŸnienia

// Kompensacja opóŸnienia odczytu RAM (fonty w ROM)
assign x_ascii = (x_txt < 10'd638) ? (x_txt + 10'd2) : 10'd0;

assign char_x = x_ascii[9:3];
assign char_y = y_txt[8:3];

wire [12:0] txt_addr_calc;
assign txt_addr_calc = char_y * 7'd80 + char_x;

// Ograniczenie adresu do obszaru 80 x 60 znaków
assign txt_addr =
    (char_x < 7'd80 && char_y < 6'd60) ?
        txt_addr_calc :
        13'd0;

//==============================================================================
// 4. FONT ROM (RAM)
//==============================================================================

wire [7:0] bitmap;                      // bitmapa aktualnego wiersza

font_rom font
(
    .clk    (clk),
    .ascii  (txt_data_r[7:0]),          // kod ASCII znaku
    .row    (pixel_y_r),                // numer wiersza bitmapy
    .pixels (bitmap)                    // 8 bitów bitmapy
);

//==============================================================================
// 5. WYŒWIETLANIE TEKSTU I KURSORA
//==============================================================================

always @(*)
begin
    text_enable  = 1'b0;
    text_pixel   = 8'h00;
    cursor_pixel = 1'b0;

    //--------------------------------------------------
    // Wyœwietlenie piksela znaku (opóŸnienie o 1 piksel)
    //--------------------------------------------------
    if (bitmap[7 - x_txt_r[2:0]])
    begin
        text_enable = 1'b1;
        text_pixel  = txt_data_rr[15:8];
    end

    //--------------------------------------------------
    // Wyœwietlenie kursora
    //--------------------------------------------------
    if (cursor_line_rr)
    begin
        cursor_pixel = 1'b1;
    end
end

endmodule

`endif