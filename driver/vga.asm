;------------------------------------------------------------
; VGAカーソル位置をI/Oポートから取得
; 結果は文字単位で cursor_pos に格納
; カーソル位置を取得しないとBIOS呼び出しを使って表示した文字が上にあった場合に
; 既に表示された文字の上から上書きしてしまいます
;------------------------------------------------------------
get_cursor_position:
    ; 下位バイト（カーソル位置のLSB）
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    inc dx        ; DX = 0x3D5
    in al, dx
    mov bl, al    ; BL = LSB

    ; 上位バイト（カーソル位置のMSB）
    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al
    inc dx
    in al, dx
    mov bh, al    ; BH = MSB

    ; BX = カーソル位置（文字単位）
    mov [cursor_pos], bx
    ret
    
;------------------------------------------------------------
; ハードウェアカーソルを更新（VGAポートに書き込み）
; 入力：BX = 新しいカーソル位置（文字単位）
;------------------------------------------------------------
update_hardware_cursor:
    push ax
    push dx

    ; 下位バイト（0x0F）を設定
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    inc dx              ; DX = 0x3D5
    mov al, bl          ; 下位バイト（BXのLSB）
    out dx, al

    ; 上位バイト（0x0E）を設定
    dec dx              ; DX = 0x3D4
    mov al, 0x0E
    out dx, al
    inc dx              ; DX = 0x3D5
    mov al, bh          ; 上位バイト（BXのMSB）
    out dx, al

    pop dx
    pop ax
    ret

;------------------------------------------------------------
; VRAMへ文字列表示（改行対応、BIOSなし）
;------------------------------------------------------------
print_string:
    pusha
    push si
    
    ; カーソル位置を取得（BIOSなし）
    call get_cursor_position
    
    ; VRAMのセグメント B800h をESに設定
    mov ax, 0xB800
    mov es, ax

    ; カーソル位置を読み込んで、バイト単位に変換
    mov di, [cursor_pos]
    shl di, 1

.next_char:
    lodsb ; AL ← [DS:SI]
    or al, al ; 終端文字0なら終了
    jz .done

    cmp al, 0x0D        ; CR（行頭に戻る）
    je .carriage_return
    cmp al, 0x0A        ; LF（次の行）
    je .line_feed

    ; 通常文字出力
    mov [es:di], al
    mov byte [es:di+1], 0x0A  ; 緑文字
    add di, 2
    
    ; スクロール判定（80×25×2 = 4000バイト）
    cmp di, 4000
    jl .next_char
    call scroll_screen
    ; scroll後は最下行に戻す
    ; mov di, 80 * 24 * 2
    mov di, 80 * 24
    shl di, 1
    jmp .next_char

.carriage_return:
    mov ax, di
    shr ax, 1
    xor dx, dx
    mov bx, 80
    div bx        ; AX = 行番号, DX = 列番号
    mul bx        ; 行頭へ
    shl ax, 1
    mov di, ax
    jmp .next_char

.line_feed:
    add di, 160         ; 次の行へ（80文字×2バイト）
    
    ; スクロール判定
    cmp di, 4000
    jl .next_char
    call scroll_screen
    mov di, 80 * 24 * 2
    
    jmp .next_char

.done:
    shr di, 1
    mov [cursor_pos], di
    mov bx, di            ; BXにカーソル位置（文字単位）を設定
    call update_hardware_cursor  ; ハードウェアカーソル移動
    pop si
    popa
    ret

;------------------------------------------------------------
; putchar_direct: ALの文字をVRAMに直接書き込む
;------------------------------------------------------------
putchar_direct:
    pusha
    push es

    ; カーソル位置（文字単位）をDIに
    mov di, [cursor_pos]
    shl di, 1          ; DI *= 2（バイト単位に）

    ; セグメント ES に VRAM の 0xB800 を設定(ここでAXを退避せずAL破壊してどハマりした)
    push ax 
    mov ax, 0xB800
    mov es, ax
    pop ax

    ; 文字と属性を書き込む
    mov [es:di], al          ; 文字
    mov byte [es:di+1], 0x0A ; 属性（緑）

    ; カーソルを1文字進める(これがないと入力する度前の文字を上書きする)
    add di, 2
    
    shr di, 1
    mov [cursor_pos], di

    ; カーソル表示も更新
    mov bx, di
    call update_hardware_cursor

    pop es
    popa
    ret
    
;------------------------------------------------------------
; 画面を1行スクロール（上に1行詰めて最下行を空白に）
;------------------------------------------------------------
scroll_screen:
    pusha
    push es
    push ds

    ; ES = VRAM (0xB800)
    mov ax, 0xB800
    mov es, ax
    mov ds, ax          ; コピー元にも同じセグメント使う（安全のため）

    ; SI = 行1の先頭（2行目） = 1行160バイト(80文字×2byte　文字1byte 色1bite)
    mov si, 160

    ; DI = 行0の先頭（1行目）
    mov di, 0

    ; CX = 24行 × 80文字 = 1920文字（3840バイト）
    mov cx, 80 * 24 ; (ここは25にしてはいけない)

.copy_loop:
    mov ax, [ds:si]
    mov [es:di], ax
    add si, 2
    add di, 2
    loop .copy_loop

    ; 最下行（25行目 = 行24）の初期化
    ; DI は現在 3840バイト目（最下行の開始位置）
    mov cx, 80
    mov ax, 0x0720         ; 空白 + 属性（黒背景＋灰色文字）

.clear_last_line:
    mov [es:di], ax
    add di, 2
    loop .clear_last_line

    ; カーソル位置を1行上に（80文字 = 1行）
    ; sub word [cursor_pos], 80とすると画面の1行目に戻ってしまったので減算ではなくべた書き
    mov word [cursor_pos], 80 * 24  ; 行番号24× 80列 = 1920文字
    mov bx, 80 * 24
    call update_hardware_cursor

    pop ds
    pop es
    popa
    ret

cursor_pos: dw 0
