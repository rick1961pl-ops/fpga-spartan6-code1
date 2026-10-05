//==============================================================================
// demo_start.v - Demo startowe (wyœwietlanie tekstu powitalnego)
//------------------------------------------------------------------------------
// Opis:
//   Modu³ wyœwietla tekst powitalny w buforze tekstowym, czeka 3 sekundy,
//   a nastêpnie kasuje ca³y bufor. Demo uruchamia siê po resecie.
//
// Tekst:
//   "VGA & PS2 & UART & ALU bios (c) Ryszard Paulch 2026"
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module demo_start
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar 25 MHz
    input  wire        rst_n,           // reset aktywny stanem niskim

    //--------------------------------------------------
    // Sterowanie buforem tekstowym
    //--------------------------------------------------
    output reg         active,          // 1 = demo aktywne (przejmuje RAM)
    output reg         we,              // zezwolenie na zapis
    output reg  [12:0] addr,            // adres komórki tekstowej
    output wire [15:0] data             // dane (ASCII + atrybut)
);

//==============================================================================
// 1. PARAMETRY
//==============================================================================

localparam [26:0] WAIT_TIME = 27'd75000000;   // 3 sekundy przy 25 MHz
localparam [12:0] RAM_LAST  = 13'd4799;       // ostatni adres bufora (80x60)
localparam [12:0] TEXT_LAST = 13'd50;         // ostatni znak tekstu

//==============================================================================
// 2. STANY FSM
//==============================================================================

localparam [3:0] ST_PREP_WRITE = 4'd0;  // przygotowanie zapisu znaku
localparam [3:0] ST_WRITE      = 4'd1;  // zapis znaku
localparam [3:0] ST_WAIT       = 4'd2;  // oczekiwanie 3 sekundy
localparam [3:0] ST_PREP       = 4'd3;  // przygotowanie kasowania
localparam [3:0] ST_CLEAR      = 4'd4;  // kasowanie bufora
localparam [3:0] ST_FINISH     = 4'd5;  // zakoñczenie demo
localparam [3:0] ST_DONE       = 4'd6;  // demo zakoñczone

//==============================================================================
// 3. REJESTRY FSM
//==============================================================================

reg [3:0]  state;                       // aktualny stan
reg [26:0] timer;                       // licznik opóŸnienia (3 s)

//==============================================================================
// 4. DANE TEKSTU
//------------------------------------------------------------------------------
// [15:8] = atrybut koloru
// [7:0]  = kod ASCII
//==============================================================================

function [15:0] demo_data;
    input [6:0] index;
    begin
        case(index)
            7'd0:  demo_data = 16'hE056; // V
            7'd1:  demo_data = 16'hE047; // G
            7'd2:  demo_data = 16'hE041; // A
            7'd3:  demo_data = 16'hFF20; // spacja
            7'd4:  demo_data = 16'hFF26; // &
            7'd5:  demo_data = 16'hFF20; // spacja
            7'd6:  demo_data = 16'hE350; // P
            7'd7:  demo_data = 16'hE353; // S
            7'd8:  demo_data = 16'hE332; // 2
            7'd9:  demo_data = 16'hFF20; // spacja
            7'd10: demo_data = 16'hFF26; // &
            7'd11: demo_data = 16'hFF20; // spacja
            7'd12: demo_data = 16'h1F55; // U
            7'd13: demo_data = 16'h1F41; // A
            7'd14: demo_data = 16'h1F52; // R
            7'd15: demo_data = 16'h1F54; // T
            7'd16: demo_data = 16'hFF20; // spacja
            7'd17: demo_data = 16'hFF26; // &
            7'd18: demo_data = 16'hFF20; // spacja
            7'd19: demo_data = 16'hFC41; // A
            7'd20: demo_data = 16'hFC4C; // L
            7'd21: demo_data = 16'hFC55; // U
            7'd22: demo_data = 16'hFF20; // spacja
            7'd23: demo_data = 16'h1C62; // b
            7'd24: demo_data = 16'h1C69; // i
            7'd25: demo_data = 16'h1C6F; // o
            7'd26: demo_data = 16'h1C73; // s
            7'd27: demo_data = 16'hFF20; // spacja
            7'd28: demo_data = 16'hFF28; // (
            7'd29: demo_data = 16'hFF63; // c
            7'd30: demo_data = 16'hFF29; // )
            7'd31: demo_data = 16'hFF20; // spacja
            7'd32: demo_data = 16'hFF52; // R
            7'd33: demo_data = 16'hFF79; // y
            7'd34: demo_data = 16'hFF73; // s
            7'd35: demo_data = 16'hFF7A; // z
            7'd36: demo_data = 16'hFF61; // a
            7'd37: demo_data = 16'hFF72; // r
            7'd38: demo_data = 16'hFF64; // d
            7'd39: demo_data = 16'hFF20; // spacja
            7'd40: demo_data = 16'hFF50; // P
            7'd41: demo_data = 16'hFF61; // a
            7'd42: demo_data = 16'hFF6C; // l
            7'd43: demo_data = 16'hFF75; // u
            7'd44: demo_data = 16'hFF63; // c
            7'd45: demo_data = 16'hFF68; // h
            7'd46: demo_data = 16'hFF20; // spacja
            7'd47: demo_data = 16'hFF32; // 2
            7'd48: demo_data = 16'hFF30; // 0
            7'd49: demo_data = 16'hFF32; // 2
            7'd50: demo_data = 16'hFF36; // 6
            default:
                demo_data = 16'h0000;
        endcase
    end
