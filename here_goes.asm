;
; HERE GOES
;

; Code and graphics by T.M.R/Cosine
; Music by Sack


; Select an output filename
		!to "here_goes.prg",cbm


; Pull in binary data
		* = $0400
		!binary "data/logo.scr"

		* = $0800
		!binary "data/logo.chr",$40

		* = $0900
music		!binary "data/freeman.prg",,$02

; Constants
rstr1p		= $00
rstr2p		= $31

bar_cnt		= $10

; Labels
rn		= $f0
cos_at_1	= $f1
cos_speed_1	= $f2
cos_offset_1	= $f3

preset_tmr	= $f4
preset_cnt	= $f5

bar_y_pos	= $07f0		; $10 bytes used

colour_work 	= $0840


; Entry point at $0cb1
		* = $0cb1
entry		sei

; Turn off ROMs and set up interrupts
		lda #$35
		sta $01

		lda #<nmi
		sta $fffa
		lda #>nmi
		sta $fffb

		lda #<int
		sta $fffe
		lda #>int
		sta $ffff

		lda #$7f
		sta $dc0d
		sta $dd0d

		lda $dc0d
		lda $dd0d

		lda #rstr1p
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

; Clear the zero page and set one value
		ldx #$50
		lda #$00
nuke_zp		sta $00,x
		inx
		bne nuke_zp

		lda #$01
		sta rn

; Zero the colour RAM
		ldx #$00
		txa
colour_clear	sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		bne colour_clear

; Set the logo's colours
		ldx #$00
		lda #$09
colour_set	ldy $0400,x
		cpy #$01
		bne *+$05
		sta $d800,x

		ldy $0500,x
		cpy #$01
		bne *+$05
		sta $d900,x

		ldy $0600,x
		cpy #$01
		bne *+$05
		sta $da00,x

		ldy $06e8,x
		cpy #$01
		bne *+$05
		sta $dae8,x

		inx
		bne colour_set

		lda #$00
		sta $d023

; Copy the raster colour tables for the first frame
		ldx #$00
colour_copy	lda colour_data,x
		sta colour_work,x
		inx
		cpx #$c0
		bne colour_copy

; Grab the first raster preset
		jsr preset_fetch

; Init the music
		lda #$00
		jsr music+$00

		cli


; Check to see if space has been pressed
main_loop	lda $dc01
		cmp #$ef
		beq *+$05
		jmp main_loop

; Reset some registers
		sei
		lda #$37
		sta $01

		lda #$00
		sta $d011
		sta $d020
		sta $d021
		sta $d418

; Reset the C64 (a linker would go here...)
		jmp $fce2


; IRQ interrupt
int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne ya
		jmp ea31

ya		lda rn
		cmp #$02
		bne *+$05
		jmp rout2


; Raster split 1
rout1

; Set video registers for the logo
		lda #$13
		sta $d016
		lda #$12
		sta $d018

; Update the preset timer and...
		dec preset_tmr
		bne pt_skip

		inc preset_tmr

; ...check the music driver to see if...
		lda music+$1df
		cmp #$02
		bne pt_skip

		dec preset_cnt
		bne pt_skip

; ...it's time for a new preset
		jsr preset_fetch

; Update the raster bar positions
pt_skip		ldx #$00
		lda cos_at_1
		clc
		adc cos_speed_1
		sta cos_at_1
		tay

bar_move	lda bar_cosinus,y
		sta bar_y_pos+$00,x
		tya
		clc
		adc cos_offset_1
		tay
		inx
		cpx #bar_cnt
		bne bar_move

; Draw the raster bars
		ldx #$00
bar_plot	ldy bar_y_pos+$00,x
		lda bar_data_1,x
		sta colour_work+$00,y
		sta colour_work+$0c,y
		lda bar_data_2,x
		sta colour_work+$01,y
		sta colour_work+$0b,y
		lda bar_data_3,x
		sta colour_work+$02,y
		sta colour_work+$0a,y
		lda bar_data_4,x
		sta colour_work+$03,y
		sta colour_work+$09,y
		lda bar_data_5,x
		sta colour_work+$04,y
		sta colour_work+$08,y
		lda bar_data_6,x
		sta colour_work+$05,y
		sta colour_work+$07,y
		lda #$01
		sta colour_work+$06,y

		inx
		cpx #bar_cnt
		bne bar_plot

