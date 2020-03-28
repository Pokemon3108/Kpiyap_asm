.model tiny
.code
org 100h 

start:
mov dx,offset string1 
mov ah,09h
int 21h

mov dx,offset string2
int 21h

mov dx,offset string3
int 21h 

ret 

string1 db 13,'String number 1$'
string2 db 10,13,'String number 2$'
string3 db 10,13,'String number 3$'

end start

