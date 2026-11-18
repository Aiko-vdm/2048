IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "keyb.inc" 
INCLUDE "rand.inc"
INCLUDE "spritedp.inc"

VMEMADR EQU 0A0000h	; video memory address  320x200
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height
BIGSPRITEWIDTH EQU 176
BIGSPRITEHEIGHT EQU 176
BIGDATASIZE EQU BIGSPRITEWIDTH*BIGSPRITEHEIGHT
SMALLSPRITEWIDTH EQU 32
SMALLSPRITEHEIGHT EQU 32
SMALLDATASIZE EQU SMALLSPRITEWIDTH*SMALLSPRITEHEIGHT
DISTANCEBETWEENCELLS EQU 5
BORDER EQU 16
THREESPRITEWIDTH EQU 134
THREESPRITEHEIGHT EQU 134
THREESPRITEDATASIZE EQU THREESPRITEWIDTH*THREESPRITEHEIGHT
FIVESPRITEWIDTH EQU 212
FIVESPRITEHEIGHT EQU 200
FIVESPRITEDATASIZE EQU FIVESPRITEWIDTH*FIVESPRITEHEIGHT

FOURCHANCE EQU 5 ; 5% chance to spawn a 4

BOARDLENGTHLOGIC EQU 4
BOARDWIDTHLOGIC EQU 4
BOARDSIZELOGIC EQU BOARDLENGTHLOGIC*BOARDWIDTHLOGIC

CENTERX EQU (SCRWIDTH-BIGSPRITEWIDTH)/2
CENTERY EQU (SCRHEIGHT-BIGSPRITEHEIGHT)/2

KEY_ESC   EQU 01h
KEY_UP    EQU 48h
KEY_DOWN  EQU 50h
KEY_LEFT  EQU 4Bh
KEY_RIGHT EQU 4Dh
KEY_ENTER EQU 1Ch
DIRECTION_NONE  EQU 0
DIRECTION_UP    EQU 1
DIRECTION_DOWN  EQU 2
DIRECTION_LEFT  EQU 3
DIRECTION_RIGHT EQU 4
DIRECTION_ENTER EQU 5

WINVALUE EQU 11

STATE_PLAYING EQU 0
STATE_WON     EQU 1
STATE_LOST    EQU 2

SCOREAREAY    EQU 8		; y coordinate of the score area
SCOREAREAH    EQU 16	; height in pixels
SCOREAREAW    EQU 72	; width in pixels
SCORECOLOR    EQU 15	; white

SELECTED_COLOR EQU 4 ; red
IDLE_COLOR EQU 8 ; grey
; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

STRUC tile
    icon dd 0 ; pointer to file name of the icon to draw
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
	; The game loop runs in sync with the screen (60 times per second)
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
	; draws the current state of the game board
	; loops over all tiles and draws them if they are not empty
    USES eax, ebx, edx, esi

	xor edx, edx					; edx = y (row)
	@@row:
	xor ebx, ebx					; ebx = x (column)
	@@col:
	; esi = adres of tile (y * 4 + x) on board
	mov eax, edx
	imul eax, BOARDWIDTHLOGIC
	add eax, ebx
	imul eax, SIZE tile
	lea esi, [board + eax]

	cmp [(tile ptr esi).value], 0
	je short @@skip					; empty tile draw nothing
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

PROC Centerx
	; returns the x coordinate where the corner of the background should be so its centerd
	arg @@width: dword
	uses eax,edx
	mov eax, SCRWIDTH
	sub eax, [@@width]
	shr eax, 1
	ret
endp Centerx

PROC Centery
	; returns the y coordinate where the corner of the background should be so its centerd
	arg @@height: dword
	uses eax,edx
	mov eax, SCRHEIGHT
	sub eax, [@@height]
	shr eax, 1
	ret
endp Centery

