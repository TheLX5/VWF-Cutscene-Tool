;##################################################################################################
;# Variable Width Font Cutscene v1.0
;# by Romi, updated by lx5
;#
;# Proper documentation later.

incsrc "vwf_defines.asm"

print "INIT ",pc
VWFInitCode_wrapper:
if !sa1
	LDA.B #VWFInitCode
	STA $0183
	LDA.B #VWFInitCode/256
	STA $0184
	LDA.B #VWFInitCode/65536
	STA $0185
	LDA #$D0
	STA $2209
.Wait
	LDA $018A
	BEQ .Wait
	STZ $018A
	RTL
endif

VWFInitCode:
	LDA !7FAB10,x			; Extra byte not supported!
	AND #$04
-	
	BNE -

	lda #$FF				; Erase Mario
	sta $78

	LDA #$80				; Force blank
	STA $2100
	STZ $0D9D|!addr			; Disable main and subscreen
	STZ $0D9E|!addr

	PHX
	LDX #$04				; Setup HDMAs
-
	LDA.l HDMATable1,x		; CH3 = Brightness
	STA $4330,x
	LDA.l HDMATable2,x		; CH4 = Layer 3 X Pos
	STA $4340,x
	LDA.l HDMATable3,x		; CH5 = Layer 3 GFX & Tilemap address
	STA $4350,x
	DEX
	BPL -

	LDX #$4F
	LDA #$80
-
	STA.l !VWF_HDMA,x
	DEX
	BPL -
	LDA.b #!VWF_HDMA/$10000
	STA $4337
	STA $4347
	PLX

	LDA #$88
	STA $420C				; Enable HDMA channels 3 and 7
	STA $0D9F|!addr
	LDA $0DAE|!addr
	STA $2100
	RTL

HDMATable1:
	db $40,$00 : dl .src
.src
	db $5F : dw !VWF_HDMA
	db $8C : dw !VWF_HDMA+$10
	db $90 : dw !VWF_HDMA+$20
	db $54 : dw !VWF_HDMA+$30
	db $90 : dw !VWF_HDMA+$40
	db $00

HDMATable2:
	db $43,$11 : dl .src
.src
	db $5F : dw !VWF_SCROLL+$00
	db $0C : dw !VWF_SCROLL+$10
	db $01 : dw !VWF_SCROLL+$20
	db $00

HDMATable3:
	db $00,$09 : dl .src
.src
	db $5F : db $59
	db $0C : db $5C
	db $01 : db $59
	db $00

print "MAIN ",pc
	LDA #$38
	STA $0D9F|!addr				; Enable HDMA channels 3, 4 & 5
	LDA $0100|!addr
	CMP #$14
	BEQ VWFMainCode_wrapper
	RTL

VWFMainCode_wrapper:
if !sa1
	lda $3fdead
	LDA.B #VWFMainCode
	STA $0183
	LDA.B #VWFMainCode/256
	STA $0184
	LDA.B #VWFMainCode/65536
	STA $0185
	LDA #$D0
	STA $2209
.Wait
	LDA $018A
	BEQ .Wait
	STZ $018A
	RTL
endif

VWFMainCode:
	PHX
	PHB
	SEI
	STZ $4200					; Disable NMI
	STZ $420C					; Disable HDMA

	STZ $1BE4|!addr				; Disable updating BG1
	STZ $1CE6|!addr				; Disable updating BG1

	PHD
	LDA #$21					; Change DP for speeed reasons
	XBA
	LDA #$00
	TCD

	LDA #$80
	STA $00						; Enable force blank
	STA $15						; VRAM control

	LDA #$02
	STA $0C						; Layer 3 GFX addr

	REP #$30
	LDA #$0014					; Mainscreen = Layer 3 & Sprites
	STA $2C						; Subscreen = Nothing

	LDA #$2000					; VRAM address
	STA $16
