; FAT表及びルートディレクトリを初期化する。
; DDで64セクタ目からの位置に書き込む。
; 固定でKERNEL.BINを一つ登録しておく。
; 前提：
;   - MBRは0セクタ目に設置
;   - VBRは63セクタ目に設置（パーティションはMBR中で63セクタ目から始まるように設定してある）
;   - FATの情報は64から始まる（VBRの直後に設置）

bits 16

; ------------------------------
; 設定値。VBRと矛盾しないよう注意
; ------------------------------
sectors_per_fat    equ 8      ; 一つのFAT表は8セクタを占める
bytes_per_sector   equ 512    ; 1セクタは512バイト
root_dir_entries   equ 512    ; ルートディレクトリに登録可能なファイル数
kernel_size        equ 65536  ; 文件大小（字节）
%define kernel_cluster_count (kernel_size / bytes_per_sector) ; KERNEL.BINが何セクタを占めるか

; ------------------------------
; FAT1表LBA 64〜始まる　(DDでこの場所に置く)
; ------------------------------
fat1:
    dw 0xFFF8          ; 予約クラスタ0
    dw 0xFFFF          ; 予約クラスタ1

    ; KERNEL.BIN（64KB）
    dw 0x0003      ; クラスタ2 -> 次は3
    dw 0x0004      ; クラスタ3 -> 次は4
    dw 0x0005      ; クラスタ4 -> 次は5
    dw 0x0006      ; クラスタ5 -> 次は6
    dw 0x0007      ; クラスタ6 -> 次は7
    dw 0x0008      ; クラスタ7 -> 次は8
    dw 0x0009      ; クラスタ8 -> 次は9
    dw 0x000A      ; クラスタ9 -> 次は10
    dw 0x000B      ; クラスタ10 -> 次は11
    dw 0x000C      ; クラスタ11 -> 次は12
    dw 0x000D      ; クラスタ12 -> 次は13
    dw 0x000E      ; クラスタ13 -> 次は14
    dw 0x000F      ; クラスタ14 -> 次は15
    dw 0x0010      ; クラスタ15 -> 次は16
    dw 0xFFFF      ; クラスタ16 -> EOF（ファイル終端）
    
    ; TEXT1.TXT
    dw 0xFFFF  ; TEXT1.TXT は1クラスタで終端
    
    ; TEXT2.TXT
    dw 0xFFFF

    ; FAT表の剰余分を0で埋める (8セクタ×512バイト-既に書き込んだ分のバイト数)
    times sectors_per_fat * bytes_per_sector - ($ - fat1) db 0

; ------------------------------
; FAT2表（FAT表1の予備　FAT1の直後）簡略化の為に0埋め
; ------------------------------
fat2:
    ; 表1個8セクタ×512バイト/表
    ; times sectors_per_fat * bytes_per_sector db 0
    dw 0xFFF8          ; 予約クラスタ0
    dw 0xFFFF          ; 予約クラスタ1

    ; KERNEL.BIN（64KB）
    dw 0x0003      ; クラスタ2 -> 次は3
    dw 0x0004      ; クラスタ3 -> 次は4
    dw 0x0005      ; クラスタ4 -> 次は5
    dw 0x0006      ; クラスタ5 -> 次は6
    dw 0x0007      ; クラスタ6 -> 次は7
    dw 0x0008      ; クラスタ7 -> 次は8
    dw 0x0009      ; クラスタ8 -> 次は9
    dw 0x000A      ; クラスタ9 -> 次は10
    dw 0x000B      ; クラスタ10 -> 次は11
    dw 0x000C      ; クラスタ11 -> 次は12
    dw 0x000D      ; クラスタ12 -> 次は13
    dw 0x000E      ; クラスタ13 -> 次は14
    dw 0x000F      ; クラスタ14 -> 次は15
    dw 0x0010      ; クラスタ15 -> 次は16
    dw 0xFFFF      ; クラスタ16 -> EOF（ファイル終端）
    
    ; TEXT1.TXT
    dw 0xFFFF  ; TEXT1.TXT は1クラスタで終端
    
    ; HELLO.COM
    dw 0xFFFF

    ; FAT表の剰余分を0で埋める (8セクタ×512バイト-既に書き込んだ分のバイト数)
    times sectors_per_fat * bytes_per_sector - ($ - fat2) db 0

; ------------------------------
; ルートディレクトリ（FAT2の直後，LBA 80）
; ------------------------------
root_dir:
    ; KERNEL.BINの登録（32字节）
    db 'KERNEL  BIN'          ; ファイル名（8.3形式）
    db 0x20                   ; 属性（0X20は通常のファイルを意味する）
    db 0                      ; 保留
    db 0                      ; 作成時間（ミリ秒）
    dw 0x0000                 ; 作成時間（16:00:00）
    dw 0x2100                 ; 作成日時（2023-01-01）
    dw 0x2100                 ; 最終変更日時
    dw 0                      ; EA索引
    dw 0x0000                 ; 最終変更時間
    dw 0x2100                 ; 最終変更日時
    dw 2   ; 開始クラスタ
    dd kernel_size            ; ファイルの大きさ（バイト）
    
    
    ; TEST1.TXTの登録
    db 'TEST1   TXT'          ; ファイル名（8.3形式）
    db 0x20                   ; 属性
    db 0
    db 0
    dw 0x0000
    dw 0x2100
    dw 0x2100
    dw 0
    dw 0x0000
    dw 0x2100
    dw 18    ; 開始クラスタ番号
    dd 512   ; ファイルサイズ（バイト）
    
    ; HELLO.COMの登録
    db 'HELLO   COM'
    db 0x20
    db 0
    db 0
    dw 0x0000
    dw 0x2100
    dw 0x2100
    dw 0
    dw 0x0000
    dw 0x2100
    dw 19    ; 開始クラスタ番号
    dd 512   ; ファイルサイズ

    ; ルートディレクトリが32セクタとなるように0で埋める。
    times root_dir_entries * 32 - ($ - root_dir) db 0

