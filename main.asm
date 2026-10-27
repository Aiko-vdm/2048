IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc" "rand.inc"

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

start:         
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode
	
PROC main
	sti
	cld

	call setVideoMode, 13h
    
    mov ax,4c00h 
    int 21h
ENDP main

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG


; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
