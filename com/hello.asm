org 0x100          ; COMは必ず0x100から開始(セグメントは自由)

mov ah, 0009h
mov dx, msg
int 21h

mov ax, 4C00h
int 21h

msg db 'Hello, World!$'

times 512 - ($ - $$) db 0  ; 1セクタ分埋める
