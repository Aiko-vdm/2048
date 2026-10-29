; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	David Blinder
; date:		
; program:	Simple image load and display for mode 13h
;
; image source: https://www.pxfuel.com/en/free-photo-obrvr
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

Include "spritedp.inc"

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SPRITEWIDTH EQU 320
SPRITEHEIGHT EQU 200
DATASIZE EQU SPRITEWIDTH*SPRITEHEIGHT;bytes of data in file
SCREEN_WIDTH EQU 320 
SCREEN_HEIGHT EQU 200



; -------------------------------------------------------------------
CODESEG


; Halt program until keystroke is pressed.
MACRO waitForKeystroke
	mov	ah,00h
	int	16h
ENDM waitForKeystroke

; terminate if key is pressed
PROC terminateAfterKeystroke
	USES eax
	mov	ah, 01h
	int	16h
	jz @@charfound
	ret
	
@@charfound:
	call terminateProcess
ENDP terminateAfterKeystroke


PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

; -------------------------------------------------------------------


PROC ReadFile
	ARG	 @@filepathptr: dword,@@dataptr: dword,@@noofbytes: dword 
	USES eax, ebx, ecx, edx, esi, edi
	
	; open file, get filehandle in AX
	mov al, 0 ; read only
	mov edx, [@@filepathptr]
	mov ah, 3dh
	int 21h
	
	mov  edx, offset openErrorMsg
	jc @@print_error ; carry flag is set if error occurs

	; read file data 
	mov bx, ax ; move filehandle to bx
	mov ecx, [@@noofbytes]
	mov edx, [@@dataptr]
	mov ah, 3fh
	int 21h

	mov  edx, offset readErrorMsg
	jc @@print_error
	
	; close file
	mov ah, 3Eh
	int 21h
	
	mov  edx, offset closeErrorMsg
	jc @@print_error
	
	ret

@@print_error:
	call setVideoMode, 03h
	mov  ah, 09h
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess	
ENDP ReadFile

PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode


PROC drawSprite
ARG @@spritePtr :dword, \
@@dstPtr :dword, \
@@x:dword, \
@@y:dword
LOCAL @@w:dword, @@h:dword
USES eax , ebx , ecx , edx , esi , edi
	mov esi , [ @@spritePtr ]
	xor eax , eax
	lodsd ; read width in EAX
	mov [@@w] , eax
	lodsd ; read heigh in EAX
	mov [@@h] , eax
	mov edi , [ @@dstPtr ]
	mov eax , [@@y]
	mov ebx , SCREEN_WIDTH
	mul ebx
	add edi , eax
	add edi , [@@x] ; EDI po in ts to f i r s t p i x e l
	mov ecx , [@@h]
	@@drawLine :
	push ecx
	mov ecx , [@@w] ; need to copy a l in e o f the s p r i t e
	rep movsb ; copy from e s i to ed i
	add edi , SCREEN_WIDTH
	sub edi , [@@w] ; ed i now po in ts to the next l in e in d s t
	pop ecx
	dec ecx
	jnz @@drawLine
ret
ENDP drawSprite
PROC fillBackground
	ARG 	@@fillcolor:byte
	USES 	eax, ecx, edi

	; Initialize video memory address.
	mov	edi, VMEMADR

	; Scan the whole video memory and assign the background colour.
	mov	ecx, SCREEN_WIDTH*SCREEN_HEIGHT
	mov	al,[@@fillcolor]
	rep	stosb

	ret
ENDP fillBackground

;PROC main
;	sti
;	cld
;	
;	push ds
;	pop	es
;	call setVideoMode, 13h
;	call fillBackground, 0
;	
;	lea eax, [sprite+8];get memory location of first image data element in the sprite variable
;	call ReadFile, offset sprite_file, eax,DATASIZE ;Fill image data from file data
;	call drawSprite, offset sprite, VMEMADR, 0,0   ;Draw sprite at (0,0)  ; locatieee!!!!!
;	waitForKeystroke	
;	call terminateProcess
;
;ENDP main

; -------------------------------------------------------------------
DATASEG
				
	sprite_file db "SPRITEDP.bin", 0
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'
	sprite DD SPRITEWIDTH, SPRITEHEIGHT; see that first two elements are double words specifying sprite dimensions
	DB DATASIZE DUP(0)
; -------------------------------------------------------------------
UDATASEG
; -------------------------------------------------------------------
STACK 100h

END
