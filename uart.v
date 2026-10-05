//==============================================================================
// uart.v - Kontroler UART (Universal Asynchronous Receiver/Transmitter)
//------------------------------------------------------------------------------
// Opis:
//   Modu³ realizuje transmisjê i odbiór danych przez UART.
//   Obs³uguje 5 prêdkoœci transmisji (wybór przez baud_sel).
//   Ramka: 1 bit startu, 8 bitów danych, 1 bit stopu (8N1).
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Prêdkoœci transmisji (dla 25 MHz):
//   baud_sel = 0 -> 9600 b/s
//   baud_sel = 1 -> 19200 b/s
//   baud_sel = 2 -> 38400 b/s
//   baud_sel = 3 -> 57600 b/s
//   baud_sel = 4 -> 115200 b/s
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module uart
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar systemowy 25 MHz
    input  wire        rst_n,           // reset aktywny stanem niskim

    //--------------------------------------------------
    // Linie UART
    //--------------------------------------------------
    input  wire        rxd,             // linia RX
    output reg         txd,             // linia TX

    //--------------------------------------------------
    // Interfejs danych
    //--------------------------------------------------
    input  wire [7:0]  data_in,         // dane do nadania
    output reg  [7:0]  data_out,        // odebrane dane
    input  wire        wr,              // impuls zapisu (rozpoczêcie nadawania)
    input  wire        rd,              // impuls odczytu (kasowanie rx_ready)

    //--------------------------------------------------
    // Konfiguracja
    //--------------------------------------------------
    input  wire [3:0]  baud_sel,        // wybór prêdkoœci transmisji

    //--------------------------------------------------
    // Status i przerwania
    //--------------------------------------------------
    output reg         rx_ready,        // 1 = odebrano nowy bajt
    output reg         tx_busy,         // 1 = trwa nadawanie
    output reg         irq_rx,          // impuls przerwania RX
    output reg         irq_tx           // impuls przerwania TX
);

