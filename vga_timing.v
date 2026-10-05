//==============================================================================
// vga_timing.v - Generator sygna³ów VGA 640x480@60Hz
//------------------------------------------------------------------------------
// Opis:
//   Modu³ generuje sygna³y synchronizacji poziomej (HSYNC) i pionowej (VSYNC)
//   oraz wspó³rzêdne X/Y dla obrazu VGA 640x480 przy odœwie¿aniu 60 Hz.
//   Dodatkowo przygotowuje wspó³rzêdne X/Y dla silnika tekstowego,
//   z kompensacj¹ opóŸnienia pipeline.
//
// Zegar:
//   clk = 25 MHz (z main.v, clk25)
//
// Parametry VGA 640x480@60Hz:
//   - H_TOTAL = 800 taktów (640 widocznych + 160 blanking)
//   - V_TOTAL = 525 linii (480 widocznych + 45 blanking)
//
// Autor  : Ryszard Paluch
// Data   : 05.10.2026
// Wersja : 1.0
//==============================================================================

module vga_timing
(
    //--------------------------------------------------
    // Zegar i reset
    //--------------------------------------------------
    input  wire        clk,             // zegar 25 MHz
    input  wire        rst_n,           // reset aktywny stanem niskim

    //--------------------------------------------------
    // Synchronizacja VGA
    //--------------------------------------------------
    output reg         hsync,           // synchronizacja pozioma (aktywna 0)
    output reg         vsync,           // synchronizacja pionowa (aktywna 0)

    //--------------------------------------------------
    // Wspó³rzêdne obrazu
    //--------------------------------------------------
    output wire [9:0]  x,               // wspó³rzêdna X (0..799)
    output wire [9:0]  y,               // wspó³rzêdna Y (0..524)

    //--------------------------------------------------
    // Wspó³rzêdne dla silnika tekstowego
    //--------------------------------------------------
    output wire [9:0]  x_txt,           // wspó³rzêdna X tekstu (0..639)
    output wire [8:0]  y_txt,           // wspó³rzêdna Y tekstu (0..479)

    //--------------------------------------------------
    // Sygna³ aktywnego obszaru obrazu
    //--------------------------------------------------
    output wire        video_on         // 1 = aktywny obszar obrazu
);

//==============================================================================
// 1. PARAMETRY VGA 640x480@60Hz
//------------------------------------------------------------------------------
// Wartoœci dla standardu VGA 640x480 przy 25 MHz (25.175 MHz nominalnie).
//==============================================================================

//--------------------------------------------------
// Parametry poziome
//--------------------------------------------------
localparam [9:0] H_VISIBLE = 10'd640;   // liczba widocznych pikseli
localparam [9:0] H_FRONT   = 10'd16;    // front porch
localparam [9:0] H_SYNC    = 10'd96;    // d³ugoœæ impulsu HSYNC
localparam [9:0] H_BACK    = 10'd48;    // back porch
localparam [9:0] H_TOTAL   = 10'd800;   // ca³kowita d³ugoœæ linii

//--------------------------------------------------
// Parametry pionowe
//--------------------------------------------------
localparam [9:0] V_VISIBLE = 10'd480;   // liczba widocznych linii
localparam [9:0] V_FRONT   = 10'd10;    // front porch
localparam [9:0] V_SYNC    = 10'd2;     // d³ugoœæ impulsu VSYNC
localparam [9:0] V_BACK    = 10'd33;    // back porch
localparam [9:0] V_TOTAL   = 10'd525;   // ca³kowita liczba linii

//--------------------------------------------------
// Przesuniêcie poziome obszaru tekstowego
//--------------------------------------------------
localparam [9:0] TXT_X_OFFSET = 10'd0;  // 0 = brak przesuniêcia

//==============================================================================
// 2. LICZNIKI VGA
//------------------------------------------------------------------------------
// h_cnt - licznik poziomy (0..H_TOTAL-1)
// v_cnt - licznik pionowy  (0..V_TOTAL-1)
//==============================================================================

reg [9:0] h_cnt;                        // licznik pozycji poziomej
reg [9:0] v_cnt;                        // licznik pozycji pionowej

//==============================================================================
// 3. GENEROWANIE LICZNIKÓW
//==============================================================================

always @(posedge clk)
begin
    if(!rst_n)
    begin
        h_cnt <= 10'd0;
        v_cnt <= 10'd0;
    end
    else
    begin
        if(h_cnt == H_TOTAL - 1)
        begin
            // Koniec linii - nowa linia
            h_cnt <= 10'd0;

            if(v_cnt == V_TOTAL - 1)
                v_cnt <= 10'd0;             // koniec ramki - nowa ramka
            else
                v_cnt <= v_cnt + 10'd1;     // nastêpna linia
        end
        else
        begin
            h_cnt <= h_cnt + 10'd1;         // nastêpny piksel
        end
    end
