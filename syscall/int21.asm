; int 21h ハンドラ
int21_handler:
    pusha
    push ds
        
    ; DSをCOM内のCSに合わせる(そうしないとDS:SIで文字列を指せない)
    push ax
    mov ax, 0x0200
    mov ds, ax
    pop ax
    
    ; 文字列表示
    cmp ah, 9
    je printstring
    
    ; カーネルへ戻る
    cmp ah, 4Ch
    je int21_exit

    jmp unknown_function
    
; AH=09h $終端文字列表示
printstring:
    mov si, dx        ; DXが文字列のオフセット
    call print_string_dollar ; VRAMに表示する関数を呼ぶ
    
    pop ds
    popa
    iret
    
; AH=4Ch 終了処理（カーネルに戻る等）
int21_exit:
    pop ds
    popa
        
    ; PSPセグメントを一時的にDSにセット
    mov ax, 0x0200
    mov ds, ax

    ; far jump でPSPから復帰先を取得してカーネルに戻る
    jmp far [ds:0]
    

unknown_function:
    pop ds
    popa
    iret