`include "fpga_regs.vh"

//==============================================================================
// 1. PARAMETRY PRÊDKOŒCI TRANSMISJI
//------------------------------------------------------------------------------
// Dzielnik zegara dla wybranej prêdkoœci transmisji.
// half_baud = baud_div / 2 (do próbkowania œrodka bitu).
//==============================================================================

reg [15:0] baud_div;                    // dzielnik prêdkoœci
reg [15:0] half_baud;                   // po³owa dzielnika

always @(*)
begin
    case (baud_sel)
        4'h0: baud_div = 16'd2604;      // 9600 b/s
        4'h1: baud_div = 16'd1302;      // 19200 b/s
        4'h2: baud_div = 16'd651;       // 38400 b/s
        4'h3: baud_div = 16'd434;       // 57600 b/s
        4'h4: baud_div = 16'd217;       // 115200 b/s
        default: baud_div = 16'd2604;   // 9600 b/s
    endcase

    half_baud = baud_div >> 1;
end

//==============================================================================
// 2. SYNCHRONIZACJA WEJŒCIA RXD
//------------------------------------------------------------------------------
// Dwa przerzutniki do synchronizacji asynchronicznego wejœcia rxd.
//==============================================================================

reg rxd_ff1;
reg rxd_ff2;

always @(posedge clk)
begin
    rxd_ff1 <= rxd;
    rxd_ff2 <= rxd_ff1;
end

//==============================================================================
// 3. NADAJNIK (TX)
//------------------------------------------------------------------------------
// Ramka: START (0) + 8 bitów danych (LSB first) + STOP (1)
// tx_shift[0] = aktualny bit do wys³ania
// tx_shift[8:1] = pozosta³e bity danych
//==============================================================================

reg [15:0] tx_cnt;                      // licznik taktów w bicie
reg [3:0]  tx_bit_cnt;                  // licznik bitów (0..9)
reg [8:0]  tx_shift;                    // rejestr przesuwny TX

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        txd        <= 1'b1;
        tx_busy    <= 1'b0;
        irq_tx     <= 1'b0;
        tx_cnt     <= 16'd0;
        tx_bit_cnt <= 4'd0;
        tx_shift   <= 9'h1FF;
    end
    else
    begin
        irq_tx <= 1'b0;

        //--------------------------------------------------
        // Rozpoczêcie nadawania
        //--------------------------------------------------
        if (wr && !tx_busy)
        begin
            tx_shift   <= {data_in, 1'b0};  // dane + bit startu
            tx_bit_cnt <= 4'd0;
            tx_cnt     <= 16'd0;
            tx_busy    <= 1'b1;
        end

        //--------------------------------------------------
        // Nadawanie w toku
        //--------------------------------------------------
        if (tx_busy)
        begin
            if (tx_cnt == baud_div - 1)
            begin
                tx_cnt <= 16'd0;

                if (tx_bit_cnt == 4'd9)
                begin
                    // Koniec ramki - bit STOP
                    txd        <= 1'b1;
                    tx_busy    <= 1'b0;
                    irq_tx     <= 1'b1;
                end
                else
                begin
                    // Wyœlij kolejny bit
                    txd        <= tx_shift[0];
                    tx_shift   <= {1'b1, tx_shift[8:1]};
                    tx_bit_cnt <= tx_bit_cnt + 1'b1;
                end
            end
            else
                tx_cnt <= tx_cnt + 1'b1;
        end
    end
end

//==============================================================================
// 4. ODBIORNIK (RX)
//------------------------------------------------------------------------------
// Ramka: START (0) + 8 bitów danych (LSB first) + STOP (1)
// Próbkowanie w œrodku bitu (half_baud).
//==============================================================================

reg [15:0] rx_cnt;                      // licznik taktów w bicie
reg [3:0]  rx_bit_cnt;                  // licznik bitów
reg [7:0]  rx_shift;                    // rejestr przesuwny RX
reg        rx_busy;                     // 1 = odbiór w toku

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        data_out   <= 8'h00;
        rx_ready   <= 1'b0;
        irq_rx     <= 1'b0;
        rx_busy    <= 1'b0;
        rx_cnt     <= 16'd0;
        rx_bit_cnt <= 4'd0;
        rx_shift   <= 8'h00;
    end
    else
    begin
        irq_rx <= 1'b0;

        //--------------------------------------------------
        // Kasowanie rx_ready przy odczycie
        //--------------------------------------------------
        if (rd)
            rx_ready <= 1'b0;

        //--------------------------------------------------
        // Wykrycie bitu START
        //--------------------------------------------------
        if (!rx_busy && !rxd_ff2)
        begin
            rx_busy    <= 1'b1;
            rx_cnt     <= 16'd0;
            rx_bit_cnt <= 4'd0;
        end
        //--------------------------------------------------
        // Odbiór w toku
        //--------------------------------------------------
        else if (rx_busy)
        begin
            if (rx_bit_cnt == 4'd0)
            begin
                //--------------------------------------------------
                // Weryfikacja bitu START (œrodek bitu)
                //--------------------------------------------------
                if (rx_cnt == half_baud - 1)
                begin
                    rx_cnt <= 16'd0;

                    if (rxd_ff2)
                        rx_busy <= 1'b0;        // fa³szywy start
                    else
                        rx_bit_cnt <= 4'd1;
                end
                else
                    rx_cnt <= rx_cnt + 1'b1;
            end
            else
            begin
                //--------------------------------------------------
                // Odbiór bitów danych (próbkowanie w œrodku bitu)
                //--------------------------------------------------
                if (rx_cnt == baud_div - 1)
                begin
                    rx_cnt <= 16'd0;

                    if (rx_bit_cnt <= 4'd8)
                        rx_shift[rx_bit_cnt - 1] <= rxd_ff2;
                    else
                    begin
                        data_out <= rx_shift;
                        rx_ready <= 1'b1;
                        irq_rx   <= 1'b1;
                        rx_busy  <= 1'b0;
                    end

                    rx_bit_cnt <= rx_bit_cnt + 1'b1;
                end
                else
                    rx_cnt <= rx_cnt + 1'b1;
            end
        end
    end
end

endmodule