
`include "config.vh"
// ============================================================================
// Interfejs wykonywania komend
//
// Parametry komendy nale¿y zapisaæ do pamiêci ram[].
//
// Kolejnoœæ wykonywania:
//
//   1. Zapis parametrów do ram[1]...ram[n].
//   2. Zapis numeru komendy do ram[0].
//   3. Modu³ rozpoczyna wykonywanie komendy.
//   4. Po zakoñczeniu w ram[15] pojawia siê STATUS_OK.
//
// Rejestry:
//
//   ram[0]  - numer komendy
//   ram[1]...ram[n] - parametry komendy
//   ram[15] - status wykonania
//
// Zapis do ram[0] jest sygna³em rozpoczêcia wykonywania komendy.
// ============================================================================

// -----------------------------------------------------------------------------
// CMD1 - Czyszczenie bufora graficznego
//
// Opis:
//   Czyœci ca³y bufor obrazu, ustawiaj¹c wszystkie piksele na kolor t³a.
//
// Parametry:
//   Brak.
//
// Wynik:
//   Ca³y ekran graficzny zostaje wyczyszczony.
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
// -----------------------------------------------------------------------------
// CMD2 - Zapis pojedynczego piksela
//
// Opis:
//   Ustawia kolor jednego piksela o podanych wspó³rzêdnych.
//
// Parametry:
//   ram[1] - m³odszy bajt wspó³rzêdnej X
//   ram[2] - starszy bajt wspó³rzêdnej X
//   ram[3] - wspó³rzêdna Y
//   ram[4] - kolor piksela
//
// Wspó³rzêdne:
//   X = {ram[2], ram[1]}
//   Y = ram[3]
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
// -----------------------------------------------------------------------------
// CMD3 - Rysowanie wype³nionego prostok¹ta
//
// Opis:
//   Rysuje prostok¹t wype³niony wskazanym kolorem.
//
// Parametry:
//   ram[1] - X1 LSB
//   ram[2] - X1 MSB
//   ram[3] - Y1 LSB
//   ram[4] - Y1 MSB
//
//   ram[5] - X2 LSB
//   ram[6] - X2 MSB
//   ram[7] - Y2 LSB
//   ram[8] - Y2 MSB
//
//   ram[9] - kolor wype³nienia
//
// Wspó³rzêdne:
//   X1 = {ram[2], ram[1]}
//   Y1 = {ram[4], ram[3]}
//   X2 = {ram[6], ram[5]}
//   Y2 = {ram[8], ram[7]}
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
// -----------------------------------------------------------------------------
// CMD4 - Rysowanie ramki prostok¹ta
//
// Opis:
//   Rysuje obrys prostok¹ta bez wype³nienia.
//
// Parametry:
//   ram[1] - X1 LSB
//   ram[2] - X1 MSB
//   ram[3] - Y1 LSB
//   ram[4] - Y1 MSB
//
//   ram[5] - X2 LSB
//   ram[6] - X2 MSB
//   ram[7] - Y2 LSB
//   ram[8] - Y2 MSB
//
//   ram[9] - kolor ramki
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
// -----------------------------------------------------------------------------
// CMD5 - Zapis znaku w okreœlonym miejscu
//
// Opis:
//   Zapisuje pojedynczy znak ASCII pod wskazanymi wspó³rzêdnymi tekstowymi.
//
// Parametry:
//   ram[1] - kolumna tekstowa
//   ram[2] - wiersz tekstowy
//   ram[3] - kod ASCII znaku
//   ram[4] - atrybut znaku
//
// Atrybut:
//   Bajt okreœlaj¹cy sposób wyœwietlania znaku
//   (np. kolor tekstu i t³a).
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
//   Po wykonaniu w ram[1],ram[2] znajduja siê aktualne wspolrzedne kursora tekstowego
// -----------------------------------------------------------------------------
// CMD6 - Czyszczenie ekranu tekstowego
//
// Opis:
//   Czyœci ca³y bufor tekstowy, wpisuj¹c spacje z domyœlnym atrybutem.
//
// Parametry:
//   Brak.
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
//   Po wykonaniu w ram[1],ram[2] znajduja siê aktualne wspolrzedne kursora tekstowego
// -----------------------------------------------------------------------------
// CMD7 - Dopisanie znaku
//
// Opis:
//   Zapisuje znak w bie¿¹cej pozycji kursora.
//   Po zapisaniu znaków kursor jest automatycznie przesuwany
//   do nastêpnej pozycji.
//
// Parametry:
//   ram[3] - kod ASCII znaku
//   ram[4] - atrybut znaku
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
//   Po wykonaniu w ram[1],ram[2] znajduja siê aktualne wspolrzedne kursora tekstowego
// -----------------------------------------------------------------------------
// Kursor tekstowy
//
// Opis:
//   Steruje sprzêtowym kursorem wyœwietlanym w trybie tekstowym VGA.
//   Konfiguracja kursora odbywa siê przez zapis do rejestru ram[14].
//   Pozycja kursora jest wyznaczana automatycznie na podstawie
//   wskaŸnika text_index.
//
// Rejestr ram[14]:
//
//   bit7   - miganie kursora
//            0 = wy³¹czone
//            1 = w³¹czone
//
//   bit6   - prêdkoœæ migania
//            0 = wolne
//            1 = szybkie
//
//   bit5:3 - kolor kursora
//            000 = inwersja koloru znaku
//            001 = czarny
//            010 = czerwony
//            011 = zielony
//            100 = niebieski
//            101 = ¿ó³ty
//            110 = cyjan
//            111 = bia³y
//
//   bit2:0 - wysokoœæ kursora
//            0 = kursor wy³¹czony
//            1..7 = wysokoœæ kursora w liniach znaku
//
// Przyk³ady:
//
//   0x00 - kursor wy³¹czony
//
//   0x03 - inwersja, wysokoœæ 3, bez migania
//   0x13 - czerwony, wysokoœæ 3, bez migania
//   0x23 - niebieski, wysokoœæ 3, bez migania
//   0x3B - bia³y, wysokoœæ 3, bez migania
//
//   0x83 - inwersja, wysokoœæ 3, miganie wolne
//   0x93 - czerwony, wysokoœæ 3, miganie wolne
//   0xBB - bia³y, wysokoœæ 3, miganie wolne
//
//   0xC3 - inwersja, wysokoœæ 3, miganie szybkie
//   0xD3 - czerwony, wysokoœæ 3, miganie szybkie
//   0xFB - bia³y, wysokoœæ 3, miganie szybkie
//
// Uwagi:
//   Miganie realizowane jest sprzêtowo i nie wymaga obs³ugi programowej.
//   Pozycja kursora wyznaczana jest automatycznie na podstawie text_index.
//   Domyœlny tryb pracy (kolor = 000) rysuje kursor przez odwrócenie koloru
//   znaku, dziêki czemu jest on widoczny niezale¿nie od ustawionego koloru
//   tekstu.
// -----------------------------------------------------------------------------
// CMD8 - Ustawienie po³o¿enia kursora tekstowego
//
// Opis:
//   Ustawia po³o¿enie kursora tekstowego bez modyfikowania zawartoœci
//   bufora tekstowego.
//
// Parametry:
//   ram[1] - kolumna tekstowa (X)
//   ram[2] - wiersz tekstowy (Y)
//
// Wspó³rzêdne:
//   X = ram[1]
//   Y = ram[2]
//
// Dzia³anie:
//   Komenda ustawia rejestry po³o¿enia kursora oraz oblicza now¹
//   wartoœæ wskaŸnika text_index.
//
//   text_index = Y * 80 + X
//
// Status:
//   Po zakoñczeniu wykonywania w ram[15] zapisywany jest STATUS_OK.
//   Po wykonaniu w ram[1] i ram[2] znajduj¹ siê aktualne wspó³rzêdne
//   kursora tekstowego.
//
// Uwagi:
//   Komenda nie zapisuje ¿adnych danych do bufora tekstowego.
//   Zmianie ulega wy³¹cznie po³o¿enie kursora.
// -----------------------------------------------------------------------------
// CMD9 - CMD_SET_PIXEL
//
// Ustawienie bie¿¹cej pozycji kursora graficznego.
//
// Parametry:
// ram[1] = X LSB
// ram[2] = X MSB
// ram[3] = Y LSB
// ram[4] = Y MSB
//
// Zakres ekranu:
// X = 0 .. 639
// Y = 0 .. 479
//
// Je¿eli wartoœæ wykracza poza ekran:
// X > 639 › X = 639
// Y > 479 › Y = 479
//
// Obliczenie liniowego adresu framebuffer:
// pixel_index = Y * 640 + X
//
// Komenda nie zapisuje piksela.
// Ustawia tylko bie¿¹cy wskaŸnik pixel_index.
// -----------------------------------------------------------------------------
// CMD10 - CMD_PUT_PIXEL
//
// Zapis piksela na aktualnej pozycji graficznej.
//
// Pozycja:
// pixel_index
//
// Kolor:
// ram[3]
// -----------------------------------------------------------------------------
// CMD20 - CMD_SD_SEND
// Wysy³anie komendy do karty SD.
//
// Parametry:
//   ram[1] - numer komendy SD
//   ram[2] - argument [31:24]
//   ram[3] - argument [23:16]
//   ram[4] - argument [15:8]
//   ram[5] - argument [7:0]
//   ram[6] - CRC komendy SD
//
// Wynik:
//   ram[10] - odpowiedŸ R1 z karty SD
//
// Status:
//   ram[15], bit STATUS_SD
//       0 - komenda SD jest wykonywana
//       1 - komenda SD zosta³a zakoñczona
//
// Kolejnoœæ wykonania:
//   1. CPU zapisuje numer komendy do ram[1].
//   2. CPU zapisuje 32-bitowy argument do ram[2]...ram[5].
//   3. CPU zapisuje CRC do ram[6].
//   4. CPU zapisuje numer CMD_SD_SEND do ram[0].
//   5. FPGA wysy³a komendê do karty SD.
//   6. FPGA oczekuje na sygna³ sd_done.
//   7. Po zakoñczeniu odpowiedŸ R1 zostaje zapisana do ram[10].
//   8. Bit STATUS_SD w ram[15] zostaje ustawiony na 1.
//
// Przyk³ad CMD0:
//   ram[1] = 8'h00
//   ram[2] = 8'h00
//   ram[3] = 8'h00
//   ram[4] = 8'h00
//   ram[5] = 8'h00
//   ram[6] = 8'h95
//   ram[0] = CMD_SD_SEND
// -----------------------------------------------------------------------------

module cpu_ram
(
	input  wire clk,
	input  wire rst_n,
	// sterowanie buforem
	output reg ENABLE,
	output reg DIR,
	input  wire [4:0] addr,
	inout  wire [7:0] data,
	// interfejs dla CPU
	input  wire CE_n,
	input  wire OE_n,
	input  wire WE_n,
	// interfejs do sram_ctrl
	output reg wr_req,
	output reg [18:0] wr_addr,
	output reg [7:0]  wr_data,
	input  wire wr_done,
	output reg txt_we,
	output reg [12:0] txt_addr,
	output reg [15:0] txt_data,
	output [12:0] cursor_index,										// bie¿¹ce po³o¿enie indeksu w buforze tekstowym
	output [7:0] cursor_ctrl,										// rejestr kontrolny kursora
	output INT,
	output reg uart_enable,
	inout ps2_clk,
	inout ps2_data,
	input  uart_rxd,
	output uart_txd,
	input  RTS,
	output [7:0] debug_port,	
	output reg soft_reset,
    output reg  sd_start,											// obsluga karty SD
    output reg  [5:0]  sd_cmd,
    output reg  [31:0] sd_arg,
    output reg  [7:0]  sd_crc,
	input wire sd_busy,
	input wire sd_done,
	input wire [7:0]  sd_r1,
	input wire sd_present_in,   									// 1 = karta SD w gnieŸdzie
	//input wire sd_token_fe_seen,
	output reg  [8:0] sd_data_addr,
	output reg  [7:0] sd_data_in,
	output reg sd_data_we,
	input wire  [7:0] sd_data_out,
	output wire SD_VCC,
	output wire sd_power_on,
	// Sprite Engine - zapis do BRAM
	output reg spr_we,
	output reg  [11:0] spr_addr,
	output reg  [7:0]  spr_data,
	// Sprite Engine - rejestry konfiguracji
	output wire [9:0]  spr_x_0,  spr_x_1,  spr_x_2,  spr_x_3,
	output wire [9:0]  spr_x_4,  spr_x_5,  spr_x_6,  spr_x_7,
	output wire [8:0]  spr_y_0,  spr_y_1,  spr_y_2,  spr_y_3,
	output wire [8:0]  spr_y_4,  spr_y_5,  spr_y_6,  spr_y_7,
	output wire [3:0]  spr_ctrl_0,  spr_ctrl_1,  spr_ctrl_2,  spr_ctrl_3,
	output wire [3:0]  spr_ctrl_4,  spr_ctrl_5,  spr_ctrl_6,  spr_ctrl_7,
	//==================================================
	output wire fb_blank
);

`include "fpga_regs.vh"


