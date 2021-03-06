.model small                
.stack 100h

.data   
   
buffer db 2000 dup(0)
max equ 2000
file_buffer db 2000 dup (0)
buf_len dw 1000
len dw 1000

cur_pos dw 0
cur_pos_h dw 0

new_word db 51 dup (0)
old_word db 51 dup (0)
old_word_len dw 0
new_word_len dw 0
 
file_end db 0
shift dw 0

cmd_size db 0
cmd_text db 128 dup (0)
cmd_error_text db "You should pass 3 arguments in cmd. Try again",10,13,'$'

file_name db 50 dup (0)
file_id dw 0
file_len dw 0
file_len_h dw 0

word_start dw 0
word_end dw 0   

dif dw 0

marks db ',.!',0
marks_number dw 3

open_error db "File wasn't opened",10,13, '$' 
close_error db "File can't be closed",10,13,'$'
len_error db "Word length should be less than 50 symbols", 10,13,'$'

program_start db "Start program",10,13,'$'

.code 


string_output macro str
   mov dx,offset str
   mov ah, 09h
   int 21h       
endm 

set_cur_pos macro offset_h, offset_l, flag
   push ax
   push bx
   push cx
   push dx
      
   mov cx, offset_h                           
   mov dx, offset_l
   mov al, flag
   mov ah,42h
   mov bx,file_id
   int 21h
   
   mov cur_pos, ax
   mov cur_pos_h, dx 
   
   pop dx
   pop cx 
   pop bx
   pop ax
endm

sub_big_macro macro num
	push ax
	mov ax, num
	call sub_big
	pop ax
endm


start:
    mov ax, @data
	mov es,ax
	
	xor cx,cx
	
	mov cl, ds:[80h]
	
	dec cl
	mov cmd_size, cl
	
	mov si, 82h
	lea di, cmd_text
	rep movsb
	
	mov ds,ax
	
	call parse_cmd 
	
	string_output program_start
	
	call open_file
	call get_file_len
	
program_loop: 

    set_cur_pos 0,0,0 
    call zero_buffer
	call read_file
	call cut_buffer
	
	sub_big_macro shift
	
	call shift_left_proc
	
	call change_word
	
	set_cur_pos 0,0,2
	call buffer_len_proc
	call write_to_file 
	
	cmp file_len_h, 0
	jne program_loop
	
	mov ax, buf_len
	cmp file_len, ax
	ja program_loop
	
	mov ax, file_len
	mov buf_len, ax 
	
	
	cmp file_len, 0
	jne program_loop
	

end_program:	
	call close_file

exit:	
	mov ah,4ch
    int 21h
	
	
parse_cmd proc
	push di
	push si
	push cx
	push bx
	
	xor ch,ch
	mov cl, cmd_size
	lea si, cmd_text
	
	dec si
skip_shifts_start:
	inc si
	cmp ds:[si], byte ptr ' '
	je skip_shifts_start

	
	lea di, file_name
	call get_str_from_cmd 
	cmp file_name,0
	je cmd_error
	
	
	lea di, old_word 
	call get_str_from_cmd
	mov old_word_len, bx
	cmp old_word,0
	je cmd_error
	;jmp exit
	cmp old_word_len, 50
	jg len_word_error

	
	lea di, new_word
	call get_str_from_cmd
	mov new_word_len, bx
	cmp new_word,0
	je cmd_error
	cmp new_word_len,50
	jg len_word_error

	cmp ds:[si], 0
    jne cmd_error
end_parse:	
    pop bx
	pop cx
	pop si
	pop di
	ret
	
cmd_error:
	string_output cmd_error_text
	jmp exit
	
len_word_error:
	string_output len_error
	jmp exit
	
parse_cmd endp

get_str_from_cmd proc
	push cx
	push ax
	push di
	
	mov bx,si
	
find_stop_symbol:	
	mov al, ds:[si]
	
	cmp al, ' '
	je found_stop_symbol
	
	cmp al, 0
	je found_stop_symbol
	
	mov es:[di], al
	inc di
	inc si
	loop find_stop_symbol
	
