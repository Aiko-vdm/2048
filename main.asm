IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc" 
INCLUDE "rand.inc"
INCLUDE "spritedp.inc"

VMEMADR EQU 0A0000h	; video memory address  320x200 dus 6400 adresses verder eindigt ie
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height
BIGSPRITEWIDTH EQU 176
BIGSPRITEHEIGHT EQU 176
BIGDATASIZE EQU BIGSPRITEWIDTH*BIGSPRITEHEIGHT
CENTERX EQU (SCRWIDTH-BIGSPRITEWIDTH)/2
CENTERY EQU (SCRHEIGHT-BIGSPRITEHEIGHT)/2
SMALLSPRITEWIDTH EQU 32
SMALLSPRITEHEIGHT EQU 32
SMALLDATASIZE EQU SMALLSPRITEWIDTH*SMALLSPRITEHEIGHT
DISTANCEBETWEENCELLS EQU 5
BORDER EQU 16

RANDOMIZEATTEMPTS EQU BOARDSIZELOGIC*10

BOARDLENGTHLOGIC EQU 4
BOARDWIDTHLOGIC EQU 4
BOARDSIZELOGIC EQU BOARDLENGTHLOGIC*BOARDWIDTHLOGIC

FOURCHANCE EQU 5 ; 5% kans op een 4

KEY_ESC   EQU 01h
KEY_UP    EQU 48h
KEY_DOWN  EQU 50h
KEY_LEFT  EQU 4Bh
KEY_RIGHT EQU 4Dh
DIRECTION_NONE  EQU 0
DIRECTION_UP    EQU 1
DIRECTION_DOWN  EQU 2
DIRECTION_LEFT  EQU 3
DIRECTION_RIGHT EQU 4
; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

STRUC tile
    icon dd 0
    value db 0 ; exponent: 0 = empty, 1 = 2, 2 = 4, etc.
ENDS tile   

PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode

proc wait_VBLANK
	ARG @@framecount: word
	USES eax, ecx, edx
	mov dx, 03dah 				
	movzx ecx, [@@framecount]
	
		@@VBlank_phase1:
		in al, dx 
		and al, 8
		jnz @@VBlank_phase1
		@@VBlank_phase2:
		in al, dx 
		and al, 8
		jz @@VBlank_phase2
	loop @@VBlank_phase1
	
	ret 
endp wait_VBLANK

PROC drawGameState
    USES eax, ebx, edx, esi

	xor edx, edx					; edx = y (rij)
	@@row:
	xor ebx, ebx					; ebx = x (kolom)
	@@col:
	; esi = adres van tile (y * 4 + x) in board
	mov eax, edx
	imul eax, BOARDWIDTHLOGIC
	add eax, ebx
	imul eax, SIZE tile
	lea esi, [board + eax]

	cmp [(tile ptr esi).value], 0
	je short @@skip					; lege tile: niets tekenen
	call drawCell, [(tile ptr esi).icon], ebx, edx

	@@skip:
	inc ebx
	cmp ebx, BOARDWIDTHLOGIC
	jb short @@col
	inc edx
	cmp edx, BOARDLENGTHLOGIC
	jb short @@row

	ret
endp drawGameState

PROC drawInit
    USES eax, ebx, ecx, edx
    
	lea eax, [BigSprite + 8]
	call ReadFile, offset FilledBackground_file, eax,BIGDATASIZE
	call drawSprite, offset BigSprite, VMEMADR, CENTERX,CENTERY

    ret
endp drawInit

PROC drawCell
	ARG 	@@cell:dword, @@x:dword, @@y:dword
    USES eax, ebx, ecx, edx

	mov ebx, [@@x]
	imul ebx, DISTANCEBETWEENCELLS+SMALLSPRITEWIDTH
	add ebx, CENTERX + BORDER
	
	mov ecx, [@@y]
	imul ecx, DISTANCEBETWEENCELLS+SMALLSPRITEHEIGHT
	add ecx, CENTERY + BORDER

	lea eax, [SmallSprite + 8]
	call ReadFile,[@@cell], eax,SMALLDATASIZE
	call drawSprite, offset SmallSprite, VMEMADR, ebx, ecx

    ret
endp drawCell