//------------------------------------------------------------------------------
// Pamiêæ RAM rejestrów CPU
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Pamiêæ RAM rejestrów CPU
//------------------------------------------------------------------------------
reg [7:0] ram [0:15];
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Sprite Engine — rejestry konfiguracji 8 sprite'ów
//------------------------------------------------------------------------------
reg [9:0]  spr_x [0:7];    // X (10 bitów)
reg [8:0]  spr_y [0:7];    // Y (9 bitów)
reg [3:0]  spr_ctrl [0:7];    // bit 0=flip_x, bit 1=flip_y, bit 2=enable

//------------------------------------------------------------------------------
// Sprite Engine — sesja ³adowania
//------------------------------------------------------------------------------
reg spr_load_active;
reg [11:0] spr_load_ptr;


//------------------------------------------------------------------------------
// Bufor grafiki
//------------------------------------------------------------------------------
reg [18:0] framebuffer_addr;										// adres aktualnego piksela
reg [18:0] pixel_index;    // bie¿¹ca pozycja kursora graficznego
reg [9:0]  x;														// pomocniczy licznik X dla rysowania
reg [8:0]  y;														// pomocniczy licznik Y dla rysowania


//------------------------------------------------------------------------------
// Bufor tekstowy
//------------------------------------------------------------------------------
// SLICE
reg [12:0] text_index;
reg [12:0] text_clear_index;
reg [12:0] txt_index_tmp;

//------------------------------------------------------------------------------
// Sterowanie FSM
//------------------------------------------------------------------------------
reg [3:0] state;
reg [7:0] command;
reg ram0_valid;
reg put_text_repeat;												// flaga repetycji
//------------------------------------------------------------------------------
// Magistrala CPU
//------------------------------------------------------------------------------
reg [1:0] we_sync;
reg [4:0] addr_latch;
reg [7:0] data_latch;
reg [7:0] debug_data;
reg fb_blank_reg;
//------------------------------------------------------------------------------
// Przerwania
//------------------------------------------------------------------------------
(* KEEP = "TRUE" *)  reg [7:0] irq_flags;							// rejestr aktywnych flag przerwañ
reg [7:0] clear_bits;												// rejestr kasowania flag przerwañ
reg [7:0] enable_irq;												// maska zezwolenia na przerwania
reg rts_old;														// poprzednia wartosci pinu RTS
reg rts_sync1;														// dwutaktowa synchronizacja RTS
reg rts_sync2;														// dwutaktowa synchronizacja RTS
reg rts_init;														// flaga fa³szywej reakcji na RTS
//------------------------------------------------------------------------------
// Timer
//------------------------------------------------------------------------------
reg [4:0] div_value;												// wybór podzia³u czêstotliwoœci
reg [7:0] div_cnt;													// licznik preskalera
reg [7:0] div_limit;												// aktualny limit podzia³u
reg [7:0] timer8_cnt;												// licznik 8-bitowego timera
reg [7:0] timcfg;													// konfiguracja timera
reg [7:0] timer8_reload;											// wartoœæ prze³adowania timera


//------------------------------------------------------------------------------
// Generatory pseudolosowe
//------------------------------------------------------------------------------
reg [7:0]  random8;													// generator 8-bitowy LFSR
reg [15:0] random16;												// generator 16-bitowy LFSR

//------------------------------------------------------------------------------
// ALU
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// ALU — opcjonalne przez USE_ALU16
//------------------------------------------------------------------------------
`ifdef USE_ALU16
	wire [31:0] alu_result;
	wire [7:0]  alu_flags;
	wire alu_done;
	reg [4:0] alu_cmd;
	reg alu_start;
`else
	wire [31:0] alu_result = 32'd0;
	wire [7:0]  alu_flags  = 8'd0;
	wire alu_done          = 1'b0;
`endif

//------------------------------------------------------------------------------
// Kursor tekstowy
//------------------------------------------------------------------------------
assign cursor_ctrl  = ram[REG_CURSOR_CTRL];
assign cursor_index = text_index;
assign debug_port = ~debug_data;
assign fb_blank = fb_blank_reg;

//------------------------------------------------------------------------------
// Sprite Engine — pod³¹czenie rejestrów do portów wyjœciowych
//------------------------------------------------------------------------------
assign spr_x_0  = spr_x[0];
assign spr_x_1  = spr_x[1];
assign spr_x_2  = spr_x[2];
assign spr_x_3  = spr_x[3];
assign spr_x_4  = spr_x[4];
assign spr_x_5  = spr_x[5];
assign spr_x_6  = spr_x[6];
assign spr_x_7  = spr_x[7];
assign spr_y_0  = spr_y[0];
assign spr_y_1  = spr_y[1];
assign spr_y_2  = spr_y[2];
assign spr_y_3  = spr_y[3];
assign spr_y_4  = spr_y[4];
assign spr_y_5  = spr_y[5];
assign spr_y_6  = spr_y[6];
assign spr_y_7  = spr_y[7];
assign spr_ctrl_0 = spr_ctrl[0];
assign spr_ctrl_1 = spr_ctrl[1];
assign spr_ctrl_2 = spr_ctrl[2];
assign spr_ctrl_3 = spr_ctrl[3];
assign spr_ctrl_4 = spr_ctrl[4];
assign spr_ctrl_5 = spr_ctrl[5];
assign spr_ctrl_6 = spr_ctrl[6];
assign spr_ctrl_7 = spr_ctrl[7];

`ifdef USE_ALU16
	wire [15:0] alu_a;
	wire [15:0] alu_b;
	assign alu_a = {ram[REG_PARAM2],ram[REG_PARAM1]};				// mapowanie parametrów komendy ALU na adresy wejsciowe
	assign alu_b = {ram[REG_PARAM4],ram[REG_PARAM3]};
