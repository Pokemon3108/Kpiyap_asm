.model small                
.stack 100h

.data   

;buffer db 'helloworld jok hello', 0     
buffer db 500 dup(0)
max equ 500
file_buffer db 500 dup (0)
buf_len dw 250
len dw 250

cur_pos dw 0
cur_pos_h dw 0
read_len dw 0
left_border dw 0
left_border_h dw 0

old_word db 'amet'  
old_word_len equ 4
new_word db 'pop' 
new_word_len equ 3
 


file_end db 0

shift dw 0

shift_pos dw 0

word_start dw 0
word_end dw 0   

dif dw 0

filename db 'lab5.txt', 0
file_id dw 0

file_len dw 0

pos_read dw 0
row db 0

;пока не нужно
invitation_for_input db "Input word",10,13, '$'
open_error db "File wasn't opened",10,13, '$' 

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

sub_big macro num
	mov cx, num
sub_loop:
	dec file_len
	loop sub_loop
endm

add_big macro num
	mov cx, num
add_loop:
	inc file_len
	loop add_loop
endm

start:
    mov ax,@data
    mov ds,ax
    mov es,ax
	
	
	call open_file
	call get_file_len

;mov cx,2	
program_loop: 
;push cx
    set_cur_pos 0,0,0 
    call zero_buffer
	call read_file
	call cut_buffer
	mov ax, shift
	;sub_big shift
	sub file_len, ax
	call shift_left_proc
	
	call change_word
	;set_cur_pos 0,shift,0
	
	
	
	
	;cmp cx, 1
	;je end_program
	
	
	set_cur_pos 0,0,2
	call buffer_len_proc
	
	
	
	call write_to_file 
	
	
	
	mov ax, buf_len
	cmp file_len, ax
	jg program_loop
	
	mov ax, file_len
	mov buf_len, ax 
	
	cmp file_len, 0
	jg program_loop
	;pop cx
	;loop program_loop

end_program:	
	call close_file
	
	mov ah,4ch
    int 21h
	


open_file proc   
    push dx
    push ax
    lea dx,filename
    mov ah,3dh
    mov al,2 ;for read and write
    int 21h  
    jc error ;cf=1
    jnb get_file_id ;cf=0 
     
error:      
	string_output open_error 
	jmp return 
   
get_file_id:      
	mov file_id,ax             
   
return:
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
                   
                   
    add cur_pos, ax

	pop dx
	pop cx
	pop bx
	pop ax
   
	ret
write_to_file endp


get_file_len proc
	push ax
	set_cur_pos 0,0,2
	call get_cur_pos
	
	;mov ax, cur_pos_h
	;mov file_len, ax
	;shl file_len, 16
	mov ax, cur_pos
	;add_big ax
	add file_len, ax
	
	set_cur_pos 0,0,0
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
     
    mov dif, new_word_len  
    sub dif, old_word_len 
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
    jne start_cycle
    
    ;push cx 
continue_search:     
    mov cx, old_word_len-1
    repe cmpsb
    jz was_found 
    
    
    jmp start_cycle
    
    
was_found:
    mov word_end, di	
	
	cmp buffer[di], ' '
    je change
    
    cmp buffer[di],13
    je change
    
    cmp buffer[di],0
    jne start_cycle

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


; shift_left_proc proc 
    ; call copy_buffers
	; push si
	; set_cur_pos 0, shift, 0
	
; shift_left:	
	; call read_file
	
	; mov si, len
	; add si, shift
	; neg si
	; set_cur_pos 0ffffh, si, 1
	; call write_to_file
	
	; set_cur_pos 0, shift, 1
	; cmp file_end, 1
	; jne shift_left
	
	; mov si, shift
	; neg si
	; set_cur_pos 0ffffh,si,2  
	; xor ax, ax
	; mov ah,40h
	; mov bx, file_id
	; mov cx,0
	; int 21h
	
	; call copy_buffers
	; pop si
	; ret
; shift_left_proc endp

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
    push si
    mov cx, max
    xor si, si  
    
zero_loop:
    mov buffer[si], 0
    inc si
    loop zero_loop
    
   
    pop si  
    pop cx
    ret
zero_buffer endp    

end start	