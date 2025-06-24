[BITS 16]
[ORG 0x7C00]  ; VBRはアドレス0x7C00に読み込まれる

; FAT16のBPB
jmp start
nop
db "MSWIN4.1"     ; OEM名
dw 512           ; セクタあたりのバイト数
db 1             ; クラスタあたりのセクタ数
dw 1             ; 予約セクタ数
db 2             ; FATテーブルの数
dw 512           ; ルートディレクトリ項目数
dw 4096          ; 総セクタ数（16ビット）
db 0xF8          ; 媒体種別（HDD等）
dw 8             ; 各FATのセクタ数
dw 63            ; トラックあたりのセクタ数
dw 255           ; ヘッド数
dd 63            ; 隠しセクタ数
dd 0             ; 総セクタ数（32ビット、16ビットが0の場合に使用）
db 0x80          ; BIOSドライブ番号（0x80＝HDD）
db 0             ; 予約（使用されない）
db 0x29          ; 拡張ブート用
dd 0x12345678    ; ボリューム番号
db "FAT16DISK "  ; ボリュームラベル
db "FAT16   "    ; ファイルシステムの種類

start:

    mov si, msg_loaded
    call print_string

    ; kernelは128セクタ分(65536バイト=64KB)，LBA=112
    ; KERNEL.BIN は LBA 112 セクタ目から始まる
    mov ah, 0x02
    mov al, 128 ; 128セクタ読み込む
    mov ch, 0 ; 
    mov cl, 50 ; セクタ = LBA 112 -> CHS
    mov dh, 1 ; ヘッド
    mov dl, 0x80 ; HDD
    mov bx, 0x8000 ; メモリ0x8000番地へ読み込む
    int 0x13
    jc load_error ; 

    jmp 0x0000:0x8000 ; kernelの開始アドレスへ跳ぶ

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret
    
load_error:
    mov si, error_msg
    call print_string

msg_loaded db "[VBR] Execution started at 0x0000:0x7C00", 0x0D, 0x0A, 0
error_msg db "Failed to load KERNEL.BIN", 0x0D, 0x0A, 0

; 残りの領域を512バイトまで埋める
times 510-($-$$) db 0

dw 0xAA55

