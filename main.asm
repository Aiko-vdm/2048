IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc" 
INCLUDE "rand.inc"

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
2Cell_file db "2Cell.bin", 0
4Cell_file db "4Cell.bin", 0
8Cell_file db "8Cell.bin", 0
16Cell_file db "16Cell.bin", 0
32Cell_file db "32Cell.bin", 0
64Cell_file db "64Cell.bin", 0
128Cell_file db "128Cell.bin", 0
256Cell_file db "256Cell.bin", 0
512Cell_file db "512Cell.bin", 0
1024Cell_file db "1024Cell.bin", 0
2048Cell_file db "2048Cell.bin", 0
8192Cell_file db "8192Cell.bin", 0
16kCell_file db "16kCell.bin", 0
32kCell_file db "32kCell.bin", 0
65kCell_file db "65kCell.bin", 0
131kCell_file db "131kCell.bin", 0
Background_file db "Background.bin", 0
EmptyCell_file db "EmptyCell.bin", 0
FilledBackground_file db "FilledBackground.bin", 0
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END main
