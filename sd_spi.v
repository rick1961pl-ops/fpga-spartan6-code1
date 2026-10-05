//==============================================================================
// sd_spi.v - Kontroler karty SD w trybie SPI
//------------------------------------------------------------------------------
// Opis:
//   Moduł realizuje komunikację z kartą SD w trybie SPI (SPI mode).
//   Obsługuje pełną sekwencję inicjalizacji oraz komendy odczytu/zapisu.
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Prędkość SPI:
//   - inicjalizacja : 100 kHz  (SPI_INIT_DIV = 125)
//   - normalna praca: 6.25 MHz (SPI_RUN_DIV  = 2)
//
// Sekwencja inicjalizacji:
//   1. 80 taktów startowych (CS=1, MOSI=1)
//   2. 8 bajtów 0xFF (CS=1, MOSI=1) - dodatkowa synchronizacja
//   3. CMD0  (GO_IDLE_STATE)
//   4. CMD8  (SEND_IF_COND)
//   5. CMD55 (APP_CMD)
//   6. ACMD41 (SD_SEND_OP_COND) - powtarzane aż R1=0x00
//   7. CMD58 (READ_OCR)
//
// Detekcja karty (styk CD w gnieździe):
//   SD_CD = 0 -> karta obecna   (styk zwarty do GND)
//   SD_CD = 1 -> brak karty     (styk rozwarty, pull-up)
//
// Sterowanie zasilaniem:
//   sd_power_on = 0 -> zasilanie wyłączone (CS=0, MOSI=0)
//   sd_power_on = 1 -> zasilanie włączone  (CS=1, MOSI=1 w idle)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module sd_spi
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar systemowy 25 MHz
    input  wire        rst_n,           // reset aktywny stanem niskim
    //--------------------------------------------------
    // Interfejs komend (z cpu_ram)
    //--------------------------------------------------
    input  wire        start,           // impuls rozpoczęcia komendy
    input  wire [5:0]  cmd,             // numer komendy SD (0..63)
    input  wire [31:0] arg,             // argument 32-bitowy komendy
    input  wire [7:0]  crc,             // bajt CRC komendy
    //--------------------------------------------------
    // Status (do cpu_ram)
    //--------------------------------------------------
    output reg         busy,            // 1 = trwa wykonywanie komendy
    output reg         done,            // impuls 1 takt = komenda zakończona
    output reg [7:0]   r1,              // odpowiedź R1 z karty SD
    output wire        sd_present_out,  // 1 = karta w gnieździe
    //--------------------------------------------------
    // Bufor sektora (z cpu_ram)
    //--------------------------------------------------
    input  wire [8:0]  data_addr,       // adres odczytu bufora (z CPU)
    input  wire [7:0]  data_in,         // dane zapisu do bufora (z CPU)
    input  wire        data_we,         // zezwolenie na zapis bufora
    output wire [7:0]  data_out,        // dane odczytu bufora (do CPU)
    //--------------------------------------------------
    // Linie SPI (do karty SD)
    //--------------------------------------------------
    output reg         SD_CS,           // chip select
    output reg         SD_CLK,          // zegar SPI
    output reg         SD_MOSI,         // master out, slave in
    input  wire        SD_MISO,         // master in, slave out
    input  wire        SD_CD,           // detekcja karty (0 = obecna)
    //--------------------------------------------------
    // Sterowanie zasilaniem karty
    //--------------------------------------------------
    input  wire        sd_power_on      // 1 = zasilanie karty włączone
);

//==============================================================================
// 1. PARAMETRY SPI
//------------------------------------------------------------------------------
// Dzielnik zegara SPI zależny od stanu inicjalizacji:
//   - spi_initialized = 0 -> SPI_INIT_DIV (wolno, 100 kHz)
//   - spi_initialized = 1 -> SPI_RUN_DIV  (szybko, 6.25 MHz)
//==============================================================================

localparam [6:0] SPI_INIT_DIV = 7'd125;
localparam [6:0] SPI_RUN_DIV  = 7'd2;

reg  spi_initialized;                   // 1 = karta zainicjalizowana
wire [6:0] spi_div;

assign spi_div = spi_initialized ? SPI_RUN_DIV : SPI_INIT_DIV;