endfunction

//==============================================================================
// 5. WYJŒCIE DANYCH DO RAM
//------------------------------------------------------------------------------
// Zale¿nie od stanu:
//   - ST_PREP_WRITE, ST_WRITE -> dane tekstu
//   - ST_PREP, ST_CLEAR       -> zera (kasowanie)
//   - pozosta³e               -> zera
//==============================================================================

assign data =
    (state == ST_PREP_WRITE || state == ST_WRITE) ?
        demo_data(addr[6:0]) :
        16'h0000;

//==============================================================================
// 6. G£ÓWNA MASZYNA STANÓW
//==============================================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state  <= ST_PREP_WRITE;
        timer  <= 27'd0;
        active <= 1'b1;
        we     <= 1'b0;
        addr   <= 13'd0;
    end
    else
    begin
        case(state)

            //--------------------------------------------------
            // ST_PREP_WRITE - przygotowanie zapisu znaku
            //--------------------------------------------------
            ST_PREP_WRITE:
            begin
                active <= 1'b1;
                we     <= 1'b1;
                state  <= ST_WRITE;
            end

            //--------------------------------------------------
            // ST_WRITE - zapis aktualnego znaku
            //--------------------------------------------------
            ST_WRITE:
            begin
                active <= 1'b1;
                we     <= 1'b1;

                if(addr == TEXT_LAST)
                begin
                    // Ostatni znak zapisany - wy³¹cz WE
                    // (¿eby data=0000 nie nadpisa³o adresu 50)
                    we    <= 1'b0;
                    timer <= 27'd0;
                    state <= ST_WAIT;
                end
                else
                begin
                    addr  <= addr + 13'd1;
                    state <= ST_PREP_WRITE;
                end
            end

            //--------------------------------------------------
            // ST_WAIT - wyœwietlanie tekstu przez 3 sekundy
            //--------------------------------------------------
            ST_WAIT:
            begin
                active <= 1'b1;
                we     <= 1'b0;

                if(timer < WAIT_TIME)
                    timer <= timer + 1'b1;
                else
                begin
                    timer <= 27'd0;
                    addr  <= 13'd0;
                    state <= ST_PREP;
                end
            end

            //--------------------------------------------------
            // ST_PREP - przygotowanie kasowania
            //--------------------------------------------------
            ST_PREP:
            begin
                active <= 1'b1;
                we     <= 1'b1;
                state  <= ST_CLEAR;
            end

            //--------------------------------------------------
            // ST_CLEAR - kasowanie bufora tekstowego
            //--------------------------------------------------
            ST_CLEAR:
            begin
                active <= 1'b1;
                we     <= 1'b1;

                if(addr == RAM_LAST)
                    state <= ST_FINISH;
                else
                    addr <= addr + 13'd1;
            end

            //--------------------------------------------------
            // ST_FINISH - zakoñczenie demo
            //--------------------------------------------------
            ST_FINISH:
            begin
                we     <= 1'b0;
                active <= 1'b0;
                state  <= ST_DONE;
            end

            //--------------------------------------------------
            // ST_DONE - demo zakoñczone
            //--------------------------------------------------
            ST_DONE:
            begin
                we     <= 1'b0;
                active <= 1'b0;
            end

            //--------------------------------------------------
            // DEFAULT - zabezpieczenie FSM
            //--------------------------------------------------
            default:
            begin
                state  <= ST_PREP_WRITE;
                timer  <= 27'd0;
                active <= 1'b1;
                we     <= 1'b0;
                addr   <= 13'd0;
            end

        endcase
    end
end

endmodule