`endif

localparam [18:0] FRAMEBUFFER_SIZE = 19'd307200;

//==================================================
// Flagi dla FSM
//==================================================
localparam [3:0] ST_IDLE			= 4'd0;
localparam [3:0] ST_DECODE			= 4'd1;
localparam [3:0] ST_EXECUTE			= 4'd2;
localparam [3:0] ST_WAIT			= 4'd3;
localparam [3:0] ST_NEXT			= 4'd4;
localparam [3:0] ST_FINISH			= 4'd5;
localparam [3:0] ST_SD_READ_WAIT	= 4'd6;
localparam [3:0] ST_SD_READ_WAIT2	= 4'd7;

//==================================================
// Parametry bufora tekstowego
//==================================================
localparam [7:0] TEXT_COLS			= 8'd80;						// liczba kolumn tekstu
localparam [7:0] TEXT_ROWS			= 8'd60;						// liczba wierszy tekstu
localparam [12:0] TEXT_CELLS 		= 13'd4800;						// liczba komórek bufora tekstowego

//------------------------------------------------------------------------------
// RTC - Unix timestamp
//------------------------------------------------------------------------------

reg [31:0] unix_time;
reg [24:0] unix_div_cnt;
//------------------------------------------------------------------------------
// UART
//------------------------------------------------------------------------------

wire [7:0] uart_data;
wire uart_rx_ready;
wire uart_tx_busy;
wire uart_irq_rx;
wire uart_irq_tx;
wire uart_wr;
wire uart_rd;

//------------------------------------------------------------------------------
// Klawiatura PS/2
//------------------------------------------------------------------------------

wire [7:0] ps2_rx_data;												// odebrany bajt z klawiatury
wire ps2_rx_ready;													// impuls gotowoœci danych
wire ps2_busy;														// zajêtoœæ nadajnika
reg ps2_start;														// rozpoczêcie transmisji PS/2
reg [7:0]  ps2_tx_data;												// dane wysy³ane do klawiatury
reg [25:0] ps2_delay_cnt;											// licznik opóŸnienia startu
reg [23:0] ps2_led_delay_cnt;										// licznik opóŸnienia LED


//------------------------------------------------------------------------------
// Sekwencja inicjalizacji klawiatury PS/2
//------------------------------------------------------------------------------
localparam PS2_INIT_IDLE  = 3'd0;									// oczekiwanie po resecie
localparam PS2_INIT_WAIT1 = 3'd1;									// oczekiwanie na ACK po RESET
localparam PS2_LED_CMD    = 3'd2;									// wys³anie komendy ED
localparam PS2_LED_DATA   = 3'd3;									// wys³anie danych LED
localparam PS2_INIT_DONE  = 3'd4;									// koniec inicjalizacji
localparam PS2_LED_DELAY  = 3'd5;									// opóŸnienie pomiêdzy LED
localparam PS2_UPDATE_LED = 3'd6;					
localparam PS2_UPDATE_DATA = 3'd7;

reg [2:0] ps2_init;													// stan inicjalizacji PS/2
reg [2:0] ps2_led_step;												// krok testu LED
reg caps_lock_old;													// rejestr poprzedniej wartoœci klawisza CAPS
reg num_lock_old;													// rejestr poprzedniej wartoœci klawisza NUM
reg scroll_lock_old;												// rejestr poprzedniej wartoœci klawisza SCROLL
reg sd_vcc_en;   													// 1 = w³¹czone wewnêtrznie, 0 = wy³¹czone
assign SD_VCC = ~sd_vcc_en;   										// pin: 1 = OFF, 0 = ON
assign sd_power_on = sd_vcc_en;
//------------------------------------------------------------------------------
// Modu³ sprzêtowego kontrolera UART
//------------------------------------------------------------------------------
uart u_uart
(
    .clk(clk),
    .rst_n(rst_n),
    .rxd(uart_rxd),
    .txd(uart_txd),
    .data_in(data_latch),
    .data_out(uart_data),
    .wr(uart_wr),
    .rd(uart_rd),
	 .baud_sel(ram[REG_CFG][7:4]),
    .rx_ready(uart_rx_ready),
    .tx_busy(uart_tx_busy),
    .irq_rx(uart_irq_rx),
    .irq_tx(uart_irq_tx)
);

//------------------------------------------------------------------------------
// Modu³ sprzêtowego kontrolera PS/2
//------------------------------------------------------------------------------
ps2_keyboard u_ps2
(
	.clk(clk),														// zegar FPGA
	.rst_n(rst_n),													// reset aktywny niski
	.ps2_clk(ps2_clk),												// linia zegara PS/2
	.ps2_data(ps2_data),											// linia danych PS/2
	.start(ps2_start),												// rozpoczêcie nadawania
	.tx_data(ps2_tx_data),											// dane nadajnika
	.rx_data(ps2_rx_data),											// odebrane dane
	.rx_ready(ps2_rx_ready),										// gotowoœæ odebranych danych
	.busy(ps2_busy)													// stan zajêtoœci
);


//------------------------------------------------------------------------------
// Dekoder kodów klawiatury PS/2
//------------------------------------------------------------------------------
wire [7:0] ps2_key_code;											// kod ASCII klawisza
wire ps2_key_ready;													// gotowoœæ znaku
wire caps_lock;														// stan CAPS LOCK
wire num_lock;														// stan NUM LOCK
wire scroll_lock;													// stan SCROLL LOCK

ps2_decoder u_ps2_decoder
(
	.clk(clk),														// zegar FPGA
	.rst_n(rst_n),													// reset
	.rx_data(ps2_rx_data),											// kod skanowany PS/2
	.rx_ready(ps2_rx_ready),										// nowy kod
	.key_code(ps2_key_code),										// znak ASCII
	.key_ready(ps2_key_ready),										// gotowy znak
	.caps_lock(caps_lock),											// stan CAPS
	.num_lock(num_lock),											// stan NUM
	.scroll_lock(scroll_lock)										// stan SCROLL
);


//==================================================
// Instancja ALU 16-bit
//==================================================
`ifdef USE_ALU16
	alu16 u_alu
	(
		.clk    (clk),												// zegar
		.rst_n  (rst_n),											// reset
		.start  (alu_start),										// start operacji
		.cmd    (alu_cmd),											// kod operacji
		.a      (alu_a),											// operand A
		.b      (alu_b),											// operand B
		.done   (alu_done),											// zakoñczenie operacji
		.result (alu_result),										// wynik
		.flags  (alu_flags)											// flagi ALU
	);
