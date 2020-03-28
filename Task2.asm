.model small
.stack 100h
.data

str db 200, 200 dup('$') 

len db 0
invitation_for_input db "Input your string",13 
delim db 10,13,'$'

.code 

start: 
    mov ax,@data
    mov ds,ax 
    mov es,ax
    
    ;string output
    mov dx,offset invitation_for_input
    mov ah, 09h
    int 21h
    
    mov dx,offset str
    mov ah,0ah
    int 21h
    
    mov al,str+1
    mov len,al
    
    xor dx,dx
    mov dl,len
    call sort
   
    mov dx,offset delim
    mov ah,09h
    int 21h
     
     
     
find_not_shifts: 
    mov cl,len
    cld
    lea di,str   
    add di,2
    mov al,20h
    repe scasb
    dec di
      
    ;mov si,2 
    mov cl,len
move_shifts:
    mov si,di
    lea di,str+2
    rep movsb  
     
    xor ax,ax
    mov al,len
    mov di,ax
    mov str[di+2],'$'
    
    mov dx,offset str+2 
    mov ah,09h  
    int 21h
     
    mov ax, 4c00h
    int 21h 

     
sort proc
    xor cx,cx
    mov si,2
    mov bx,0
    mov cx,dx
    
	words_number: 
		inc si
		cmp str[si],20h 
		je increment_word_num          
		loop words_number
    
		increment_word_num: 
		inc bx
		cmp cx,0
		jne words_number
    
;word_number was counted (is in bx)    
    
    mov cx,bx
    add dx,2
	sorting_cycle:
        
		mov si,dx
		mov di,dx
		mov bx,dx
    
		internal_cycle:    
			cmp si,2  ;while (start>0)
			jle again
    
			push cx
    
			std 
			mov cx,di
			lea di,str
			add di,si
			mov al,20h
			repne scasb ;find ' '  (mid)
			pop cx
			;jne continue 
    
		found_mid:
			inc di ;start=mid-1 
     
		;continue:
			mov si,di
	
	          
		find_start:
			dec si
			cmp si,2
			jl move_words
			cmp str[si],20h
			je move_words
			jmp find_start
    
    
		move_words:
   ; dec si ;move left cause si wasn not decremented
			push si
			push di
			push ax 	
			call leftIsBigger 
			pop ax
			pop di
			pop si
			jle after_move ;right word is bigger than left
	
		shift_words: ;if (RightIsBigger(start, mid,str))
			push si
			push di
    
			inc si
			mov di,bx ;di=bx for reverse proc
			dec di
			call reverse
			pop di
			pop si
    
			mov ax,di
			mov di,si
			add di,bx
			sub di,ax ;mid = start + end - mid;
    
			push si
			push di
    
			;si-start, di-mid
			inc si ;start
			dec di
			call reverse
			pop di
			pop si
    
			;si-mid, di-end
			push si
			push di
    
			inc di
			mov si,di
			mov di,bx
			dec di
			call reverse
			pop di
			pop si
    
		after_move:
			mov bx,di
			jmp internal_cycle
	again:    
    loop sorting_cycle	    
     
    ret
sort endp 

leftIsBigger proc ;check what word is bigger
    push dx
    push bx
start_proc:
    inc si 
    inc di
    
    mov dl,str[si]
    mov bl,str[di]
     
    
    cmp dl,91
    jnl not_less      
    cmp dl,64
    jng not_less
    add dl,32

not_less:    
    cmp bl, 91
    jnl another
    cmp bl, 64
    jng another
    add bl,32   
another:

    cmp dx, bx
    jne stop_cycle  
    cmp dx,20h
    je stop_cycle
    cmp bx,20h
    je stop_cycle
    cmp bx,'$'
    je stop_cycle 
    
less:
         

    
    jmp start_proc
    
stop_cycle:
    
    cmp dx,bx ;compare str[start] and str[mid]
    pop bx
    pop dx
    
    ret 
    
leftIsBigger endp         

reverse proc
cycle:
   cmp si,di ;i,j
   jge return
   
   mov ah,str[si]
   mov al,str[di]
   mov str[si],al
   mov str[di],ah
   inc si
   dec di
   jmp cycle  
    
return:    
   ret
reverse endp 




end start