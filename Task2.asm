.model small
.stack 100h
.data

max_size equ 200
;str db max_size
;str db 13, "qwe fghc vcdqwsa a iop$"
;str1 db 10, 13,"lfhldjfhld$" 
len db 0
str db max_size(?)

.code
start: 
    mov ax,@data
    mov ds,ax 
      
    mov dx, offset str,   
    mov ah, 0ah
    int 21h
    
    mov al,str+1
    mov len,al
    
    mov di,0
    mov si,2 
    xor cx,cx
    mov cl,len
    
shift: ;shift for 2 bytes left
    mov dl,str[si] 
    mov str[di],dl
    inc di
    inc si
    loop shift
    
    mov str[di],24h            
    
    ;string output
    ;mov dx,offset str
    ;mov ah, 09h
    ;int 21h
     
    mov ah,4ch
    int 21h 
    
    
    
end start


          
