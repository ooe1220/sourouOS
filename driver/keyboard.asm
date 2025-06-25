%define MAX_INPUT 64     ; 命令の最大入力文字数
input_buffer times MAX_INPUT+1 db 0
newline db 0x0D, 0x0A,0

; キーボード入力関数
; 入力された結果はinput_bufferへ格納
read_input:
    pusha
    ;BIOS依存(INT10)では動いていたがES=DSと明記と失敗してハマった
    ;(stosb は 必ず ES:DI を使う 命令)
    push ds
    pop es
    mov di, input_buffer ;入力バッファ
    mov cx, 0            ; 文字数を数える
    
.read_char:
    ; 一文字読み込み（結果はASCIIコードでALへ格納される）
    ; mov ah, 0x00
    ; int 0x16
    call get_key
    
    ; 無効キーは無視
    cmp al, 0
    je .read_char         ; 無効キーは無視
    
    ; エンターが押された場合の処理
    cmp al, 0x0D
    je .done_input
    
    ; バックスペースが押された場合の処理(1文字削除)
    cmp al, 0x08
    je .do_delete_last_char
    
    ; 長さが超えていないか確認
    cmp cx, MAX_INPUT ; 入力文字数が上限に達していないか確認
    jae .read_char    ; 上限超えたら無視して次のキー入力へ
    
    ; 入力に問題が無い場合は入力バッファへ格納
    stosb    ; AL の文字を [ES:DI] に格納（バッファに保存）、DI++（次の位置へ）
    inc cx   ; 入力文字数＋１
    
    ; 入力された文字を画面へ表示
    ; mov ah, 0x0E
    ; int 0x10
    call putchar_direct ; 表示する文字はALに入っている
    jmp .read_char
    
.done_input:
    ; 文字列を終了（終端文字を追加）
    mov al, 0
    stosb
    
    ; 改行
    ; mov ah, 0x0E
    ; mov al, 0x0D
    ; int 0x10
    ; mov al, 0x0A
    ; int 0x10
    mov si, newline
    call print_string
    
    popa
    ret

.do_delete_last_char:
    cmp cx, 0        ; 入力バッファが空なら無視
    je .read_char
    dec di               ; バッファ位置を1文字戻す
    dec cx               ; 入力文字数カウントを減らす
    
    call delete_last_char
    jmp .read_char
    
; キーボードからの入力を受け取り対応するASCIIコードをAL経由で返す
get_key:
    in al, 0x64       ; 0x64ポート経由で入力されているかを確認
    test al, 1        ; 0ビット目　1：有り　0：無し
    jz get_key        ; 押されていなければget_keyへ戻って初めから
    
    in al, 0x60       ; 押されたキーの番号を取得

    ; キーの番号最高位が　０：押された　１：離された
    test al, 0x80
    jnz get_key       ; 離された場合は入力と見做さない
    
    ; キーの番号からASCIIコードへ変換していく
    cmp al, 0x1E      ; 'a'
    je .a
    cmp al, 0x30      ; 'b'
    je .b
    cmp al, 0x2E      ; 'c'
    je .c
    cmp al, 0x20      ; 'd'
    je .d
    cmp al, 0x12      ; 'e'
    je .e
    cmp al, 0x21      ; 'f'
    je .f
    cmp al, 0x22      ; 'g'
    je .g
    cmp al, 0x23      ; 'h'
    je .h
    cmp al, 0x17      ; 'i'
    je .i
    cmp al, 0x24      ; 'j'
    je .j
    cmp al, 0x25      ; 'k'
    je .k
    cmp al, 0x26      ; 'l'
    je .l
    cmp al, 0x32      ; 'm'
    je .m
    cmp al, 0x31      ; 'n'
    je .n
    cmp al, 0x18      ; 'o'
    je .o
    cmp al, 0x19      ; 'p'
    je .p
    cmp al, 0x10      ; 'q'
    je .q
    cmp al, 0x13      ; 'r'
    je .r
    cmp al, 0x1F      ; 's'
    je .s
    cmp al, 0x14      ; 't'
    je .t
    cmp al, 0x16      ; 'u'
    je .u
    cmp al, 0x2F      ; 'v'
    je .v
    cmp al, 0x11      ; 'w'
    je .w
    cmp al, 0x2D      ; 'x'
    je .x
    cmp al, 0x15      ; 'y'
    je .y
    cmp al, 0x2C      ; 'z'
    je .z
    cmp al, 0x1C      ; Enter
    je .enter
    cmp al, 0x0E      ; バックスペース
    je .backspace
    
    xor al, al        ; 上記以外のキーは無効（0を返す）
    ret
    
.a:
    mov al, 'a'
    ret
.b:
    mov al, 'b'
    ret
.c:
    mov al, 'c'
    ret
.d:
    mov al, 'd'
    ret
.e:
    mov al, 'e'
    ret
.f:
    mov al, 'f'
    ret
.g:
    mov al, 'g'
    ret
.h:
    mov al, 'h'
    ret
.i:
    mov al, 'i'
    ret
.j:
    mov al, 'j'
    ret
.k:
    mov al, 'k'
    ret
.l:
    mov al, 'l'
    ret
.m:
    mov al, 'm'
    ret
.n:
    mov al, 'n'
    ret
.o:
    mov al, 'o'
    ret
.p:
    mov al, 'p'
    ret
.q:
    mov al, 'q'
    ret
.r:
    mov al, 'r'
    ret
.s:
    mov al, 's'
    ret
.t:
    mov al, 't'
    ret
.u:
    mov al, 'u'
    ret
.v:
    mov al, 'v'
    ret
.w:
    mov al, 'w'
    ret
.x:
    mov al, 'x'
    ret
.y:
    mov al, 'y'
    ret
.z:
    mov al, 'z'
    ret
.enter:
    mov al, 0x0D      ; EnterのASCIIコード（CR）
    ret
.backspace:
    mov al, 0x08
    ret