PROC drawInit
	arg 	@@sprite: dword,@@file: dword,@@datasize: dword, @@width: dword, @@height: dword
	; draws the background
    USES eax, ebx, ecx, edx
    mov eax,[@@sprite]
	add eax, 8
	call ReadFile, [@@file], eax, [@@datasize]

	mov ebx, SCRWIDTH
	sub ebx, [@@width]
	shr ebx, 1						

	mov ecx, SCRHEIGHT
	sub ecx, [@@height]
	shr ecx, 1	
	call drawSprite, [@@sprite], VMEMADR, ebx, ecx
	;call drawSprite, offset [@@sprite], VMEMADR, call centerx [@@centerx], call centery [@@centery]

    ret
endp drawInit

PROC draw4Bg
	call drawInit, offset BigSprite, offset FilledBackground_file, BIGDATASIZE, BIGSPRITEWIDTH, BIGSPRITEHEIGHT
	ret
endp draw4Bg

PROC draw3Bg
	call drawInit, offset ThreeSprite, offset ThreeBackground_file, THREESPRITEDATASIZE, THREESPRITEWIDTH, THREESPRITEHEIGHT
	ret
endp draw3Bg

PROC draw5Bg
	call drawInit, offset FiveSprite, offset FiveBackground_file, FIVESPRITEDATASIZE, FIVESPRITEWIDTH, FIVESPRITEHEIGHT
	ret
endp draw5Bg

PROC drawCell
	; draws a cell at the given coordinates
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
	mov edi, [@@count] ; number of tiles to spawn
	test edi, edi
	jz @@success
	
	@@nextTile:
	mov ecx, 100
	@@spawn:
	xor	edx, edx
	call rand16
	mov	esi, BOARDSIZELOGIC
	div	esi 	; divide by board size to get a random tile index
	imul edx, SIZE tile
	lea esi, [board + edx]
	
	cmp	[(tile ptr esi).value], 0
	je	@@found
	loop	@@spawn
	xor eax, eax
	ret 	; no empty tile found, return 0
	
	@@found:
	call rand16
	xor edx,edx
	mov ebx, 100
	div ebx 	; edx = random number between 0 and 99
	cmp edx, FOURCHANCE 	; if random number < FOURCHANCE, spawn a 4, else spawn a 2
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
	mov eax, 1 ; return 1 to indicate that every tile was spawned
	ret
Endp SpawnTile

PROC setDrawCursor
	; sets the cursor position for drawing at text column @@col and row @@row (8x8 pixels per character)
	ARG @@col:byte, @@row:byte
	USES eax, ebx, edx
	
	mov dl, [@@col]
	mov dh, [@@row]
	xor bh, bh
	mov ah, 2 ; function 02h: set cursor position
	int 10h ; calls function in ah
	ret
ENDP setDrawCursor

PROC printChar
	; prints a character at the current cursor position and moves the cursor to the next position
	ARG @@char:byte
	USES eax, ebx, ecx, edx
	
	mov al, [@@char]
	mov ah, 0Eh ; function 0Eh: display char and move cursor
	xor bh, bh
	mov bl, SCORECOLOR
	int 10h
	ret
ENDP printChar

PROC drawScore
	; erases the previous score and draws the current score at the top of the screen ("SCORE" label and score value)
	USES eax, ebx, ecx, edx, esi, edi
	
	;erasing previous score
	mov edi, VMEMADR  + SCOREAREAY*SCRWIDTH ; address of first pixel of score area
	mov ebx, SCOREAREAH	; number of pixel rows to delete
	xor eax, eax	; 0 = black
	@@eraseLoop:
	mov ecx, SCOREAREAW ; number of pixels per row
	rep stosb ; write al to [edi], move edi, repeat ecx times
	add edi, SCRWIDTH - SCOREAREAW ; edi to beginning of next pixel row
	dec ebx
	jnz @@eraseLoop
	
	; draw score label
	call setDrawCursor, 0, 1
	call printString, offset scoreLabel
	
	; draw score value
	call setDrawCursor, 0, 2
	call printNumber, [score]
	
	ret	
ENDP drawScore

