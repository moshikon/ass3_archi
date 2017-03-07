global printer
        extern resume,WorldWidth,WorldLength,state,printf, CORS

section .rodata
    print_odd:      db      "%c ", 0, 0
    print_even:     db      " %c", 0, 0
    print_line:     db      "", 10, 0
    print_test:     db      "%c", 10, 0

section .data
    counter: dd 0
    counter_width: dd 0
    counter_length: dd 0

section .text
printer:
    mov esi,0
    odd:

        mov dword ebx,[counter_width]
        mov dword ecx, [WorldLength]
        cmp ebx,ecx
        je finish_print
        push    dword [state+esi]
        push    dword print_odd
        call    printf
        add     ESP, 8
        add esi,4
        inc dword [counter_length]
        mov dword ebx,[counter_length]
        mov dword ecx, [WorldWidth]
        cmp ebx,ecx
        jne odd
        push    dword print_line
        call    printf
        add ESP, 4
        mov dword [counter_length],0
        inc dword [counter_width] 
even:
        mov dword ebx,[counter_width]
        mov dword ecx, [WorldLength]
        cmp ebx,ecx
        je finish_print
        push    dword [state+esi]
        push    dword print_even
        call    printf
        add     ESP, 8
        add esi,4
        inc dword [counter_length]   
        mov dword ebx,[counter_length]
        mov dword ecx, [WorldWidth]
        cmp ebx,ecx
        jne even
        push    dword print_line
        call    printf
        add ESP, 4
        mov dword [counter_length],0
        inc dword [counter_width] 
        jmp odd 

finish_print:
        mov ebx, [CORS]
        call resume             ; resume scheduler
        mov dword [counter],0
        mov dword [counter_length],0
        mov dword [counter_width], 0
        jmp printer