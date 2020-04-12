.model small 
.386
.stack 100h

.data

game_over db "GAME OVER", '$'
start_game db "CHOOSE LEVEL",'$'
level_1 db "1-EASY",'$'
level_2 db "2-MIDDLE",'$'
level_3 db "3-HARD",'$'
level_4 db "4-QUIT",'$'
level db 0
yellow equ 14
green equ 10
red equ 4
white equ 15
rand db 179
left_border dw 40
right_border dw 120
shift_border_to_left dw 0
number_of_border_shifts db 5
car_current_position dw 3760
left db 1
right db 0
left_or_right db 0
seed dw 0
seed2 dw 0

.code

output_string macro string, len, row, column, color

	push es
	push ax
	push bx
	push cx
	push dx
	push bp

	mov ax, @data
	mov es, ax
	mov bh,0
	mov bp, offset string
	mov ah, 13h
	mov al, 00h
	mov cx, len
	mov bl, color
	mov dh, row
	mov dl, column
	int 10h

	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
endm

set_cursor macro row,column,page_number
	mov dh,row	
	mov dl,column
	mov bh,page_number
	
endm

start:
	;получить доступ к видеопамяти
	push 0b800h
	pop es
	
	mov ax,@data
	mov ds,ax
	
	;mov ah, 0ch 
    ;int 21h 
	call clear_keyboard_buffer
	
	;установка видеорежима
	mov ax,0003h
	int 10h
	output_string start_game,12,6,34,green
	output_string level_1,6,12,37,green
	output_string level_2,8,14,36,green
	output_string level_3,6,16,37,green
	output_string level_4,6,18,37,green
	;set_cursor 20,40,0
	call choose_level

	mov cx,25
pre_game_borders:
	
	call scroll
	call draw_border
	
	loop pre_game_borders
	
	
scroll_cycle:

	call scroll
	call create_obstacles
	call draw_border
	call get_key
	call draw_car
	call shift_border
	
	xor ch,ch
	mov cl,4
	sub cl,level
	;mov cl, 4-level
	delay_cycle:
	call delay
	loop delay_cycle
	mov bx,car_current_position
	mov es:[bx],0
	mov es:[bx+1],0
	
	jmp scroll_cycle
	
		
	mov ah,4ch
    int 21h 	


game_start proc
	mov ax,0003h
	int 10h
	
	mov bx,2310
	mov cx,12
	mov si,0

cycle_game_start:	
	
	mov al,start_game[si]
	mov es:[bx], al
	mov al,red
	mov es:[bx+1],al
	inc si
	add bx,2
	loop cycle_game_start

	
ret
game_start endp

draw_car proc
	;push ax
	;push bx
	mov al,green
	mov bx, car_current_position
	mov es:[bx],65
	mov es:[bx+1],al
	
	; xor dx,dx
	; mov bx,160
	; div bx
	; cmp dx,left_border
	; jb end_game
	; cmp dx,right_border
	; ja end_game
	
	mov bx,car_current_position
	sub bx,160
    
	mov al,219
	cmp es:[bx],al
	je end_game
	
	mov bx,car_current_position
	cmp es:[bx+2],al
	je end_game
	cmp es:[bx-2],al
	je end_game
	;pop bx
	;pop ax
	ret
	
end_game:
	
	
	mov ax,0003h
	int 10h
	output_string game_over,9,10,35,red
	output_string level_1,6,12,37,green
	output_string level_2,8,14,36,green
	output_string level_3,6,16,37,green
	output_string level_4,6,18,37,green
	call delay
	;set_cursor 20,40,0
	call choose_level
	mov left_border,40
	mov right_border,120
	mov car_current_position,3760
	;pop bx
	;pop ax
	mov cx,25
	jmp pre_game_borders
	ret
	
draw_car endp

delay proc
	push cx
	push bx
	push ax
	push dx
	mov ah,0
	int 1ah
	mov bx,dx
	
cycle:
	int 1ah
	cmp bx,dx
	je cycle
	
	pop dx
	pop ax
	pop bx
	pop cx
ret	
delay endp

create_obstacles proc
	push cx
	push bx
	push ax
	push dx
	
	;получить рандомное число в cx:dx
	mov ah,0
	int 1ah
	
	mov cx,1
draw:	
	call random
	;mov ah,80
	call draw_obstacle
	loop draw
	
	
	pop dx
	pop ax
	pop bx
	pop cx

ret
create_obstacles endp


draw_obstacle proc
	mov al,rand
	xor ah,ah
	;xchg ah,al
	;mov ah,0
	mov bx,ax
	mov al,yellow
	mov es:[bx],219
	mov es:[bx+1],al 

ret
draw_obstacle endp
	
random proc
	; push cx
	; push bx
	; mov ax,dx
    ; mov cx,8
; newbit:
    ; mov bx,ax
    ; and bx,002Dh
    ; xor bh,bl
    ; clc
    ; jpe shift
    ; stc
; shift:
    ; rcr ax,1
    ; loop newbit
 
    ; pop bx
	; pop cx
    
	; push cx
	; mov al,dl
	; mov dl,45
	; mul dl
	; add al,21
	; mov dl,right_border
	; div dl
	; ;остаток в ah
	
	
	; cmp ah,left_border
	; jg not_shift_obstacle
	; add ah,left_border