PROC fillRect
	; draws rectangle in video memory with color
	ARG @@x:dword, @@y:dword, @@w:dword, @@h:dword, @@color:byte
	USES eax, ebx, ecx, edi
	
	mov eax, [@@y]
	imul eax, SCRWIDTH
	add eax, [@@x]
	lea edi, [VMEMADR + eax]
	mov al, [@@color]
	mov ebx, [@@h]
	@@line:
	mov ecx, [@@w]
	rep stosb
	add edi, SCRWIDTH
	sub edi, [@@w]
	dec ebx
	jnz @@line
	ret
ENDP fillRect

PROC printString
	; prints a 0-terminated string at cursor position
	ARG @@str:dword
	USES eax, esi

	mov esi, [@@str]
	@@printString:
	movzx eax, [byte ptr esi] ; eax = current char
	test eax, eax ; test if it's concluding 0
	jz @@done
	call printChar, eax
	inc esi
	jmp @@printString
	@@done:
	ret
ENDP printString

PROC printNumber
	; prints number in decimal at cursor position
	ARG @@n:dword
	USES eax, ebx, ecx, edx
	
	mov eax, [@@n] ; eax = number
	mov ebx, 10 ; divisor 10, to separate digit by digit
	xor ecx, ecx
	@@printDigits:
	xor edx, edx
	div ebx ; eax = eax / 10 (quotient), edx = remainder (last digit)
	push edx ; push number onto the stack (popped later in reverse order)
	inc ecx
	test eax, eax ; if quotient 0, all digits are split off
	jnz @@printDigits 
	
	@@printStack:
	pop edx ; retrieve digit from stack
	add edx, '0' ; convert digit to character
	call printChar, edx ; print digit character
	loop @@printStack
	ret
ENDP printNumber

PROC drawButton
	; draws button (rectangle, red if selected, grey if not, with text on top)
	ARG @@y:dword, @@col:dword, @@row:dword, @@text:dword, @@selected:dword
	USES eax

	mov eax, IDLE_COLOR                 ; assume not selected
	cmp [@@selected], 0
	je short @@draw
	mov eax, SELECTED_COLOR             ; selected: red
	@@draw:
	call fillRect, 112, [@@y], 96, 16, eax      ; rectangle first
	call setDrawCursor, [@@col], [@@row]        ; then the text on top of it
	call printString, [@@text]
	ret
ENDP drawButton

PROC drawGameOver
	; draws game over screen with buttons "TRY AGAIN" and "EXIT"
	uses eax
	
	call fillRect, 0, 0, SCRWIDTH, SCRHEIGHT, 0 ; make whole screen black
	
	call setDrawCursor, 15, 4 ; centered
	call printString, offset txtGameOver
	call setDrawCursor, 14, 7
	call printString, offset txtFinalScore
	call setDrawCursor, 14, 8
	call printNumber, [score]
	
	; button "TRY AGAIN"
	xor eax, eax
	cmp [MenuSelected], 0
	sete al
	call drawButton, 92, 15, 12, offset txtTryAgain, eax
	
	; button "EXIT"
	mov al, IDLE_COLOR
	cmp [MenuSelected], 1
	jne @@button2
	mov al, SELECTED_COLOR
	@@button2:
	xor eax, eax
	cmp [MenuSelected], 1
	sete al
	call drawButton, 116, 18, 15, offset txtExit, eax
	ret
ENDP drawGameOver

PROC drawWin
	; draws screen with game over, buttons try again and exit
	call fillRect, 0, 0, SCRWIDTH, SCRHEIGHT, 0 ; make whole screen black

	call setDrawCursor, 16, 4
	call printString, offset txtYouWin
	call setDrawCursor, 15, 7
	call printString, offset txtYourScore
	call setDrawCursor, 15, 8
	call printNumber, [score]
	
	; button "KEEP PLAYING"
	xor eax, eax                        ; changes the flags
	cmp [MenuSelected], 0
	sete al                             ; al = 1 if equal (selected), else 0
	call drawButton, 92, 14, 12, offset txtKeepPlaying, eax
	
	;button "EXIT"
	xor eax, eax
	cmp [MenuSelected], 1
	sete al
	call drawButton, 116, 18, 15, offset txtExit, eax
	
	call setDrawCursor, 12, 20
	call printString, offset txtControls
	ret