; Set up for the second raster split
		lda #$02
		sta rn
		lda #rstr2p
		sta $d012

; Exit the IRQ
		jmp ea31


; Raster split 2
rout2		ldx #$0a
		dex
		bne *-$01
		bit $ea

; Split 192 scanlines of the screen
; (This code clears the colour_work table with colour_data's
; contents as it goes, so the raster bars don't need erasing!)
		ldx #$00
colour_split_1	ldy #$02
		dey
		bne *-$01
		nop
		nop
		nop

		lda colour_data,x
		sta $d020
		lda colour_work,x
		sta $d021

		nop
		nop

		lda colour_data+$01,x
		sta $d020
		lda colour_work+$01,x
		sta $d021

		lda colour_data,x
		sta colour_work,x
		inx

		lda colour_data,x
		sta colour_work,x
		inx

		ldy #$02
		dey
		bne *-$01
		nop
		nop
		nop

		ldy colour_data+$08,x
		lda colour_data,x
		sty $d022
		sta $d020
		lda colour_work,x
		sta $d021

		lda colour_data,x
		sta colour_work,x
		inx

		ldy #$05
		dey
		bne *-$01
		nop

		ldy colour_data+$08,x
		lda colour_data,x
		sty $d022
		sta $d020
		lda colour_work,x
		sta $d021

		lda colour_data,x
		sta colour_work,x

		inx

		ldy #$05
		dey
		bne *-$01
		nop

		ldy colour_data+$08,x
		lda colour_data,x
		sty $d022
		sta $d020
		lda colour_work,x
		sta $d021

		lda colour_data,x
		sta colour_work,x

		inx

		ldy #$05
		dey
		bne *-$01
		nop

		ldy colour_data+$08,x
		lda colour_data,x
		sty $d022
		sta $d020
		lda colour_work,x
		sta $d021

		lda colour_data,x
		sta colour_work,x

		inx

		ldy #$05
		dey
		bne *-$01
		nop

		ldy colour_data+$08,x
		lda colour_data,x
		sty $d022
		sta $d020
		lda colour_work,x
		sta $d021

		lda colour_data,x
		sta colour_work,x

		inx

		ldy #$05
		dey
		bne *-$01
		nop
		nop
		ldy #$0c

		lda colour_data,x
		sty $d022
		sta $d020
		lda colour_work,x
		sta $d021

		lda colour_data,x
		sta colour_work,x

		nop
		nop
		nop
		nop
		nop
		nop

		inx
		cpx #$c0
		beq *+$05
		jmp colour_split_1

		lda scroll_x
		eor #$07
		sta $d016

		lda #$16
		sta $d018

		bit $ea

; A bar on the last eight scanlines for the scroller
		lda colour_data,x
		sta $d020
		sta $d021
		inx

		nop
		nop
		nop

		lda colour_data,x
		sta $d020
		sta $d021
		inx

		ldy #$09
		dey
		bne *-$01
		bit $ea

		lda colour_data,x
		sta $d020
		sta $d021
		inx

		ldy #$09
		dey
		bne *-$01
		bit $ea

		lda colour_data,x
		sta $d020
		sta $d021
		inx

		ldy #$09
		dey
		bne *-$01
		bit $ea

		lda colour_data,x
		sta $d020
		sta $d021
		inx

		ldy #$09
		dey
		bne *-$01
		bit $ea

		lda colour_data,x
		sta $d020
		sta $d021
		inx

		ldy #$09
		dey
		bne *-$01
		bit $ea

		lda colour_data,x
		sta $d020
		sta $d021
		inx

		ldy #$09
		dey
		bne *-$01
		bit $ea

		lda colour_data,x
		sta $d020
		sta $d021
		inx

; The rasters are done, so reset the border colour
		ldy #$09
		dey
		bne *-$01
		bit $ea
		nop

		lda #$00
		sta $d020

; Check to see if we need to update the scroller
		ldy scroll_speed
scroll_update	ldx scroll_x
		inx
		cpx #$08
		bne scr_xb

; Shift the scroller's screen area
		ldx #$00
mover		lda $07c1,x
		sta $07c0,x
		inx
		cpx #$26
		bne mover

; Read a new character
mread		lda scroll_text
		bne okay

		lda #<scroll_text
		sta mread+$01
		lda #>scroll_text
		sta mread+$02

		jmp mread

; Check for a speed command and respond if so
okay		cmp #$c0
		bcc okay_2

		and #$07
		sta scroll_speed

		lda #$20

; Write the new character
okay_2		sta $07e6

; Update the reader for the next character
		inc mread+$01
		bne *+$05
		inc mread+$02

		ldx #$00
scr_xb		stx scroll_x

		dey
		bne scroll_update

; Play the music
		jsr music+$03

; Set up for the first raster split
		lda #$01
		sta rn
		lda #rstr1p
		sta $d012

; Exit the IRQ
ea31		pla
		tay
		pla
		tax
		pla
nmi		rti


; Grab a preset for the raster bars
preset_fetch	jsr preset_read
		cmp #$ff
		bne pf_okay

; First byte was $ff, the data has run out so reset
		lda #<preset_data
		sta preset_read+$01
		lda #>preset_data
		sta preset_read+$02

		jmp preset_fetch

; Set the first vector and read the other two
pf_okay		sta cos_at_1
		jsr preset_read
		sta cos_speed_1
		jsr preset_read
		sta cos_offset_1

; Set up delays to make sure we trigger at the right point
		lda #$40
		sta preset_tmr
		lda #$10
		sta preset_cnt

		rts

; Self mod code to read preset data
preset_read	lda preset_data

		inc preset_read+$01
		bne *+$05
		inc preset_read+$02

		rts


; Raster bar preset data - curve position, speed and offset
preset_data	!byte $00,$02,$08
		!byte $80,$01,$84
		!byte $80,$fe,$0b
		!byte $40,$01,$17
		!byte $50,$01,$42
		!byte $90,$02,$fb
		!byte $b0,$ff,$86

		!byte $ff	; end of data marker

; Cosine data for the moving bars
bar_cosinus	!byte $b2,$b2,$b2,$b2,$b2,$b2,$b2,$b1
		!byte $b1,$b0,$b0,$af,$af,$ae,$ad,$ac
		!byte $ac,$ab,$aa,$a9,$a8,$a7,$a6,$a5
		!byte $a3,$a2,$a1,$a0,$9e,$9d,$9b,$9a
		!byte $98,$97,$95,$93,$92,$90,$8e,$8c
		!byte $8b,$89,$87,$85,$83,$81,$7f,$7d
		!byte $7b,$79,$77,$75,$73,$71,$6f,$6c
		!byte $6a,$68,$66,$64,$62,$5f,$5d,$5b

		!byte $59,$57,$54,$52,$50,$4e,$4c,$4a
		!byte $47,$45,$43,$41,$3f,$3d,$3b,$39
		!byte $37,$35,$33,$31,$2f,$2d,$2b,$29
		!byte $27,$25,$24,$22,$20,$1e,$1d,$1b
		!byte $1a,$18,$17,$15,$14,$12,$11,$10
		!byte $0e,$0d,$0c,$0b,$0a,$09,$08,$07
		!byte $06,$05,$05,$04,$03,$03,$02,$02
		!byte $01,$01,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$01,$01
		!byte $01,$02,$02,$03,$03,$04,$05,$06
		!byte $06,$07,$08,$09,$0a,$0b,$0c,$0e
		!byte $0f,$10,$11,$13,$14,$15,$17,$18
		!byte $1a,$1c,$1d,$1f,$21,$22,$24,$26
		!byte $28,$29,$2b,$2d,$2f,$31,$33,$35
		!byte $37,$39,$3b,$3d,$3f,$42,$44,$46
		!byte $48,$4a,$4c,$4f,$51,$53,$55,$57

		!byte $59,$5c,$5e,$60,$62,$64,$67,$69
		!byte $6b,$6d,$6f,$71,$73,$76,$78,$7a
		!byte $7c,$7e,$80,$82,$84,$86,$87,$89
		!byte $8b,$8d,$8f,$90,$92,$94,$96,$97
		!byte $99,$9a,$9c,$9d,$9f,$a0,$a1,$a3
		!byte $a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab
		!byte $ac,$ad,$ad,$ae,$af,$af,$b0,$b0
		!byte $b1,$b1,$b2,$b2,$b2,$b2,$b2,$b2

; Colour data for the moving bars
bar_data_1	!byte $06,$06,$06,$06,$06,$06,$09,$09
		!byte $09,$09,$09,$09,$09,$09,$09,$09

bar_data_2	!byte $0b,$0b,$0b,$0b,$0b,$0b,$0b,$0b
		!byte $0b,$0b,$02,$02,$02,$02,$02,$02

bar_data_3	!byte $04,$04,$08,$08,$08,$08,$08,$08
		!byte $08,$08,$08,$08,$08,$08,$08,$08

bar_data_4	!byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		!byte $05,$05,$05,$05,$05,$05,$0a,$0a

bar_data_5	!byte $03,$03,$03,$03,$03,$03,$03,$03
		!byte $03,$03,$03,$03,$0f,$0f,$0f,$0f

bar_data_6	!byte $0d,$0d,$0d,$0d,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07


; Various bits for the scroller
scroll_x	!byte $00
scroll_speed	!byte $03

scroll_text	!scr $c1,"**** HERE GOES ****"

		!scr "        "

		!scr $c3,"Coding and graphics by"
		!scr $c1,"T.M.R",$c3,"with music from"
		!scr $c1,"Sack",$c3
		!scr "        "

		!scr $c2,"Here's my ",$22,"traditional",$22," "
		!scr "raster-flavoured ICC entry, this time for the "
		!scr "new 4K competition!"
		!scr "        "

		!scr $c4,"I'm nearly out of RAM now, so greetings "
		!scr "to all of Cosine's friends and don't forget "
		!scr "to visit  "
		!scr $c1,"Cosine.org.uk",$c2
		!scr "        "

		!scr $c7,"T.M.R signing out, 2019/11/06... .. .  ."
		!scr "        "

		!byte $00	; end of text marker


; Background colour table
		* = $1338

colour_data	!byte $09,$09,$09,$02,$09,$02,$02,$02
		!byte $08,$02,$08,$08,$08,$0a,$08,$0a
		!byte $0a,$0a,$0f,$0a,$0f,$0f,$0f,$07
		!byte $0f,$07,$07,$07,$01,$07,$01,$01
		!byte $01,$07,$01,$07,$07,$07,$0f,$07
		!byte $0f,$0f,$0f,$0a,$0f,$0a,$0a,$0a
		!byte $08,$0a,$08,$08,$08,$02,$08,$02
		!byte $02,$02,$09,$02,$09,$09,$09,$00

		!byte $09,$09,$09,$0b,$09,$0b,$0b,$0b
		!byte $08,$0b,$08,$08,$08,$05,$08,$05
		!byte $05,$05,$0f,$05,$0f,$0f,$0f,$0d
		!byte $0f,$0d,$0d,$0d,$01,$0d,$01,$01
		!byte $01,$0d,$01,$0d,$0d,$0d,$0f,$0d
		!byte $0f,$0f,$0f,$05,$0f,$05,$05,$05
		!byte $08,$05,$08,$08,$08,$0b,$08,$0b
		!byte $0b,$0b,$09,$0b,$09,$09,$09,$00

		!byte $06,$06,$06,$0b,$06,$0b,$0b,$0b
		!byte $04,$0b,$04,$04,$04,$0e,$04,$0e
		!byte $0e,$0e,$03,$0e,$03,$03,$03,$0d
		!byte $03,$0d,$0d,$0d,$01,$0d,$01,$01
		!byte $01,$0d,$01,$0d,$0d,$0d,$03,$0d
		!byte $03,$03,$03,$0e,$03,$0e,$0e,$0e
		!byte $04,$0e,$04,$04,$04,$0b,$04,$0b
		!byte $0b,$0b,$06,$0b,$06,$06,$06,$00

scroll_colours	!byte $02,$0a,$07,$0d,$03,$05,$0e,$06