-	
	STZ $18						; Clear 0x2000 bytes of VRAM at $2000
	DEC A
	BNE -

	LDA #$5800					; Initialize VRAM at $5800 ($0400 bytes)
	STA $16

	LDX #$0400
	LDA #$0000
-	
	STA $18
	INC A
	AND #$01FF
	DEX
	BNE -

	LDX #$0040					; Initialize VRAM at $5C00 ($0040 bytes)
	LDA #$0600
-	
	STA $18
	INC A
	DEX
	BNE -

	PLD
	SEP #$30

	PEA.w ((!VWF_VARS>>8)&$FF00)|(!VWF_VARS>>16)
	PLB
	PLB


	LDX #$4F					; Clear $50 bytes of RAM
-	
	STZ.w !VWF_HDMA,x
	DEX
	BPL -

	LDX #$0F					; Initialize brightness HDMA table
	TXA
	LDY #$00
	STA.w !VWF_HDMA+$30
-	
	STA.w !VWF_HDMA+$20,x
	STA.w !VWF_HDMA+$40,y
	INY
	DEX
	DEC A
	BPL -

	JSL $7F8000					; Clear all OAM position

	LDA.w !VWF_DATA+$02			; Setup indirect addressing for the VWF data
	STA $D7
	REP #$30
	LDA.w !VWF_DATA+$00
	STA $D5

	LDX #$03FE
-
	STZ.w !VWF_GFX,x
	DEX #2
	BPL -

								; Initialize VWF related RAM
	STZ.w !CurrentLine			; Current line
	STZ.w !FontColor			; Font color
	STZ.w !TermChars			; Num of characters until end of line

	LDA #$0008					; Padding
	STA.w !LeftPad				; Left padding
	STA.w !NewLeftPad			; New line? padding
	STA.w !RightPad				; Right padding
	;STA.w !NewRightPad		;/

	STA.w !Xposition			; Current/Initial X position
	STZ.w !LineDrawn			; Num of line
	STZ.w !Timer				; Timer
	STZ.w !LineBroken			; Line break flag
	STZ.w !Inner				; ?
	STZ.w !ForcedScroll			; ?
	STZ.w !SelectMsg			; for branch

	LDA #$FFFF
	STA.w !SkipPos
	STZ.w !Skipped

	LDA.w #$0100
	STA.w !VWF_SCROLL+$00
	STA.w !VWF_SCROLL+$10
	LDA.w #$0080
	STA.w !VWF_SCROLL+$02
	LDA.w #$FFFF-$5F
	STA.w !VWF_SCROLL+$12
	STZ.w !VWF_SCROLL+$20
	LDA #$FF80
	STA.w !VWF_SCROLL+$22
	

	LDX #$001E
-
	STZ $0400,x					; Clear OAM high bits
	DEX #2
	BPL -
	SEP #$20


	LDA #$81
	STA $004200					; Enable NMI and wait for V-Blank once
-	

	LDA $10
	BEQ -
	STZ $10
	
	JSL !amk_new_main			; Call AMK's main code
	LDA #$81
	STA $004200
	LDA $0D9F
	STA $00420C

	LDY #$0000
.Loop
	LDA.w !Skipped				; Check if the player has skipped text
	BEQ .normal_vwf
	LDA #$00
	REP #$20
	BRA .ForcedEnd

.normal_vwf
	LDA.w !ForcedScroll			; Check if text should scroll down
	BEQ +
	INC.w !VWF_SCROLL+$22		; Move text's position down 1px every frame
	LDA.w !VWF_SCROLL+$22			; also check if text has scrolled for 16 px
	AND #$0F
	BNE +
	STZ.w !ForcedScroll			; Stop if it has scrolled 16px down
+
	LDA.w !TermChars			; Check if a word has ended.
	BNE .NoNewTerm

	LDA [$D5],y					; Load next VWF data byte
	REP #$20
	BPL .IsChar					; If < $80, it's a character