ENDP drawWin

PROC updateGameOverMenu
	; handles Game Over menu 
	USES eax
	
	movzx eax, [direction] ; input 
	cmp eax, DIRECTION_UP
	je @@switch
	cmp eax, DIRECTION_DOWN
	je @@switch ; up or down both just switch selected button
	cmp eax, DIRECTION_ENTER
	je @@confirm
	jmp @@done
	
	@@switch:
	xor [MenuSelected], 1	; switch 0 to 1 or 1 to 0
	mov [redraw], 1 	; the color changed: redraw
	jmp @@done
	
	@@confirm:
	cmp [MenuSelected], 0
	jne short @@exit
	call resetGame	; Try again confirmed, game restarts
	jmp @@done
	@@exit:
	mov [quit], 1
	
	@@done:
	ret
ENDP updateGameOverMenu

PROC updateWinMenu
	; handles win menu
	USES eax

	movzx eax, [direction]              ; the input of this frame
	cmp eax, DIRECTION_UP
	je short @@switch
	cmp eax, DIRECTION_DOWN
	je short @@switch                   ; up and down both switch the selected button
	cmp eax, DIRECTION_ENTER
	je short @@confirm
	jmp short @@done                    ; any other key: nothing

	@@switch:
	xor [MenuSelected], 1       ; switch 0 to 1 or 1 to 0
	mov [redraw], 1                     ; the color changed: redraw
	jmp short @@done

	@@confirm:
	cmp [MenuSelected], 0
	jne short @@exit
	; KEEP PLAYING
	mov [hasWon], 1                     ; don't detect the 2048 tile as a win again
	mov [gameState], STATE_PLAYING      ; the game continues
	mov [MenuSelected], 0       ; reset the menu for next time
	call fillRect, 0, 0, SCRWIDTH, SCRHEIGHT, 0     ; remove the win screen text
	mov [redraw], 1                     ; main draws board and score again
	jmp short @@done
	@@exit:
	mov [quit], 1                       ; EXIT: the main loop ends

	@@done:
	ret
ENDP updateWinMenu

PROC resetGame
	; starts new game
	USES eax, ecx, edi
	
	mov edi, offset board 
	mov ecx, BOARDSIZELOGIC * SIZE tile
	xor al, al 
	rep stosb
	mov [score], 0
	mov [gameState], STATE_PLAYING
	mov [MenuSelected], 0
	call fillRect, 0, 0, SCRWIDTH, SCRHEIGHT, 0 
	call SpawnTile, 2   
	mov [redraw], 1 
	mov [hasWon], 0
	ret
ENDP resetGame



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
	jz @@next ; key isn't pressed
	test dh, dh
	jnz @@next ; key was already pressed
	lea eax, [ecx + 1]
	mov [direction], al ; store the direction of the pressed key

	@@next:
	inc ecx
	cmp ecx, 5
	jb @@keyLoop
	
	cmp [__keyb_keyboardState + KEY_ESC], 0
	je @@done
	mov [quit], 1

	@@done:
	ret
	
ENDP handleInput

