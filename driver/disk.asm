;---------------------------------------------------
; 任意LBAの任意セクタ数を任意メモリへ読み込む
; 入力:
;   DX = 保存先セグメント (ESに設定される)
;   BX = 保存先オフセット (DIに設定される)
;   CX:SI = LBAアドレス (32bit)
;   AL = 読み込むセクタ数 (最大128)
;---------------------------------------------------
read_sectors:
    ; 引数をメモリへ退避（レジスタを上書きする前に保存）
    mov [tmp_sectors], al  ; セクタ数
    mov [tmp_seg], dx      ; 保存先セグメント
    mov [tmp_ofs], bx      ; 保存先オフセット
    mov [tmp_lba_low], si  ; LBA下位16bit
    mov [tmp_lba_high], cx ; LBA上位16bit

    ; 必要レジスタ退避（呼び出し規約に従って保存）
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov dx, [tmp_seg]      ; ESセグメント設定用
    mov bx, [tmp_ofs]      ; DIオフセット設定用

    ; メモリ転送用設定
    mov es, dx             ; 保存先セグメントをESに設定
    mov di, bx             ; 保存先オフセットをDIに設定

    ;-----------------------------------------
    ; IDEコントローラへのLBA設定
    ;-----------------------------------------

    ; 0x1F6: ドライブ/ヘッドレジスタ
    ; bit7-4: 0xE0 (LBAモード + マスタードライブ)
    ; bit3-0: LBAアドレスのbit24-27
    mov dx, 0x1F6
    mov cx, [tmp_lba_high] ; LBA上位
    mov ah, ch             ; LBA bit24-27 (CXの上位8bit)
    and ah, 0x0F           ; 下位4bitのみ有効
    mov al, 0xE0           ; LBAモード + マスタードライブ
    or  al, ah             ; LBAアドレス上位と結合
    out dx, al

    ; 0x1F2: セクタカウントレジスタ
    mov dx, 0x1F2
    mov al, [tmp_sectors]  ; 読み込むセクタ数
    out dx, al

    ; 0x1F3: セクタ番号レジスタ (LBA bit0-7)
    mov dx, 0x1F3
    mov si, [tmp_lba_low]  ; LBA下位
    mov ax, si             ; LBA下位16bit (SI)
    out dx, al             ; bit0-7を出力

    ; 0x1F4: シリンダ低位レジスタ (LBA bit8-15)
    mov dx, 0x1F4
    shr ax, 8              ; bit8-15をALに
    out dx, al

    ; 0x1F5: シリンダ高位レジスタ (LBA bit16-23)
    mov dx, 0x1F5
    mov cx, [tmp_lba_high] ; LBA上位
    mov al, cl             ; LBA bit16-23 (CXの下位8bit)
    out dx, al

    ; 0x1F7: コマンドレジスタ
    mov dx, 0x1F7
    mov al, 0x20           ; 読み込みコマンド (READ SECTORS)
    out dx, al

    ;-----------------------------------------
    ; データ読み込み処理
    ;-----------------------------------------
    
    mov byte [already_read_sectors], 0 ;既に読みこんだセクタ数を数える

.next_sector:
    ; データ準備完了(DRQ)を待つ
.wait_drq:
    mov dx, 0x1F7
    in  al, dx
    test al, 8             ; bit3 (DRQ)が立っているか
    jz   .wait_drq         ; 準備できてなければ待機

    ; 1セクタ(512バイト=256ワード)を転送
    mov cx, 256            ; ループカウンタ
    mov dx, 0x1F0          ; データポート

.read_word:
    in  ax, dx             ; データポートから1ワード(2バイト)読み込み
    mov [es:di], ax        ; メモリに保存
    add di, 2              ; 次のワード位置へ
    loop .read_word

    ; 次のセクタへ
    inc byte [already_read_sectors]     ; 読み込んだセクタ数を増やす
    mov al, [already_read_sectors]
    cmp al, [tmp_sectors]               ; 総セクタ数と比較
    jb  .next_sector       ; 未完なら継続

    ;-----------------------------------------
    ; 終了処理
    ;-----------------------------------------
    ; レジスタ復旧（退避した逆順で）
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;-----------------------------------------
; データ領域
;-----------------------------------------
section .data
tmp_sectors   db 0    ; 読み込むセクタ数
tmp_seg       dw 0    ; 保存先セグメント
tmp_ofs       dw 0    ; 保存先オフセット
tmp_lba_low   dw 0    ; LBAアドレス下位
tmp_lba_high  dw 0    ; LBAアドレス上位
already_read_sectors db 0  ; 読み込み済みセクタカウンタ（0初期化）