//==============================================================================
// 2. TIMEOUTY
//------------------------------------------------------------------------------
// Wartości maksymalne liczników dla operacji oczekujących na kartę SD.
//==============================================================================

localparam [19:0] DATA_TIMEOUT_MAX = 20'hFFFFF;   // timeout dla danych (512 B)
localparam [3:0]  R1_BYTE_MAX      = 4'd15;       // max bajtów na odpowiedź R1
localparam [15:0] R1_TIMEOUT_MAX   = 16'd65535;   // timeout dla ACMD41

//==============================================================================
// 3. STANY FSM
//------------------------------------------------------------------------------
// Stany głównej maszyny stanów kontrolera SD.
//==============================================================================

localparam [4:0]
    ST_IDLE         = 5'd0,     		// oczekiwanie na komendę
    ST_SEND         = 5'd1,    			// wysyłanie 6 bajtów komendy
    ST_R1_WAIT      = 5'd2,     		// oczekiwanie na odpowiedź R1
    ST_R1_CHECK     = 5'd3,     		// sprawdzenie odpowiedzi R1
    ST_R7_SKIP      = 5'd4,     		// pominięcie 4 bajtów R7 (CMD8)
    ST_DONE         = 5'd5,     		// zakończenie operacji
    ST_DATA_WAIT    = 5'd6,     		// oczekiwanie na token 0xFE
    ST_DATA_READ    = 5'd7,     		// odbiór 512 bajtów
    ST_DATA_STORE   = 5'd8,     		// zapis odebranego bajtu do bufora
    ST_DATA_CRC1    = 5'd9,     		// odbiór CRC bajt 1
    ST_DATA_CRC2    = 5'd10,    		// odbiór CRC bajt 2
    ST_OCR_READ     = 5'd11,    		// odbiór 4 bajtów OCR (CMD58)
    ST_INIT_CLOCK   = 5'd12,    		// 80 taktów startowych
    ST_WRITE_TOKEN  = 5'd13,    		// wysyłanie tokenu 0xFE
    ST_WRITE_DATA   = 5'd14,    		// wysyłanie 512 bajtów
    ST_WRITE_CRC1   = 5'd15,    		// wysyłanie CRC bajt 1
    ST_WRITE_CRC2   = 5'd16,    		// wysyłanie CRC bajt 2
    ST_WRITE_RESP   = 5'd17,    		// odbiór odpowiedzi zapisu
    ST_CMD_START    = 5'd18,    		// start komendy (CS=0, przygotowanie)
    ST_SYNC_CLOCKS  = 5'd19,    		// 8 bajtów 0xFF przed CMD0
    ST_SEND_DUMMY   = 5'd20,    		// komenda 0x3F - 8 x 0xFF
    ST_ACMD_WAIT    = 5'd21;    		// oczekiwanie na ACMD41 (CS=0)

//==============================================================================
// 4. REJESTRY FSM
//------------------------------------------------------------------------------
// Wszystkie rejestry używane przez główną maszynę stanów.
//==============================================================================

reg [4:0]  state;                   	// aktualny stan FSM

reg [5:0]  cmd_reg;                 	// zarejestrowany numer komendy
reg [31:0] arg_reg;                 	// zarejestrowany argument komendy
reg [7:0]  crc_reg;                 	// zarejestrowany CRC komendy

reg [7:0]  tx_shift;                	// rejestr przesuwny nadajnika
reg [7:0]  rx_shift;                	// rejestr przesuwny odbiornika
reg [7:0]  r1_rx_shift;             	// rejestr przesuwny odpowiedzi R1

reg [2:0]  bit_count;               	// licznik bitów (0..7)
reg [2:0]  byte_count;              	// licznik bajtów komendy (0..5)
reg [3:0]  r1_byte_count;           	// licznik bajtów odpowiedzi R1
reg [1:0]  r7_byte_count;           	// licznik bajtów R7 (0..3)

reg [6:0]  init_clk_count;          	// licznik 80 taktów startowych
reg        init_clk_last;           	// flaga ostatniego taktu

reg [2:0]  sync_byte_count;         	// licznik bajtów synchronizacji (0..7)
reg [3:0]  cmd0_retry_count;        	// licznik ponowień CMD0
reg [2:0]  dummy_count;             	// licznik bajtów dummy (0..7)

