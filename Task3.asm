.model small
.stack 100h
.data

buffer db 16,17 dup ('$') 
invitation_for_input_1 db "Input 1st number: ", '$'
invitation_for_input_2 db 10,13,"Input 2nd number: $" 
error db 10,13,"Error! Not digits or overflow", 10, 13, '$'    
overflow db 10,13,"Overflow. Input number again$"
and_oper db 10,13,"AND ", '$'
or_oper db 10,13,"OR ", '$'
xor_oper db 10,13,"XOR ", '$' 
not_oper db 10,13,"NOT ", '$'
delim db 10,13,'$'
base dw 10


.code

string_output macro delim
    mov dx,offset delim
    mov ah, 09h
    int 21h   
endm

start: 
    mov ax, @data
    mov ds,ax 
    mov es,ax
     
    string_output invitation_for_input_1 
    call input_number
    
    mov bx, ax
    string_output invitation_for_input_2
  
    call zero_buffer
        
    push bx
    call input_number 
    pop bx ;1st number in bx, 2nd in ax
    
    push ax   
    string_output delim
    pop ax 
     
    ;call zero_buffer 
    
    push ax
    mov ax,bx 
    call bin_sys 
    string_output buffer
    pop ax
    
    push ax
    call bin_sys
    string_output delim
    string_output buffer
    
    string_output and_oper
    pop ax
    push ax
    and ax,bx
    call bin_sys
    string_output delim
    string_output buffer
 
    
    string_output or_oper
    pop ax
    push ax
    or ax,bx
    call bin_sys
    string_output delim
    string_output buffer 
    
    
    string_output xor_oper
    pop ax 
    push ax
    xor ax,bx 
    call bin_sys
    string_output delim
    string_output buffer
     
      
    string_output not_oper
    pop ax
    not ax
    call bin_sys
    string_output delim
    string_output buffer
      
    mov ah,4ch
    int 21h          
               
zero_buffer proc 
    push ax
    lea di, buffer+1
    cld
    mov al,'$'
    mov cx, 15
    rep stosb 
    pop ax
    ret
zero_buffer endp	

input_number proc  
input: 
    mov dx, offset buffer
    mov ah,0ah
    int 21h 
    
    mov si,1
    
    mov di,2
    xor ax,ax ;number in ax 
    xor cx,cx
    xor bx,bx
    mov cl, buffer+1  

go_through_str:    
    cmp cl, buffer+1
    jne get_digit
     

negative_number:
    mov bl, buffer+2
    cmp bl, '-'
    jne get_digit
    mov si,-1
    inc di
    loop go_through_str
    
get_digit: 
    mov bl, buffer[di]
    inc di
    sub bl, '0'
    jl error_input
    add bl,'0'
    sub bl,'9' 
    jg error_input
    add bl,'9'
    
    
create_number:
    mul base
    cmp ax, 8000h
    ja error_input  
     
    sub bx,'0'
    add ax, bx
    ;jo error_input
    cmp ax, 8000h
    ja error_input
    loop go_through_str
    mul si
    cmp si, 1
    je check_positive
    ret    
     

check_positive: 
    or ax,ax
    js error_input
    ret
       
error_input: 
    string_output error
    jmp start             
    ret
input_number endp     


bin_sys proc
    mov cx,16
    mov si,0
    
cycle:    
    xor dl,dl
    shl ax, 1 
    rcl dl,1
    add dl,'0'
    mov buffer[si],dl
    inc si
    loop cycle   
    ret
bin_sys endp	
    
end start    