Proc SpawnTile
	ARG  @@count:dword
	Uses ebx, esi, ecx, edx, edi
	mov edi, [@@count]
	test edi, edi
	jz @@success
	
	@@nextTile:
	mov ecx, 100
	@@spawn:
	xor	edx, edx
	call rand16
	mov	esi, BOARDSIZELOGIC
	div	esi
	imul edx, SIZE tile
	lea esi, [board + edx]
	
	cmp	[(tile ptr esi).value], 0
	je	@@found
	loop	@@spawn
	xor eax, eax
	ret
	
	@@found:
	call rand16
	xor edx,edx
	mov ebx, 100
	div ebx
	cmp edx, FOURCHANCE
	jb @@spawnfour

	mov	[(tile ptr esi).value], 1  
	mov [(tile ptr esi).icon], offset OneCell_file
	jmp @@placed
	
	@@spawnfour:
	mov	[(tile ptr esi).value], 2
	mov [(tile ptr esi).icon], offset TwoCell_file
	
	@@placed:
	dec edi
	jnz	@@nextTile
	
	@@success:
	mov eax, 1
	ret
Endp SpawnTile

PROC handleInput
	; checks each frame if a new arrow key has been pressed and stores result in variable
	USES eax, ebx, ecx, edx
	mov [direction], DIRECTION_NONE
	xor ecx, ecx
	@@keyLoop: ; we loop over arrow keys with ecx as index
	movzx ebx, [keyTable + ecx] ; retrieves the scan code of the current key
	mov dl, [__keyb_keyboardState + ebx] ; retrieves the state of the current key
	mov dh, [prevState + ecx] ; retrieves the previous state of the current key
	mov [prevState + ecx], dl ; updates the previous state of the current key

	test dl, dl 
	jz @@next ; key is'nt pressed
	test dh, dh
	jnz @@next ; key was already pressed
	lea eax, [ecx + 1]
	mov [direction], al ; store the direction of the pressed key

	@@next:
	inc ecx
	cmp ecx, 4
	jb @@keyLoop
	
	cmp [__keyb_keyboardState + KEY_ESC], 0
	je @@done
	mov [quit], 1

	@@done:
	ret
	
ENDP handleInput

PROC UpdateGameState
	USES eax

	cmp [direction], DIRECTION_RIGHT
	je @@right
	cmp [direction], DIRECTION_LEFT
	je @@left
	cmp [direction], DIRECTION_DOWN
	je @@down
	cmp [direction], DIRECTION_UP
	je @@up

	jmp @@done

	@@right:
	call slideRight
	jmp @@check
	@@left:	
	call slideLeft
	jmp @@check
	@@down:
	call slideDown
	jmp @@check
	@@up:
	call slideUp
	jmp @@check
	@@check:
	test eax, eax
	jz @@done					
	call SpawnTile, 1
	mov [redraw], 1

	@@done:
	ret
ENDP UpdateGameState

PROC higherSlide
	ARG 	@@start, @@step, @@condition, @@tile, @@row
	USES ebx, ecx, edx, esi, edi
	mov [moved], 0
	mov esi, offset board ; begin of row
	mov ebx, BOARDWIDTHLOGIC ; #rows to process
	
	@@rowLoop: ; right to left
	mov [dword ptr tempRow], 0
	mov ecx, [@@start]	; read
	mov edi, [@@start]	; write
	xor edx, edx
	
	@@scan: ; read a tile
	mov eax, ecx
	imul eax, [@@tile]
	add eax, esi
	movzx eax, [(tile ptr eax).value]
	test eax, eax ; value = 0 => skip
	jz @@nextScan	
	
	cmp eax, edx ; value = last value => merge
	jne @@place
	add edi, [@@step]
	inc [byte ptr tempRow + edi] ; edi points to the next free tile, last placed tile is at edi + 1
	sub edi, [@@step]
	xor edx, edx ; reset last value: can't merge twice 
	jmp @@nextScan
	
	@@place:
	mov [tempRow + edi], al ; exponent of the tile to place at edi
	mov edx, eax
	sub edi, [@@step]
	
	@@nextScan:
	sub ecx, [@@step]
	cmp ecx, [@@condition]
	jne @@scan
	
	xor ecx, ecx ; write back the tempRow to the board (left to right)
	@@write:
	mov eax, ecx
	imul eax, [@@tile]
	add eax, esi
	movzx edx, [tempRow + ecx]

	cmp dl, [(tile ptr eax).value]
	je @@same
	mov [moved], 1
	@@same:
	mov [(tile ptr eax).value], dl

	test edx, edx
	jz @@empty
	mov edx, [iconTable + edx*4 - 4] ; for a non-empty tile, look up the icon in iconTable.
	mov [(tile ptr eax).icon], edx
	jmp @@nextWrite
	@@empty:
	mov [(tile ptr eax).icon], 0
	
	@@nextWrite:
	inc ecx
	cmp ecx, BOARDWIDTHLOGIC
	jb short @@write

	add esi, [@@row] ; move to next row
	dec ebx
	jnz @@rowLoop

	movzx eax, [moved]
	ret