PROC checkGameState
	; checks if the game is won, lost or still playing
	; returns STATE_WON, STATE_LOST or STATE_PLAYING in eax
	USES ebx, ecx, edx, esi, edi
	
	cmp [hasWon], 0
	jne @@moves ; already won earlier: skip the win check

	; loop over all tiles to check if any tile has value 2048 (exponent 11)
	mov esi, offset board
	mov ecx, BOARDSIZELOGIC
	@@winLoop:
	cmp [(tile ptr esi).value], WINVALUE
	je @@won
	add esi, SIZE tile
	loop @@winLoop
	
	; check if any move is possible (if any tile has a neighbor with the same value)
	@@moves:
	mov esi, offset board 	; esi = address of the current tile
	xor edx, edx			; edx = y
	@@row:
	xor ebx, ebx		; ebx = x
	@@col:
	mov al, [(tile ptr esi).value]
	test al, al
	jz @@playing 		; if the tile is empty, the game is still playing

	cmp ebx, BOARDWIDTHLOGIC-1
	jae @@noRight 		; if the tile is on the right edge, don't check right neighbor
	lea edi, [esi + SIZE tile]	; edi = address of the right neighbor
	cmp al,[(tile ptr edi).value] 
	je @@playing	; if the right neighbor has the same value, you can still merge
	
	@@noRight:
	cmp edx, BOARDLENGTHLOGIC-1
	jae @@noDown	; if the tile is on the bottom edge, don't check down neighbor
	lea edi, [esi + BOARDWIDTHLOGIC*SIZE tile] ; edi = address of the down neighbor
	cmp al,[(tile ptr edi).value]
	je short @@playing	; again, if the down neighbor has the same value, you can still merge

	@@noDown:
	add esi, SIZE tile
	inc ebx
	cmp ebx, BOARDWIDTHLOGIC
	jb @@col
	inc edx
	cmp edx, BOARDLENGTHLOGIC
	jb @@row
	mov eax, STATE_LOST ; no empty tile and no merge possible, game is lost
	ret

	@@won:
	mov eax, STATE_WON
	ret
	
	@@playing:
	mov eax, STATE_PLAYING
	ret
ENDP checkGameState

PROC UpdateGameState
	; updates the game state based on the current direction of movement. 
	; if a move was made, it spawns a new tile and sets the redraw flag.
	USES eax

	cmp [gameState], STATE_PLAYING
	jne @@done ; game over or won: ignore moves

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
	; higherSlide shifts a line (row or column) toward a “wall”. The four directions differ only in:
	; where you begin (position of "wall": @@start)
	; the direction in which you traverse the line (@@step: +1 or -1)
	; how many bytes you shift per position within the line (@@tile: SIZE tile)
	; how many bytes you shift to reach the next line (@@row: BOARDWIDTHLOGIC*SIZE tile for rows, SIZE tile for columns)
	ARG 	@@start, @@step, @@condition, @@tile, @@row 
	; @@condition is the value of the index that indicates the end of the line (-1 or BOARDWIDTHLOGIC)
	USES ebx, ecx, edx, esi, edi
	mov [moved], 0
	mov esi, offset board ; begin of line to process
	mov ebx, BOARDWIDTHLOGIC ; #rows to process
	
	@@rowLoop: 
	mov [dword ptr tempRow], 0	; clear the temporary row
	mov ecx, [@@start]	; read
	mov edi, [@@start]	; write = next free tile in the temporary row
	xor edx, edx ; last value = 0 (no tile yet)
	
	@@scan: ; read a tile
	mov eax, ecx
	imul eax, [@@tile] 	; position of the tile to read in bytes (position * bytes per tile)
	add eax, esi		; + beginning of line = address of the tile to read
	movzx eax, [(tile ptr eax).value]
	test eax, eax 
	jz @@nextScan	; value = 0 => skip
	
	cmp eax, edx ; value = last value 
	jne @@place
	add edi, [@@step] ; merge
	inc [byte ptr tempRow + edi] ; edi points to the next free tile, last placed tile is at edi + step (towards the wall)
	sub edi, [@@step] ; move edi back to the last placed tile (towards the wall)
	
	push ecx	; store the read position on the stack to restore it later
	lea ecx, [eax + 1] ; cl = exponent of the tile to place (value + 1)
	mov eax, 1 ; initial value 1 (2^0)
	shl eax, cl ; eax = 1 << (value + 1) = 2^(value+1),
	add [score], eax ; add to score
	pop ecx	; restore read position

	xor edx, edx ; reset last value: can't merge twice 
	jmp @@nextScan
	
	@@place:
	mov [tempRow + edi], al ; exponent of the tile to place at edi
	mov edx, eax	; last value = value of the tile just placed
	sub edi, [@@step]	; move to the next free tile in the temporary row (away from the wall)
	
	@@nextScan:
	sub ecx, [@@step]
	cmp ecx, [@@condition]
	jne @@scan
	
	xor ecx, ecx ; write back the tempRow to the board (0 -> BOARDWIDTHLOGIC-1)
	@@write:
	mov eax, ecx
	imul eax, [@@tile]
	add eax, esi
	movzx edx, [tempRow + ecx]

	cmp dl, [(tile ptr eax).value]
	je @@same
	mov [moved], 1 	; if the value of the tile has changed, set moved to 1
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

	movzx eax, [moved] ; return 1 if a tile has moved, 0 otherwise
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
	call higherSlide, BOARDWIDTHLOGIC-1, 1, -1, BOARDWIDTHLOGIC*SIZE tile, SIZE tile
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
    call draw4Bg
	call SpawnTile, 2
	call drawGameState
	call drawScore
    @@gameLoop:
    CALL wait_VBLANK, 1
	call handleInput
	call UpdateGameState
	
	cmp [gameState], STATE_PLAYING
	jne @@notPlaying
	call checkGameState
	mov [gameState], al
	cmp al, STATE_PLAYING
	je @@draw
	mov [redraw], 1
	jmp short @@draw

	@@notPlaying: 
	cmp [gameState], STATE_LOST
	je @@lostMenu
	cmp [gameState], STATE_WON
	jne @@draw
	call updateWinMenu
	jmp @@draw 
	@@lostMenu:
	call updateGameOverMenu

	@@draw:
	cmp [redraw], 0
	je @@noDraw
	cmp [gameState], STATE_LOST
	je @@drawGameOver
	cmp [gameState], STATE_WON
	je @@drawWin
	call draw4Bg			
	call drawGameState
	call drawScore
	jmp @@drawn
	@@drawGameOver:
	call drawGameOver
	jmp @@drawn
	@@drawWin:
	call drawWin
	@@drawn: 
	mov [redraw], 0

	@@noDraw:
	cmp [quit], 0
	je @@gameLoop

	call __keyb_uninstallKeyboardHandler
	call setVideoMode, 03h
    mov ax,4c00h 
    int 21h
