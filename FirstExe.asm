.model small
.stack 100h
.data
string1 db 13,'String number 1$'
string2 db 10,13,'String number 2$'
string3 db 10,13,'String number 3$'     

.code
start:
mov ax,@data
mov ds,ax  

mov dx,offset string1 
mov ah,09h
int 21h

mov dx,offset string2
int 21h

mov dx,offset string3
int 21h 

mov ah,4ch
int 21h
end start

