.286
.model tiny
.code
org 100h

begin:
	jmp start


delay_sec dw 0
ticks dw 0
ticks_per_sec equ 182

oldInt08h dd 0
oldInt09h dd 0
oldInt72h dd 0

current_ticks dw 0
new_page db 0
saver db 1


screen dw 2000 dup (0)
symbol db 4
screen_size equ 2000

flag db 123

newInt08h proc far
	pushf
	call dword ptr cs:oldInt08h
	
	pusha
	push ds
	push es
	push cs
	pop ds
	
	
	cmp new_page, 1
	je stop_08h
	
	cmp current_ticks, 0
	jne not_zero_ticks
	
	mov ax, ticks
	mov current_ticks, ax
	
	call copy_screen
	call change_screen
	
not_zero_ticks:
	dec current_ticks

stop_08h:	
	pop es
	pop ds
	popa
	iret
	
endp newInt08h

newInt09h proc far
	pushf
	call dword ptr cs:oldInt09h
	
	pusha
	push ds
	push es
	push cs
	pop ds
	
	cmp saver, 0
	je end_key_int
	
	in al, 60h
	cmp al, 01h
	je is_escape
	
	cmp new_page,0
	je set_cur_ticks
	jmp not_escape

is_escape:	
	cli

	mov ah,25h
	mov al, 08h
	lds dx, dword ptr cs:oldInt08h
	int 21h
	
	mov ah,25h
	mov al, 09h
	lds dx, dword ptr cs:oldInt09h
	int 21h
	
	push cs
    pop ds
	sti
	
	mov saver, 0
	
	cmp new_page,0
	je set_cur_ticks
	
	
	
not_escape:
	call change_screen
	jmp end_key_int
	
	
set_cur_ticks:
	mov ax, ticks
	mov current_ticks,	ax

end_key_int:	
	pop es
	pop ds
	popa
	iret
	
endp newInt09h


copy_screen proc
	pusha
	
	push 0b800h
	pop es
	xor bx,bx
	mov cx, screen_size
save_screen:
	mov ax, es:[bx]
	mov [screen+bx], ax
	add bx,2
	loop save_screen
	
	popa
	ret
endp copy_screen
	

change_screen proc
	pusha
	push 0b800h
	pop es
	
	mov cx, screen_size
	xor bx,bx
	cmp new_page, 1
	je dos_picture
	
sleep_picture:
	mov al, symbol
	mov es:[bx], al
	mov es:[bx+1], al
	add bx, 2
	loop sleep_picture
	jmp end_change

dos_picture:
	xor di,di
	shl cx, 1
	lea si, screen
	rep movsb
	
	
end_change:	
	mov ax, ticks
	mov current_ticks,	ax
	neg new_page
	inc new_page
	popa
	ret
endp change_screen



; загрузочная часть
start:
	
	xor cx,cx
 
	mov cl, cs:[80h]
	dec cl
 
	
	mov si, 82h
	lea di, cmd_text
	rep movsb
	
 
	call parse_cmd
	call get_ticks
	
	
	
	mov ax, ticks
	mov current_ticks,ax
	
	
	mov al, 08h
	mov ah, 35h
	int 21h
	
	mov word ptr oldInt08h, bx
	mov word ptr oldInt08h +2, es
	
	
	mov al, 09h
	mov ah,35h
	int 21h
	
	mov word ptr oldInt09h, bx
	mov word ptr oldInt09h+2, es
	
	
	mov di, offset flag
	mov al, flag
	cmp al, es:[di]
	je exit
	

	cli
	
	mov ah,25h
	mov al, 08h
	mov dx, offset newInt08h
	int 21h
	
	mov ah,25h
	mov al, 09h
	mov dx, offset newInt09h
	int 21h
	
	
	sti 

	mov dx, offset start
	int 27h
	
	
exit:
	mov ah, 4ch
	int 21h
 
outp:
	string_output teststr
	jmp exit
 
string_output macro str
	push dx
	push ax
 
	mov dx,offset str
	mov ah, 09h
	int 21h     
 
	pop ax
	pop dx
endm

parse_cmd proc
	push si
	push cx
	
	lea si, cmd_text
	
	dec si
skip_shifts_start:
	inc si
	cmp [si], byte ptr ' '
	je skip_shifts_start
	
	xor ch,ch
	mov cl, cmd_len
	call get_delay_sec
	cmp delay_sec,0
	je cmd_error
	cmp byte ptr [si], 0
	jne cmd_error
	
	
	pop cx
	pop si
	ret
	
cmd_error:
	string_output cmd_error_text
	jmp exit
parse_cmd	endp 

get_delay_sec proc
	push ax
	push dx
	
	xor ah,ah
	xor dx,dx
get_number:	 
    cmp byte ptr [si], 0
	je skip_shifts
	cmp byte ptr [si], 0dh
	je skip_shifts
	cmp byte ptr [si], ' '
	je skip_shifts
	
	cmp byte ptr[si], '0'
	jl not_number
	cmp byte ptr[si], '9'
	jg not_number
	
	
	mov al, byte ptr [si]
	sub al, '0'
	inc si
	
	xchg ax, delay_sec
	mul base
	cmp dx,0
    jne big_number
	add ax, delay_sec
	jc big_number
	xchg delay_sec,ax
	jmp get_number

skip_shifts:	
	cmp byte ptr [si], ' '
	jne end_get_number
	inc si
	jmp skip_shifts

end_get_number:
	pop dx
	pop ax
	ret
	
not_number:
	string_output not_number_text
	jmp exit
	
big_number:
	string_output big_number_text
	jmp exit	

get_delay_sec endp 

get_ticks proc
	push ax
	push bx
	
	mov ax, delay_sec
	mov bx, ticks_per_sec
	mul bx
	mov bx,base
	div bx
	mov ticks, ax
	
	pop bx
	pop ax
	ret
get_ticks endp 	


cmd_error_text db "You should pass 1 argument to cmd (not zero)", 10,13,'$'
base dw 10

not_number_text db "Input is not a number",10,13,'$'
big_number_text db "Number is great than 65535",10,13,'$' 

cmd_text db 127 dup (0)
cmd_len db 0

escape db "Press esc to turn off screensaver", 10, 13, '$'
	
end begin	

