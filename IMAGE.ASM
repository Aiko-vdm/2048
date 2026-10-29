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
	

	; read file data
	mov bx, ax ; move filehandle to bx
	mov ecx, FULLPALLETESIZE + PIXELCOUNT
	mov edx, offset palette
	mov ah, 3fh
	int 21h

	; close file
	mov ah, 3Eh
	int 21h
	
	; copy to video buffer, update palette
	mov esi, offset imagedata
	mov edi, VMEMADR
	mov ecx, PIXELCOUNT
	rep movsb
	ret
ENDP processFile

; -------------------------------------------------------------------

; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
UDATASEG
	palette	db FULLPALLETESIZE dup (?)
	imagedata db PIXELCOUNT dup (?)

; -------------------------------------------------------------------
STACK 100h

END