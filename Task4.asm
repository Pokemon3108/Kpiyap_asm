.model small 
.stack 100h
.data
game_over db "GAME OVER", '$'
yellow equ 14
green equ 10
red equ 4
white equ 15
rand db 179
left_border db 40
right_border db 120
shift_border_to_left dw 0
number_of_border_shifts db 5
car_current_position dw 3760
difference_time db 5
time db 0
left db 1
right db 0
random_counter db 15
left_or_right db 0
.code

start:
	;получить доступ к видеопамяти
	push 0b800h
	pop es
	
	mov ax,@data
	mov ds,ax
	
	;установка видеорежима
	mov ax,0003h
	int 10h


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
	
	mov cx,2
	delay_cycle:
	call delay
	loop delay_cycle
	mov es:[bx+160],0
	mov es:[bx+161],0
	
	jmp scroll_cycle
	
		
	mov ah,4ch
    int 21h 	


draw_car proc

	mov al,green
	mov bx, car_current_position
	mov es:[bx],65
	mov es:[bx+1],al
	
	mov bx,car_current_position
	sub bx,160
    
	mov al,219
	cmp es:[bx],al
	je end_game
	ret
	
end_game:
	call delay
	call game_over_proc
		
	mov ah,4ch
    int 21h 
	
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
	
	mov cx,2
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
	
	xchg ah,al
	mov ah,0
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
    
	push cx
	mov al,dl
	mov dl,45
	mul dl
	add al,21
	mov dl,right_border
	div dl
	;остаток в ah
	
	
	
	cmp ah,left_border
	jg not_shift_obstacle
	add ah,left_border

not_shift_obstacle:	
	test ah,1
	jpe two
not_two:
	
	inc ah
	;shl ah,1
two:	
	mov dl,ah
	mov rand,ah
	pop cx
	
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
	;call create_obstacles
	;pop dx
	
	;call get_key
	
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
	mov ah, 0ch 
    int 21h 
	
ret
get_key endp	

game_over_proc proc
	mov ax,0003h
	int 10h
	
	mov bx,1990
	mov cx,9
	mov si,0

cycle_game_over:	
	
	mov al,game_over[si]
	mov es:[bx], al
	mov al,red
	mov es:[bx+1],al
	inc si
	add bx,2
	loop cycle_game_over

	ret 
game_over_proc endp

draw_border proc
	push bx 
	xor bh,bh
	mov bl,left_border
	mov es:[bx],219
	mov es:[bx+1],white
	mov bl,right_border
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
	; dec random_counter
	; cmp random_counter,0
	; je go_straight
	; jmp end_shift_proc
	
	
try_left:
	cmp left,1
	jne try_right
	cmp left_border,0
	jl end_shift_proc
	sub left_border,2
	sub right_border,2
	dec number_of_border_shifts
	mov left_or_right,1
	jmp end_shift_proc


try_right:
	cmp right,1
	jne end_shift_proc
	cmp right_border,158
	jg end_shift_proc
	add left_border,2
	add right_border,2
	dec number_of_border_shifts
	mov left_or_right,0
	jmp end_shift_proc

	
set_shift:
	;mov random_counter,15
	mov ah,0
	int 1ah
	xor dh,dh
	shr dl,5
	mov number_of_border_shifts,dl	
	cmp left_or_right,1
	jne set_left

	
	mov right,1
	jmp end_shift_proc
	
set_left:
	mov left,1


end_of_screen:
	mov number_of_border_shifts,0
	
end_shift_proc:	
	pop ax
	pop dx
	pop cx

ret
shift_border endp



end start
	
  
  
