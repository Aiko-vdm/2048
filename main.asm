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
start:
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

	mov	edi, VMEMADR
	
	mov al, [@@fillcolor]
	mov ah, al				
    mov cx, ax			
	shl eax, 16				
	mov ax, cx			

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

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
