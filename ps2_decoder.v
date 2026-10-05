//==============================================================================
// ps2_decoder.v - Dekoder kodów klawiatury PS/2
//------------------------------------------------------------------------------
// Opis:
//   Modu³ dekoduje kody skanowania PS/2 na kody ASCII.
//   Obs³uguje:
//     - normalne klawisze (litery, cyfry, znaki specjalne)
//     - SHIFT (lewy i prawy)
//     - CAPS LOCK, NUM LOCK, SCROLL LOCK
//     - klawisze rozszerzone (strza³ki, Insert, Delete, Home, End, PgUp, PgDn)
//     - klawisze funkcyjne (F1-F12 - ignorowane)
//     - sekwencjê PAUSE (ignorowana)
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module ps2_decoder
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire       clk,              // zegar 25 MHz
    input  wire       rst_n,            // reset aktywny stanem niskim

    //--------------------------------------------------
    // Wejœcie z odbiornika PS/2
    //--------------------------------------------------
    input  wire [7:0] rx_data,          // odebrany bajt z PS/2
    input  wire       rx_ready,         // impuls - nowy bajt

    //--------------------------------------------------
    // Wyjœcie do cpu_ram
    //--------------------------------------------------
    output reg  [7:0] key_code,         // kod ASCII klawisza
    output reg        key_ready,        // impuls - nowy znak

    //--------------------------------------------------
    // Stany klawiszy modyfikuj¹cych
    //--------------------------------------------------
    output reg        caps_lock,        // stan CAPS LOCK
    output reg        num_lock,         // stan NUM LOCK
    output reg        scroll_lock       // stan SCROLL LOCK
);

//==============================================================================
// 1. STANY FSM
//==============================================================================

localparam [2:0] ST_NORMAL = 3'd0;      // odbiór normalnego kodu
localparam [2:0] ST_BREAK  = 3'd1;      // odbiór kodu puszczenia (po F0)
localparam [2:0] ST_EXT    = 3'd2;      // odbiór kodu rozszerzonego (po E0/E1)
localparam [2:0] ST_PAUSE  = 3'd3;      // ignorowanie PAUSE

//==============================================================================
// 2. REJESTRY FSM
//==============================================================================

reg [2:0] state;                        // aktualny stan FSM
reg       shift_state;                  // stan SHIFT (0 = zwolniony, 1 = wciœniêty)

//==============================================================================
// 3. PAMIÊÆ ROM ZNAKÓW ASCII
//------------------------------------------------------------------------------
// Konwersja kodu skanowania PS/2 na znak ASCII.
//==============================================================================

wire [7:0] ascii_code;                  // znak ASCII z ROM

ps2_ascii_rom_async u_ps2_ascii_rom
(
    .a   (rx_data),                     // adres ROM = kod skanowania PS/2
    .spo (ascii_code)                   // wyjœcie ROM = znak ASCII
);

//==============================================================================
// 4. KONWERSJA PS/2 -> ASCII (z SHIFT i CAPS LOCK)
//------------------------------------------------------------------------------
// Funkcja kombinacyjna uwzglêdniaj¹ca:
//   - CAPS LOCK (wielkie litery)
//   - SHIFT (znaki specjalne)
//==============================================================================

