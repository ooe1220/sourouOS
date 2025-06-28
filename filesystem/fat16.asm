; FAT表及びルートディレクトリを0x0000:9000へ読み込む
; 8 (FAT1) + 8 (FAT2) + 32 (ルートディレクトリ) = 48セクタ
; 64セクタ目から48セクタを読み込む(パーティション第63セクタ目〜、63セクタ目にはVBRを設置)

; メモリ上の分布
; FAT1は64セクタ目から8セクタ分、メモリの 0x0000:0x9000 に読み込む
; FAT2はその次の8セクタ分、つまり72〜79セクタ目、メモリの 0x0000:0xA000 に読み込む
; ルートディレクトリは80セクタ目から32セクタ分、メモリの 0x0000:0xB000 に読み込む

; 番地計算方法
; セクタサイズは512バイト（0x200）
; FAT1のサイズ：8セクタ × 512 = 4096 = 0x1000バイト
; FAT2の開始アドレスは FAT1の終了アドレス + 0x1000 → 0x9000 + 0x1000 = 0xA000
; ルートディレクトリ開始アドレスは FAT2の終了アドレス + 0x1000 → 0xA000 + 0x1000 = 0xB000

read_fat:
    pusha
    push es
    
    mov bl, 0x40           ; LBA 0-7 64セクタ目〜
    mov bh, 0x00           ; LBA 8-15
    mov cl, 0x00           ; LBA 16-23
    mov si, 48              ; 読み込みセクタ数 48
    
    xor ax, ax
    mov es, ax
    mov di, 0x9000         ; 転送先 0x0000:9000
    
    call read_multi_sector
    
    mov si, msg_fat_loaded
    call print_string
    
    pop es
    popa
    
    ret
    
msg_fat_loaded db '[Kernel] FAT info loaded at 0x0000:0x9000', 0x0D, 0x0A, 0

