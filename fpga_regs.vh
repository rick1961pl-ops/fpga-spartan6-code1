`include "config.vh"
// poczatek rejestrów tylko do zapisu
//==================================================
// Rejestry interfejsu komend (0–15)
//==================================================

localparam REG_COMMAND			= 8'd0;
localparam REG_XPOS_TXT			= 8'd1;
localparam REG_YPOS_TXT			= 8'd2;
localparam REG_CHAR_ASCII		= 8'd3;
localparam REG_CHAR_ATTR		= 8'd4;
localparam REG_PARAM1			= 8'd5;
localparam REG_PARAM2			= 8'd6;
localparam REG_PARAM3			= 8'd7;
localparam REG_PARAM4			= 8'd8;
localparam REG_PARAM5			= 8'd9;
localparam REG_SD				= 8'd10;
localparam REG_CFG				= 8'd11;								// rejestr konfiguracja odbiornika/nadajnika
//7 6 5 4 3 2 1 0
//- - - - - - - -
//- - - - - - - 			 RX_EN
//- - - - - - L TX_EN
//- - - - - L
//- - - - L
//L			BAUD_SEL
localparam REG_UART_DATA		= 8'd12;								// rejestr odbiornika/nadajnika
localparam REG_PS2_DATA			= 8'd13;
localparam REG_CURSOR_CTRL		= 8'd14;
localparam REG_STATUS_VGA		= 8'd15;

// poczatek rejestrów tylko do odczytu
//==================================================
// Rejestry przerwañ i timera (16–22)
//==================================================
//7 6 5 4 3 2 1 0
//- - - - - - - -
//- - - - - - - L¦¦ IRQ_TIMER8_OVF
//- - - - - - L¦¦¦¦ IRQ_TIMER8_CMP
//- - - - - L¦¦¦¦¦¦ IRQ_PS2
//- - - - L¦¦¦¦¦¦¦¦ IRQ_UART_RX
//- - - L¦¦¦¦¦¦¦¦¦¦ IRQ_UART_TX
//- - L¦¦¦¦¦¦¦¦¦¦¦¦
//- L¦¦¦¦¦¦¦¦¦¦¦¦¦¦
//L¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ IRQ_ALU
localparam REG_INT_FLAGS		= 8'd16;
localparam REG_CLEAR_FLAGS		= 8'd17;
localparam REG_INT_ENABLE		= 8'd18;
localparam REG_DIV				= 8'd19;
localparam REG_TIMER8_0			= 8'd20;
localparam REG_TIMCFG			= 8'd21;
localparam REG_RELOAD			= 8'd22;

//==================================================
// Rejestry ALU (23–28) — opcjonalne przez USE_ALU16
//==================================================
`ifdef USE_ALU16
localparam REG_ALU_CMD         = 8'd23;
localparam REG_ALU_RES0        = 8'd24;
localparam REG_ALU_RES1        = 8'd25;
localparam REG_ALU_RES2        = 8'd26;
localparam REG_ALU_RES3        = 8'd27;
localparam REG_ALU_FLAGS       = 8'd28;
`endif
//==================================================
// Generator liczb pseudolosowych (29–31)
//==================================================

localparam REG_RANDOM8         = 8'd29;								// LSB generatora pseudolosowego dla liczby 8bitowej
localparam REG_RANDOM16L       = 8'd30;								// LSB generatora pseudolosowego dla liczby 16bitowej
localparam REG_RANDOM16H       = 8'd31;								// MSB generatora pseudolosowego dla liczby 16bitowej

//====================================================================
// Wartoœæ bitu zajetoœci  bitu STATUS_VGA
//====================================================================

localparam VGA_IDLE     = 0;
localparam VGA_BUSY     = 1;
//====================================================================
// numery bitów w rejestrze statusu REG_STATUS_VGA
//====================================================================
localparam STATUS_VGA     		= 0;								// flaga zajetosci/ zwolnienia
localparam STATUS_PS2		    = 1;								// flaga nowek kodu klawisza w PS2
localparam STATUS_UART_RXD     	= 2;								// flaga zakoñczenia odbioru z UART
localparam STATUS_UART_TXD     	= 3;								// flaga zakonczenia nadawania do UART
localparam STATUS_SD     		= 4;								// flaga bitwy operacji na karcie SD
localparam STATUS_SD_PRESENT   	= 5;								// flaga obecnoœi karty SD w gnieŸdzie
localparam STATUS_SD_POWER     	= 6;								// flaga wlaczenia/wylaczenia zasilania karty SD
//localparam STATUS_SD_TOKEN_FE  	= 5;								
//====================================================================
// Przerwania bity zezwolenia na przerwanie w rejestrze r[18]
//====================================================================

localparam IRQ_TIMER8_OVF      = 0;
localparam IRQ_TIMER8_CMP      = 1;
localparam IRQ_PS2             = 2;
localparam IRQ_UART_RX 		   = 3;
localparam IRQ_UART_TX 		   = 4;
localparam IRQ_CMD_DONE        = 5;
localparam IRQ_RTS        	   = 6;
`ifdef USE_ALU16
localparam IRQ_ALU             = 7;
`endif
//==================================================
// Timer bit konfiguracji pracy timera w rejestrze
//==================================================

localparam TIMCFG_AUTORELOAD   = 0;
localparam TIMCFG_COMPARE      = 1;

localparam DIV_OFF             = 5'd0;
localparam DIV_2               = 5'd1;
localparam DIV_4               = 5'd2;
localparam DIV_8               = 5'd3;
localparam DIV_16              = 5'd4;
localparam DIV_32              = 5'd5;
localparam DIV_64              = 5'd6;
localparam DIV_128             = 5'd7;
localparam DIV_255             = 5'd8;

//==================================================
// Komendy ALU
//==================================================
//==================================================
// Komendy ALU — opcjonalne przez USE_ALU16
//==================================================
`ifdef USE_ALU16
localparam ALU_NOP    = 5'd0;
localparam ALU_ADD    = 5'd1;
localparam ALU_SUB    = 5'd2;
localparam ALU_MUL    = 5'd3;
localparam ALU_DIV    = 5'd4;
localparam ALU_MOD    = 5'd5;
localparam ALU_AND    = 5'd6;
localparam ALU_OR     = 5'd7;
localparam ALU_XOR    = 5'd8;
localparam ALU_NOT    = 5'd9;
localparam ALU_SHL    = 5'd10;
localparam ALU_SHR    = 5'd11;
localparam ALU_ROL    = 5'd12;
localparam ALU_ROR    = 5'd13;
localparam ALU_INC    = 5'd14;
localparam ALU_DEC    = 5'd15;
localparam ALU_SWAPB  = 5'd16;
localparam ALU_SWAPN  = 5'd17;
localparam ALU_NEG    = 5'd18;
localparam ALU_CMP    = 5'd19;
localparam ALU_BSET   = 5'd20;
localparam ALU_BCLR   = 5'd21;
localparam ALU_BINV   = 5'd22;
localparam ALU_BTST   = 5'd23;
localparam ALU_MIN    = 5'd24;
localparam ALU_MAX    = 5'd25;
localparam ALU_CLZ    = 5'd26;
localparam ALU_CTZ    = 5'd27;
localparam ALU_POPCNT = 5'd28;
localparam ALU_ASR    = 5'd29;
localparam ALU_ADC    = 5'd30;
localparam ALU_SBC    = 5'd31;
`endif
//==================================================
// Flagi ALU
//==================================================
`ifdef USE_ALU16
localparam FLAG_Z = 0;
localparam FLAG_C = 1;
localparam FLAG_N = 2;
localparam FLAG_V = 3;
`endif
//==============================================================
// Komendy CPU wpisanie do ram[0] + dodatkowe parametry w ram[n]
//==============================================================
localparam CMD_NONE					= 8'd0;							// brak komendy
localparam CMD_CLEAR_FRAMEBUFFER	= 8'd1;							// czyszczenie bufora grafiki
localparam CMD_WRITE_PIXEL			= 8'd2;							// zapis pojedynczego piksela
localparam CMD_DRAW_RECT			= 8'd3;							// rysowanie prostok¹ta
localparam CMD_DRAW_FRAME			= 8'h4;							// rysowanie ramki
localparam CMD_WRITE_TEXT			= 8'd5;							// zapis znaku tekstowego
localparam CMD_CLEAR_TEXT			= 8'd6;							// czyszczenie bufora tekstowego
localparam CMD_PUT_TEXT				= 8'd7;							// zapis znaku na pozycji kursora
localparam CMD_SET_CURSOR 			= 8'd8;							// zmiana polozenia kursora tekstowego
localparam CMD_SET_PIXEL 			= 8'd9;							// komenda ustawienie wskaznika na kursor graficzny
localparam CMD_PUT_PIXEL 			= 8'd10;						// komenda wyswietlenia piksela w oparciu o CMD_SET_PIXEL
localparam CMD_UART_ON 				= 8'd11;						// komenda wlaczenie UART
localparam CMD_UART_OFF 			= 8'd12;						// komenda wylaczenie UART
localparam CMD_SET_UNIX 			= 8'd13;						// komenda ustawienie czasu UNIX
localparam CMD_GET_UNIX 			= 8'd14;						// komenda pobrania czasu UNIX
localparam CMD_SET_DEBUG 			= 8'd15;						// komenda wystawienia danej na debug_port
localparam CMD_GET_DEBUG 			= 8'd16;						// komenda pobrania danej z debug_port
localparam CMD_GET_RTS 				= 8'd17;						// komenda pobrania pinu RTS
localparam CMD_RESET_FPGA 			= 8'd18;						// RESET FPGA
localparam CMD_GET_CURSOR 			= 8'd19;						// pobranie polozenia kursora tekstowego
localparam CMD_PUT_TEXT_REPEAT_OFF  = 8'd20; 						// kasowanie flagi repetycji znaku
localparam CMD_FB_BLANK_OFF  		= 8'd21;   						// zablokuj framebuffer (czarny)
localparam CMD_FB_BLANK_ON 			= 8'd22;   						// odblokuj framebuffer
//==================================================
// Komendy dla karty SD - komendy SD
//==================================================
localparam CMD_SD_SEND         	= 8'd40;
localparam CMD_SD_READ_STATUS  	= 8'd41;
localparam CMD_SD_READ_DATA 		= 8'd42;
localparam CMD_SD_WRITE_DATA 		= 8'd43;
localparam CMD_SD_VCC_ON        	= 8'd44;
localparam CMD_SD_VCC_OFF       	= 8'd45;
//==================================================
// Komendy sprite
//==================================================
localparam CMD_SPRITE_LOAD_BEGIN = 8'd50;
localparam CMD_SPRITE_LOAD_DATA  = 8'd51;
localparam CMD_SPRITE_LOAD_END   = 8'd52;
localparam CMD_SPRITE_POS        = 8'd53;
localparam CMD_SPRITE_ENABLE     = 8'd54;
localparam CMD_SPRITE_CLEAR      = 8'd55;
//==================================================
// Bity konfiguracyjne dla REG_CFG
//==================================================
localparam RX_ENABLE = 0;
localparam TX_ENABLE = 1;