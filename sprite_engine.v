//**********************************************************
//  Sprite Engine - 16 sprite'ów 16x16, 8bpp
//  - £adowanie z CPU przez BRAM (Port A)
//  - Odczyt przez sprite_engine (Port B)
//  - Priorytet: ni¿szy indeks = wy¿szy
//  - Key color: 0 (przezroczysty)
//  - Flip X/Y
//**********************************************************
module sprite_engine
(
    input  wire        clk,
    input  wire        rst_n,

    // Pozycja piksela VGA
    input  wire [9:0]  x,
    input  wire [8:0]  y,
    input  wire        video_on,

    // Rejestry konfiguracji sprite'ów 0-7 (X)
    input  wire [9:0]  spr_x_0,
    input  wire [9:0]  spr_x_1,
    input  wire [9:0]  spr_x_2,
    input  wire [9:0]  spr_x_3,
    input  wire [9:0]  spr_x_4,
    input  wire [9:0]  spr_x_5,
    input  wire [9:0]  spr_x_6,
    input  wire [9:0]  spr_x_7,

    // Rejestry konfiguracji sprite'ów 0-7 (Y)
    input  wire [8:0]  spr_y_0,
    input  wire [8:0]  spr_y_1,
    input  wire [8:0]  spr_y_2,
    input  wire [8:0]  spr_y_3,
    input  wire [8:0]  spr_y_4,
    input  wire [8:0]  spr_y_5,
    input  wire [8:0]  spr_y_6,
    input  wire [8:0]  spr_y_7,

    // Rejestry kontrolne 0-7 (flip_x, flip_y, enable)
    input  wire [3:0]  spr_ctrl_0,
    input  wire [3:0]  spr_ctrl_1,
    input  wire [3:0]  spr_ctrl_2,
    input  wire [3:0]  spr_ctrl_3,
    input  wire [3:0]  spr_ctrl_4,
    input  wire [3:0]  spr_ctrl_5,
    input  wire [3:0]  spr_ctrl_6,
    input  wire [3:0]  spr_ctrl_7,

    // Interfejs zapisu do BRAM (Port A) - z cpu_ram
    input  wire        spr_we,
    input  wire [11:0] spr_addr,
    input  wire [7:0]  spr_data,

    // Wyjœcie do main.v
    output reg  [7:0]  sprite_pixel,
    output reg         sprite_enable
);

//**********************************************************
//  Instancja sprite_bram (True Dual Port)
//  Port A: zapis z CPU
//  Port B: odczyt przez sprite_engine
//**********************************************************
wire [11:0] bram_addrb;
wire [7:0]  bram_doutb;

