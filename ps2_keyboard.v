//==============================================================================
// ps2_keyboard.v - Kontroler klawiatury PS/2
//------------------------------------------------------------------------------
// Opis:
//   Modu³ realizuje komunikacjê z klawiatur¹ PS/2 (dwukierunkow¹).
//   Obs³uguje:
//     - odbiór kodu klawisza (8 bitów + parzystoœæ + STOP)
//     - nadawanie komend do klawiatury (np. LED, RESET)
//
// Po resecie:
//   - PS2_CLK  = Z (wysoka impedancja)
//   - PS2_DATA = Z (wysoka impedancja)
// Klawiatura ma pe³n¹ kontrolê nad magistral¹.
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module ps2_keyboard
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar systemowy 25 MHz
    input  wire        rst_n,           // reset aktywny stanem niskim

    //--------------------------------------------------
    // Linie PS/2 (dwukierunkowe)
    //--------------------------------------------------
    inout  wire        ps2_clk,         // linia zegara PS/2
    inout  wire        ps2_data,        // linia danych PS/2

    //--------------------------------------------------
    // Sterowanie z cpu_ram
    //--------------------------------------------------
    input  wire        start,           // rozpoczêcie transmisji do klawiatury
    input  wire [7:0]  tx_data,         // bajt wysy³any do klawiatury

    //--------------------------------------------------
    // Dane do cpu_ram
    //--------------------------------------------------
    output reg  [7:0]  rx_data,         // odebrany kod klawisza
    output reg         rx_ready,        // impuls gotowego odebranego bajtu
    output reg         busy             // zajêtoœæ nadajnika
);

