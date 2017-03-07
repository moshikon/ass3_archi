global scheduler
        extern resume, end_co, printf, CORS, WorldWidth, WorldLength

section .data
        counter_genertaions: dd 0
        counter_frequency: dd 0
        counter_genertaion_of_cells: dd 0
        t: dd 0
        k: dd 0
        num_of_cells:dd 0

section .text
scheduler:
        mov eax,[WorldWidth]
        mov ecx,[WorldLength]
        mul ecx
        mov [num_of_cells], eax
        mov esi, dword [esp]
        mov dword[t], esi  
        mov esi, dword [esp+4]
        mov dword[k], esi  
        mov edi,0

genertaions:
        mov dword ebx,[counter_genertaions]
        mov dword ecx, [t]
        cmp ebx,ecx
        jne next_cell
        mov ebx, [CORS+4] ; should call the printer
        call resume
        jmp end_co

next_cell:
        mov dword ebx,[counter_genertaion_of_cells]
        mov dword ecx, [num_of_cells]
        cmp ebx,ecx
        je end_generation

        mov edx , [counter_genertaion_of_cells]
        add edx, edx
        add edx, edx
        add edx, 8
        mov ebx, [CORS+edx] ; should call the cell

        call resume

        inc dword [counter_frequency]
        inc dword [counter_genertaion_of_cells]

        mov dword ebx,[counter_frequency]
        mov dword ecx, [k]
        cmp ebx,ecx
        jne next_cell

        mov dword [counter_frequency], 0
        mov ebx, [CORS+4] ; should call the printer
        call resume
        jmp next_cell

end_generation:        
        inc edi
        mov dword[counter_genertaion_of_cells],0

        cmp edi,2
        jne next_cell
        mov edi,0

        inc dword [counter_genertaions]
        jmp genertaions