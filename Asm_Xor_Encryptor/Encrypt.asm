OPTION DOTNAME
.CODE
PUBLIC XOREncrypt
PUBLIC BytesToHex

XOREncrypt PROC
    cmp r9, 0       ; Is keySize 0?
    je Exit         ; Yes, go Exit
    cmp rdx, 0      ; Is bufSize 0?
    je Exit         ; Yes, go Exit

    xor r10, r10    ; Set key index to 0
L1:
    cmp rdx, 0      ; Any bytes in buffer?
    je Exit         ; No, go Exit
    movzx eax, byte ptr [rcx]       ; Get byte from buffer
    movzx r11d, byte ptr [r8 + r10] ; Get byte from key
    xor al, r11b                    ; XOR buffer byte with key byte
    mov byte ptr [rcx], al          ; Save result to buffer
    inc rcx         ; Next buffer byte
    dec rdx         ; Decrease buffer counter
    inc r10         ; Next key index
    cmp r10, r9     ; Key index = keySize?
    jne L2          ; No, go L2
    xor r10, r10    ; Reset key index to 0
L2:
    jmp L1          ; Repeat
Exit:
    ret             ; Return
XOREncrypt ENDP

BytesToHex PROC
    ; Parameters:
    ; rcx - buffer (pointer to byte array)
    ; rdx - bufSize (size of array)
    ; r8  - hexBuffer (pointer to hex string buffer)

    push rbx        ; Save rbx
    push rsi        ; Save rsi
    push rdi        ; Save rdi

    mov rsi, rcx    ; rsi = buffer
    mov rdi, r8     ; rdi = hexBuffer
    mov rcx, rdx    ; rcx = bufSize (loop counter)
    xor rbx, rbx    ; rbx = index in buffer

    ; Hex digits table (0-9, A-F)
    lea r9, [hexDigits] ; r9 = pointer to hex digits

convert_loop:
    cmp rcx, 0      ; Any bytes left?
    je end_convert  ; No, go end

    movzx eax, byte ptr [rsi + rbx] ; Get byte from buffer
    mov r10, rax    ; Save byte in r10

    ; First char (high nibble)
    shr al, 4       ; Get high nibble
    movzx eax, al   ; Clear high bits
    mov al, byte ptr [r9 + rax] ; Get hex char from table
    mov byte ptr [rdi], al ; Save to hexBuffer
    inc rdi         ; Next char in hexBuffer

    ; Second char (low nibble)
    mov rax, r10    ; Restore byte
    and al, 0Fh     ; Get low nibble
    movzx eax, al   ; Clear high bits
    mov al, byte ptr [r9 + rax] ; Get hex char from table
    mov byte ptr [rdi], al ; Save to hexBuffer
    inc rdi         ; Next char in hexBuffer

    inc rbx         ; Next byte in buffer
    dec rcx         ; Decrease counter
    jmp convert_loop ; Repeat

end_convert:
    mov byte ptr [rdi], 0 ; Null-terminate the string
    pop rdi         ; Restore rdi
    pop rsi         ; Restore rsi
    pop rbx         ; Restore rbx
    ret             ; Return

hexDigits DB "0123456789ABCDEF", 0 ; Hex chars table
BytesToHex ENDP
END