`include "config.vh"

//==============================================================================
// 1. STEROWANIE LINIAMI PS/2
//------------------------------------------------------------------------------
// FPGA mo¿e tylko œci¹gaæ liniê do masy (open-drain), nigdy wymuszaæ 1.
//   clk_oe  = 1 -> PS2_CLK  = 0
//   clk_oe  = 0 -> PS2_CLK  = Z (wysoka impedancja)
//   data_oe = 1 -> PS2_DATA = 0
//   data_oe = 0 -> PS2_DATA = Z (wysoka impedancja)
//==============================================================================

reg clk_oe;                             // sterowanie lini¹ zegara
reg data_oe;                            // sterowanie lini¹ danych

assign ps2_clk  = (clk_oe)  ? 1'b0 : 1'bz;
assign ps2_data = (data_oe) ? 1'b0 : 1'bz;

//==============================================================================
// 2. SYNCHRONIZACJA WEJŒÆ PS/2
//------------------------------------------------------------------------------
// Dwa przerzutniki do synchronizacji asynchronicznych linii PS/2.
//==============================================================================

reg ps2_clk_ff0,  ps2_clk_ff1,  ps2_clk_ff2;
reg ps2_data_ff0, ps2_data_ff1, ps2_data_ff2;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        ps2_clk_ff0  <= 1'b1;
        ps2_clk_ff1  <= 1'b1;
        ps2_clk_ff2  <= 1'b1;

        ps2_data_ff0 <= 1'b1;
        ps2_data_ff1 <= 1'b1;
        ps2_data_ff2 <= 1'b1;
    end
    else
    begin
        // Synchronizacja zegara PS/2
        ps2_clk_ff0  <= ps2_clk;
        ps2_clk_ff1  <= ps2_clk_ff0;
        ps2_clk_ff2  <= ps2_clk_ff1;

        // Synchronizacja danych PS/2
        ps2_data_ff0 <= ps2_data;
        ps2_data_ff1 <= ps2_data_ff0;
        ps2_data_ff2 <= ps2_data_ff1;
    end
end

// Wykrycie opadaj¹cego zbocza zegara PS/2 (moment próbkowania danych)
wire ps2_clk_fall;
assign ps2_clk_fall = ps2_clk_ff2 & ~ps2_clk_ff1;

//==============================================================================
// 3. STANY ODBIORNIKA
//==============================================================================

localparam [3:0] ST_IDLE   = 4'd0;      // oczekiwanie na START
localparam [3:0] ST_DATA0  = 4'd1;      // bit danych 0
localparam [3:0] ST_DATA1  = 4'd2;      // bit danych 1
localparam [3:0] ST_DATA2  = 4'd3;      // bit danych 2
localparam [3:0] ST_DATA3  = 4'd4;      // bit danych 3
localparam [3:0] ST_DATA4  = 4'd5;      // bit danych 4
localparam [3:0] ST_DATA5  = 4'd6;      // bit danych 5
localparam [3:0] ST_DATA6  = 4'd7;      // bit danych 6
localparam [3:0] ST_DATA7  = 4'd8;      // bit danych 7
localparam [3:0] ST_PARITY = 4'd9;      // bit parzystoœci
localparam [3:0] ST_STOP   = 4'd10;     // bit STOP

//==============================================================================
// 4. REJESTRY ODBIORNIKA
//==============================================================================

reg [3:0] state;                        // aktualny stan odbiornika
reg [7:0] rx_shift;                     // rejestr przesuwny odebranych bitów
reg       parity_bit;                   // odebrany bit parzystoœci

//==============================================================================
// 5. ODBIORNIK PS/2
//------------------------------------------------------------------------------
// Ramka PS/2: START (0) + 8 bitów danych + PARITY + STOP (1)
// Próbkowanie na opadaj¹cym zboczu zegara PS/2.
//==============================================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rx_data    <= 8'h00;
        rx_ready   <= 1'b0;
        rx_shift   <= 8'h00;
        parity_bit <= 1'b0;
        state      <= ST_IDLE;
    end
    else
    begin
        // Domyœlnie brak nowego bajtu
        rx_ready <= 1'b0;

        // Próbkowanie tylko na opadaj¹cym zboczu zegara PS/2
        if(ps2_clk_fall)
        begin
            case(state)

                //--------------------------------------------------
                // Oczekiwanie na bit START
                //--------------------------------------------------
                ST_IDLE:
                begin
                    if(ps2_data_ff2 == 1'b0)
                        state <= ST_DATA0;
                end

                //--------------------------------------------------
                // Odbiór bitów danych (0..7)
                //--------------------------------------------------
                ST_DATA0: begin rx_shift[0] <= ps2_data_ff2; state <= ST_DATA1; end
                ST_DATA1: begin rx_shift[1] <= ps2_data_ff2; state <= ST_DATA2; end
                ST_DATA2: begin rx_shift[2] <= ps2_data_ff2; state <= ST_DATA3; end
                ST_DATA3: begin rx_shift[3] <= ps2_data_ff2; state <= ST_DATA4; end
                ST_DATA4: begin rx_shift[4] <= ps2_data_ff2; state <= ST_DATA5; end
                ST_DATA5: begin rx_shift[5] <= ps2_data_ff2; state <= ST_DATA6; end
                ST_DATA6: begin rx_shift[6] <= ps2_data_ff2; state <= ST_DATA7; end
                ST_DATA7: begin rx_shift[7] <= ps2_data_ff2; state <= ST_PARITY; end

                //--------------------------------------------------
                // Bit parzystoœci
                //--------------------------------------------------
                ST_PARITY:
                begin
                    parity_bit <= ps2_data_ff2;
                    state      <= ST_STOP;
                end

                //--------------------------------------------------
                // Bit STOP + weryfikacja ramki
                //--------------------------------------------------
                ST_STOP:
                begin
                    if ((ps2_data_ff2 == 1'b1) &&
                        ((^rx_shift) != parity_bit))
                    begin
                        // Poprawna ramka - przekazanie danych dalej
                        rx_data  <= rx_shift;
                        rx_ready <= 1'b1;
                    end

                    state <= ST_IDLE;
                end

                default:
                    state <= ST_IDLE;

            endcase
        end
    end
end

//==============================================================================
// 6. STANY NADAJNIKA
//==============================================================================

localparam [3:0] TX_IDLE        = 4'd0; // oczekiwanie na polecenie
localparam [3:0] TX_REQ         = 4'd1; // przygotowanie transmisji
localparam [3:0] TX_START       = 4'd2; // wys³anie bitu START
localparam [3:0] TX_RELEASE_CLK = 4'd3; // zwolnienie zegara
localparam [3:0] TX_BIT0        = 4'd4; // bit danych 0
localparam [3:0] TX_BIT1        = 4'd5; // bit danych 1
localparam [3:0] TX_BIT2        = 4'd6; // bit danych 2
localparam [3:0] TX_BIT3        = 4'd7; // bit danych 3
localparam [3:0] TX_BIT4        = 4'd8; // bit danych 4
localparam [3:0] TX_BIT5        = 4'd9; // bit danych 5
localparam [3:0] TX_BIT6        = 4'd10;// bit danych 6
localparam [3:0] TX_BIT7        = 4'd11;// bit danych 7
localparam [3:0] TX_PARITY      = 4'd12;// bit parzystoœci
localparam [3:0] TX_STOP        = 4'd13;// bit STOP
localparam [3:0] TX_ACK         = 4'd14;// oczekiwanie na ACK
localparam [3:0] TX_DONE        = 4'd15;// zakoñczenie transmisji

//==============================================================================
// 7. REJESTRY NADAJNIKA
//==============================================================================

reg [12:0] tx_timer;                    // licznik czasu transmisji
reg [3:0]  tx_state;                    // aktualny stan nadajnika
reg [7:0]  tx_shift;                    // rejestr przesuwny danych TX
reg        tx_parity;                   // bit parzystoœci transmisji

//==============================================================================
// 8. NADAJNIK PS/2
//------------------------------------------------------------------------------
// Ramka PS/2: START (0) + 8 bitów danych + PARITY + STOP (1)
// Zegar generowany przez klawiaturê (po zwolnieniu linii CLK).
//==============================================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        clk_oe    <= 1'b0;
        data_oe   <= 1'b0;
        busy      <= 1'b0;
        tx_timer  <= 13'd0;
        tx_shift  <= 8'h00;
        tx_parity <= 1'b1;
        tx_state  <= TX_IDLE;
    end
    else
    begin
        case(tx_state)

            //--------------------------------------------------
            // Oczekiwanie na rozpoczêcie transmisji
            //--------------------------------------------------
            TX_IDLE:
            begin
                clk_oe    <= 1'b0;
                data_oe   <= 1'b0;
                busy      <= 1'b0;

                tx_timer  <= 13'd0;
                tx_parity <= 1'b1;

                if(start)
                begin
                    busy     <= 1'b1;
                    tx_shift <= tx_data;
                    tx_timer <= 13'd0;
                    tx_state <= TX_REQ;
                end
            end

            //--------------------------------------------------
            // Request To Send - FPGA przejmuje zegar PS/2
            //--------------------------------------------------
            TX_REQ:
            begin
                clk_oe  <= 1'b1;            // CLK = LOW
                data_oe <= 1'b0;            // DATA = Z
                busy    <= 1'b1;

                if(tx_timer < 13'd3750)
                    tx_timer <= tx_timer + 13'd1;
                else
                begin
                    tx_timer <= 13'd0;
                    tx_state <= TX_START;
                end
            end

            //--------------------------------------------------
            // Wys³anie bitu START
            //--------------------------------------------------
            TX_START:
            begin
                clk_oe  <= 1'b1;            // CLK = LOW
                data_oe <= 1'b1;            // DATA = 0 (START)
                busy    <= 1'b1;

                if(tx_timer < 13'd5000)
                    tx_timer <= tx_timer + 13'd1;
                else
                begin
                    tx_timer <= 13'd0;
                    tx_state <= TX_RELEASE_CLK;
                end
            end

            //--------------------------------------------------
            // Zwolnienie zegara - klawiatura generuje CLK
            //--------------------------------------------------
            TX_RELEASE_CLK:
            begin
                clk_oe  <= 1'b0;
                data_oe <= 1'b1;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                    tx_state <= TX_BIT0;
            end

            //--------------------------------------------------
            // Wysy³anie bitów danych (0..7)
            //--------------------------------------------------
            TX_BIT0:
            begin
                data_oe <= ~tx_shift[0];    // bit 0 -> 0, bit 1 -> Z
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT1;
                end
            end

            TX_BIT1:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT2;
                end
            end

            TX_BIT2:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT3;
                end
            end

            TX_BIT3:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT4;
                end
            end

            TX_BIT4:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT5;
                end
            end

            TX_BIT5:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT6;
                end
            end

            TX_BIT6:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_BIT7;
                end
            end

            TX_BIT7:
            begin
                data_oe <= ~tx_shift[0];
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    tx_parity <= tx_parity ^ tx_shift[0];
                    tx_shift  <= {1'b0, tx_shift[7:1]};
                    tx_state  <= TX_PARITY;
                end
            end

            //--------------------------------------------------
            // Bit parzystoœci (odd parity)
            //--------------------------------------------------
            TX_PARITY:
            begin
                data_oe <= ~tx_parity;
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                    tx_state <= TX_STOP;
            end

            //--------------------------------------------------
            // Bit STOP
            //--------------------------------------------------
            TX_STOP:
            begin
                data_oe <= 1'b0;            // STOP = 1 (Z)
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                    tx_state <= TX_ACK;
            end

            //--------------------------------------------------
            // Odbiór potwierdzenia ACK od klawiatury
            //--------------------------------------------------
            TX_ACK:
            begin
                data_oe <= 1'b0;
                clk_oe  <= 1'b0;
                busy    <= 1'b1;

                if(ps2_clk_fall)
                begin
                    // ACK = LOW na DATA (niezale¿nie od wartoœci)
                    tx_state <= TX_DONE;
                end
            end

            //--------------------------------------------------
            // Zakoñczenie transmisji
            //--------------------------------------------------
            TX_DONE:
            begin
                clk_oe   <= 1'b0;
                data_oe  <= 1'b0;
                busy     <= 1'b0;
                tx_state <= TX_IDLE;
            end

            //--------------------------------------------------
            // Zabezpieczenie FSM
            //--------------------------------------------------
            default:
                tx_state <= TX_IDLE;

        endcase
    end
end

endmodule