end

//==============================================================================
// 4. AKTYWNY OBSZAR OBRAZU
//------------------------------------------------------------------------------
// video_on_raw = 1 tylko dla X < 640 i Y < 480.
//==============================================================================

wire video_on_raw;

assign video_on_raw =
    (h_cnt < H_VISIBLE) &&
    (v_cnt < V_VISIBLE);

//==============================================================================
// 5. GENEROWANIE SYNCHRONIZACJI
//------------------------------------------------------------------------------
// HSYNC/VSYNC s¹ aktywne stanem niskim na wyjœciu.
// Sygna³y *_active s¹ aktywne stanem wysokim (wewnêtrznie).
//==============================================================================

wire hsync_active;
wire vsync_active;

// HSYNC aktywny po H_VISIBLE + H_FRONT przez H_SYNC taktów
assign hsync_active =
    (h_cnt >= H_VISIBLE + H_FRONT) &&
    (h_cnt <  H_VISIBLE + H_FRONT + H_SYNC);

// VSYNC aktywny po V_VISIBLE + V_FRONT przez V_SYNC linii
assign vsync_active =
    (v_cnt >= V_VISIBLE + V_FRONT) &&
    (v_cnt <  V_VISIBLE + V_FRONT + V_SYNC);

//==============================================================================
// 6. PIPELINE WSPÓ£RZÊDNYCH
//------------------------------------------------------------------------------
// Rejestry opóŸniaj¹ce o 1 takt, dla kompensacji opóŸnienia
// bufora tekstowego i framebuffera.
//==============================================================================

reg [9:0] x_r;                          // zarejestrowana wspó³rzêdna X
reg [9:0] y_r;                          // zarejestrowana wspó³rzêdna Y
reg       video_on_r;                   // zarejestrowany video_on
reg [9:0] x_txt_r;                      // zarejestrowana wspó³rzêdna X tekstu
reg [8:0] y_txt_r;                      // zarejestrowana wspó³rzêdna Y tekstu

always @(posedge clk)
begin
    if(!rst_n)
    begin
        x_r        <= 10'd0;
        y_r        <= 10'd0;
        x_txt_r    <= 10'd0;
        y_txt_r    <= 9'd0;
        video_on_r <= 1'b0;
    end
    else
    begin
        //--------------------------------------------------
        // Rejestracja wspó³rzêdnych obrazu
        //--------------------------------------------------
        x_r <= h_cnt;
        y_r <= v_cnt;

        //--------------------------------------------------
        // Wspó³rzêdna X tekstu
        //--------------------------------------------------
        if(h_cnt + TXT_X_OFFSET < H_VISIBLE)
            x_txt_r <= h_cnt + TXT_X_OFFSET;
        else
            x_txt_r <= H_VISIBLE - 1;

        //--------------------------------------------------
        // Wspó³rzêdna Y tekstu
        //--------------------------------------------------
        if(h_cnt >= H_VISIBLE)
        begin
            // Podczas blankingu poziomego - przygotuj nastêpny wiersz
            if(v_cnt < V_VISIBLE - 1)
                y_txt_r <= v_cnt[8:0] + 9'd1;
            else
                y_txt_r <= 9'd0;
        end
        else if(v_cnt < V_VISIBLE)
        begin
            // W aktywnym obszarze - bie¿¹ca linia
            y_txt_r <= v_cnt[8:0];
        end
        else
        begin
            // Podczas blankingu pionowego
            y_txt_r <= 9'd0;
        end

        //--------------------------------------------------
        // Rejestracja video_on
        //--------------------------------------------------
        video_on_r <= video_on_raw;
    end
end

//==============================================================================
// 7. WYJŒCIA WSPÓ£RZÊDNYCH I VIDEO_ON
//==============================================================================

assign x        = x_r;
assign y        = y_r;
assign x_txt    = x_txt_r;
assign y_txt    = y_txt_r;
assign video_on = video_on_r;

//==============================================================================
// 8. WYJŒCIA SYNCHRONIZACJI
//------------------------------------------------------------------------------
// HSYNC i VSYNC s¹ aktywne stanem niskim.
//==============================================================================

always @(posedge clk)
begin
    if(!rst_n)
    begin
        hsync <= 1'b1;                  // stan nieaktywny
        vsync <= 1'b1;                  // stan nieaktywny
    end
    else
    begin
        hsync <= ~hsync_active;         // inwersja - aktywny 0
        vsync <= ~vsync_active;         // inwersja - aktywny 0
    end
end

endmodule