found_stop_symbol:
	mov al,0
	mov [di],al
	inc si
	
	sub bx,si
	neg bx 
	dec bx

skip_shifts:	
	;mov al, ' '
	cmp ds:[si], byte ptr ' '
	jne end_get_str
	inc si
	jmp skip_shifts

end_get_str:	
	pop di
	pop ax
	pop cx
	ret
get_str_from_cmd endp

open_file proc   
    push dx
    push ax
    lea dx,file_name
    mov ah,3dh
    mov al,2 ;for read and write
    int 21h  
    jc error ;cf=1
    jnb get_file_id ;cf=0 
     
error:      
	string_output open_error 
	jmp exit 
   
get_file_id:      
	mov file_id,ax             
   
	pop ax
	pop dx        
	ret
open_file endp 


read_file proc 
	push ax
	push bx
	push cx
	push dx  
   
   
	mov ah,3fh
	mov bx,file_id
	mov cx,buf_len
	lea dx, buffer
	int 21h  
	
	mov len, ax
	cmp ax, buf_len
	je read_file_end
	mov file_end,1

read_file_end:        
	pop dx
	pop cx
	pop bx
	pop ax 
   
	ret
read_file endp

	
get_cur_pos proc
	push ax
	push bx
	push cx
	push dx
	
	mov al,1
	mov bx, file_id
	mov cx,0
	mov dx,0
	mov ah,42h
	int 21h
	
	mov cur_pos_h, dx
	mov cur_pos, ax
	pop dx
	pop cx
	pop bx
	pop ax
	ret
get_cur_pos endp	


close_file proc   
	push bx
	push ax
   
	mov ah,3eh
	mov bx,file_id
	int 21h 
   
	jnb end_close
	string_output close_error
end_close:	
	pop ax
	pop bx
	ret
close_file endp

write_to_file proc
	push ax
	push bx
	push cx
	push dx 
    
	mov ah,40h
	mov bx,file_id
	mov cx,len
	lea dx, buffer
	int 21h  

	pop dx
	pop cx
	pop bx
	pop ax
   
	ret
write_to_file endp


get_file_len proc
	push ax
	push bx
	set_cur_pos 0,0,2
	call get_cur_pos
	
	mov ax, cur_pos
	mov bx, cur_pos_h
	
	mov file_len, ax
	mov file_len_h, bx
	
	set_cur_pos 0,0,0
	
	pop bx
	pop ax
	ret
get_file_len endp	


cut_buffer proc
    push ax
    push cx
    push di
    
    mov ax, max
    shr ax, 1
    cmp len, ax
    jl set_shift
    
    std
    mov ax, ' '
    lea di, buffer 
    add di, len
    mov cx, len
    repne scasb
   
    
	mov shift, cx
	add shift, 2
	
    xchg len,cx
    sub cx,len
zero:    
    mov buffer[di+2], 0 
    inc di
    loop zero 
    jmp end_cut

set_shift:    
    mov ax, len
    mov shift, ax
	
end_cut:	
    pop di
    pop cx
    pop ax
    ret
cut_buffer endp 


change_word proc
    push cx
    push di
    push si
    push ax
    
	
    mov ax, new_word_len  
    sub ax, old_word_len 
	mov dif,ax
    call buffer_len_proc
   
    mov ax,len
    mov word_end, 0
start_cycle: 
    
    cld 
    xor ax,ax 
    mov cx, len
    mov al, old_word
    lea di, buffer
    add di, word_end
    lea si, old_word
    inc si
    repne scasb
    jcxz end_change_met
    jmp continue_check
	
end_change_met:
	jmp end_change_word

continue_check:     
    mov word_start,di 
    dec word_start
    mov word_end, di
    cmp word_start, 0
    je continue_search
    
    cmp buffer[di-2],' '
    je continue_search
	
	cmp buffer[di-2],9
    je continue_search
	
	cmp buffer[di-2],10
    je continue_search
	
	cmp buffer[di-2],13
    jne start_cycle
    
continue_search:     
    mov cx, old_word_len
    dec cx 
    repe cmpsb
    jz was_found 
    jmp start_cycle
    