sprite_bram u_sprite_bram (
    .clka  (clk),
    .wea   (spr_we),
    .addra (spr_addr),
    .dina  (spr_data),
    .douta (),
    
    .clkb  (clk),
    .web   (1'b0),
    .addrb (bram_addrb),
    .dinb  (8'd0),
    .doutb (bram_doutb)
);

//**********************************************************
//  Potok 1: rejestracja x, y, video_on
//**********************************************************
/* KOREKTA POLOZENIA SPRITE
reg [9:0] x_d1;
reg [8:0] y_d1;
reg       video_on_d1;

always @(posedge clk) begin
    x_d1        <= x;
    y_d1        <= y;
    video_on_d1 <= video_on;
end
*/

//**********************************************************
//  Detekcja trafienia (kombinacyjnie)
//  Priorytet: ni¿szy indeks = wy¿szy
//  Uwaga: u¿ywamy pêtli for na tablicach tymczasowych
//**********************************************************

// Tablice pomocnicze dla pêtli
wire [9:0] spr_x_arr [0:7];
wire [8:0] spr_y_arr [0:7];
wire [3:0] spr_ctrl_arr [0:7];

assign spr_x_arr[0]  = spr_x_0;
assign spr_x_arr[1]  = spr_x_1;
assign spr_x_arr[2]  = spr_x_2;
assign spr_x_arr[3]  = spr_x_3;
assign spr_x_arr[4]  = spr_x_4;
assign spr_x_arr[5]  = spr_x_5;
assign spr_x_arr[6]  = spr_x_6;
assign spr_x_arr[7]  = spr_x_7;

assign spr_y_arr[0]  = spr_y_0;
assign spr_y_arr[1]  = spr_y_1;
assign spr_y_arr[2]  = spr_y_2;
assign spr_y_arr[3]  = spr_y_3;
assign spr_y_arr[4]  = spr_y_4;
assign spr_y_arr[5]  = spr_y_5;
assign spr_y_arr[6]  = spr_y_6;
assign spr_y_arr[7]  = spr_y_7;

assign spr_ctrl_arr[0]  = spr_ctrl_0;
assign spr_ctrl_arr[1]  = spr_ctrl_1;
assign spr_ctrl_arr[2]  = spr_ctrl_2;
assign spr_ctrl_arr[3]  = spr_ctrl_3;
assign spr_ctrl_arr[4]  = spr_ctrl_4;
assign spr_ctrl_arr[5]  = spr_ctrl_5;
assign spr_ctrl_arr[6]  = spr_ctrl_6;
assign spr_ctrl_arr[7]  = spr_ctrl_7;

// Wynik detekcji
reg        hit_found;
reg [3:0]  hit_idx;
reg [3:0]  hit_px;
reg [3:0]  hit_py;
reg [3:0]  hit_ctrl;

integer i;
always @(*) begin
    hit_found = 1'b0;
    hit_idx   = 4'd0;
    hit_px    = 4'd0;
    hit_py    = 4'd0;
    hit_ctrl  = 4'd0;

    // Od najwy¿szego indeksu do najni¿szego - ni¿szy wygrywa
    for (i = 7; i >= 0; i = i - 1) begin
	/* KOREKTA POLOZENIA SPRITE
        if (spr_ctrl_arr[i][2] && video_on_d1) begin
            if ((x_d1 >= spr_x_arr[i]) &&
                (x_d1 <  spr_x_arr[i] + 10'd16) &&
                (y_d1 >= {1'b0, spr_y_arr[i]}) &&
                (y_d1 <  {1'b0, spr_y_arr[i]} + 9'd16)) begin
	*/
if (spr_ctrl_arr[i][2] && video_on) begin
    if ((x >= spr_x_arr[i]) &&
        (x < spr_x_arr[i] + 10'd16) &&
        (y >= {1'b0, spr_y_arr[i]}) &&
        (y < {1'b0, spr_y_arr[i]} + 9'd16)) begin
		
                hit_found = 1'b1;
                hit_idx   = i[3:0];
			/* KOREKTA POLOZENIA SPRITE				
                hit_px    = x_d1[3:0] - spr_x_arr[i][3:0];
				hit_py    = y_d1[3:0] - spr_y_arr[i][3:0];
			*/
hit_px = x[3:0] - spr_x_arr[i][3:0];
hit_py = y[3:0] - spr_y_arr[i][3:0];				
                hit_ctrl  = spr_ctrl_arr[i];
            end
        end
    end
end

//**********************************************************
//  Potok 2: obliczenie adresu BRAM
//  Adres: sprite_idx * 256 + (py * 16) + px
//       = {idx[3:0], py[3:0], px[3:0]}
//**********************************************************

// Flip X/Y
wire flip_x = hit_ctrl[0];
wire flip_y = hit_ctrl[1];

wire [3:0] px_eff = flip_x ? (4'd15 - hit_px) : hit_px;
wire [3:0] py_eff = flip_y ? (4'd15 - hit_py) : hit_py;

// Adres BRAM - 12 bitów
// bit 11:8 = idx
// bit 7:4  = py
// bit 3:0  = px
wire [11:0] addr_calc = {hit_idx, py_eff, px_eff};

assign bram_addrb = addr_calc;

//**********************************************************
//  Potok 3: rejestracja sygna³ów towarzysz¹cych
//  (BRAM ma 1 takt opóŸnienia)
//**********************************************************
reg        hit_r;
reg        video_on_r;

always @(posedge clk) begin
    hit_r      <= hit_found;
    //video_on_r <= video_on_d1;
	video_on_r <= video_on;
end

//**********************************************************
//  Potok 4: wyjœcie
//  BRAM zwraca dane 1 takt po adresie
//  Wiêc w tym samym takcie co hit_r mamy bram_doutb
//**********************************************************
wire [7:0] color_out = bram_doutb;
/* KOREKTA POLOZENIA SPRITE
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sprite_pixel  <= 8'd0;
        sprite_enable <= 1'b0;
    end else begin
        // Key color = 0 (przezroczysty)
        if (hit_r && video_on_r && (color_out != 8'd0)) begin
            sprite_pixel  <= color_out;
            sprite_enable <= 1'b1;
        end else begin
            sprite_pixel  <= 8'd0;
            sprite_enable <= 1'b0;
        end
    end
end
*/
always @(*) begin
    if (!rst_n) begin
        sprite_pixel  = 8'd0;
        sprite_enable = 1'b0;
    end
    else if (hit_r && video_on_r) begin
        sprite_pixel  = color_out;
        sprite_enable = (color_out != 8'd0);
    end
    else begin
        sprite_pixel  = 8'd0;
        sprite_enable = 1'b0;
    end
end
endmodule