`endif

//==================================================
// Dekoder preskalera timera
//==================================================
always @*
begin
	case(div_value)

		DIV_OFF: div_limit = 8'd0;									// timer zatrzymany
		DIV_2:   div_limit = 8'd2;									// podzia³ przez 2
		DIV_4:   div_limit = 8'd4;									// podzia³ przez 4
		DIV_8:   div_limit = 8'd8;									// podzia³ przez 8
		DIV_16:  div_limit = 8'd16;									// podzia³ przez 16
		DIV_32:  div_limit = 8'd32;									// podzia³ przez 32
		DIV_64:  div_limit = 8'd64;									// podzia³ przez 64
		DIV_128: div_limit = 8'd128;								// podzia³ przez 128
		DIV_255: div_limit = 8'd255;								// podzia³ maksymalny
		default: div_limit = 8'd0;									// zabezpieczenie
	endcase
end


//------------------------------------------------------------------------------
// Wyjœcie przerwania
//------------------------------------------------------------------------------

assign INT = |(irq_flags & enable_irq);								// aktywne gdy ustawione i odblokowane przerwanie

//==================================================
// Synchronizacja WE_n
//==================================================

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		we_sync <= 2'b11;											// stan nieaktywny WE
	end
	else
	begin
		we_sync <= {we_sync[0], WE_n};								// przesuniêcie synchronizatora
	end
end


wire we_rise = ~we_sync[1] & we_sync[0];							// wykrycie zbocza narastaj¹cego WE

// zezwolenie na wysy³kê przez UART
assign uart_wr = we_rise && (addr_latch == REG_UART_DATA) && ram[REG_CFG][1];
// zezwolenie na odbiór przez UART
assign uart_rd = (!CE_n) && (!OE_n) && (addr_latch == REG_UART_DATA) && ram[REG_CFG][0];
// kasowanie flagi PS2 przy odczycie rejestru 
wire ps2_rd;
assign ps2_rd = (!CE_n) && (!OE_n) && (addr_latch == REG_PS2_DATA);
//==================================================
// Zatrzaski adresu i danych magistrali CPU
//==================================================
//
// Adres oraz dane s¹ próbkowane ca³y czas podczas aktywnego CE.
// Dziêki temu dane s¹ stabilne w momencie wykrycia zakoñczenia
// impulsu zapisu WE.
//

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		addr_latch <= 5'd0;											// wyzerowanie adresu
		data_latch <= 8'd0;											// wyzerowanie danych
	end
	else
	begin
		if(!CE_n)
		begin
			addr_latch <= addr;										// zapamiêtanie adresu CPU
			data_latch <= data;										// zapamiêtanie danych CPU
		end
	end
end

//==================================================
// Multiplekser odczytu (bez 'bz) - wartosc kombinacyjna
// Uzywa addr_latch (stabilny przez caly odczyt)
//==================================================
wire [7:0] read_mux =
    (addr_latch <= 5'd15)          ? ram[addr_latch] :
    (addr_latch == REG_INT_FLAGS)  ? irq_flags :
    (addr_latch == REG_INT_ENABLE) ? enable_irq :
    (addr_latch == REG_DIV)        ? div_value :
    (addr_latch == REG_TIMER8_0)   ? timer8_cnt :
    (addr_latch == REG_TIMCFG)     ? timcfg :
    (addr_latch == REG_RELOAD)     ? timer8_reload :
    (addr_latch == REG_RANDOM8)    ? random8 :
    (addr_latch == REG_RANDOM16L)  ? random16[7:0] :
    (addr_latch == REG_RANDOM16H)  ? random16[15:8] :
`ifdef USE_ALU16
    (addr_latch == REG_ALU_RES0)   ? alu_result[7:0] :
    (addr_latch == REG_ALU_RES1)   ? alu_result[15:8] :
    (addr_latch == REG_ALU_RES2)   ? alu_result[23:16] :
    (addr_latch == REG_ALU_RES3)   ? alu_result[31:24] :
    (addr_latch == REG_ALU_FLAGS)  ? alu_flags :