ENDP higherSlide

Proc slideLeft
	call higherSlide, 0, -1, BOARDWIDTHLOGIC, SIZE tile, BOARDWIDTHLOGIC*SIZE tile
	ret
endp slideLeft

Proc slideRight
	call higherSlide, BOARDWIDTHLOGIC-1, 1, -1, SIZE tile, BOARDWIDTHLOGIC*SIZE tile
	ret
endp slideRight

Proc slideDown
	call higherSlide, BOARDWIDTHLOGIC-1, 1, -1,  BOARDWIDTHLOGIC*SIZE tile, SIZE tile
	ret
endp slideDown

Proc slideUp
	call higherSlide, 0, -1, BOARDWIDTHLOGIC, BOARDWIDTHLOGIC*SIZE tile, SIZE tile
	ret
endp slideUp

PROC main
	sti
	cld
	push ds
	pop	es

	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
    call drawInit
	call SpawnTile, 2
	call drawGameState
	;call drawCell , offset OneCell_file, 0, 0
    @@gameLoop:
    CALL wait_VBLANK, 1
	call handleInput
	call UpdateGameState
	
	cmp [redraw], 0
	je short @@noDraw
	call drawInit				
	call drawGameState
	mov [redraw], 0
	@@noDraw:

	cmp [quit], 0
	je @@gameLoop
    ;CALL drawGameState
    ;CALL handleInput
    ;CALL updateGameState
    ;CALL checkGameState
    ;CMP AL, 3 ;loss?
    ;JNE @@gameLoop
	call __keyb_uninstallKeyboardHandler
    mov ax,4c00h 
    int 21h
ENDP main

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
size equ 4
board tile size dup(size dup(<0, 0>))
OneCell_file db "assets/2Cell.bin", 0
TwoCell_file db "assets/4Cell.bin", 0
ThreeCell_file db "assets/8Cell.bin", 0
FourCell_file db "assets/16Cell.bin", 0
FiveCell_file db "assets/32Cell.bin", 0
SixCell_file db "assets/64Cell.bin", 0
SevenCell_file db "assets/128Cell.bin", 0
EightCell_file db "assets/256Cell.bin", 0
NineCell_file db "assets/512Cell.bin", 0
TenCell_file db "assets/1024Cell.bin", 0
ElevenCell_file db "assets/2048Cell.bin", 0
TwelveCell_file db "assets/4096Cell.bin", 0
ThirteenCell_file db "assets/8192Cell.bin", 0
FourteenCell_file db "assets/16kCell.bin", 0
FifteenCell_file db "assets/32kCell.bin", 0
SixteenCell_file db "assets/65kCell.bin", 0
SeventeenCell_file db "assets/131kCell.bin", 0
Background_file db "assets/Bg.bin", 0
EmptyCell_file db "assets/ECell.bin", 0
FilledBackground_file db "assets/FBg.bin", 0

BigSprite DD BIGSPRITEWIDTH, BIGSPRITEHEIGHT
DB BIGDATASIZE DUP(0)
SmallSprite DD SMALLSPRITEWIDTH, SMALLSPRITEHEIGHT
DB SMALLDATASIZE DUP(0)

keyTable  db KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT   ; index + 1 = DIRECTION_xxx
prevState db 4 dup(0)
direction db DIRECTION_NONE
quit      db 0

tempRow  db 4 dup(0)
moved   db 0
redraw  db 1			; 1 zodat het begin getekend wordt

iconTable dd offset OneCell_file, offset TwoCell_file, offset ThreeCell_file
          dd offset FourCell_file, offset FiveCell_file, offset SixCell_file
          dd offset SevenCell_file, offset EightCell_file, offset NineCell_file
          dd offset TenCell_file, offset ElevenCell_file, offset TwelveCell_file
          dd offset ThirteenCell_file, offset FourteenCell_file, offset FifteenCell_file
          dd offset SixteenCell_file, offset SeventeenCell_file
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