; not_shift_obstacle:	
	
	
	; test ah,1
	; jz two
; not_two:
	
	; inc ah
	
; two:	
	; mov dl,ah
	; mov rand,ah
	; pop cx
	
	
	push	cx
	push	dx
	push	di
	mov si,left_border
	mov di,right_border
 
	mov	dx, word [seed]
	or	dx, dx
	jnz	metka
	db 0fh, 31h
	mov	dx, ax
metka:	
	mov	ax, word [seed2]
	or	ax, ax
	jnz	metka1
	in	ax, 40h
metka1:		
	mul	dx
	inc	ax
	mov word [seed], dx
	mov	word [seed2], ax
 
	xor	dx, dx
	sub	di, si
	inc	di
	div	di
	mov	ax, dx
	add	ax, si
	
	test al,1
	jz two
	
not_two:
	inc al	
two:		
	mov rand,al
 
	pop	di
	pop	dx
	pop	cx
	ret
	
	; push cx
    ; ;(time+prev_rand)*17+13
    ; ;push ax
    ; push bx
    ; mov ax, 0
    ; int 1ah
    ; mov ax, dx
    ; mov ah, 0
    ; mov bx, 100
    ; xor dx, dx
    ; idiv bl
    ; mov ax, dx
    ; mov ah, 0
    ; add ax, rand
    ; mov bl, 17
    ; mul bl
    ; add ax, 13
	; test ax,1
	; jpo not_two
	; jpe two
	
; not_two:
	; inc ax

; two:	
	
    ; mov rand, ax
    ; clc
    ; pop bx
    ; ;pop ax 
    ; pop cx
    ; ret
	
   ret
random endp


scroll proc
	;push dx
	;scroll
	push cx 
	push ax 
	push dx 
	push bx
	xor bx, bx
	mov cx,0
	mov ah,7
	mov al,1
	mov dh, 24
	mov dl, 79
	int 10h
	pop bx
	pop dx 
	pop ax 
	pop cx
	
ret
scroll endp

get_key proc
	in al,60h
	cmp al,75; left
	je go_left
	cmp al,77 ;right
	jne flush
	add car_current_position,2
	jmp flush
	
	
go_left:
	sub car_current_position,2

flush:	
	;очистка буфера клавиатуры
	;mov ah, 0ch 
    ;int 21h 
	call clear_keyboard_buffer
	
ret
get_key endp	


draw_border proc
	push bx 
	;xor bh,bh
	mov bx,left_border
	mov es:[bx],219
	mov es:[bx+1],white
	mov bx,right_border
	mov es:[bx],219
	mov es:[bx+1],white
	pop bx
	ret 
draw_border endp


shift_border proc
	push cx
	push dx
	push ax
	
	cmp number_of_border_shifts,0
	jne try_left
	
	mov left,0
	mov right,0
	
	
	mov cl,80
	and cl,rand
	
	cmp cl,80
	je set_shift
	jmp end_shift_proc
	
	
try_left:
	mov cx,left_border
	shr cl,5
	and cl,1
	
	cmp left,1
	jne try_right
	cmp left_border,20
	je end_left
	sub left_border,2
	sub right_border,2
	dec number_of_border_shifts

	mov left_or_right,cl
	jmp end_shift_proc


try_right:
	cmp right,1
	jne end_shift_proc
	cmp right_border,158
	je end_right
	add left_border,2
	add right_border,2
	dec number_of_border_shifts

	mov left_or_right,cl
	jmp end_shift_proc

	
set_shift:
	mov ah,0
	int 1ah
	xor dh,dh
	shr dl,5
	mov number_of_border_shifts,dl	
	;cmp left,1
	
	cmp left_or_right,1
	jne set_left


	mov right,1
	jmp end_shift_proc
	
set_left:
	mov left,1
	mov left_or_right,0
	jmp end_shift_proc

end_left:
	mov right,1
	mov left_or_right,1
	jmp end_of_screen
	
end_right:
	mov left,1
	
end_of_screen:
	mov number_of_border_shifts,0
	
end_shift_proc:	
	pop ax
	pop dx
	pop cx

ret
shift_border endp

choose_level proc
	push ax
	
	;mov ah, 0ch 
   ; int 21h
input:  
   call clear_keyboard_buffer
   
	mov ah,0
	int 16h
	
	cmp al,'1'
	jb input
	
	cmp al,'4'
	ja input
	
	xor ah,ah
	sub al,48
	mov level,al
	 
	cmp al,4
	jne end_choose_level
	
	mov ax,0003h
	int 10h
	mov ah,4ch
	int 21h
	
end_choose_level:
	mov ax,0003h
	int 10h
	;mov ah, 0ch 
    ;int 21h
	call clear_keyboard_buffer
	pop ax
ret
choose_level endp

clear_keyboard_buffer proc 
    push ax
   mov ah, 0ch 
    int 21h
    pop ax
    ret
clear_keyboard_buffer endp

end start