was_found:
    mov word_end, di	
	
	cmp buffer[di], ' '
    je change
    
    cmp buffer[di],13
    je change
    
	cmp buffer[di], 9
	je change
	
	cmp buffer[di],10
	je change
	
	lea si, marks
	mov cx, marks_number
check_marks:
	mov al, ds:[si]
	cmp buffer[di], al
	je change
	inc si
	loop check_marks
	jnz continue_cmp
	jmp start_cycle
	
continue_cmp:	
    cmp buffer[di],0
    je change
	jmp start_cycle

change:	
    call buffer_len_proc
	call reverse 
	
	mov si, len
	sub si, old_word_len
	mov cx, old_word_len
zero_end_buffer:   
    mov buffer[si],0
    inc si
    loop zero_end_buffer	
	
	mov si, len
	sub si, old_word_len
	
	mov di, new_word_len
	dec di
	
	mov cx, new_word_len  
change_word_cycle:   
    mov al, new_word[di]	
    mov buffer[si], al	
	inc si
	dec di
	loop change_word_cycle   
	
	
	mov ax, dif 
	add len, ax
	call reverse
	

    mov ax, word_end
	add ax, dif  
    mov word_start, ax
    mov word_end, ax
	
	mov ax,len
	cmp word_end, ax
	je end_change_word

	jmp start_cycle

end_change_word:
   	
	pop ax
	pop si
	pop di
	pop cx 
	
	ret
change_word endp


reverse proc
    push si
	push di
	mov si,word_start
	mov di, len  
	dec di
cycle:
	cmp si, di ;i,j
	jge end_reverse
  
	mov ah,buffer[si]
	mov al,buffer[di]
	mov buffer[si],al
	mov buffer[di],ah
	inc si
	dec di
	jmp cycle  
   
end_reverse:
	pop di
	pop si    
	ret
reverse endp


shift_left_proc proc
    call copy_buffers
    
    push si
    push ax
    push cx
    push bx
    
    set_cur_pos 0,shift,0 
    
shift_left:
    push len
	call read_file
   
   
    mov si, shift
	add si, len
	neg si
	set_cur_pos 0ffffh, si, 1
    
	call write_to_file
	
	pop len
	set_cur_pos  0,len,1
   
	cmp file_end ,1
	jne shift_left
   
	;обрезка файла  
	push shift
	neg shift
	mov ah,40h
	mov bx, file_id
	mov cx,0
	set_cur_pos 0ffffh,shift,2  
	pop shift
	int 21h
	mov file_end, 0
    
    call copy_buffers 
    pop si
    pop bx
    pop cx
    pop ax
   
	ret
shift_left_proc endp 


buffer_len_proc proc 
    push ax
    push di   
    
    mov di,-1
len_cycle:   
    inc di
    cmp buffer[di] ,0
    jne len_cycle
    
    sub di, offset buffer
    mov len,di 
    
    pop di
    pop ax    
    ret
buffer_len_proc endp


copy_buffers proc 
    push cx
    push si
    push di
    
    mov cx,buf_len
    shl cx, 1
    xor si,si
    xor di,di
copy:     
    mov al, file_buffer[di]
    mov ah, buffer[si]
    mov file_buffer[di], ah
    mov buffer[si], al
    inc di
    inc si
    loop copy     
    
    pop di
    pop si
    pop cx
    ret
copy_buffers  endp 


zero_buffer proc 
    push cx
	push ax
	push di
    
	mov al, 0
	mov cx, max
	lea di,  buffer
	rep stosb
    
    pop di
	pop ax
    pop cx
    ret
zero_buffer endp    


sub_big proc
	cmp file_len, ax
	jb len_smaller
	sub file_len,ax
	jmp end_sub
	
len_smaller:
	cmp file_len_h, 0
	jne file_len_h_greater
	mov file_len,0
	jmp end_sub
	
file_len_h_greater:
	dec file_len_h
	
	sub ax, file_len
	mov file_len, 0ffffh
	sub file_len, ax
	inc file_len
	
end_sub:	
	ret
sub_big endp

end start	