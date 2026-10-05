//==============================================================================
// sram_ctrl.v - Kontroler SRAM (framebuffer 640x480x8bpp)
//------------------------------------------------------------------------------
// Opis:
//   Modu³ realizuje dostêp do zewnêtrznej pamiêci SRAM (framebuffer).
//   Obs³uguje:
//     - czyszczenie ca³ego framebuffera po resecie (ST_CLEAR)
//     - odczyt piksela dla VGA (ST_READ)
//     - zapis piksela z CPU (ST_WRITE_SETUP, ST_WRITE, ST_WRITE_END)
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Pamiêæ:
//   - 640 x 480 = 307200 pikseli
//   - 8 bitów na piksel (RGB332)
//   - adres 19-bitowy (0..307199)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

`include "config.vh"

module sram_ctrl
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar 25 MHz
    input  wire        rst_n,           // reset aktywny stanem niskim

    //--------------------------------------------------
    // Interfejs VGA (odczyt)
    //--------------------------------------------------
    input  wire [18:0] pixel_addr,      // adres piksela dla VGA
    output reg  [7:0]  pixel,           // piksel odczytany z SRAM

    //--------------------------------------------------
    // Interfejs zapisu (z CPU)
    //--------------------------------------------------
    input  wire        wr_req,          // ¿¹danie zapisu
    input  wire [18:0] wr_addr,         // adres zapisu
    input  wire [7:0]  wr_data,         // dane zapisu
    output reg         wr_done,         // zapis zakoñczony

    //--------------------------------------------------
    // Status
    //--------------------------------------------------
    output reg         clear_done,      // czyszczenie zakoñczone

    //--------------------------------------------------
    // Interfejs SRAM
    //--------------------------------------------------
    output reg  [18:0] sram_addr,       // adres SRAM
    inout  wire [7:0]  sram_data,       // dane SRAM
    output reg         ce_n,            // chip enable (aktywny 0)
    output reg         oe_n,            // output enable (aktywny 0)
    output reg         we_n,            // write enable (aktywny 0)
    output reg         lb_n,            // lower byte (aktywny 0)
    output reg         ub_n             // upper byte (aktywny 0)
);

//==============================================================================
// 1. PARAMETRY
//==============================================================================

localparam [18:0] SCREEN_PIXELS = 19'd307200;       // 640 x 480
localparam [18:0] LAST_PIXEL    = SCREEN_PIXELS - 19'd1;

//==============================================================================
// 2. STANY FSM
//==============================================================================

localparam [2:0] ST_CLEAR       = 3'd0;   // czyszczenie framebuffera
localparam [2:0] ST_READ        = 3'd1;   // odczyt dla VGA
localparam [2:0] ST_WRITE_SETUP = 3'd2;   // przygotowanie zapisu
localparam [2:0] ST_WRITE       = 3'd3;   // zapis
localparam [2:0] ST_WRITE_END   = 3'd4;   // zakoñczenie zapisu

//==============================================================================
// 3. REJESTRY FSM
//==============================================================================

reg [2:0]  state;                       // aktualny stan
reg [2:0]  next_state;                  // nastêpny stan

reg [18:0] clear_addr;                  // adres czyszczenia
reg [18:0] addr_out;                    // adres zapisu
reg [7:0]  data_out;                    // dane zapisu

//==============================================================================
// 4. INTERFEJS SRAM - KIERUNEK DANYCH
//------------------------------------------------------------------------------
// sram_data jest trójstanowe:
//   - ST_CLEAR       -> 8'h00 (zapis zera)
//   - ST_WRITE_SETUP -> data_out (dane zapisu)
//   - ST_WRITE       -> data_out (dane zapisu)
//   - pozosta³e      -> 8'bz (wysoka impedancja, odczyt)
//==============================================================================

assign sram_data =
    (state == ST_CLEAR) ? 8'h00 :
    (state == ST_WRITE_SETUP || state == ST_WRITE) ? data_out :
    8'bz;

//==============================================================================
// 5. LOGIKA NASTÊPNEGO STANU
//==============================================================================

always @(*)
begin
    next_state = state;

    case(state)

        //------------------------------------------
        // CLEAR - czyszczenie framebuffera
        //------------------------------------------
        ST_CLEAR:
        begin
            if(clear_addr == LAST_PIXEL)
                next_state = ST_READ;
            else
                next_state = ST_CLEAR;
        end

        //------------------------------------------
        // READ - odczyt dla VGA
        //------------------------------------------
        ST_READ:
        begin
            if(wr_req)
                next_state = ST_WRITE_SETUP;
            else
                next_state = ST_READ;
        end

        //------------------------------------------
        // WRITE_SETUP - przygotowanie zapisu
        //------------------------------------------
        ST_WRITE_SETUP:
        begin
            next_state = ST_WRITE;
        end

        //------------------------------------------
        // WRITE - zapis
        //------------------------------------------
        ST_WRITE:
        begin
            next_state = ST_WRITE_END;
        end

        //------------------------------------------
        // WRITE_END - zakoñczenie zapisu
        //------------------------------------------
        ST_WRITE_END:
        begin
            next_state = ST_READ;
        end

        //------------------------------------------
        // DEFAULT - zabezpieczenie FSM
        //------------------------------------------
        default:
            next_state = ST_CLEAR;

    endcase
end

//==============================================================================
// 6. G£ÓWNA MASZYNA STANÓW
//==============================================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state      <= ST_CLEAR;
        clear_addr <= 19'd0;
        addr_out   <= 19'd0;
        clear_done <= 1'b0;
        wr_done    <= 1'b0;
        data_out   <= 8'h00;
    end
    else
    begin
        state   <= next_state;
        wr_done <= 1'b0;

        case(state)

            //--------------------------------------
            // CLEAR
            //--------------------------------------
            ST_CLEAR:
            begin
                if(clear_addr == LAST_PIXEL)
                    clear_done <= 1'b1;
                else
                    clear_addr <= clear_addr + 19'd1;
            end

            //--------------------------------------
            // READ
            //--------------------------------------
            ST_READ:
            begin
                if(wr_req)
                begin
                    addr_out <= wr_addr;
                    data_out <= wr_data;
                end
            end

            //--------------------------------------
            // WRITE
            //--------------------------------------
            ST_WRITE:
            begin
                // Zapis realizowany przez logikê kombinacyjn¹
                // (WE=0, adres i dane s¹ ju¿ ustawione).
            end

            //--------------------------------------
            // WRITE_END
            //--------------------------------------
            ST_WRITE_END:
            begin
                wr_done <= 1'b1;
            end

            //--------------------------------------
            // DEFAULT
            //--------------------------------------
            default:
            begin
            end

        endcase
    end
end

//==============================================================================
// 7. LOGIKA WYJŒCIOWA
//------------------------------------------------------------------------------
// Sterowanie liniami SRAM zale¿nie od stanu.
//==============================================================================

always @(*)
begin
    //------------------------------------------------
    // Wartoœci domyœlne
    //------------------------------------------------
    ce_n      = 1'b0;           // SRAM zawsze wybrana
    oe_n      = 1'b1;
    we_n      = 1'b1;
    lb_n      = 1'b0;
    ub_n      = 1'b1;
    sram_addr = pixel_addr;
    pixel     = 8'h00;

    //------------------------------------------------
    // Zale¿nie od stanu
    //------------------------------------------------
    case(state)

        //--------------------------------------------
        // CLEAR
        //--------------------------------------------
        ST_CLEAR:
        begin
            sram_addr = clear_addr;
            oe_n      = 1'b1;
            we_n      = 1'b0;
        end

        //--------------------------------------------
        // READ
        //--------------------------------------------
        ST_READ:
        begin
            sram_addr = pixel_addr;
            oe_n      = 1'b0;
            we_n      = 1'b1;
            pixel     = sram_data;
        end

        //--------------------------------------------
        // WRITE_SETUP
        //--------------------------------------------
        ST_WRITE_SETUP:
        begin
            sram_addr = addr_out;
            oe_n      = 1'b1;
            we_n      = 1'b1;
        end

        //--------------------------------------------
        // WRITE
        //--------------------------------------------
        ST_WRITE:
        begin
            sram_addr = addr_out;
            oe_n      = 1'b1;
            we_n      = 1'b0;
        end

        //--------------------------------------------
        // WRITE_END
        //--------------------------------------------
        ST_WRITE_END:
        begin
            sram_addr = addr_out;
            oe_n      = 1'b1;
            we_n      = 1'b1;
        end

    endcase
end

endmodule