.ForcedEnd						; If => $80, it's a command
	PEA.w .ReturnedCommand-1	; Push return address
	AND #$007F
	ASL 						; Grab command ID
	TAX
	LDA.l CommandAddress,x		; Push command address to jump to
	PHA
	RTS							; Jump to command
.ReturnedCommand
	SEP #$20					; Finalize command parsing
	BRA .Finalize

.IsChar	
	STZ.w !TermWidth			; Word width
	DEC.w !TermWidth			; Make it $FFFF

	PHY							; Calculate line's total width
.calculate_line
	AND #$00FF					; Grab VWF data and get font width
	TAX
	LDA.l FontWidth,x
	AND #$00FF
	SEC
	ADC.w !TermWidth
	STA.w !TermWidth			; Calculate word's current width
	INC.w !TermChars			; Increase word's characters
	INY
	LDA [$D5],y					; Grab next VWF data byte
	BIT #$0080
	BEQ .calculate_line
	PLY

	LDA #$0100					; Calculate line's valid width by substracting paddings
	SEC
	SBC.w !LeftPad
	SBC.w !RightPad				; Invalid width (doesn't fit into $0100 px) hangs the game
	STA.w !ValidWidth
-	
	BMI -
	LDA.w !TermWidth			; Same here; if line end is over the valid width, hang the game.
	CMP.w !ValidWidth
-	
	BCS -

	CLC
	ADC.w !Xposition
	SEC
	SBC.w !LeftPad
	CMP.w !ValidWidth
	SEP #$20
	BCC .Finalize

	REP #$20
	INC.w !Inner
	JSR BreakLine				; if there isn't much space to render a term, break a line
	STZ.w !Inner
	BCS +
	STZ.w !TermChars			; Reset word's characters
+
	SEP #$20
	BRA .Finalize

.NoNewTerm	
	LDA.b #!VWF_GFX
	STA $04						; Just draw a character without calculating the current line
	LDA.b #!VWF_GFX>>8
	STA $05
	LDA [$D5],y					; Grab next VWF data byte
	JSR DrawChar

.Finalize
	LDA.w !SkipPos+1			; Determine if the current text can be skipped with START
	BMI .WaitVblank
	XBA
	LDA $16
	AND #$10					; Check if START has been pressed
	BEQ .WaitVblank
	LDA.w !SkipPos				; Get skip position and use it as the new VWF data index
	TAY
	INC.w !Skipped				; Activate "text skipped" flag


.WaitVblank
	LDA $10							; Wait for V-Blank
	BEQ .WaitVblank
	STZ $10

	INC $13							; Increase frame counter

	LDA #$00
	STA $00420C						; Disable HDMA
	LDA #$80
	STA $002100						; Force blank and turn screen to black
	STA $002115						; Enable VRAM increment

if !sa1 == 1
	LDX #$120B						; Optimization for DMA upload
else
	LDX #$420B						; Optimization for DMA upload
endif
	REP #$20
	LDA.w !CurrentLine
	LSR.w !LineBroken
	BCC +
	SBC #$0E00
+
	AND #$0E00						; Calculate VRAM address
	ORA #$2000
	STA $002116

	LDA #$1801						; DMA setting = $01
	STA $F5,x						; DMA destination = VRAM Write
	LDA.w #!VWF_GFX
	STA $F7,x
	LDA.w #!VWF_GFX>>8
	STA $F8,x
	LDA #$0400						; Transfer 0x400 bytes (whole tilemap)
	STA $FA,x
	SEP #$20
	LDA #$01						; Enable DMA transfer
	STA $00,x
	LDA $0D9F						; Enable HDMA
	STA $01,x
	
	JSL !amk_new_main				; Call AMK's main code

	JMP .Loop						; Gameloop

CommandAddress:
	dw FinishVWF-1		; 80
	dw PutSpace-1		; 81
	dw BreakLine-1		; 82
	dw WaitButton-1		; 83
	dw WaitTime-1		; 84
	dw FontColor1-1		; 85
	dw FontColor2-1		; 86
	dw FontColor3-1		; 87
	dw PadLeft-1		; 88
	dw PadRight-1		; 89
	dw PadBoth-1		; 8A
	dw ChangeMusic-1	; 8B
	dw EraseSentence-1	; 8C
	dw ChangeTopic-1	; 8D
	dw ShowOAM-1		; 8E
	dw HideOAM-1		; 8F
	dw BranchLabel-1	; 90
	dw JumpLabel-1		; 91
	dw SkipLabel-1		; 92


;##################################################################################################
;# Every command available

;################################################
;# Command $80
;# Finish VWF dialogue

FinishVWF:
	SEP #$20

.clear_data
	LDX #$004F
..loop
	LDA.w !VWF_HDMA,x				; Fade to black everything
	BEQ ..skip
	DEC.w !VWF_HDMA,x
..skip
	DEX
	BPL ..loop

	LDA.w !VWF_HDMA+$30
	REP #$20
	BNE PutSpace_return
	INY
	LDA [$D5],y						; Load VWF ending sequence
	PLX
	SEP #$30
	PLB								; Return DB to normal
	PLX
	STA $F0
	CMP #$20
	BCS .no_teleport

.teleport
	TAY								; < $20: Teleport using screen exits
	LDA $19B8|!addr,y
	STA $19B8|!addr
	LDA $19D8|!addr,y
	STA $19D8|!addr
	LDA #$05
	STA $71
	RTL

.no_teleport
	CMP #$20
	BNE .end_level
	JML $05B160						; != $20: Side exit

.end_level							; == $20: End level
	SBC #$20
	STA $13CE|!addr
	STA $0DD5|!addr
	INC $1DE9|!addr
	LDA #$0B
	STA $0100|!addr
	RTL

;################################################
;# Command $81
;# Put a 4px width space

PutSpace:	
	LDA.w !Xposition
	CLC
	ADC #$0004
	STA.w !Xposition
	INY
.return
	RTS

;################################################
;# Command $82
;# (Forced) Line break

BreakLine:
	LDA.w !ForcedScroll			; If text is already scrolling, ignore the line break
	BEQ .no_scrolling
	CLC
	RTS

.no_scrolling
	LDA.w !LineDrawn			; Check lines drawn on screen, if > 4, scroll text
	CMP #$0004
	BCC +
	INC.w !ForcedScroll			; Activate scroll flag if needed
	BRA ++
+	
	INC.w !LineDrawn			; Increase lines drawn
++	
	LDA.w !CurrentLine
	CLC
	ADC #$0200
	STA.w !CurrentLine
	LDA.w !NewLeftPad
	STA.w !LeftPad
	STA.w !Xposition

.clear_tilemap
	LDX #$03FE
..loop
	STZ.w !VWF_GFX,x
	DEX #2
	BPL ..loop

	INC.w !LineBroken			; Activate line break flag
	LDA.w !Inner
	BNE .return
	INY
	SEC
.return
	RTS

;################################################
;# Command $83
;# Wait for button to continue text

WaitButton:	
	LDA.b $15-1					; Check if a button has been pressed or is being pressed
	BPL .return
	LDA.b $17-1
	BPL .INY
	LDA.b $18-1
	BPL .return

.INY
	INY							; Load next VWF byte in the next frame

.Erase
	LDA #$00F0					; Reset first OAM slot position (arrow GFX)
	STA $0201
	RTS

.return
	LDA $13						; Make the arrow blink
	AND #$0010
	BNE .Erase
	LDA.w !ForcedScroll
	BNE .Erase

	LDA.w !Xposition
	STA $0200
	LDA.w !LineDrawn
	ASL #4
	ADC #$0086
	STA $0201
	LDA.w #!RightArrowGFX
	STA $0202
	RTS

;################################################
;# Command $84
;# Waits a few frames before continuing with the text

WaitTime:
	INY
	LDA [$D5],y					; Load wait duration from VWF data
	AND #$00FF
	CMP.w !Timer				; Check if time is over
	BEQ .INY
	INC.w !Timer				; Increase timer
	DEY							; And reset VWF data index to keep getting into the same routine
	RTS

.INY
	STZ.w !Timer				; Done waiting, reset timer and increase VWF data index
	INY
	RTS

;################################################
;# Command $85
;# Change font color #1

FontColor1:
	STZ.w !FontColor				; Forces font color to the first option
	INY
	RTS

;################################################
;# Command $86
;# Change font color #2

FontColor2:						; Forces font color to the second option
	LDA #$0010
	STA.w !FontColor
	INY
	RTS

;################################################
;# Command $87
;# Change font color #3

FontColor3:
	LDA #$0020					; Forces font color to the third option
	STA.w !FontColor
	INY
	RTS

;################################################
;# Command $88
;# Change left padding

PadLeft:
	INY
	LDA [$D5],y					; Grab new left padding width
	AND #$00FF
	STA.w !NewLeftPad
	INY
	RTS

;################################################
;# Command $89
;# Change right padding

PadRight:
	INY
	LDA [$D5],y					; Grab new right padding width
	AND #$00FF
	STA.w !RightPad
	INY
	RTS

;################################################
;# Command $8A
;# Change both paddings

PadBoth:
	INY
	LDA [$D5],y					; Grab new left padding width
	AND #$00FF
	STA.w !NewLeftPad
	BRA PadRight				; and the right one.

;################################################
;# Command $8B
;# Change music

ChangeMusic:
	INY
	SEP #$20
	LDA [$D5],y
	STA $1DFB
	REP #$20
	INY
	RTS

;################################################
;# Command $8C
;# EraseSentence

EraseSentence:
	LDA !ForcedScroll
	BNE .return

.clear_gfx_buffer
	LDX #$03FE
..loop
	STZ.w !VWF_GFX,x
	DEX #2
	BPL ..loop
	SEP #$20

.loop

.wait_vblank
	LDA $10						; Wait for V-Blank
	BEQ .wait_vblank
	STZ $10

	LDA #$00
	STA $00420C					; Disable HDMA
	LDA #$80
	STA $002100					; Enable F-Blank
	STA $002115					; VRAM Increment

if !sa1 == 1
	LDX #$120B						; Optimization for DMA upload
else
	LDX #$420B						; Optimization for DMA upload
endif
	REP #$21
	LDA.w !CurrentLine
	ADC #$0200
	STA.w !CurrentLine
	AND #$0E00
	ORA #$2000
	STA $002116					; Calculate VRAM Addr

	LDA #$1801					; Write to VRAM
	STA $F5,x
	LDA.w #!VWF_GFX
	STA $F7,x
	LDA.w #!VWF_GFX>>8
	STA $F8,x
	LDA #$0400
	STA $FA,x
	SEP #$20

	LDA #$01
	STA $00,x					; Enable DMA
	LDA $0D9F
	STA $01,x					; Enable HDMA

	INC.w !Timer
	LDA.w !Timer
	CMP #$08
	BNE .loop
	INY
	
	REP #$20
	STZ.w !CurrentLine
	LDA.w !NewLeftPad
	STA.w !LeftPad
	STA.w !Xposition
	STZ.w !LineDrawn
	STZ.w !Timer
	LDA #$FF80
	STA.w !VWF_SCROLL+$22
.return

	JSL !amk_new_main			; Call AMK's main code
	RTS

;################################################
;# Not a command
;# Fades out topic

TopicFadeOut:
	LDA.w !ForcedScroll
	BNE .return

	PHY
	PHP
	SEP #$30
.loop
	LDA.w !VWF_HDMA+$15				; If topic is black, return
	BEQ .faded_out


	LDX.w !Timer
	LDA #$0B
	SEC
	SBC.w !Timer
	TAY
..dec_loop
	LDA.w !VWF_HDMA+$10,x			; Fade out the topic by updating the HDMA table
	BEQ ..min_brightness
	DEC.w !VWF_HDMA+$10,x
	PHX
	TYX
	DEC.w !VWF_HDMA+$10,x
	PLX
..min_brightness

	INY
	DEX
	BPL ..dec_loop

	LDA.w !Timer
	CMP #$05
	BCS ..skip
	INC.w !Timer
..skip


.wait_vblank
	LDA $10							; Wait for next V-Blank
	BEQ .wait_vblank
	STZ $10
	
	JSL !amk_new_main			; Call AMK's main code

	BRA .loop

.faded_out
	PLP
	STZ.w !Timer
	PLY

.return
	RTS

;################################################
;# Not a command
;# Fades in topic

TopicFadeIn:
	LDA !ForcedScroll
	BNE .return

	PHY
	PHP
	SEP #$30
	LDA #$04
	STA.w !Timer

.loop	
	LDA.w !VWF_HDMA+$10
	CMP #$0F
	BEQ .faded_in

	LDX #$05
	LDY #$06
..inc_loop
	LDA.w !VWF_HDMA+$10,x
	CMP #$0F
	BEQ ..max_brightness
	INC.w !VWF_HDMA+$10,x
	PHX
	TYX
	INC.w !VWF_HDMA+$10,x
	PLX
..max_brightness	

	INY
	DEX
	CPX.w !Timer
	BNE ..inc_loop
	LDA.w !Timer
	BMI ..skip
	DEC.w !Timer
..skip


.wait_vblank
	LDA $10
	BEQ .wait_vblank
	STZ $10
	
	JSL !amk_new_main			; Call AMK's main code

	BRA .loop
	
.faded_in
	PLP
	STZ.w !Timer
	PLY

.return
	RTS

;################################################
;# Command $8D
;# Changes the current topic

ChangeTopic:
	JSR TopicFadeOut

	SEP #$A0
	LDA #$00
	STA $004200
	REP #$20

	LDA.w !Xposition
	PHA
	STZ.w !Xposition

	LDA.w #!VWF_TOPIC_GFX
	STA $04
	LDX #$03FE
-	
	STZ.w !VWF_TOPIC_GFX,x
	DEX #2
	BPL -
	SEP #$20
	INY
.Loop
	LDA [$D5],y
	BPL .IsChar
	CMP #$8D
	BEQ .END
	REP #$20
	PEA.w .ReturnedCommand-1
	AND #$007F
	ASL A
	TAX
	LDA.l CommandAddress,x
	PHA
	RTS
.ReturnedCommand
	SEP #$20
	BRA .Loop
.IsChar
	JSR DrawChar
	BRA .Loop

.END
	LDA #$81
	STA $004200
-

	LDA $10
	BEQ -
	STZ $10

	LDA #$00
	STA $00420C
	LDA #$80
	STA $002100
	STA $002115

if !sa1 == 1
	LDX #$120B						; Optimization for DMA upload
else
	LDX #$420B						; Optimization for DMA upload
endif
	REP #$20
	LDA #$3000
	STA $002116
	LDA #$1801
	STA $F5,x
	LDA.w #!VWF_TOPIC_GFX
	STA $F7,x
	LDA.w #!VWF_TOPIC_GFX>>8
	STA $F8,x
	LDA #$0400
	STA $FA,x
	SEP #$20
	LDA #$01
	STA $00,x
	LDA $0D9F
	STA $01,x

	REP #$20
	LDA.w !Xposition
	LSR
	CLC
	ADC #$FF80
	STA $CA10
	PLA
	STA.w !Xposition
	STZ.w !TermChars
	INY
	JSR TopicFadeIn
	
	JSL !amk_new_main			; Call AMK's main code
	
	RTS

;################################################
;# Not a command
;# Fades out OAM tiles

TopFadeOut:
	LDA !ForcedScroll
	BNE .return

	PHY
	PHP
	SEP #$30
.loop
	LDA.w !VWF_HDMA
	BEQ .faded_out
	DEC.w !VWF_HDMA


.wait_vblank
	LDA $10
	BEQ .wait_vblank
	STZ $10
	
	JSL !amk_new_main			; Call AMK's main code

	BRA .loop

.faded_out
	PLP
	PLY

.return
	RTS

;################################################
;# Not a command
;# Fades in the OAM tiles

TopFadeIn:
	LDA.w !ForcedScroll
	BNE .return

	PHY
	PHP
	SEP #$30
.loop
	LDA.w !VWF_HDMA
	CMP #$0F
	BEQ .max_brightness

	INC.w !VWF_HDMA


.wait_vblank
	LDA $10
	BEQ .wait_vblank
	STZ $10

	JSL !amk_new_main			; Call AMK's main code

	BRA .loop

.max_brightness
	PLP
	PLY

.return
	RTS

;################################################
;# Command $8E
;# Draws OAM tiles on screen

ShowOAM:
	JSR HideOAM
	LDA #$0001					; High OAM index
	STA $0E

	LDX #$0004					; Starting OAM index

	LDA [$D5],y					; Fetch amount of tiles to be drawn on screen
	AND #$00FF
	STA $0C
	INY

; Format:
; XX YY TT yxs?ccct

.draw_loop
	LDA [$D5],y					; Get X/Y positions
	STA $0200,x
	INY #2
	LDA [$D5],y					; Grab tile and properties data
	STA $0202,x

	LDA [$D5],y					; Get extra info for later usage
	AND #$2000
	ASL #2
	STA $08

	INX #4						; Increase indexes for the next tile
	INY #2

	PHX							; Calculate a proper high OAM index for $0400
	LDA $0E						; No need for $0420
	LSR #2
	ORA #$0400					; $0400 | (index >> 2)
	STA $00
	LDA $0E
	AND #$0003					
	ASL 
	TAX
	LDA ($00)
	AND.l .Mask,x
	ASL $08
	BCC +
	ORA.l .OR,x
+
	STA ($00)
	PLX

	INC $0E
	DEC $0C
	BNE .draw_loop

	JSR TopFadeIn
	RTS

.Mask
	dw $FFFC,$FFF3,$FFCF,$FF3F
.OR	
	dw $0002,$0008,$0020,$0080

;################################################
;# Command $8F
;# Hides every sprite tile

HideOAM:
	JSR TopFadeOut
	SEP #$20
	LDA #$F0
	JSL $7F8005
	REP #$20
	INY
.return
	RTS

;################################################
;# Command $90
;# Option menu

BranchLabel:
	LDA !ForcedScroll
	BNE HideOAM_return

	LDA [$D5],y				; Fetch amount of options
	STA $06
	XBA
	AND #$007F
	STA $02
	ASL #4
	STA $04

	LDA.w !LeftPad
	SEC
	SBC #$000A
	BCS +
	LDA #$0000
+	
	STA $0200
	LDA.w !SelectMsg
	ASL #4
	STA $00
	LDA.w !LineDrawn
	ASL #4
	ADC #$008F
	ADC $00
	SEC
	SBC $04
	STA $0201
	LDA.w #!DownArrowGFX
	STA $0202

	LDA $16
	AND #$000C
	BEQ ++
	CMP #$000C
	BEQ ++
	BIT #$0004
	BEQ +
	INC.w !SelectMsg
	LDA.w !SelectMsg
	CMP $02
	BCC ++
	STZ.w !SelectMsg
	BRA ++
+
	DEC.w !SelectMsg
	BPL ++
	LDA $02
	DEC A
	STA.w !SelectMsg
++
	LDA.b $16-1
	ORA.b $18-1
	BPL .return
	LDA #$00F0
	STA $0201
	INY
	INY
	TYA
	ASL.w !SelectMsg
	ADC.w !SelectMsg
	TAY
	LDA [$D5],y
	TAY
	STZ.w !SelectMsg
	LDA $06
	BMI .return
	INC.w !Inner
	JSR BreakLine
	STZ.w !Inner

.return
	RTS

;################################################
;# Command $91
;# Jump label

JumpLabel:
	INY
	LDA [$D5],y
	TAY
	RTS

;################################################
;# Command $92
;# Skip label

SkipLabel:
	INY
	LDA [$D5],y
	STA.w !SkipPos
	INY #2
	RTS

;##################################################################################################
;# Draw character on screen
;# 
;# Input:
;# 		A: Character number. Can't be over $80
;#		$04: 16-bit address of the tilemap in RAM

DrawChar:
	PHY
	STA $00					; Preserve character number

	PHK
	PLA
	STA $0C					; Get current bank
	STA $0F

	REP #$20
	LDA $00					; Calculate character width from LUT
	AND #$00FF
	TAX
	LDA.l FontWidth,x
	AND #$00FF
	STA $08					; $08 = Current character width

	TXA
	ASL #2					; Calculate index for character's GFX
	STA $00					; Index = char_loc + char_num * 6
	ASL
	ADC $00
	ADC.w #Letters			; Add characters ROM location
	STA $0A					; $0A = Address for the left part of the current character GFX

	ADC #$0400
	STA $0D					; $0D = Address for the right part of the current character GFX

							; There are some characters that don't fit in a 8px width space
							; W doesn't fit, so it's broke down into two different tiles

	LDY #$0000
.YLoop
	STZ $00					
	LDA [$0A],y
	STA $01					; $00 = Left tile's px
	LDA [$0D],y				
	AND #$00FF
	ORA $00					; A = LLLLLLLL RRRRRRRR

	LDX #$0000
.XLoop
	ASL						; Check if the current pixel isn't blank
	BCC .NoPixel			; also shift its position

	PHA						; Preserve GFX tiles
	PHX						; and loop

	TXA
	CLC						; Calculate pixel's X position in the screen
	ADC.w !Xposition
	PHA

	AND #$FFF8
	ASL
	CPY #$0008
	BCC +
	ORA #$0200
+	
	STA $00

	TYA
	AND #$0007
	ASL
	ADC $04					; Add GFX data
	ADC $00
	STA $00					; $00 = GFX address to draw to
	PLA

	AND #$0007
	ASL
	ORA.w !FontColor		; Grab font color and apply it
	TAX
	LDA ($00)
	ORA.l BitTable,x		; Merge GFX data together
	STA ($00)

	PLX
	PLA

.NoPixel
	INX
	CPX $08					; Check if all of the pixels in the current character have been merged into the tilemap
	BNE .XLoop

	INY
	CPY #$000C				; Check if every pixel has been drawn. (Chracters can't be over 12 px tall)
	BCC .YLoop

	LDA.w !Xposition
	ADC $08					; Add the character's width + 1 to the X position
	STA.w !Xposition		; Basically preparing the new character to be drawn

	DEC.w !TermChars		; Decrease amount of characters to be drawn in the current line

-	
	CMP #$0100				; Failsafe. Hangs the game if somehow the text goes out of bounds.
	BCS -

	SEP #$20
	PLY
	INY						; Increase VWF data index

	RTS


BitTable:
	dw $0080,$0040,$0020,$0010,$0008,$0004,$0002,$0001
	dw $8000,$4000,$2000,$1000,$0800,$0400,$0200,$0100
	dw $8080,$4040,$2020,$1010,$0808,$0404,$0202,$0101

Letters:
	incbin "vwf.bin"
FontWidth:
	incbin "width.bin"
