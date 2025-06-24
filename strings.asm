
; 小文字が含まれていれば大文字へ変換
; SI=対象文字列
to_upper:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    cmp al, 'a'
    jb .next
    cmp al, 'z'
    ja .next
    sub al, 0x20
    mov [si-1], al
.next:
    jmp .loop
.done:
    popa
    ret

; 文字列比較
; SI=文字列1, DI=文字列2
; 結果: AX = 0 if equal, 1 if not equal
strcmp:
    pusha
    push si
    push di
.compare:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .compare

.equal:
    pop di
    pop si
    popa
    mov ax, 0
    ret

.not_equal:
    pop di
    pop si
    popa
    mov ax, 1
    ret