reg [8:0]  sector_count;            	// licznik bajtów sektora (0..511)
reg [8:0]  write_byte_count;        	// licznik bajtów zapisu (0..511)
reg        write_resp_seen;         	// 1 = odebrano odpowiedź zapisu

reg [19:0] data_timeout;            	// licznik timeout dla danych
reg [15:0] r1_timeout;              	// licznik timeout dla ACMD41
reg        no_card_done;            	// 1 = zgłoszono brak karty

reg [6:0]  div_count;               	// licznik dzielnika SPI

//==============================================================================
// 5. DETEKCJA KARTY SD
//------------------------------------------------------------------------------
// SD_CD = 0 -> karta obecna (styk zwarty do GND)
// SD_CD = 1 -> brak karty   (styk rozwarty, pull-up)
//
// Sygnał SD_CD jest synchronizowany do clk przez 2 przerzutniki.
//==============================================================================

reg sd_sd_meta, sd_sd_sync;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        {sd_sd_meta, sd_sd_sync} <= 2'b11;
    else
        {sd_sd_meta, sd_sd_sync} <= {SD_CD, sd_sd_meta};
end

wire sd_present = ~sd_sd_sync;      // 1 = karta obecna

assign sd_present_out = sd_present;

//==============================================================================
// 6. BUFOR SEKTORA SD
//------------------------------------------------------------------------------
// Bufor 512-bajtowy (dual-port BRAM):
//   - Port A: zapis z FSM (podczas odbioru danych z karty)
//   - Port B: odczyt/zapis z CPU (przez data_addr, data_in, data_we)
//==============================================================================

wire [7:0] buffer_din;              // dane wejściowe bufora (z FSM)
wire [8:0] buffer_addr;             // adres zapisu (z FSM)
wire [8:0] buffer_read_addr;        // adres odczytu (z FSM lub CPU)
wire [7:0] buffer_dout;             // dane wyjściowe bufora
wire       buffer_we;               // zezwolenie na zapis (z FSM)

// Wybór trybu pracy bufora
wire write_active;
assign write_active = (state == ST_WRITE_TOKEN) || (state == ST_WRITE_DATA)  || (state == ST_WRITE_CRC1)  || (state == ST_WRITE_CRC2);

assign buffer_din       = rx_shift;
assign buffer_addr      = sector_count;
assign buffer_read_addr = write_active ? sector_count : data_addr;
assign data_out         = buffer_dout;
assign buffer_we        = (state == ST_DATA_STORE);

ram_SD_buffer ram_SD_buffer_inst
(
    // Port A - zapis z FSM
    .clka  (clk),
    .wea   (buffer_we),
    .addra (buffer_addr),
    .dina  (buffer_din),
    .douta (),
    // Port B - odczyt/zapis z CPU
    .clkb  (clk),
    .web   (data_we),
    .addrb (buffer_read_addr),
    .dinb  (data_in),
    .doutb (buffer_dout)
);

//==============================================================================
// 7. GŁÓWNA MASZYNA STANÓW
//------------------------------------------------------------------------------
// Realizuje całą logikę kontrolera SD: inicjalizację, wysyłanie komend,
// odbiór odpowiedzi R1, odczyt/zapis danych.
//==============================================================================

