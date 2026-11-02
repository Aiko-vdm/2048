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

PROC fillBackground
	ARG 	@@fillcolor:byte
	USES 	eax, ecx, edi

	; Initialize video memory address.
	mov	edi, VMEMADR
	
	; copy color value across all bytes of eax
	mov al, [@@fillcolor]	; ???B
	mov ah, al				; ??BB
	mov cx, ax			
	shl eax, 16				; BB00
	mov ax, cx				; BBBB

	; Scan the whole video memory and assign the background colour.
	mov	ecx, SCRWIDTH*SCRHEIGHT/4
	rep	stosd

	ret
ENDP fillBackground

PROC drawGameState
    USES eax, ebx, ecx, edx
    mov ecx, size
    mov ebx, 0
    @@drawLoop:
    
    ;CALL fillBackground, 12
    loop @@drawLoop

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
	jb short @@keyLoop
	
	cmp [__keyb_keyboardState + KEY_ESC], 0
	je @@done
	mov [quit], 1

	@@done:
	ret
	
ENDP handleInput

PROC main
	sti
	cld
	push ds
	pop	es

	call setVideoMode, 13h
	call __keyb_installKeyboardHandler
    call drawInit
	call drawCell , offset OneCell_file, 0, 0
    @@gameLoop:
    CALL wait_VBLANK, 1
    CALL drawGameState
    CALL handleInput
    ;CALL updateGameState
    ;CALL checkGameState
    ;CMP AL, 3 ;loss?
	cmp [quit], 0
	je @@gameLoop
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
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