`endif
    8'h00;

//==================================================
// Rejestr posredni (latch wyjsciowy) - Wariant C
//==================================================
reg [7:0] data_latch_out;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        data_latch_out <= 8'h00;
    else if(!OE_n && !CE_n && WE_n)
        data_latch_out <= read_mux;
end

//==================================================
// Wyjscie na magistrale - przelacznik + stabilny latch
//==================================================
assign data =
    (!CE_n && !OE_n && WE_n) ? data_latch_out : 8'bz;
//==================================================
// Zapis SRAM oraz obs³uga modu³ów
//==================================================

integer i;
// SLICE
//reg [12:0] cursor_x_tmp;
//reg [12:0] cursor_y_tmp;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		//--------------------------------------------------
		// RESET
		//--------------------------------------------------
	begin
		soft_reset <= 1'b0;
		debug_data <= 8'h00;
		fb_blank_reg <= 1'b1;
		//--------------------------------------------------
		// Czas Unix
		//--------------------------------------------------	
		unix_time   <= 32'd0;
		unix_div_cnt <= 25'd0;	
		//--------------------------------------------------
		// Odlaczenie TXD od FT232
		//--------------------------------------------------	
		uart_enable <= 1'b0;
		//--------------------------------------------------
		// Flaga rozpoczêcia komendy
		//--------------------------------------------------
		ram0_valid <= 1'b0;
		//--------------------------------------------------
		// Czyszczenie rejestrów RAM
		//--------------------------------------------------
		for(i = 0; i < 16; i = i + 1)
			ram[i] <= 8'h00;
		//--------------------------------------------------
		// FSM komend
		//--------------------------------------------------
		state   <= ST_IDLE;
		command <= 8'd0;
		put_text_repeat <= 1'b0;
		//--------------------------------------------------
		// Kontroler pamiêci grafiki
		//--------------------------------------------------
		wr_req  <= 1'b0;
		wr_addr <= 19'd0;
		wr_data <= 8'd0;
		//--------------------------------------------------
		// Bufor grafiki
		//--------------------------------------------------
		framebuffer_addr <= 19'd0;
		pixel_index <= 19'd0;
		x <= 10'd0;
		y <= 9'd0;
		//--------------------------------------------------
		// Bufor tekstowy
		//--------------------------------------------------
		txt_we <= 1'b0;
		txt_addr <= 13'd0;
		txt_data <= 16'd0;
		text_index <= 13'd0;
		text_clear_index <= 13'd0;
		//--------------------------------------------------
		// Bufor poziomów logicznych
		//--------------------------------------------------
		ENABLE <= 1'b1;
		DIR    <= 1'b1;
		//--------------------------------------------------
		// Przerwania
		//--------------------------------------------------
		clear_bits <= 8'b0;
		irq_flags  <= 8'h00;
		enable_irq <= 8'h00;
		rts_sync1 <= 1'b0;
		rts_sync2 <= 1'b0;
		rts_old   <= 1'b0;
		rts_init  <= 1'b0;
		//--------------------------------------------------
		// Timer
		//--------------------------------------------------
		div_value <= 5'b0;
		div_cnt <= 8'b0;
		timer8_cnt <= 8'b0;
		timcfg <= 8'b0;
		timer8_reload <= 8'b0;
		//--------------------------------------------------
		// Generatory pseudolosowe
		//--------------------------------------------------
		random8  <= 8'hA5;
		random16 <= 16'hACE1;
		//--------------------------------------------------
		// ALU
		//--------------------------------------------------
		`ifdef USE_ALU16
			alu_start <= 1'b0;
			alu_cmd   <= 5'd0;
		`endif
		//--------------------------------------------------
		// karta SD
		//--------------------------------------------------
		sd_start <= 1'b0;
		sd_data_we <= 1'b0;
		sd_cmd   <= 6'd0;
		sd_arg   <= 32'd0;
		sd_crc   <= 8'hFF;
		sd_data_addr <= 9'd0;
		sd_data_in   <= 8'd0;
		sd_data_we   <= 1'b0;
		sd_vcc_en <= 1'b0;    // pin SD_VCC = 1 = zasilanie WY£¥CZONE
		//--------------------------------------------------
		// PS/2
		//--------------------------------------------------
		ps2_start <= 1'b0;
		ps2_tx_data <= 8'h00;
		ps2_init <= PS2_INIT_IDLE;
		ps2_led_step <= 3'd0;
		ps2_delay_cnt <= 26'd0;
		ps2_led_delay_cnt <= 24'd0;
		caps_lock_old   <= 1'b0;
		num_lock_old    <= 1'b0;
		scroll_lock_old <= 1'b0;
		//--------------------------------------------------
		// Sprite Engine
		//--------------------------------------------------
		spr_we   <= 1'b0;
		spr_addr <= 12'd0;
		spr_data <= 8'd0;
		spr_load_active <= 1'b0;
		spr_load_ptr    <= 12'd0;
		// Wyzeruj konfiguracjê sprite'ów
		for(i = 0; i < 8; i = i + 1) begin
			spr_x[i]    <= 10'd0;
			spr_y[i]    <= 9'd0;
			spr_ctrl[i] <= 4'd0;
		end	
	end
	else
	begin
		soft_reset <= 1'b0;
		//--------------------------------------------------
		// CZas Unix powiekszenie licznika
		//--------------------------------------------------	
		if(unix_div_cnt == 25'd24999999)
			begin
				unix_div_cnt <= 25'd0;
				unix_time <= unix_time + 32'd1;
			end
		else
			begin
				unix_div_cnt <= unix_div_cnt + 25'd1;
			end	
		//==================================================
		// SD - domyœlnie sygna³ START jest impulsem 1 cykl
		//==================================================
		sd_start <= 1'b0;
		sd_data_we <= 1'b0;
	
		//==================================================
		// Sprite Engine - domyœlnie spr_we = 0 (impuls 1 takt)
		//==================================================
		spr_we <= 1'b0;
		//==================================================
		// Synchronizacja RTS - 2 takty
		//==================================================
		rts_sync1 <= RTS;
		rts_sync2 <= rts_sync1;

		//==================================================
		// Inicjalizacja stanu RTS po resecie
		// Nie generuje przerwania
		//==================================================
		if (!rts_init)
		begin
			rts_old  <= rts_sync2;
			rts_init <= 1'b1;
		end
		else
		begin
			//==================================================
			// Przerwanie przy ka¿dej zmianie RTS
			//==================================================
			if (rts_sync2 != rts_old)
			begin
				if (enable_irq[IRQ_RTS])
					irq_flags[IRQ_RTS] <= 1'b1;
			end
			rts_old <= rts_sync2;
		end
		
		//--------------------------------------------------
		// Aktualizacja LED klawiatury PS/2
		//--------------------------------------------------
		if(ps2_init == PS2_INIT_DONE)
			begin
				if((caps_lock   != caps_lock_old) ||
					(num_lock    != num_lock_old) ||
					(scroll_lock != scroll_lock_old))
					begin
						caps_lock_old   <= caps_lock;
						num_lock_old    <= num_lock;
						scroll_lock_old <= scroll_lock;
						if(!ps2_busy)
							begin
								ps2_tx_data <= 8'hED;
								ps2_start   <= 1'b1;
								ps2_init <= PS2_UPDATE_LED;
							end
					end
			end
		//--------------------------------------------------
		// Odbiór znaku z klawiatury PS/2
		//--------------------------------------------------
		if (ps2_rd)
			begin
				ram[REG_STATUS_VGA][STATUS_PS2] <= 1'b0;
			end
		else if(ps2_key_ready && ps2_key_code != 8'h00)
			begin
				ram[REG_PS2_DATA] <= ps2_key_code;
				ram[REG_STATUS_VGA][STATUS_PS2] <= 1'b1;
				if(enable_irq[IRQ_PS2])
					irq_flags[IRQ_PS2] <= 1'b1;
			end			
		//--------------------------------------------------
		// Obs³uga UART
		//--------------------------------------------------		
		if (uart_rx_ready && ram[REG_CFG][0])
			ram[REG_UART_DATA] <= uart_data;
		ram[REG_STATUS_VGA][STATUS_UART_RXD] <= uart_rx_ready;					// ustawienie flagi w rejestrze statusu ¿e zakoñczono odbiór
		ram[REG_STATUS_VGA][STATUS_UART_TXD] <= uart_tx_busy;					// ustawienie flagi w rejestrze statusu ¿e zakoñczono nadawanie

		if (uart_irq_rx && ram[REG_CFG][RX_ENABLE] && enable_irq[IRQ_UART_RX])	// ustawienie flag przerwania od nadajnika i odbiornika
			begin																// pod warunkiem ¿e w³aczono zezwoelnie na przerwanie
				irq_flags[IRQ_UART_RX] <= 1'b1;
			end
		if (uart_irq_tx && ram[REG_CFG][TX_ENABLE] && enable_irq[IRQ_UART_TX])
			begin
				irq_flags[IRQ_UART_TX] <= 1'b1;
			end
		//--------------------------------------------------
		// Generator pseudolosowy 8-bit
		//--------------------------------------------------
		random8 <=
		{
			random8[6:0],
			random8[7] ^ random8[5] ^ random8[4] ^ random8[3]
		};
		//--------------------------------------------------
		// Generator pseudolosowy 16-bit
		//--------------------------------------------------
		random16 <=
		{
			random16[14:0],
			random16[15] ^ random16[13] ^ random16[12] ^ random16[10]
		};
		//--------------------------------------------------
		// Przerwanie od zakoñczenia ALU
		//--------------------------------------------------
		`ifdef USE_ALU16
			if(alu_done)
				irq_flags[IRQ_ALU] <= 1'b1;
		`endif
		//--------------------------------------------------
		// Timer 8-bit
		//--------------------------------------------------
		if(div_limit != 8'd0)
		begin
			if(div_cnt == (div_limit - 8'd1))
			begin
				div_cnt <= 8'd0;

				if(timer8_cnt == 8'hFF)
				begin
					irq_flags[IRQ_TIMER8_OVF] <= 1'b1;

					if(timcfg[TIMCFG_AUTORELOAD])
						timer8_cnt <= timer8_reload;
					else
						timer8_cnt <= 8'd0;
				end
				else
				begin
					timer8_cnt <= timer8_cnt + 8'd1;
				end
			end
			else
			begin
				div_cnt <= div_cnt + 8'd1;
			end
		end
		else
		begin
			div_cnt <= 8'd0;
		end
		//--------------------------------------------------
		// Domyœlne ustawienia magistrali i pamiêci tekstowej
		//--------------------------------------------------
		txt_we <= 1'b0;
		//--------------------------------------------------
		// ALU - impuls start
		//--------------------------------------------------
		`ifdef USE_ALU16
			alu_start <= 1'b0;
		`endif
		//--------------------------------------------------
		// Sterowanie buforem przez CPU
		//--------------------------------------------------
		if(!CE_n && !WE_n && OE_n)
			begin
				ENABLE <= 1'b0;
				DIR    <= 1'b0;   // CPU › FPGA
			end
		else if(!CE_n && WE_n && !OE_n)
			begin
				ENABLE <= 1'b0;
				DIR    <= 1'b1;   // FPGA › CPU
			end
		else
			begin
				ENABLE <= 1'b1;   // bufor wy³¹czony
				DIR    <= 1'b1;
		end
		//--------------------------------------------------
		// Obs³uga zakoñczenia zapisu CPU
		//--------------------------------------------------
		if(we_rise)
		begin
			case(addr_latch)
				//--------------------------------------------------
				// Numer komendy
				//--------------------------------------------------
				5'd0:
				begin
					ram[0] <= data_latch;
					if(!(put_text_repeat && (data_latch == CMD_PUT_TEXT)))
					begin
						ram[REG_STATUS_VGA][STATUS_VGA] <= VGA_BUSY;
						ram0_valid <= 1'b1;
					end
				end
				//--------------------------------------------------
				// Parametry komendy
				//--------------------------------------------------
				5'd1,
				5'd2,
				5'd4,
				5'd5,
				5'd6,
				5'd7,
				5'd8,
				5'd9,
				5'd10,
				5'd11,
				5'd12,
				5'd13,
				5'd14,
				5'd15:
					ram[addr_latch] <= data_latch;
				5'd3:
				begin
					ram[3] <= data_latch;
					if(put_text_repeat)
					begin
						command <= CMD_PUT_TEXT;
						ram[REG_STATUS_VGA][STATUS_VGA] <= VGA_BUSY;
						ram0_valid <= 1'b1;
					end
				end					
				//--------------------------------------------------
				// Kasowanie wybranych przerwañ
				//--------------------------------------------------
				REG_CLEAR_FLAGS:
				begin
					clear_bits <= data_latch;
				end
				//--------------------------------------------------
				// Zezwolenie na przerwania
				//--------------------------------------------------
				REG_INT_ENABLE:
				begin
					enable_irq <= data_latch;

					if(!data_latch[IRQ_TIMER8_OVF])
						irq_flags[IRQ_TIMER8_OVF] <= 1'b0;
				end
				//--------------------------------------------------
				// Preskaler timera
				//--------------------------------------------------
				REG_DIV:
				begin
					div_value <= data_latch[4:0];
					div_cnt <= 8'd0;
					timer8_cnt <= 8'd0;
					if(data_latch[4:0] == DIV_OFF)
						irq_flags[IRQ_TIMER8_OVF] <= 1'b0;
				end
				//--------------------------------------------------
				// Rejestr licznika TIMER8
				//--------------------------------------------------
				REG_TIMER8_0:
				begin
					timer8_cnt <= data_latch;
				end
				//--------------------------------------------------
				// Konfiguracja timera
				//--------------------------------------------------
				REG_TIMCFG:
				begin
					timcfg <= data_latch;
				end
				//--------------------------------------------------
				// Wartoœæ prze³adowania timera
				//--------------------------------------------------
				REG_RELOAD:
				begin
					timer8_reload <= data_latch;
				end
				//--------------------------------------------------
				// Komenda ALU
				//--------------------------------------------------
`ifdef USE_ALU16
				REG_ALU_CMD:
				begin
					alu_cmd   <= data_latch[4:0];
					alu_start <= 1'b1;
				end