always @(posedge clk or negedge rst_n)
begin
    //--------------------------------------------------
    // Reset
    //--------------------------------------------------
    if(!rst_n)
    begin
        state            <= ST_IDLE;
        cmd_reg          <= 6'd0;
        arg_reg          <= 32'd0;
        crc_reg          <= 8'h01;
        tx_shift         <= 8'hFF;
        rx_shift         <= 8'h00;
        r1_rx_shift      <= 8'h00;
        bit_count        <= 3'd0;
        byte_count       <= 3'd0;
        r1_byte_count    <= 4'd0;
        r7_byte_count    <= 2'd0;
        init_clk_count   <= 7'd0;
        init_clk_last    <= 1'b0;
        sync_byte_count  <= 3'd0;
        cmd0_retry_count <= 4'd0;
        sector_count     <= 9'd0;
        write_byte_count <= 9'd0;
        write_resp_seen  <= 1'b0;
        dummy_count      <= 3'd0;
        data_timeout     <= 20'd0;
        r1_timeout       <= 16'd0;
        no_card_done     <= 1'b0;
        div_count        <= 7'd0;
        busy             <= 1'b0;
        done             <= 1'b0;
        r1               <= 8'hFF;
        spi_initialized  <= 1'b0;
        SD_CLK           <= 1'b0;

        // Reset: zasilanie SD wyłączone (sd_vcc_en = 0),
        // więc CS=0, MOSI=0 jest bezpieczne (nie "karmimy" karty przez diody)
        SD_CS            <= 1'b0;
        SD_MOSI          <= 1'b0;
    end
    else
    begin
        done <= 1'b0;

        case(state)

        //======================================================================
        // ST_IDLE - oczekiwanie na komendę
        //======================================================================
        ST_IDLE:
        begin
            busy <= 1'b0;

            // Stan spoczynku linii zależny od zasilania
            if(sd_power_on)
            begin
                SD_CS   <= 1'b1;
                SD_MOSI <= 1'b1;
            end
            else
            begin
                SD_CS   <= 1'b0;
                SD_MOSI <= 1'b0;
            end

            SD_CLK       <= 1'b0;
            div_count    <= 7'd0;
            data_timeout <= 20'd0;

            //--------------------------------------------------
            // Start komendy
            //--------------------------------------------------
            if(start && sd_present && sd_power_on)
            begin
                cmd_reg <= cmd;
                arg_reg <= arg;
                crc_reg <= crc;
                busy    <= 1'b1;

                byte_count       <= 3'd0;
                bit_count        <= 3'd0;
                div_count        <= 7'd0;
                tx_shift         <= 8'hFF;
                r1_rx_shift      <= 8'h00;
                r1_byte_count    <= 4'd0;
                rx_shift         <= 8'h00;
                data_timeout     <= 20'd0;
                sector_count     <= 9'd0;
                write_byte_count <= 9'd0;
                r7_byte_count    <= 2'd0;
                write_resp_seen  <= 1'b0;

                if(cmd == 6'd0)
                begin
                    // CMD0 - specjalna obsługa (inicjalizacja)
                    spi_initialized  <= 1'b0;
                    init_clk_count   <= 7'd0;
                    init_clk_last    <= 1'b0;
                    sync_byte_count  <= 3'd0;
                    cmd0_retry_count <= 4'd0;

                    SD_CS   <= 1'b1;
                    SD_CLK  <= 1'b0;
                    SD_MOSI <= 1'b1;

                    state <= ST_INIT_CLOCK;
                end
                else
                begin
                    // Pozostałe komendy
                    SD_CS   <= 1'b0;
                    SD_CLK  <= 1'b0;
                    SD_MOSI <= 1'b1;
                    state   <= ST_CMD_START;
                end
            end
            else if(start && (!sd_present || !sd_power_on))
            begin
                // Brak karty LUB zasilanie wyłączone - nie wykonuj
                r1 <= 8'hFF;
                if(!no_card_done)
                begin
                    done         <= 1'b1;
                    no_card_done <= 1'b1;
                end
            end
            else
            begin
                no_card_done <= 1'b0;
            end
        end

        //======================================================================
        // ST_INIT_CLOCK - 80 taktów startowych (CS=1, MOSI=1)
        //======================================================================
        ST_INIT_CLOCK:
        begin
            SD_CS   <= 1'b1;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                begin
                    SD_CLK <= 1'b1;

                    if(init_clk_count == 7'd79)
                        init_clk_last <= 1'b1;
                    else
                        init_clk_count <= init_clk_count + 1'b1;
                end
                else
                begin
                    SD_CLK <= 1'b0;

                    if(init_clk_last)
                    begin
                        init_clk_last  <= 1'b0;
                        init_clk_count <= 7'd0;
                        state          <= ST_SYNC_CLOCKS;
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_SEND_DUMMY - 8 x 0xFF (CS=1)
        //======================================================================
        ST_SEND_DUMMY:
        begin
            SD_CS   <= 1'b1;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count   <= 3'd0;
                        dummy_count <= dummy_count + 1'b1;

                        if(dummy_count == 3'd7)
                        begin
                            dummy_count <= 3'd0;
                            SD_CS       <= 1'b0;
                            state       <= ST_DONE;
                        end
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_SYNC_CLOCKS - 8 x 0xFF (CS=1) przed CMD0
        //======================================================================
        ST_SYNC_CLOCKS:
        begin
            SD_CS   <= 1'b1;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count       <= 3'd0;
                        sync_byte_count <= sync_byte_count + 1'b1;

                        if(sync_byte_count == 3'd7)
                        begin
                            sync_byte_count <= 3'd0;
                            arg_reg         <= 32'h00000000;
                            crc_reg         <= 8'h95;
                            SD_CS           <= 1'b0;
                            state           <= ST_CMD_START;
                        end
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_CMD_START - start komendy
        //======================================================================
        ST_CMD_START:
        begin
            SD_CS   <= 1'b0;
            SD_CLK  <= 1'b0;
            SD_MOSI <= 1'b1;

            div_count  <= 7'd0;
            byte_count <= 3'd0;
            bit_count  <= 3'd0;

            if(!sd_present)
            begin
                // Karta została wyjęta - przerwij
                SD_CS   <= 1'b1;
                SD_CLK  <= 1'b0;
                SD_MOSI <= 1'b1;
                r1      <= 8'hFF;
                busy    <= 1'b0;
                done    <= 1'b1;
                state   <= ST_IDLE;
            end
            else if(cmd_reg == 6'd63)
            begin
                // Komenda dummy 0x3F - 8 x 0xFF
                SD_CS       <= 1'b1;
                dummy_count <= 3'd0;
                bit_count   <= 3'd0;
                state       <= ST_SEND_DUMMY;
            end
            else
            begin
                // Normalna komenda
                if(cmd_reg == 6'd0)
                    crc_reg <= 8'h95;
                else if(cmd_reg == 6'd8)
                    crc_reg <= 8'h87;

                tx_shift <= {1'b0, 1'b1, cmd_reg};
                SD_MOSI  <= 1'b0;
                state    <= ST_SEND;
            end
        end

        //======================================================================
        // ST_SEND - wysyłanie 6 bajtów komendy
        //======================================================================
        ST_SEND:
        begin
            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;

                        if(byte_count == 3'd5)
                        begin
                            // Koniec komendy - przejdź do oczekiwania na R1
                            SD_MOSI       <= 1'b1;
                            SD_CLK        <= 1'b0;
                            r1_rx_shift   <= 8'h00;
                            r1_byte_count <= 4'd0;
                            bit_count     <= 3'd0;
                            div_count     <= 7'd0;
                            state         <= ST_R1_WAIT;
                        end
                        else
                        begin
                            byte_count <= byte_count + 1'b1;

                            case(byte_count)
                            3'd0: begin tx_shift <= arg_reg[31:24]; SD_MOSI <= arg_reg[31]; end
                            3'd1: begin tx_shift <= arg_reg[23:16]; SD_MOSI <= arg_reg[23]; end
                            3'd2: begin tx_shift <= arg_reg[15:8];  SD_MOSI <= arg_reg[15]; end
                            3'd3: begin tx_shift <= arg_reg[7:0];   SD_MOSI <= arg_reg[7];  end
                            3'd4: begin tx_shift <= crc_reg;        SD_MOSI <= crc_reg[7];  end
                            default: begin tx_shift <= 8'hFF;       SD_MOSI <= 1'b1;        end
                            endcase
                        end
                    end
                    else
                    begin
                        bit_count <= bit_count + 1'b1;
                        SD_MOSI   <= tx_shift[6];
                        tx_shift  <= {tx_shift[6:0], 1'b0};
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_R1_WAIT - oczekiwanie na odpowiedź R1
        //======================================================================
        ST_R1_WAIT:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                begin
                    SD_CLK      <= 1'b1;
                    r1_rx_shift <= {r1_rx_shift[6:0], SD_MISO};

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        state     <= ST_R1_CHECK;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
                else
                    SD_CLK <= 1'b0;
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_R1_CHECK - sprawdzenie odpowiedzi R1
        //======================================================================
        ST_R1_CHECK:
        begin
            SD_CS   <= 1'b0;
            SD_CLK  <= 1'b0;
            SD_MOSI <= 1'b1;
            div_count <= 7'd0;

            if(r1_rx_shift != 8'hFF)
            begin
                r1 <= r1_rx_shift;

                if(cmd_reg == 6'd0)
                begin
                    // CMD0 - oczekiwana odpowiedź 0x01
                    if(r1_rx_shift == 8'h01)
                    begin
                        cmd0_retry_count <= 4'd0;
                        state            <= ST_DONE;
                    end
                    else if(cmd0_retry_count < 4'd5)
                    begin
                        cmd0_retry_count <= cmd0_retry_count + 1'b1;
                        SD_CS            <= 1'b1;
                        sync_byte_count  <= 3'd0;
                        bit_count        <= 3'd0;
                        state            <= ST_SYNC_CLOCKS;
                    end
                    else
                    begin
                        r1    <= 8'hFF;
                        state <= ST_DONE;
                    end
                end
                else if((cmd_reg == 6'd8) && (r1_rx_shift == 8'h01))
                begin
                    // CMD8 - przejdź do pominięcia R7
                    r7_byte_count <= 2'd0;
                    bit_count     <= 3'd0;
                    r1_rx_shift   <= 8'h00;
                    state         <= ST_R7_SKIP;
                end
                else if(((cmd_reg == 6'd17) || (cmd_reg == 6'd9) || (cmd_reg == 6'd10)) &&
                        (r1_rx_shift == 8'h00))
                begin
                    // CMD17/CMD9/CMD10 - odczyt danych
                    bit_count    <= 3'd0;
                    rx_shift     <= 8'd0;
                    sector_count <= 9'd0;
                    data_timeout <= 20'd0;
                    state        <= ST_DATA_WAIT;
                end
                else if((cmd_reg == 6'd58) && (r1_rx_shift == 8'h00))
                begin
                    // CMD58 - odczyt OCR
                    sector_count <= 9'd0;
                    bit_count    <= 3'd0;
                    rx_shift     <= 8'd0;
                    state        <= ST_OCR_READ;
                end
                else if((cmd_reg == 6'd24) && (r1_rx_shift == 8'h00))
                begin
                    // CMD24 - zapis bloku
                    sector_count     <= 9'd0;
                    bit_count        <= 3'd0;
                    write_byte_count <= 9'd0;
                    write_resp_seen  <= 1'b0;
                    tx_shift         <= 8'hFE;
                    SD_MOSI          <= 1'b1;
                    state            <= ST_WRITE_TOKEN;
                end
                else if(cmd_reg == 6'd55)
                begin
                    // CMD55 - przejdź do oczekiwania na ACMD41
                    r1_timeout <= 16'd0;
                    state      <= ST_ACMD_WAIT;
                end
                else
                    state <= ST_DONE;
            end
            else
            begin
                if(r1_byte_count == R1_BYTE_MAX)
                begin
                    r1    <= 8'hFF;
                    state <= ST_DONE;
                end
                else
                begin
                    r1_byte_count <= r1_byte_count + 1'b1;
                    r1_rx_shift   <= 8'h00;
                    bit_count     <= 3'd0;
                    state         <= ST_R1_WAIT;
                end
            end
        end

        //======================================================================
        // ST_ACMD_WAIT - czekaj na ACMD41 z CS=0
        //======================================================================
        ST_ACMD_WAIT:
        begin
            SD_CS   <= 1'b0;
            SD_CLK  <= 1'b0;
            SD_MOSI <= 1'b1;

            busy      <= 1'b0;
            done      <= 1'b1;
            div_count <= 7'd0;

            if(!sd_present)
            begin
                SD_CS <= 1'b1;
                r1    <= 8'hFF;
                state <= ST_IDLE;
            end
            else if(r1_timeout == R1_TIMEOUT_MAX)
            begin
                r1_timeout <= 16'd0;
                SD_CS      <= 1'b1;
                state      <= ST_IDLE;
            end
            else
            begin
                r1_timeout <= r1_timeout + 1'b1;

                if(start && (cmd == 6'd41))
                begin
                    r1_timeout <= 16'd0;
                    cmd_reg    <= cmd;
                    arg_reg    <= arg;
                    crc_reg    <= crc;
                    busy       <= 1'b1;
                    done       <= 1'b0;

                    byte_count    <= 3'd0;
                    bit_count     <= 3'd0;
                    r1_rx_shift   <= 8'h00;
                    r1_byte_count <= 4'd0;

                    tx_shift <= {1'b0, 1'b1, 6'd41};
                    SD_MOSI  <= 1'b0;
                    state    <= ST_SEND;
                end
            end
        end

        //======================================================================
        // ST_R7_SKIP - pomiń 4 bajty R7
        //======================================================================
        ST_R7_SKIP:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;

                        if(r7_byte_count == 2'd3)
                        begin
                            r7_byte_count <= 2'd0;
                            state         <= ST_DONE;
                        end
                        else
                            r7_byte_count <= r7_byte_count + 1'b1;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_DATA_WAIT - czekaj na token FE
        //======================================================================
        ST_DATA_WAIT:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                begin
                    SD_CLK   <= 1'b1;
                    rx_shift <= {rx_shift[6:0], SD_MISO};
                end
                else
                begin
                    SD_CLK <= 1'b0;

                    if(data_timeout == DATA_TIMEOUT_MAX)
                    begin
                        bit_count    <= 3'd0;
                        rx_shift     <= 8'd0;
                        data_timeout <= 20'd0;
                        state        <= ST_DONE;
                    end
                    else
                    begin
                        data_timeout <= data_timeout + 1'b1;

                        if(bit_count == 3'd7)
                        begin
                            if(rx_shift == 8'hFE)
                            begin
                                sector_count <= 9'd0;
                                bit_count    <= 3'd0;
                                rx_shift     <= 8'd0;
                                data_timeout <= 20'd0;
                                state        <= ST_DATA_READ;
                            end
                            else
                            begin
                                bit_count <= 3'd0;
                                rx_shift  <= 8'd0;
                            end
                        end
                        else
                            bit_count <= bit_count + 1'b1;
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_DATA_READ - odbiór 512 bajtów
        //======================================================================
        ST_DATA_READ:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                begin
                    SD_CLK   <= 1'b1;
                    rx_shift <= {rx_shift[6:0], SD_MISO};

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        state     <= ST_DATA_STORE;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
                else
                    SD_CLK <= 1'b0;
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_DATA_STORE - zapis odebranego bajtu
        //======================================================================
        ST_DATA_STORE:
        begin
            SD_CS   <= 1'b0;
            SD_CLK  <= 1'b0;
            SD_MOSI <= 1'b1;
            div_count <= 7'd0;

            // Zakończ po 16 bajtach (CMD9/CMD10) lub 512 bajtach (CMD17)
            if((((cmd_reg == 6'd9) || (cmd_reg == 6'd10)) && (sector_count == 9'd15)) ||
               ((cmd_reg == 6'd17) && (sector_count == 9'd511)))
            begin
                sector_count <= 9'd0;
                state        <= ST_DATA_CRC1;
            end
            else
            begin
                sector_count <= sector_count + 1'b1;
                rx_shift     <= 8'd0;
                state        <= ST_DATA_READ;
            end
        end

        //======================================================================
        // ST_DATA_CRC1 - CRC bajt 1
        //======================================================================
        ST_DATA_CRC1:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        state     <= ST_DATA_CRC2;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_DATA_CRC2 - CRC bajt 2
        //======================================================================
        ST_DATA_CRC2:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        state     <= ST_DONE;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_OCR_READ - odbiór 4 bajtów OCR (CMD58)
        //======================================================================
        ST_OCR_READ:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                begin
                    SD_CLK   <= 1'b1;
                    rx_shift <= {rx_shift[6:0], SD_MISO};

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        rx_shift  <= 8'd0;

                        if(sector_count == 9'd3)
                        begin
                            sector_count    <= 9'd0;
                            spi_initialized <= 1'b1;   // karta zainicjalizowana
                            state           <= ST_DONE;
                        end
                        else
                            sector_count <= sector_count + 1'b1;
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
                else
                    SD_CLK <= 1'b0;
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_WRITE_TOKEN - wysyłanie tokenu 0xFE (CMD24)
        //======================================================================
        ST_WRITE_TOKEN:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= tx_shift[7];

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count        <= 3'd0;
                        sector_count     <= 9'd0;
                        write_byte_count <= 9'd0;
                        tx_shift         <= buffer_dout;
                        SD_MOSI          <= buffer_dout[7];
                        state            <= ST_WRITE_DATA;
                    end
                    else
                    begin
                        bit_count <= bit_count + 1'b1;
                        tx_shift  <= {tx_shift[6:0], 1'b0};
                        SD_MOSI   <= tx_shift[6];
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_WRITE_DATA - wysyłanie 512 bajtów
        //======================================================================
        ST_WRITE_DATA:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= tx_shift[7];

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;

                        if(write_byte_count == 9'd511)
                        begin
                            sector_count <= 9'd0;
                            tx_shift     <= 8'hFF;
                            SD_MOSI      <= 1'b1;
                            state        <= ST_WRITE_CRC1;
                        end
                        else
                        begin
                            write_byte_count <= write_byte_count + 1'b1;
                            sector_count     <= sector_count + 1'b1;
                            tx_shift         <= buffer_dout;
                            SD_MOSI          <= buffer_dout[7];
                        end
                    end
                    else
                    begin
                        bit_count <= bit_count + 1'b1;
                        tx_shift  <= {tx_shift[6:0], 1'b0};
                        SD_MOSI   <= tx_shift[6];
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_WRITE_CRC1 - CRC zapisu, bajt 1
        //======================================================================
        ST_WRITE_CRC1:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= tx_shift[7];

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;
                        tx_shift  <= 8'hFF;
                        SD_MOSI   <= 1'b1;
                        state     <= ST_WRITE_CRC2;
                    end
                    else
                    begin
                        bit_count <= bit_count + 1'b1;
                        tx_shift  <= {tx_shift[6:0], 1'b0};
                        SD_MOSI   <= tx_shift[6];
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_WRITE_CRC2 - CRC zapisu, bajt 2
        //======================================================================
        ST_WRITE_CRC2:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= tx_shift[7];

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                    SD_CLK <= 1'b1;
                else
                begin
                    SD_CLK <= 1'b0;

                    if(bit_count == 3'd7)
                    begin
                        bit_count       <= 3'd0;
                        rx_shift        <= 8'd0;
                        write_resp_seen <= 1'b0;
                        state           <= ST_WRITE_RESP;
                    end
                    else
                    begin
                        bit_count <= bit_count + 1'b1;
                        tx_shift  <= {tx_shift[6:0], 1'b0};
                        SD_MOSI   <= tx_shift[6];
                    end
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_WRITE_RESP - odbiór odpowiedzi zapisu
        //======================================================================
        ST_WRITE_RESP:
        begin
            SD_CS   <= 1'b0;
            SD_MOSI <= 1'b1;

            if(div_count == spi_div - 1'b1)
            begin
                div_count <= 7'd0;

                if(SD_CLK == 1'b0)
                begin
                    SD_CLK   <= 1'b1;
                    rx_shift <= {rx_shift[6:0], SD_MISO};

                    if(bit_count == 3'd7)
                    begin
                        bit_count <= 3'd0;

                        if(({rx_shift[6:0], SD_MISO} & 8'h1F) == 8'h05)
                        begin
                            write_resp_seen <= 1'b1;
                            rx_shift        <= 8'd0;
                        end
                        else
                        begin
                            state    <= ST_DONE;
                            rx_shift <= 8'd0;
                        end
                    end
                    else
                        bit_count <= bit_count + 1'b1;
                end
                else
                begin
                    SD_CLK <= 1'b0;

                    if(write_resp_seen && (SD_MISO == 1'b1))
                        state <= ST_DONE;
                end
            end
            else
                div_count <= div_count + 1'b1;
        end

        //======================================================================
        // ST_DONE - zakończenie operacji
        //======================================================================
        ST_DONE:
        begin
            if(sd_power_on)
            begin
                SD_CS   <= 1'b1;
                SD_MOSI <= 1'b1;
            end
            else
            begin
                SD_CS   <= 1'b0;
                SD_MOSI <= 1'b0;
            end

            SD_CLK    <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b1;
            div_count <= 7'd0;
            state     <= ST_IDLE;
        end

        //======================================================================
        // DEFAULT - zabezpieczenie FSM
        //======================================================================
        default:
        begin
            state <= ST_IDLE;

            if(sd_power_on)
            begin
                SD_CS   <= 1'b1;
                SD_MOSI <= 1'b1;
            end
            else
            begin
                SD_CS   <= 1'b0;
                SD_MOSI <= 1'b0;
            end

            SD_CLK    <= 1'b0;
            busy      <= 1'b0;
            div_count <= 7'd0;
        end

        endcase
    end
end

endmodule