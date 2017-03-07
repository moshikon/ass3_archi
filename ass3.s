 global main
         extern printf, build_structures_asm, init_co_from_asm, start_co_from_asm, WorldWidth, WorldLength

section .text
    align 16

main:
    push    EBP
    mov EBP, ESP

    call build_structures_asm

    mov eax,[WorldWidth]
    mov ecx,[WorldLength]
    mul ecx
    add eax,2
    mov edi, eax

    mov ebx,0
    init:
    cmp ebx, edi
    je finish_init
    push ebx
    call init_co_from_asm
    add esp, 4
    inc ebx
    jmp init

    finish_init:
    call start_co_from_asm

    mov esp, EBP
    pop EBP
    ret