`endif
			endcase
		end
		//--------------------------------------------------
		// Kasowanie flag przerwañ
		//--------------------------------------------------
		if(clear_bits != 8'b0)
		begin
			irq_flags  <= irq_flags & ~clear_bits;
			clear_bits <= 8'b0;
		end
		//--------------------------------------------------
		// Kasowanie impulsu start PS/2
		//--------------------------------------------------
		if(ps2_start)
			ps2_start <= 1'b0;
		//--------------------------------------------------
		// Inicjalizacja klawiatury PS/2
		//--------------------------------------------------
		case(ps2_init)
			//--------------------------------------------------
			// OpóŸnienie po resecie FPGA
			//--------------------------------------------------
			PS2_INIT_IDLE:
			begin
				if(ps2_delay_cnt < 26'd40_000_000)
				begin
					ps2_delay_cnt <= ps2_delay_cnt + 1'b1;
				end
				else
				begin
					if(!ps2_busy)
					begin
						ps2_tx_data <= 8'hFF;				// komenda RESET klawiatury
						ps2_start   <= 1'b1;

						ps2_init <= PS2_INIT_WAIT1;
					end
				end
			end
			//--------------------------------------------------
			// Oczekiwanie na odpowiedŸ AA po RESET
			//--------------------------------------------------
			PS2_INIT_WAIT1:
			begin
				if(ps2_rx_ready && ps2_rx_data == 8'hAA)
				begin
					ps2_led_step <= 3'd0;

					ps2_tx_data <= 8'hED;					// komenda sterowania LED
					ps2_start   <= 1'b1;

					ps2_init <= PS2_LED_CMD;
				end
			end
			//--------------------------------------------------
			// Wysy³anie komendy LED
			//--------------------------------------------------
			PS2_LED_CMD:
			begin
				if(ps2_rx_ready && ps2_rx_data == 8'hFA)
				begin
					case(ps2_led_step)
						3'd0:
							ps2_tx_data <= 8'h01;			// SCROLL LOCK ON
						3'd1:
							ps2_tx_data <= 8'h00;			// wszystkie LED OFF
						3'd2:
							ps2_tx_data <= 8'h02;			// NUM LOCK ON
						3'd3:
							ps2_tx_data <= 8'h00;			// wszystkie LED OFF
						3'd4:
							ps2_tx_data <= 8'h04;			// CAPS LOCK ON
						3'd5:
							ps2_tx_data <= 8'h00;			// wszystkie LED OFF
						default:
						begin
							ps2_init <= PS2_INIT_DONE;
						end
					endcase
					ps2_start <= 1'b1;
					ps2_init <= PS2_LED_DATA;
				end
			end
			//--------------------------------------------------
			// Oczekiwanie na potwierdzenie danych LED
			//--------------------------------------------------
			PS2_LED_DATA:
			begin
				if(ps2_rx_ready && ps2_rx_data == 8'hFA)
				begin
					ps2_led_delay_cnt <= 45'd0;

					ps2_init <= PS2_LED_DELAY;
				end
			end
			//--------------------------------------------------
			// OpóŸnienie pomiêdzy zmianami LED
			//--------------------------------------------------
			PS2_LED_DELAY:
			begin
				//if(ps2_led_delay_cnt < 25'd20_500_000)
				if(ps2_led_delay_cnt < 24'd12_250_000)
				begin
					ps2_led_delay_cnt <= ps2_led_delay_cnt + 1'b1;
				end
				else
				begin
					ps2_led_delay_cnt <= 24'd0;
					if(ps2_led_step == 3'd5)
					begin
						irq_flags[IRQ_PS2] <= 1'b0;
						ram[REG_PS2_DATA] <= 8'h00;
						ps2_init <= PS2_INIT_DONE;
					end
					else
					begin
						ps2_led_step <= ps2_led_step + 1'b1;
						ps2_tx_data <= 8'hED;
						ps2_start <= 1'b1;
						ps2_init <= PS2_LED_CMD;
					end
				end
			end
			//--------------------------------------------------
			// Koniec inicjalizacji
			//--------------------------------------------------
			PS2_INIT_DONE:
				begin
					if((caps_lock != caps_lock_old) ||
						(num_lock != num_lock_old) ||
						(scroll_lock != scroll_lock_old))
						begin
							caps_lock_old   <= caps_lock;
							num_lock_old    <= num_lock;
							scroll_lock_old <= scroll_lock;
							if(!ps2_busy)
								begin
									ps2_tx_data <= 8'hED;
									ps2_start   <= 1'b1;
									ps2_init <= PS2_UPDATE_LED;
								end
						end
				end
			PS2_UPDATE_LED:
				begin
					if(ps2_rx_ready && ps2_rx_data == 8'hFA)
						begin
							ps2_tx_data <=
								{
									5'b00000,
									caps_lock,
									num_lock,
									scroll_lock
								};
							ps2_start <= 1'b1;
							ps2_init <= PS2_UPDATE_DATA;
						end
				end
			PS2_UPDATE_DATA:
				begin
					if(ps2_rx_ready && ps2_rx_data == 8'hFA)
						begin
							ps2_init <= PS2_INIT_DONE;
						end
				end
			default:
			begin
				ps2_init <= PS2_INIT_IDLE;
			end
		endcase
		//--------------------------------------------------
		// G³ówna maszyna stanów wykonywania komend
		//--------------------------------------------------
		case(state)
			//--------------------------------------------------
			// Oczekiwanie na now¹ komendê
			//--------------------------------------------------
			ST_IDLE:
			begin
				if(ram0_valid)
					state <= ST_DECODE;
			end
			//--------------------------------------------------
			// Pobranie numeru komendy
			//--------------------------------------------------
			ST_DECODE:
			begin
				command <= ram[REG_COMMAND];
				ram0_valid <= 1'b0;              // ‹ DODAJ
				state <= ST_EXECUTE;
			end
			//--------------------------------------------------
			// Wykonanie komendy
			//--------------------------------------------------
			ST_EXECUTE:
			begin
				ram[REG_STATUS_VGA][STATUS_VGA] <= VGA_BUSY;   // ‹ DODAJ TÊ LINIÊ
				case(command)
					CMD_RESET_FPGA:
					begin
						soft_reset <= 1'b1;
						state <= ST_FINISH;
					end
					CMD_SET_DEBUG:
					begin
						debug_data <= ram[9];
						state <= ST_FINISH;
					end
					CMD_GET_DEBUG:
					begin
						ram[9] <= debug_data;
						state <= ST_FINISH;
					end
					CMD_GET_RTS:
					begin
						ram[9] <= {7'd0, RTS};
						state <= ST_FINISH;
					end
					CMD_CLEAR_FRAMEBUFFER:
					begin
						do_clear_framebuffer;
					end
					CMD_WRITE_PIXEL:
					begin
						do_write_pixel;
					end
					CMD_DRAW_RECT:
					begin
						do_draw_rect;
					end
					CMD_DRAW_FRAME:
					begin
						do_draw_frame;
					end
					CMD_WRITE_TEXT:
					begin
						do_write_text;
					end
					CMD_CLEAR_TEXT:
					begin
						do_clear_text;
					end
					CMD_PUT_TEXT:
					begin
						do_put_text;
					end
					CMD_PUT_TEXT_REPEAT_OFF:
					begin
						put_text_repeat <= 1'b0;
						state <= ST_FINISH;
					end
					CMD_FB_BLANK_OFF:
					begin
						fb_blank_reg <= 1'b1;
						state <= ST_FINISH;
					end
					CMD_FB_BLANK_ON:
					begin
						fb_blank_reg <= 1'b0;
						state <= ST_FINISH;
					end
					CMD_SET_CURSOR:
					begin
						do_set_cursor;
					end
					CMD_SET_PIXEL:
					begin
						do_set_pixel;
					end
					CMD_PUT_PIXEL:
					begin
						do_put_pixel;
					end
					CMD_UART_ON:
					begin
						uart_enable <= 1'b1;
						state <= ST_FINISH;
					end
					CMD_UART_OFF:
					begin
						uart_enable <= 1'b0;
						state <= ST_FINISH;
					end
					CMD_SET_UNIX:
					begin
						unix_time <= {ram[4],ram[3],ram[2],ram[1]};
						unix_div_cnt <= 25'd0;
						state <= ST_FINISH;
					end
					CMD_GET_UNIX:
					begin
						ram[1] <= unix_time[7:0];
						ram[2] <= unix_time[15:8];
						ram[3] <= unix_time[23:16];
						ram[4] <= unix_time[31:24];
						state <= ST_FINISH;
					end
					CMD_SD_READ_DATA:
					begin
						sd_data_addr <= {ram[2][0], ram[1]};
						state <= ST_SD_READ_WAIT2;
					end
					CMD_SD_WRITE_DATA:
					begin
						sd_data_addr <= {ram[2][0], ram[1]};
						sd_data_in   <= ram[3];
						sd_data_we   <= 1'b1;
						state <= ST_FINISH;
					end
					CMD_SD_READ_STATUS:
					begin
						ram[REG_STATUS_VGA][STATUS_SD] <= ~sd_busy;
						ram[REG_STATUS_VGA][STATUS_SD_PRESENT] <= sd_present_in;
						ram[REG_STATUS_VGA][STATUS_SD_POWER] <= sd_vcc_en;
						ram[REG_SD] <= sd_r1;
						state <= ST_FINISH;
					end
					CMD_SD_SEND:
					begin
						ram[REG_STATUS_VGA][STATUS_SD] <= 1'b0;
						sd_cmd <= ram[1][5:0];
						sd_arg <=
							{
							ram[2],
							ram[3],
							ram[4],
							ram[5]
							};
						sd_crc <= ram[6];
						sd_start <= 1'b1;
						state <= ST_WAIT;
					end
					CMD_SD_VCC_ON:            			// w³¹cz zasilanie
					begin
						sd_vcc_en <= 1'b1;    			// pin = 1 = ON
						state <= ST_FINISH;
					end
					CMD_SD_VCC_OFF:           			// wy³¹cz zasilanie
					begin
						sd_vcc_en <= 1'b0;    			// pin = 1 = OFF
						state <= ST_FINISH;
					end
					
					CMD_GET_CURSOR:
					begin
						// Bez dzielenia - odczyt aktualnych rejestrow X/Y
						ram[1] <= ram[REG_XPOS_TXT];
						ram[2] <= ram[REG_YPOS_TXT];
						state <= ST_FINISH;
					end		
					//==================================================
					// Komendy sprite
					//==================================================
					CMD_SPRITE_LOAD_BEGIN:
					begin
						spr_load_ptr    <= {ram[1][3:0], 8'd0};   // idx * 256
						spr_load_active <= 1'b1;
						state <= ST_FINISH;
					end
					CMD_SPRITE_LOAD_DATA:
					begin
						if(spr_load_active)
						begin
							spr_addr <= spr_load_ptr;
							spr_data <= ram[1];
							spr_we   <= 1'b1;
							spr_load_ptr <= spr_load_ptr + 12'd1;
						end
						state <= ST_FINISH;
					end
					CMD_SPRITE_LOAD_END:
					begin
						spr_we          <= 1'b0;
						spr_load_active <= 1'b0;
						state <= ST_FINISH;
					end
					//==================================================
					// Komendy sprite — pozycja / enable / clear
					//==================================================
					CMD_SPRITE_POS:
					begin
						spr_x[ram[REG_XPOS_TXT][3:0]] <= {ram[REG_CHAR_ASCII][1:0], ram[REG_YPOS_TXT]};
						spr_y[ram[REG_XPOS_TXT][3:0]] <= {ram[REG_PARAM1][0], ram[REG_CHAR_ATTR]};
						state <= ST_FINISH;
					end
					CMD_SPRITE_ENABLE:
					begin
						spr_ctrl[ram[REG_XPOS_TXT][3:0]][2] <= ram[REG_YPOS_TXT][0];
						state <= ST_FINISH;
					end
					CMD_SPRITE_CLEAR:
					begin
						// Wy³¹cz wszystkie sprite'y (enable = 0)
						spr_ctrl[0][2] <= 1'b0;
						spr_ctrl[1][2] <= 1'b0;
						spr_ctrl[2][2] <= 1'b0;
						spr_ctrl[3][2] <= 1'b0;
						spr_ctrl[4][2] <= 1'b0;
						spr_ctrl[5][2] <= 1'b0;
						spr_ctrl[6][2] <= 1'b0;
						spr_ctrl[7][2] <= 1'b0;
						state <= ST_FINISH;
					end		
					default:
					begin
						state <= ST_FINISH;
					end
				endcase				
			end
			ST_SD_READ_WAIT:
			begin
				ram[REG_SD] <= sd_data_out;
				state <= ST_FINISH;
			end
			ST_SD_READ_WAIT2:
			begin
				state <= ST_SD_READ_WAIT;
			end		
			//--------------------------------------------------
			// Oczekiwanie na zakoñczenie zapisu pamiêci
			//--------------------------------------------------
			ST_WAIT:
			begin
			//==================================================
			// Oczekiwanie na kartê SD
			//==================================================
			if(command == CMD_SD_SEND)
			begin
				if(sd_done)
				begin
					ram[REG_SD] <= sd_r1;
					ram[REG_STATUS_VGA][STATUS_SD] <= 1'b1;
					//ram[REG_STATUS_VGA][STATUS_SD_TOKEN_FE] <= sd_token_fe_seen;
					state <= ST_FINISH;
				end
			end
				else if(wr_done)
				begin
					wr_req <= 1'b0;
					case(command)
						CMD_CLEAR_FRAMEBUFFER:
							state <= ST_NEXT;
						CMD_WRITE_PIXEL:
							state <= ST_FINISH;
						CMD_PUT_PIXEL:
							state <= ST_FINISH;
						CMD_DRAW_RECT:
							state <= ST_NEXT;
						CMD_DRAW_FRAME:
							state <= ST_NEXT;
						CMD_CLEAR_TEXT:
							state <= ST_NEXT;
						default:
							state <= ST_FINISH;
					endcase
				end
			end
			//--------------------------------------------------
			// Nastêpny krok d³ugiej operacji
			//--------------------------------------------------
			ST_NEXT:
			begin
				case(command)
					CMD_CLEAR_FRAMEBUFFER:
					begin
						do_next_clear_framebuffer;
					end
					CMD_DRAW_RECT:
					begin
						do_next_draw_rect;
					end
					CMD_DRAW_FRAME:
					begin
						do_next_draw_frame;
					end
					CMD_CLEAR_TEXT:
					begin
						do_next_clear_text;
					end
					default:
					begin
						state <= ST_FINISH;
					end
				endcase
			end
			//--------------------------------------------------
			// Zakoñczenie wykonywania komendy
			//--------------------------------------------------
			ST_FINISH:
			begin
				ram[REG_STATUS_VGA][STATUS_VGA] <= VGA_IDLE;
				// przerwanie tylko dla d³ugich komend
				if(command == CMD_DRAW_RECT || command == CMD_DRAW_FRAME || command == CMD_CLEAR_FRAMEBUFFER ||  command == CMD_CLEAR_TEXT)
				begin
					irq_flags[IRQ_CMD_DONE] <= 1'b1;
				end
				if(command == CMD_PUT_TEXT)
					put_text_repeat <= 1'b1;
				else
					put_text_repeat <= 1'b0;
				state <= ST_IDLE;
			end
			//--------------------------------------------------
			// Zabezpieczenie FSM
			//--------------------------------------------------
			default:
			begin
				state <= ST_IDLE;
			end
		endcase
	end
end



//==================================================
// Taski wykonywania komend
//==================================================


//--------------------------------------------------
// CMD_CLEAR_FRAMEBUFFER
//
// Rozpoczêcie czyszczenia ca³ego framebuffer
//--------------------------------------------------
task do_clear_framebuffer;
begin
	pixel_index <= 19'd0;
	framebuffer_addr <= 19'd0;
	wr_addr <= 19'd0;
	wr_data <= 8'h00;
	wr_req <= 1'b1;
	state <= ST_WAIT;
end
endtask

//--------------------------------------------------
// CMD_WRITE_PIXEL
//
// Zapis pojedynczego piksela
//--------------------------------------------------
task do_write_pixel;
begin
	wr_addr <= {ram[3][2:0],ram[2],ram[1]};
	wr_data <= ram[4];
	wr_req <= 1'b1;
	state <= ST_WAIT;
end
endtask

//--------------------------------------------------
// CMD_DRAW_RECT
//
// Wype³niony prostok¹t
//
// ram[1] = X1[7:0]
// ram[2] = X1[9:8] + Y1[5:0]
// ram[3] = Y1[8:6]
//
// ram[4] = X2[7:0]
// ram[5] = X2[9:8] + Y2[5:0]
// ram[6] = Y2[8:6]
//
// ram[7] = kolor
//--------------------------------------------------
task do_draw_rect;
begin
    x <= {ram[2][1:0], ram[1]};
    y <= {ram[3][2:0], ram[2][7:2]};
    wr_addr <=
        ({10'd0, {ram[3][2:0], ram[2][7:2]}} * 19'd640) +
        {ram[2][1:0], ram[1]};
    wr_data <= ram[7];
    wr_req  <= 1'b1;
    state   <= ST_WAIT;
end
endtask
//--------------------------------------------------
// CMD_DRAW_FRAME
//
// Ramka prostokata
//
// ram[1] = X1[7:0]
// ram[2] = X1[9:8] + Y1[5:0]
// ram[3] = Y1[8:6]
//
// ram[4] = X2[7:0]
// ram[5] = X2[9:8] + Y2[5:0]
// ram[6] = Y2[8:6]
//
// ram[7] = kolor ramki
// ram[8] = bit7   = FILL
//          bit6:0 = grubosc ramki
// ram[9] = kolor wypelnienia
//
// FILL = 0 -> tylko ramka
// FILL = 1 -> ramka + wypelnienie
//--------------------------------------------------

task do_draw_frame;
begin
    x <= {ram[2][1:0], ram[1]};
    y <= {ram[3][2:0], ram[2][7:2]};
    wr_addr <=
        ({10'd0, {ram[3][2:0], ram[2][7:2]}} * 19'd640) +
        {ram[2][1:0], ram[1]};
    wr_data <= ram[8];      // ‹ kolor ramki z ram[8]
    wr_req  <= 1'b1;
    state   <= ST_WAIT;
end
endtask

//--------------------------------------------------
// CMD_WRITE_TEXT
//
// Zapis pojedynczego znaku do bufora tekstowego
//--------------------------------------------------

task do_write_text;
begin
	if((ram[REG_XPOS_TXT] < TEXT_COLS) &&
	   (ram[REG_YPOS_TXT] < TEXT_ROWS))
	begin
		// obliczenie indeksu bufora tekstowego
		txt_index_tmp =
			(ram[REG_YPOS_TXT] << 6) +
			(ram[REG_YPOS_TXT] << 4) +
			 ram[REG_XPOS_TXT];
		// adres komórki tekstowej
		txt_addr <= txt_index_tmp;
		// znak + atrybut
		txt_data <=
			{
				ram[REG_CHAR_ATTR],
				ram[REG_CHAR_ASCII]
			};
		// impuls zapisu
		txt_we <= 1'b1;
		// przesuniêcie kursora
		update_text_cursor;
	end
	state <= ST_FINISH;
end
endtask



//--------------------------------------------------
// CMD_CLEAR_TEXT
//
// Czyszczenie ca³ego bufora tekstowego
//--------------------------------------------------
task do_clear_text;
begin
	// pocz¹tek kasowania bufora
	text_clear_index <= 13'd0;
	txt_addr <= 13'd0;
	// spacja z domyœlnym atrybutem
	txt_data <= 16'h0020;
	txt_we <= 1'b1;
	state <= ST_NEXT;
end
endtask

//--------------------------------------------------
// CMD_PUT_TEXT
//
// Wpisanie znaku w aktualnej pozycji kursora
//--------------------------------------------------
task do_put_text;
begin
	txt_index_tmp = text_index;
	txt_addr <= txt_index_tmp;
	txt_data <=
		{
			ram[REG_CHAR_ATTR],
			ram[REG_CHAR_ASCII]
		};
	txt_we <= 1'b1;
	// aktualizacja pozycji kursora
	update_text_cursor;
	state <= ST_FINISH;
end
endtask

//--------------------------------------------------
// Kolejny zapis czyszczenia framebuffer
//--------------------------------------------------
task do_next_clear_framebuffer;
begin
	if(framebuffer_addr == (FRAMEBUFFER_SIZE - 1))
	begin
		wr_req <= 1'b0;
		state <= ST_FINISH;
	end
	else
	begin
		framebuffer_addr <= framebuffer_addr + 19'd1;
		wr_addr <= framebuffer_addr + 19'd1;
		wr_data <= 8'h00;
		wr_req <= 1'b1;
		state <= ST_WAIT;
	end
end
endtask

//--------------------------------------------------
// Kolejny piksel wypelnionego prostokata
//--------------------------------------------------
task do_next_draw_rect;
begin
    if(x == {ram[5][1:0], ram[4]})
    begin
        x <= {ram[2][1:0], ram[1]};
        if(y == {ram[6][2:0], ram[5][7:2]})
        begin
            wr_req <= 1'b0;
            state  <= ST_FINISH;
        end
        else
        begin
            y <= y + 9'd1;
            wr_addr <=
                ({10'd0, (y + 9'd1)} * 19'd640) +
                {ram[2][1:0], ram[1]};
            wr_data <= ram[7];
            wr_req  <= 1'b1;
            state   <= ST_WAIT;
        end
    end
    else
    begin
        x <= x + 10'd1;
        wr_addr <=
            ({10'd0, y} * 19'd640) +
            (x + 10'd1);
        wr_data <= ram[7];
        wr_req  <= 1'b1;
        state   <= ST_WAIT;
    end
end
endtask
//--------------------------------------------------
// Kolejny piksel ramki z wype³nieniem
//
// Parametry (bez buforowania — czytane z ram[] na bie¿¹co):
//   ram[1] = X1[7:0]
//   ram[2] = X1[9:8] + Y1[5:0]
//   ram[3] = Y1[8:6]
//   ram[4] = X2[7:0]
//   ram[5] = X2[9:8] + Y2[5:0]
//   ram[6] = Y2[8:6]
//   ram[7] = kolor ramki
//   ram[8] = bit7   = FILL
//            bit6:0 = gruboœæ ramki
//   ram[9] = kolor wype³nienia
//--------------------------------------------------
task do_next_draw_frame;
begin
    if(x == {ram[5][1:0], ram[4]})
    begin
        //--------------------------------------------------
        // Koniec wiersza
        //--------------------------------------------------
        x <= {ram[2][1:0], ram[1]};
        if(y == {ram[6][2:0], ram[5][7:2]})
        begin
            // koniec ca³ej ramki
            wr_req <= 1'b0;
            state  <= ST_FINISH;
        end
        else
        begin
            y <= y + 9'd1;
            wr_addr <=
                ({10'd0, (y + 9'd1)} * 19'd640) +
                {ram[2][1:0], ram[1]};
            // Pierwszy piksel nowego wiersza = X1 › zawsze ramka
            wr_data <= ram[8];      // ‹ kolor ramki z ram[8]
            wr_req  <= 1'b1;
            state   <= ST_WAIT;
        end
    end
    else
    begin
        //--------------------------------------------------
        // Œrodek wiersza
        //--------------------------------------------------
        x <= x + 10'd1;
        wr_addr <=
            ({10'd0, y} * 19'd640) +
            (x + 10'd1);

        //--------------------------------------------------
        // Czy piksel nale¿y do ramki, czy do wype³nienia?
        //
        // Ramka obejmuje pas o gruboœci T wokó³ krawêdzi:
        //   lewa   : x <= X1 + T - 1
        //   prawa  : x >= X2 - T + 1
        //   góra   : y <  Y1 + T
        //   dó³    : y >= Y2 - T + 1
        //--------------------------------------------------
        if(
            ((x + 10'd1) <=
                ({ram[2][1:0], ram[1]} + ram[7][6:0] - 10'd1)) ||   // ‹ gruboœæ z ram[7]
            ((x + 10'd1) >=
                ({ram[5][1:0], ram[4]} - ram[7][6:0] + 10'd1)) ||   // ‹ gruboœæ z ram[7]
            (y <
                ({ram[3][2:0], ram[2][7:2]} + ram[7][6:0])) ||      // ‹ gruboœæ z ram[7]
            (y >=
                ({ram[6][2:0], ram[5][7:2]} - ram[7][6:0] + 9'd1))  // ‹ gruboœæ z ram[7]
        )
        begin
            wr_data <= ram[8];   // ‹ kolor ramki z ram[8]
        end
        else
        begin
            wr_data <= ram[9];   // ‹ kolor wype³nienia z ram[9]
        end
        wr_req <= 1'b1;
        state  <= ST_WAIT;
    end
end
endtask
//--------------------------------------------------
// Kolejny krok czyszczenia bufora tekstowego
//--------------------------------------------------
task do_next_clear_text;
begin
	txt_addr <= text_clear_index;
	txt_data <= 16'h0020;
	txt_we <= 1'b1;
	if(text_clear_index == (TEXT_CELLS - 1))
	begin
		// ustawienie kursora na pocz¹tek
		text_index <= 13'd0;
		ram[REG_XPOS_TXT] <= 8'd0;
		ram[REG_YPOS_TXT] <= 8'd0;
		state <= ST_FINISH;
	end
	else
	begin
		text_clear_index <= text_clear_index + 13'd1;
		state <= ST_NEXT;
	end
end
endtask

//==================================================
// Aktualizacja kursora tekstowego
//==================================================
// SLICE
task update_text_cursor;
begin
	//--------------------------------------------------
	// Aktualizacja indeksu tekstowego
	//--------------------------------------------------
	if(txt_index_tmp == (TEXT_CELLS - 1))
	begin
		text_index <= 13'd0;
		ram[REG_XPOS_TXT] <= 8'd0;
		ram[REG_YPOS_TXT] <= 8'd0;
	end
	else
	begin
		text_index <= txt_index_tmp + 13'd1;
		//--------------------------------------------------
		// Inkrementalne liczenie X/Y (bez dzielenia!)
		// X: 0..79 -> reset do 0 i Y+1
		// Y: 0..59 -> reset do 0
		//--------------------------------------------------
		if(ram[REG_XPOS_TXT] == (TEXT_COLS - 8'd1))
		begin
			ram[REG_XPOS_TXT] <= 8'd0;
			if(ram[REG_YPOS_TXT] == (TEXT_ROWS - 8'd1))
				ram[REG_YPOS_TXT] <= 8'd0;
			else
				ram[REG_YPOS_TXT] <= ram[REG_YPOS_TXT] + 8'd1;
		end
		else
		begin
			ram[REG_XPOS_TXT] <= ram[REG_XPOS_TXT] + 8'd1;
		end
	end
end
endtask

//--------------------------------------------------
// Zamiana wspó³rzêdnych X/Y
//--------------------------------------------------
task do_set_cursor;
	begin
		if ((ram[1] < TEXT_COLS) &&(ram[2] < TEXT_ROWS))
			begin
				ram[REG_XPOS_TXT] <= ram[1];
				ram[REG_YPOS_TXT] <= ram[2];
				text_index <=
						(ram[2] << 6) +
						(ram[2] << 4) +
						ram[1];
			end
		state <= ST_FINISH;
		end
endtask
//--------------------------------------------------
// Zamiana wspó³rzêdnych X/Y dla kursora graficznego
//--------------------------------------------------
task do_set_pixel;
	begin
		if ({ram[2], ram[1]} > 16'd639)
			pixel_index <=
				({ram[4], ram[3]} > 16'd479) ?
				19'd307199 :
				({ram[4], ram[3]} * 19'd640) + 19'd639;
		else if ({ram[4], ram[3]} > 16'd479)
			pixel_index <=
				19'd306560 + {ram[2], ram[1]};
		else
			pixel_index <=
				({ram[4], ram[3]} * 19'd640) +
				{ram[2], ram[1]};
	state <= ST_FINISH;
	end
endtask

//--------------------------------------------------
// Wyswietlenie piksela na ustawionej pozycji
//--------------------------------------------------
task do_put_pixel;
	begin
		wr_addr <= pixel_index;
		wr_data <= ram[3];
		wr_req  <= 1'b1;
		if(pixel_index < 19'd307199)
			pixel_index <= pixel_index + 19'd1;
		else
			pixel_index <= 19'd0;
		state <= ST_WAIT;
	end
endtask

endmodule
