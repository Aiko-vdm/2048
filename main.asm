IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc" 
INCLUDE "rand.inc"
INCLUDE "image.inc"

VMEMADR EQU 0A0000h	; video memory address  320x200 dus 6400 adresses verder eindigt ie
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

STRUC tile
    icon dd 0
    value db 0 
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
    
    CALL fillBackground, 12
	CALL processFile, offset FilledBackground_file
    loop @@drawLoop

    ret
endp drawGameState

PROC main
	sti
	cld
	push ds
	pop	es

	call setVideoMode, 13h
    
    @@gameLoop:
    CALL wait_VBLANK, 1
    CALL drawGameState
    ;CALL handleInput
    ;CALL updateGameState
    ;CALL checkGameState
    CMP AL, 3 ;loss?
    JNE @@gameLoop

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
TwelveCell_file db "assets/8192Cell.bin", 0
ThirteenCell_file db "assets/16kCell.bin", 0
FourteenCell_file db "assets/32kCell.bin", 0
FifteenCell_file db "assets/65kCell.bin", 0
SixteenCell_file db "assets/131kCell.bin", 0
Background_file db "assets/Bg.bin", 0
EmptyCell_file db "assets/ECell.bin", 0
FilledBackground_file db "assets/FBg.bin", 0
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
