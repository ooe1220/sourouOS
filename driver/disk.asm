; read_multi_sector:
;  複数セクタの読み込み
;  BX = LBA下位16bit (LBA 0-15)
;  CX = LBA上位8bit  (LBA 16-23)
;  SI = 読み込みセクタ数
;  ES:DI = 転送先アドレス
;  現状CXの値には対応しておらず65536セクタを越えると0に戻る
;  今後対応する
;  初めはread_sectorを呼び出さず直接複数セクタを呼び出す関数を作る
;  予定であったがどうしても1セクタ以上読み込まれずこの形になった。

read_multi_sector:
    pusha              ; 全レジスタ退避

.next_sector:
    ; 現在のLBAで1セクタ読み込み
    call read_sector
    jc .error          ; エラーあれば終了

    ; 次のセクタへLBAインクリメント
    inc bl             ; LBA下位8bit++
    cmp bl, 0
    jne .skip_bh_inc
    inc bh             ; 下位16bitの上位8bit（bh）++
.skip_bh_inc:
    ; 転送先アドレスを512バイト進める
    add di, 512

    dec si
    jnz .next_sector

    popa
    clc                ; 成功フラグクリア
    ret

.error:
    mov si, disktest
    call print_string
    popa
    stc                ; エラーフラグセット
    ret



; =========================================================
; read_sector - IDE HDDから1セクタ（512バイト）読み込み
;
; 機能:
;   指定したLBAアドレスから1セクタ（512バイト）を
;   メモリ(ES:DI)へ転送する
;
; 呼び出し前の設定:
;   BX ＝ LBAアドレス 下位16ビット（LBA 0-15）
;   CX ＝ LBAアドレス 上位8ビット（LBA 16-23）
;   ES:DI ＝ 転送先メモリアドレス（512バイト以上の領域）
;
; 戻り値:
;   CF = 0 正常終了
;   CF = 1 エラー発生
;
; 補足:
;   常に512バイト固定の読み込み
; =========================================================

read_sector:
    pusha
    push ds
    push es
    
    ; 引数を保存
    mov [lba_low16_bx], bx  ; BXレジスタをスタックに保存（bl、bhを含む）
    mov [lba_high8_cx], cx  ; CXレジスタをスタックに保存（clを含む）
    
    ; ===== 1. HDDが使用可能か =====
    mov dx, 0x1F7       ; 状態レジスタポート
    mov cx, 0xFFFF      ; 最大試行回数
.wait_not_busy:
    in al, dx
    test al, 0x80       ; 最高位ビット=1かどうか(0x80 = 1000 0000)
    jz .ready           ; 1でなければ使用可能 →readyへ遷移
    dec cx              ; 試行回数を減算
    jnz .wait_not_busy  ; 使用不可の場合は待ち続ける
    jmp .error          ; 時間切れ

.ready:

    ; ===== 2. どのドライブを選択するか​​と​​LBAアドレスの上位4ビット​​を設定 =====
    mov dx, 0x1F6       ; 「ドライブ/ヘッドレジスタ」
    mov al, 0xE0        ; 本文を参照
    or al, bh           ; 
    and al, 0xEF        ; bit4=0(固定)
    out dx, al
    
    ; ===== 3. 読み込みセクタ数の設定 =====
    mov dx, 0x1F2       ; セクタ数レジスタ​​：転送する​​セクタ数​​を指定するために使用
    mov al, 1           ; 1セクタ読み込み
    out dx, al

    ; ===== 4. LBAアドレスの指定 =====
    
    ; 引数を取り出す
    mov bx, [lba_low16_bx]
    mov cx, [lba_high8_cx]
    
    mov dx, 0x1F3       ; LBA 0-7
    mov al, bl          ; bl = LBA 0-7
    out dx, al

    mov dx, 0x1F4       ; LBA 8-15
    mov al, bh          ; bh = LBA 8-15
    out dx, al

    mov dx, 0x1F5       ; LBA 16-23
    mov al, cl   
    out dx, al
    
    ; ===== 5. 読み込み命令送信 =====
    mov dx, 0x1F7
    mov al, 0x20        ; 0x20​​: セクタ読み込み　(参考　0x30​​: セクタ書き込み)
    out dx, al          ; 一般的な書き方　outb(0x1F7, 0x20) → 読み込み開始

    ; ===== 6. データ転送が可能となるのを待つ =====
    mov cx, 0xFFFF      ; 最大試行回数
.wait_data_ready:
    in al, dx
    test al, 0x80       ; 読み込み可能か
    jnz .wait_data_ready
    test al, 0x08
    jnz .data_ready
    dec cx
    jnz .wait_data_ready
    jmp .error

.data_ready:
    ; ===== 7. エラー確認 =====
    test al, 0x01       ; 状態レジスタ 0bit目=1はエラー
    jnz .error

    ; ===== 8. データ読み込み =====
    mov cx, 256         ; 512バイト(WORD単位で÷2)　IDEデータレジスタ（0x1F0）は​​16ビット（2バイト）単位​​でデータを扱う
    mov dx, 0x1F0       ; データレジスタ(読み書きに使用される)
    cld                 ; 念のため明示的にDF=0に設定し、insw実行時に​​メモリアドレス（DI）を自動増加​​（+2）させる。std（DF=1）だと、アドレスが減少（-2）
    rep insw            ; ES:DIへ読み込む　cxの回数だけinswを繰り返し、

    pop es
    pop ds
    popa
    clc                 ; 成功
    ret

.error:

    pop es
    pop ds
    popa
    stc                 ; 失败
    ret

disktest db  'disktest', 0x0D, 0x0A, 0
lba_low16_bx dw 0     ; LBA 下位16bit バッファ
lba_high8_cx dw 0     ; LBA 上位8bit バッファ(chは実質無意味)
