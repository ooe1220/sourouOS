; いづれは外部コマンド(DIR.COM)にする予定
; ファイル一覧を表示する
; 
dir:

    ; ルートディレクトリの先頭番地
    mov si, 0xB000

    ; 全32エントリを順番に見る
    mov cx,32

.dir_loop:
    push cx           ; ループカウンタ退避
    push si           ; SI退避

    ; 最初の1バイトを確認（0なら未使用、0xE5は削除済み）
    mov al, [si]
    cmp al, 0
    je .skip_entry    ; 0ならスキップ
    cmp al, 0xE5
    je .skip_entry    ; 削除済みエントリはスキップ

    ; ファイル名（8+3）を表示
    mov bx, si
    call print_filename_83   ; ファイル名表示サブルーチン（後述）

    ; 改行
    mov si, newline
    call print_string

.skip_entry:
    pop si
    add si, 32         ; 次のエントリへ
    pop cx
    loop .dir_loop

ret


; 入力: BX = エントリ先頭番地
print_filename_83:
    pusha

    mov si, bx          ; SI = エントリ先頭

    ; 8文字のファイル名表示
    mov cx, 8
.print_name:
    mov al, [si]
    cmp al, ' '         ; スペースなら終端
    je .skip_spaces
    call putchar_direct
    
.skip_spaces:
    inc si
    loop .print_name

    ; ドットを表示
    mov al, '.'
    call putchar_direct

    ; 拡張子（3文字）
    mov cx, 3
.print_ext:
    mov al, [si]
    cmp al, ' '
    je .skip_ext_spaces
    call putchar_direct
    
.skip_ext_spaces:
    inc si
    loop .print_ext

    popa
    ret

