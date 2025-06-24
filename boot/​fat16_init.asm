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
kernel_start_cluster equ 2    ; KERNEL.BINが始まるクラスタ番号
kernel_size        equ 65536  ; 文件大小（字节）
%define cluster_count (kernel_size / bytes_per_sector) ; KERNEL.BINが何セクタを占めるか

; ------------------------------
; FAT1表LBA 64〜始まる　(DDでこの場所に置く)
; ------------------------------
fat1:
    ; 初めの2クラスタ分は実質固定
    dw 0xFFF8 ; F8はHDD、FF固定
    dw 0xFFFF ; ファイルの最後のクラスタの目印

    ; KERNEL.BINクラスタの連なり（2 → 3 → ... → EOF）
    %assign i kernel_start_cluster
        %rep cluster_count
        %if i == kernel_start_cluster + cluster_count - 1 ;最後のクラスタには目印0xFFFFを置く
            dw 0xFFFF
        %else
            dw i + 1
        %endif
        %assign i i + 1
    %endrep

    ; FAT表の剰余分を0で埋める (8セクタ×512バイト-既に書き込んだ分のバイト数)
    times sectors_per_fat * bytes_per_sector - ($ - fat1) db 0

; ------------------------------
; FAT2表（FAT表1の予備　FAT1の直後）簡略化の為に0埋め
; ------------------------------
fat2:
    ; 表1個8セクタ×512バイト/表
    times sectors_per_fat * bytes_per_sector db 0

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
    dw kernel_start_cluster   ; 開始クラスタ
    dd kernel_size            ; ファイルの大きさ（バイト）

    ; ルートディレクトリが32セクタとなるように0で埋める。
    times root_dir_entries * 32 - ($ - root_dir) db 0

