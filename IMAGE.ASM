; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	David Blinder
; date:		20/10/2021
; program:	Simple image load and display for mode 13h
;
; image source: https://www.pxfuel.com/en/free-photo-xpoec
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "image.inc"

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
FULLPALLETESIZE EQU 768 ; bytes in palette
COLORCOUNT EQU 128 ; number of unique colors for palette cycling
PIXELCOUNT EQU 320*200	; pixel count

; -------------------------------------------------------------------
CODESEG

; Set the video mode
PROC setVideoMode
	ARG 	@@VM:byte
	USES 	eax

	movzx ax,[@@VM]
	int 10h

	ret
ENDP setVideoMode

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

; Update the colour palette.
;	* Psource: palette source location
; 	* Nbytes: number of bytes that should be updated for palette
; 	* Firstcolor: internal palette offset
PROC updateColourPalette
	ARG	 	@@Psource:dword, @@Nbytes: dword, @@Firstcolor: word
	USES 	eax, ecx, edx, esi

	mov esi, [@@Psource]
	mov ecx, [@@Nbytes] ; amount of color bytes to read (movzx = zero extend)
	

	mov dx, 03C8h 		; DAC write port
	mov ax, [@@Firstcolor]	; index of first color to change
	out dx, al			; write to IO
	inc dx
	rep outsb			; update colors

	ret
ENDP updateColourPalette

; Terminate the program.
PROC terminateProcess
	USES eax
	call setVideoMode, 03h
	mov	ax,04C00h
	int 21h
	ret
ENDP terminateProcess

; -------------------------------------------------------------------

; opens file, read contents to palette + imagedata, closes file
PROC processFile
	ARG	 @@filepathptr: dword
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
	mov ecx, FULLPALLETESIZE + PIXELCOUNT
	mov edx, offset palette
	mov ah, 3fh
	int 21h

	mov  edx, offset readErrorMsg
	jc @@print_error
	
	; close file
	mov ah, 3Eh
	int 21h
	
	mov  edx, offset closeErrorMsg
	jc @@print_error
	
	; copy to video buffer, update palette
	mov esi, offset imagedata
	mov edi, VMEMADR
	mov ecx, PIXELCOUNT
	rep movsb
	call updateColourPalette, offset palette, FULLPALLETESIZE, 0
	ret

@@print_error:
	call setVideoMode, 03h
	mov  ah, 09h
	int  21h
	
	mov	ah,00h
	int	16h
	call terminateProcess	
ENDP processFile

; -------------------------------------------------------------------

; -------------------------------------------------------------------
DATASEG
				
	image_file db "imdata.bin", 0	
	openErrorMsg db "could not open file", 13, 10, '$'
	readErrorMsg db "could not read data", 13, 10, '$'
	closeErrorMsg db "error during file closing", 13, 10, '$'

; -------------------------------------------------------------------
UDATASEG
	palette	db FULLPALLETESIZE dup (?)
	imagedata db PIXELCOUNT dup (?)

; -------------------------------------------------------------------
STACK 100h

END