function [7:0] convert_ascii;
    input [7:0] scan;                   // kod skanowania PS/2
    input [7:0] ascii;                  // znak ASCII z ROM
    begin
        convert_ascii = ascii;

        // Znak ` i ~
        if (scan == 8'h0E)
        begin
            if (shift_state)
                convert_ascii = 8'h7E;  // ~
            else
                convert_ascii = 8'h60;  // `
        end

        // Obs³uga wielkich liter
        if ((ascii >= "a") && (ascii <= "z"))
        begin
            if (caps_lock ^ shift_state)
                convert_ascii = ascii - 8'd32;
        end

        // Znaki specjalne po SHIFT
        if (shift_state)
        begin
            case(scan)
                // Cyfry
                8'h16: convert_ascii = "!";
                8'h1E: convert_ascii = "@";
                8'h26: convert_ascii = "#";
                8'h25: convert_ascii = "$";
                8'h2E: convert_ascii = "%";
                8'h36: convert_ascii = "^";
                8'h3D: convert_ascii = "&";
                8'h3E: convert_ascii = "*";
                8'h46: convert_ascii = "(";
                8'h45: convert_ascii = ")";

                // Znaki
                8'h4C: convert_ascii = ":";
                8'h52: convert_ascii = 8'h22;
                8'h41: convert_ascii = "<";
                8'h49: convert_ascii = ">";
                8'h4A: convert_ascii = "?";
                8'h54: convert_ascii = "{";
                8'h5B: convert_ascii = "}";
                8'h5D: convert_ascii = "|";
                8'h4E: convert_ascii = "_";
                8'h55: convert_ascii = "+";
                8'h0E: convert_ascii = "~";

                default: convert_ascii = convert_ascii;
            endcase
        end
    end
endfunction

//==============================================================================
// 5. G£ÓWNA MASZYNA STANÓW
//------------------------------------------------------------------------------
// Dekoduje kody skanowania PS/2 na znaki ASCII.
//==============================================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state       <= ST_NORMAL;
        key_code    <= 8'h00;
        key_ready   <= 1'b0;
        caps_lock   <= 1'b0;
        num_lock    <= 1'b0;
        scroll_lock <= 1'b0;
        shift_state <= 1'b0;
    end
    else
    begin
        // Domyœlnie brak nowego znaku
        key_ready <= 1'b0;

        // Dekodowanie tylko po odebraniu bajtu PS/2
        if(rx_ready)
        begin
            case(state)

                //--------------------------------------------------
                // ST_NORMAL - odbiór normalnego kodu klawisza
                //--------------------------------------------------
                ST_NORMAL:
                begin
                    // F0 - puszczenie klawisza
                    if(rx_data == 8'hF0)
                        state <= ST_BREAK;

                    // E0 - kod rozszerzony
                    else if(rx_data == 8'hE0)
                        state <= ST_EXT;

                    // E1 - Pause/Break
                    else if(rx_data == 8'hE1)
                        state <= ST_PAUSE;

                    // CAPS LOCK / NUM LOCK / SCROLL LOCK
                    else if(rx_data == 8'h58 ||
                            rx_data == 8'h77 ||
                            rx_data == 8'h7E)
                    begin
                        if(rx_data == 8'h58)
                            caps_lock <= ~caps_lock;
                        else if(rx_data == 8'h77)
                            num_lock <= ~num_lock;
                        else if(rx_data == 8'h7E)
                            scroll_lock <= ~scroll_lock;

                        key_code  <= 8'h00;
                        key_ready <= 1'b0;
                    end

                    // Lewy SHIFT
                    else if(rx_data == 8'h12)
                        shift_state <= 1'b1;

                    // Prawy SHIFT
                    else if(rx_data == 8'h59)
                        shift_state <= 1'b1;

                    // CTRL - ignorowany
                    else if(rx_data == 8'h14)
                    begin
                        // CTRL - ignorowany
                    end

                    // ALT - ignorowany
                    else if(rx_data == 8'h11)
                    begin
                        // LEFT ALT - ignorowany
                    end

                    // Klawisze funkcyjne F1-F12 - ignorowane
                    else if(rx_data == 8'h05 ||
                            rx_data == 8'h06 ||
                            rx_data == 8'h04 ||
                            rx_data == 8'h0C ||
                            rx_data == 8'h03 ||
                            rx_data == 8'h0B ||
                            rx_data == 8'h83 ||
                            rx_data == 8'h0A ||
                            rx_data == 8'h01 ||
                            rx_data == 8'h09 ||
                            rx_data == 8'h78 ||
                            rx_data == 8'h07)
                    begin
                        // F1-F12 - ignorowane
                    end

                    // Klawiatura numeryczna (NUM LOCK w³¹czony)
                    else if(num_lock &&
                            (rx_data == 8'h70 ||
                             rx_data == 8'h69 ||
                             rx_data == 8'h72 ||
                             rx_data == 8'h7A ||
                             rx_data == 8'h6B ||
                             rx_data == 8'h73 ||
                             rx_data == 8'h74 ||
                             rx_data == 8'h6C ||
                             rx_data == 8'h75 ||
                             rx_data == 8'h7D ||
                             rx_data == 8'h71 ||
                             rx_data == 8'h79 ||
                             rx_data == 8'h7B ||
                             rx_data == 8'h7C))
                    begin
                        case(rx_data)
                            8'h70: key_code <= 8'h30;   // 0
                            8'h69: key_code <= 8'h31;   // 1
                            8'h72: key_code <= 8'h32;   // 2
                            8'h7A: key_code <= 8'h33;   // 3
                            8'h6B: key_code <= 8'h34;   // 4
                            8'h73: key_code <= 8'h35;   // 5
                            8'h74: key_code <= 8'h36;   // 6
                            8'h6C: key_code <= 8'h37;   // 7
                            8'h75: key_code <= 8'h38;   // 8
                            8'h7D: key_code <= 8'h39;   // 9
                            8'h71: key_code <= 8'h2E;   // .
                            8'h79: key_code <= 8'h2B;   // +
                            8'h7B: key_code <= 8'h2D;   // -
                            8'h7C: key_code <= 8'h2A;   // *
                            default: key_code <= 8'h00;
                        endcase
                        key_ready <= 1'b1;
                    end

                    // Zwyk³y klawisz - pobranie znaku ASCII
                    else
                    begin
                        key_code <= convert_ascii(rx_data, ascii_code);
                        key_ready <= 1'b1;
                    end
                end

                //--------------------------------------------------
                // ST_BREAK - drugi bajt po F0 (puszczenie klawisza)
                //--------------------------------------------------
                ST_BREAK:
                begin
                    // Puszczenie lewego SHIFT
                    if(rx_data == 8'h12)
                        shift_state <= 1'b0;

                    // Puszczenie prawego SHIFT
                    else if(rx_data == 8'h59)
                        shift_state <= 1'b0;

                    // Puszczenie CTRL
                    else if(rx_data == 8'h14)
                    begin
                        // CTRL - ignorowany
                    end

                    state <= ST_NORMAL;
                end

                //--------------------------------------------------
                // ST_EXT - drugi bajt po E0/E1 (kod rozszerzony)
                //--------------------------------------------------
                ST_EXT:
                begin
                    case(rx_data)
                        8'h75: begin key_code <= 8'h80; key_ready <= 1'b1; end // strza³ka w górê
                        8'h72: begin key_code <= 8'h81; key_ready <= 1'b1; end // strza³ka w dó³
                        8'h6B: begin key_code <= 8'h82; key_ready <= 1'b1; end // strza³ka w lewo
                        8'h74: begin key_code <= 8'h83; key_ready <= 1'b1; end // strza³ka w prawo
                        8'h70: begin key_code <= 8'h84; key_ready <= 1'b1; end // Insert
                        8'h71: begin key_code <= 8'h85; key_ready <= 1'b1; end // Delete
                        8'h6C: begin key_code <= 8'h86; key_ready <= 1'b1; end // Home
                        8'h69: begin key_code <= 8'h87; key_ready <= 1'b1; end // End
                        8'h7D: begin key_code <= 8'h88; key_ready <= 1'b1; end // Page Up
                        8'h7A: begin key_code <= 8'h89; key_ready <= 1'b1; end // Page Down
                    endcase

                    state <= ST_NORMAL;
                end

                //--------------------------------------------------
                // ST_PAUSE - ignorowanie sekwencji PAUSE
                //--------------------------------------------------
                ST_PAUSE:
                begin
                    if(rx_data == 8'h77)
                        state <= ST_NORMAL;
                end

                //--------------------------------------------------
                // DEFAULT - zabezpieczenie FSM
                //--------------------------------------------------
                default:
                    state <= ST_NORMAL;

            endcase
        end
    end
end

endmodule