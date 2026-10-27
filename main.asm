; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:	Stijn Bettens, David Blinder
; date:		25/09/2017
; program:	Hello World!
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

start:
     sti            ; set The Interrupt Flag => enable interrupts
     cld            ; clear The Direction Flag
	;test
	; if else oefening
	mov eax, 1 ; assign aan eax 1

    cmp eax, 0 ; compare inhoud eax met 0 (doet eax - 0)
    jz is_zero ; jump enkel als 0 is

    cmp eax, 1 ; compare inhoud eax met 1 (doet eax - 1)
    jz is_one ; jump enkel als 0 is

    mov edx, offset msg_neither ; steekt adres msg in edx
    jmp printme ; onvoorwaardelijke jump

    is_zero: 
    mov edx, offset msg_zero
    jmp printme

    is_one:
    mov edx, offset msg_one

    printme:
    mov ah,09h ; Zelfde als mov ah,9, suffix h duidt aan dat hexadecimaal is ipv decimaal
    int 21h  ;print
    mov ax,4c00h ; stop programma ofz
	
	; Hello world loop
	mov ah, 09h
	mov edx, offset msg
	mov ecx, 10 ; # of loops
	
	printloop:
	int 21h
	loop printloop
	
	mov ax, 4c00h
	int 21h
	
	;wpo1: print hello world
    mov ah,9 ; zet nummer 9 in ah (8-bit register), 9 is een functienummer => print een string eindigend op $
    mov edx,offset msg ; Zet het adres van msg in edx. Function 9 expects the address of the string in edx. Offset betekent dus 'adres van'
    int 21h ;Calls DOS interrupt 21h, which runs the function chosen in ah. Here that prints the string starting at edx until it hits a $.
    mov ah,0 ;Interrupt 16h is the BIOS keyboard service. Function 0 waits until a key is pressed and returns it in al.
    int 16h ;  The program freezes until you press something.
	
    mov ah,2 ;Function 2 of int 21h = print a single character whose ASCII code is in dl.
    mov dl,'H'
    int 21h ; Puts the ASCII code of 'H' (72) in dl and prints it.
	
    mov dl,5
    add dl,'0' ;This prints the digit 5 as text. The number 5 is not the character '5': the ASCII code for '0' is 48, so 5 + 48 = 53 which is '5'.
    int 21h; Note that ah is still 2, so you don't need to set it again.
	
    mov ax,4c00h ;ax is ah and al together: 4Ch in ah is the function "terminate program", and 00h in al is the return code (0 = success).
    int 21h
	


; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	msg db "Hello World!", 13, 10, '$' 
	msg_neither db "Neither", 13, 10, '$'
	msg_one db "one", 13, 10, '$'
	msg_zero db "zero", 13, 10, '$'

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h

END start
