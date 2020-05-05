.model small                
.stack 100h

.data   

;buffer db 'helloworld jok hello', 0     
buffer db 40 dup(0)
file_buffer db 40 dup (0)
buf_len equ 20 
len dw 20
cut dw 20
old_word db 'hello'  
old_word_len equ 5
new_word db 'pop' 
new_word_len equ 3 
temp dw '0' 
read_len dw 20

file_end db 0

shift dw 0

shift_pos dw 0

word_start dw 0
word_end dw 0   

dif dw 0

filename db 'C:\emu8086\vdrive\C\lab5.txt', 0
file_id dw 0

file_len dw 0 
file_len_h dw 0 

cur_pos dw 5
cur_pos_h dw 0 

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
   pop dx
   pop cx 
   pop bx
   pop ax
endm

start:
    mov ax,@data
    mov ds,ax
    mov es,ax
   
   ;string_output invitation_for_input
;    mov dx,offset word
;    mov ah,0ah
;    int 21h
;    mov al,word+1
;    mov word_len, al

    
   
    call open_file
   
     
start_file:
    call get_cur_pos     
    mov ax, cur_pos
    mov shift_pos, ax
    call read_file ;cur_pos=20
    
    
    ;call get_cur_pos
    call cut_buffer 
    call buffer_len_proc
    
    
    mov ax, len
    mov cut, ax
    
    
    call change_word  
    
    
    mov ax, cur_pos
    sub ax, read_len
    add ax, len
    mov cur_pos, ax
    
    
    push cur_pos
    sub ax, len
    mov cur_pos, ax 
   
    mov ax, old_word_len
    mov bx, new_word_len
    cmp bx, ax
    jge new_bigger
     
    mov ax, read_len 
    cmp len, ax
    je write
     
    mov ax, cut
    sub ax, len
    mov shift, ax
    call shift_left_proc
    
    jmp write
   
new_bigger: 
    mov ax, len
    sub ax, read_len  
    mov shift, ax
    call shift_right_proc   
   
write:    
    ;call get_cur_pos 
    pop cur_pos
    set_cur_pos 0, shift_pos, 0
    call write_to_file
   
    
    cmp file_end, 1
    je end_program
	jmp start_file
	
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
	
	mov read_len, ax
	add cur_pos, ax
   
	cmp ax,buf_len
	je read_file_end
	mov file_end,1
	mov len, ax
   

read_file_end:        
	pop dx
	pop cx
	pop bx
	pop ax 
   
	ret
read_file endp  
          
          
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



shift_left_proc proc
    call copy_buffers
    push cur_pos
    
    push ax
    push cx
    push bx 
    
    mov  ax, shift_pos
    push shift
    add shift, ax
    set_cur_pos 0,shift,0 
    pop shift
shift_left:

	call read_file
    
    push len
    push read_len
    
    neg read_len
    mov ax, shift
    sub read_len,ax
 
continue_shift:
	set_cur_pos 0ffffh, read_len, 1
    
    pop read_len 
    mov ax, read_len
    mov len,ax
	call write_to_file
	
	pop len  
	
	
	set_cur_pos  0,shift,1
   
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
    pop bx
    pop cx
    pop ax
    pop cur_pos
	ret
shift_left_proc endp    


shift_right_proc proc 
    call copy_buffers
    push cur_pos
	set_cur_pos 0,0,2
	push len
	push ax   
	push bx
	
	
shift_right:
	mov ax, cur_pos 
	mov bx, cur_pos
	sub bx, shift_pos
	cmp bx, len
	
	;cmp ax, len
	jge continue_loop
	mov len, bx

continue_loop:
	push len
	neg len
	set_cur_pos 0ffffh, len,1
	pop len
	call read_file

	
	push len
	
	mov ax, shift
	cmp len,ax
	jg greater
	 
	set_cur_pos 0, shift ,0

	call write_to_file
	pop len
	jmp end_shift_right
	
greater:
    push len	
	neg len 
	mov ax, shift
	add len,ax
	;-3=2-5
	
	set_cur_pos  0ffffh,len,1  
	pop len
	call write_to_file
	
	
	push len 
	mov ax, shift
	add len,ax
	neg len
	set_cur_pos 0ffffh, len, 1
	pop len
	
	
	call get_cur_pos    
	mov ax, shift_pos
	cmp cur_pos, ax
	je end_shift_right
	
	jmp shift_right

	
end_shift_right:
    call copy_buffers 
    pop bx
	pop ax	
	pop len  
	pop cur_pos
	ret
shift_right_proc endp


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




change_word proc
    push cx
    push di
    push si
    push ax
     
    mov dif, new_word_len  
    sub dif, old_word_len 
    call buffer_len_proc
   
    mov ax,len

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
    
   ; mov bx, len-1
;    sub bx,cx  
;    pop cx
;    sub cx,bx
;    mov cx,remain
    
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


cut_buffer proc
    push ax
    push cx
    push di
    
    std
    mov ax, ' '
    lea di, buffer 
    add di, len
    mov cx, len
    repne scasb
    
    xchg len,cx
    sub cx,len
zero:    
    mov buffer[di+2], 0 
    inc di
    loop zero
    
    pop di
    pop cx
    pop ax
    ret
cut_buffer endp    


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
 
end start 

