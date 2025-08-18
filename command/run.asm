; 入力を大文字化 or 8.3形式変換
; mov si, input_buffer
; mov di, file_name_8_3
; call convert_to_8_3_com

; SI = 入力文字列先頭
; DI = 出力バッファ（11バイト確保済み）
convert_to_8_3_com:
    push cx
    push dx

    mov cx, 8
    xor dx, dx

convert_name_loop:
    mov al, [si]
    cmp al, 0
    je fill_spaces_name

    mov [di], al
    inc di
    inc si
    inc dx
    dec cx
    jnz convert_name_loop

fill_spaces_name:
    mov cx, 8
    sub cx, dx
    jz write_ext

fill_space_loop:
    mov byte [di], ' '
    inc di
    loop fill_space_loop

write_ext:
    mov byte [di], 'C'
    mov byte [di+1], 'O'
    mov byte [di+2], 'M'

    pop dx
    pop cx
    ret


; ============================================================
; find_com_and_run:
; 入力:
;   file_name_8_3 に 8.3形式(11バイト)のファイル名を格納しておくこと
;
; 処理概要:
;   1. メモリ 0x0000:0x9000 にあるルートディレクトリ（64エントリ分）を走査
;   2. file_name_8_3 と一致するエントリを探す
;   3. 見つかれば開始クラスタ番号から1クラスタ分(8セクタ)だけCOMファイルを読み込み
;   4. 読み込んだ COM を 0x0200:0x0100 に配置して実行
;
; 出力:
;   AX = 0  ファイル見つからず
;   戻らず直接 COM 実行  見つかった場合は jmpで制御移行
;
; 前提:
;   - ルートディレクトリは 0x0000:0x9000 に読み込まれていること
;   - 1クラスタ 8セクタ構成
;   - データ領域開始LBA = 112 セクタ目
; ============================================================
find_com_and_run:
    pusha
    push ds
    push es

    xor ax, ax
    mov ds, ax
    mov si, 0xB000       ; ルートディレクトリ先頭
    mov cx, 512           ; エントリ数

search_loop:
    push cx
    push si

    mov di, file_name_8_3
    mov cx, 11
    repe cmpsb
    je .found_entry

    pop si
    add si, 32           ; 次のエントリへ
    pop cx
    loop search_loop

    ; 見つからなかった場合
    mov ax, 0
    jmp done

.found_entry:
    ; SIは次の位置なので戻す
    pop si
    pop cx
    
    ; PSP準備
    push es
    mov ax, 0x0200          ; PSPのセグメント
    mov es, ax
    mov word [es:2], cs     ; PSP:2 にカーネルのCS
    mov word [es:0], kernel_return ; PSP:0 にカーネル復帰IP
    pop es

    ; クラスタ→LBA変換（仮に1クラスタ8セクタ、データ領域先頭LBA=112）
    add si, 26
    mov ax, [ds:si]      ; 開始クラスタ取得
    
    ; call print_ax_hex ; 開始クラスタが取得出来ているかの確認用
    
    ; 開始クラスタ→開始セクタへ変換する
    mov bx, ax        ; BX = Cluster
    sub bx, 2         ; (Cluster - 2)
    mov ax, 8         ; SectorsPerCluster
    mul bx            ; DX:AX = (Cluster-2) * 8
    add ax, 112       ; DataAreaStart = 112
    adc dx, 0         ; 繰り上がり処理（念のため）
    
    ; COMファイルをメモリ上へ読みこむ(xp /512 0x2100)
    mov cx, dx    ; LBA上位16bit
    mov si, ax    ; LBA下位16bit
    mov dx, 0x0200      ; 保存先セグメント
    mov bx, 0x0100      ; 保存先オフセット  
    mov al, 8           ; 読み込むクラスタ数 = 1(1クラスタ=8バイト)
    call read_sectors

    ; COM実行
    jmp 0x0200:0x0100
            
    kernel_return:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov byte [com_status], 1   ; COM 正常終了 (DS=0の状態代入)

done:
    pop es
    pop ds
    popa
    ret

; データ領域
bpb_sec_per_cluster dw 8        ; 実際はBPBから読み込む
data_area_start dd 112          ; データ領域開始LBA
file_name_8_3 times 11 db 0

com_status db 0   ; 0=未実行/失敗, 1=成功

runtest db "TEST", 0x0D, 0x0A,0

