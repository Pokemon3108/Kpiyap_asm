.model small
.stack 100h
 
.data
 
 
blockEPB dw 0
	cmd_offset dw offset cmd, 0
	fcb1 dw 005ch, 0
	fcb2 dw 006ch, 0
 
	cmd db 10,' '
	cmd_text db 125 dup (0), '$'
 
EPBlen dw $-blockEPB
 
path db "lab7.exe",0   
delim db 10,13,'$'
number_str db 126 dup (0), '$'
realloc_error_text db "Realloc error",10,13,'$'
copy_text db "Program copy: ", '$'
cmd_error_text db "You should pass 1 argument to cmd", 10,13,'$'
start_program db "Start program. ",'$'
end_program db "End program. ",'$'
number db 0
max_len dw 5   
base dw 10
len db 0
copies db 5 dup(0), '$'
previous_copy db 5 dup (0), '$'
new_program_symbol db 1
cmd_max equ 10 
big_number_text db "Number is great than 255",10,13,'$' 
not_number_text db "Input is not a number",10,13,'$'
data_segment_size = $ - blockEPB
.code
 
string_output macro str
	push dx
	push ax
 
	mov dx,offset str
	mov ah, 09h
	int 21h     
 
	pop ax
	pop dx
endm 
 
start:	
 
	mov ax,es
	mov bx, (code_segment_size/16+1)+(data_segment_size/16+1)+256/16+256/16
 
	mov ah, 4ah
	int 21h
	jnb continue_start
	jmp realloc_error
 
continue_start:
	mov ax,@data
	mov es,ax
 
	xor cx,cx
 
	mov cl, ds:[80h]
	dec cl
 
	push cx
	mov si, 82h
	lea di, cmd_text
	rep movsb
	pop cx
 
	mov ax, @data
    mov ds, ax
 
	call parse_cmd
	
	string_output start_program
	string_output copy_text
	string_output copies
	string_output delim
	
	lea di, copies
	call strlen
	lea si, copies
	lea di, previous_copy
	mov cl,len
	xor ch,ch
	rep movsb
	
	
	lea di, number_str
	call atoi
	cmp number, 0
	jne continue_start_1
	jmp copy_output
continue_start_1:	
	dec number
 
	lea di, number_str
	call itoa
 
	lea di, copies
	call atoi
	inc number
	lea di, copies
	call itoa
	
	call create_new_cmd
 
 
	mov bx,offset blockEPB
    mov ax,ds
    mov word ptr[blockEPB+4],ax
    mov ax,cs
    mov word ptr[blockEPB+8],ax
    mov word ptr[blockEPB+12],ax
 
	mov ax, 4b00h
	lea dx, path
	lea bx, blockEPB
	int 21h

copy_output: 
	string_output end_program
	string_output copy_text
	string_output previous_copy
	string_output delim
 
	jmp exit
 
realloc_error:
	string_output realloc_error_text 
 
exit:
	mov ah,4ch
	int 21h
 

parse_cmd proc
	push cx
	push si
	push di
	push ax
 
	lea si, cmd_text
	
	dec si
skip_shifts_start:
	inc si
	cmp [si], byte ptr ' '
	je skip_shifts_start
	
 
	lea di, number_str
	call get_number	
	cmp number_str,0
	je cmd_error
	
 
	lea di, copies
	call get_number
	cmp copies, 0
	jne new_program_check
	mov copies,'0'
	jmp end_parse
	
	
new_program_check:
	mov al, new_program_symbol
	cmp [si], al
	jne cmd_error
	

end_parse:	
	pop ax
	pop di
	pop si
	pop cx
	ret 
 
cmd_error:
	string_output cmd_error_text
	jmp exit
parse_cmd endp
 
 
get_number proc
	push cx
	push di
	push bx
    
    mov bx,0
find_stop_symbol:	
	mov al, ds:[si]
	
	cmp al, 13
	je found_stop_symbol     
	cmp al,' '
	je found_stop_symbol 
	cmp al,0
	je found_stop_symbol
	
	cmp al, '0'
	jl not_number
	cmp al, '9'
	jg not_number
	
	mov [di], al
	inc si
	inc di
	inc bx  
	loop find_stop_symbol

 
found_stop_symbol:	
	mov al, 0
	mov [di], 0
	inc si
	

skip_shifts:	
	cmp ds:[si], byte ptr ' '
	jne end_get_number
	inc si
	jmp skip_shifts

not_number:
	string_output not_number_text
	jmp exit

big:
    string_output big_number_text
	jmp exit

end_get_number:	 
    pop bx
	pop di
	pop cx
	ret
get_number endp
 
 
atoi proc
	push cx
	push di
	push bx
	push ax
 
	call strlen
    
    xor ax,ax
	xor ch,ch
	mov cl, len
create_number:
   	mov al, number
   	mul base
   ;	jc big_number  
   	cmp ah,0
    jne big_number
    mov number, al
	mov al, ds:[di]
	sub al, '0'
	add number, al
	jc big_number
	inc di
 
	loop create_number
 
	pop ax
	pop bx
	pop di
	pop cx
	ret
	
big_number:
	string_output big_number_text
	jmp exit
 
atoi endp
 
 
itoa proc
	push ax
	push si 
	push bx 
	push di
 
	call zero_str
get_str:   
    xor ah,ah
	mov al, number
    mov bx, base	
	div bl     
	mov number, al
	add ah, '0'
	mov ds:[di], ah
	inc di
	cmp al, 0
	jne get_str
 
 
	pop di
	call strlen
 
	push di
	mov si,di
 
	xor ah,ah
	mov al, len
	add di, ax
	dec di
	call reverse
 
	pop di
	pop bx
	pop si
	pop ax
	ret
itoa endp
 
 
strlen proc 
    push ax
	push cx
	push di
 
 
	mov al, 0
	mov cx,max_len
	repne scasb
 
	mov bx, max_len
	sub bx, cx 
	dec bx
	mov len, bl
 
	pop di
	pop cx
	pop ax
    ret 
strlen endp
 
zero_str proc 
    push cx
    push ax
    push di
 
    mov cx, max_len
    mov al, 0   
    rep stosb 
 
    pop di
    pop ax
    pop cx
    ret
zero_str endp 
 
reverse proc
	push ax
	push si
	push di
 
reverse_m:
	mov al, byte ptr [si]
	mov ah, byte ptr [di]
	mov byte ptr [si], ah
	mov byte ptr [di], al
	inc si
	dec di
	cmp si, di
	jl reverse_m
 
	pop di
	pop si
	pop ax
	ret
reverse endp
 
 
 create_new_cmd proc
	push di
	push cx
	push si
	xor ch,ch 
 
	xor ch,ch
	lea di, cmd_text
	push max_len
	mov cl, cmd_max
	mov max_len, cx
	call zero_str
	pop max_len
 
 
	push di
	lea di, number_str
	call strlen ;len=strlen(number_str)
	pop di 
 
	mov cl, len
	lea si, number_str
	rep movsb
 
	mov [di], byte ptr ' ' 
	inc di
 
	push di
	lea di, copies
	call strlen ;len=strlen(copies)
	pop di
 
	mov cl,len
	lea si, copies
	rep movsb
	
	mov [di], byte ptr ' ' 
	inc di
	mov cl, new_program_symbol
	mov [di], cl
 
	pop si
	pop cx
	pop di
	ret
create_new_cmd endp
code_segment_size =$-start
end start