ENDP main

; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
board tile BOARDWIDTHLOGIC dup(BOARDLENGTHLOGIC dup(<0, 0>))
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
ThreeBackground_file db "assets/3BG.bin", 0
FiveBackground_file db "assets/5BG.bin", 0

BigSprite DD BIGSPRITEWIDTH, BIGSPRITEHEIGHT
DB BIGDATASIZE DUP(0)
SmallSprite DD SMALLSPRITEWIDTH, SMALLSPRITEHEIGHT
DB SMALLDATASIZE DUP(0)
ThreeSprite DD THREESPRITEWIDTH, THREESPRITEHEIGHT
DB THREESPRITEDATASIZE DUP(0)
FiveSprite DD FIVESPRITEWIDTH, FIVESPRITEHEIGHT
DB FIVESPRITEDATASIZE DUP(0)

keyTable  db KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER   ; index + 1 = DIRECTION_xxx
prevState db 5 dup(0)
direction db DIRECTION_NONE
quit      db 0
gameState db STATE_PLAYING

tempRow  db 4 dup(0)
moved   db 0
redraw  db 1			; 1 so that the board is drawn at the start of the game

score      dd 0	; score value, stored as a dword to allow for large scores
scoreLabel db "SCORE", 0 ; label to display above the score value

MenuSelected db 0 ; 
txtGameOver db "GAME OVER", 0
txtFinalScore db "FINAL SCORE", 0
txtTryAgain db "TRY AGAIN", 0
txtExit db "EXIT", 0
txtControls db "ARROW UP/DOWN + ENTER", 0

hasWon          db 0                ; 1 = player already won and chose to keep playing
txtYouWin       db "YOU WIN", 0
txtYourScore    db "YOUR SCORE", 0
txtKeepPlaying  db "KEEP PLAYING", 0

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