STKSZ	equ	16*1024
global build_structures_asm, init_co_from_asm, start_co_from_asm, end_co, resume
        extern scheduler, printer, printf, malloc, free

section .rodata
	align 16
	print_1:     db      "length=%d", 10, 0
	print_2:     db      "width=%d", 10, 0
	print_3:     db      "number of generations=%d", 10, 0
	print_4:     db      "print frequency=%d", 10, 0

section .data
	align 16
global	WorldLength 
	WorldLength: dd 0
global	WorldWidth 
	WorldWidth: dd 0
	my_file: dd 0
	my_file_size: dd 0
	t: dd 0
	k: dd 0
	num_of_cells:dd 0
    ten: dd 10
    debug: dd 0
	filename: dd 0

section .bss
	align 16
	CURR:	resd	1
	SPT:	resd	1
	SPMAIN:	resd	1
global	CORS
	CORS:	resd	(60*60+2)
	BIG_STACK: resb STKSZ * (60*60+2)
	BUFFER: resb	10000
global state
	state: resd 3600
	cell_i:	resd	1
	cell_j:	resd	1
	cell_num:	resd	1

section .text
	align 16

build_structures_asm:
    push ebp
    mov  ebp, esp

    mov ecx, dword[ebp+16]
    cmp ecx,6
    jb end1

    mov edi, dword[ebp+20]

    mov eax, dword [edi+4]
    mov bl, byte[eax]
    cmp bl, 45
    jne not_debug
    mov bl, byte[eax+1]
    cmp bl, 100
    jne not_debug
    mov bl, byte[eax+2]
    cmp bl, 0
    jne not_debug
    mov dword[debug],1

	mov eax, dword [edi+8]
	mov [filename], eax       
	mov eax, dword [edi+12]
	push eax
	call atoi
	add esp, 4

	mov [WorldLength], eax
	mov eax, dword [edi+16]
	push eax
	call atoi
	add esp, 4

	mov [WorldWidth], eax
	mov eax, dword [edi+20] 
	push eax
	call atoi
	add esp, 4

	mov [t], eax
	mov eax, dword [edi+24] 
	push eax
	call atoi
	add esp, 4

	mov [k], eax
	jmp cont_build

	not_debug:
	mov eax, dword [edi+4]
	mov [filename], eax       
	mov eax, dword [edi+8]
	push eax
	call atoi
	add esp, 4

	mov [WorldLength], eax
	mov eax, dword [edi+12]
	push eax
	call atoi
	add esp, 4

	mov [WorldWidth], eax
	mov eax, dword [edi+16] 
	push eax
	call atoi
	add esp, 4

	mov [t], eax
	mov eax, dword [edi+20]
	push eax
	call atoi
	add esp, 4

	mov [k], eax
	jmp cont_build

end1:
    mov eax,1
    mov ebx,1
    int 80h

atoi:
    push    ebp
    mov     ebp, esp        ; Entry code - set up ebp and esp
    push ecx
    push edx
    push ebx
    mov ecx, dword [ebp+8]  ; Get argument (pointer to string)
    xor eax,eax
    xor ebx,ebx

atoi_loop:
    xor edx,edx
    cmp byte[ecx],0
    jz  atoi_end
    imul dword[ten]
    mov bl,byte[ecx]
    sub bl,'0'
    add eax,ebx
    inc ecx
    jmp atoi_loop

atoi_end:
    pop ebx                 ; Restore registers
    pop edx
    pop ecx
    mov     esp, ebp        ; Function exit code
    pop     ebp
    ret

cont_build:

	cmp dword [debug], 1
	jne not_debug1
		push eax
        push    dword [WorldLength]
        push    dword print_1
        call    printf
        add     ESP, 8
        pop eax
		push eax
        push    dword [WorldWidth]
        push    dword print_2
        call    printf
        add     ESP, 8
        pop eax
		push eax
        push    dword [t]
        push    dword print_3
        call    printf
        add     ESP, 8
        pop eax
		push eax
        push    dword [k]
        push    dword print_4
        call    printf
        add     ESP, 8
        pop eax
	
	not_debug1:
	mov eax,[WorldWidth]
	mov ecx,[WorldLength]
	mul ecx
	mov [num_of_cells], eax

; open the file

    mov   eax,  5          
    mov ebx, dword [filename]
    mov ecx, 0             ;for read only access
    mov edx, 0777          ;read, write and execute by all
    int  0x80
    mov [my_file], eax
   ;read from file
    mov eax, 3
    mov ebx, [my_file]
    mov ecx, BUFFER
    mov edx, 10000
    int 0x80
    mov [my_file_size], eax
    inc dword [my_file_size]
   ; close the file
    mov eax, 6
    mov ebx, [my_file]
    int 0x80
	mov esi,0
	mov edi,0

copy_loop:

	mov edx,0
	mov dl,  byte [BUFFER+esi]

	inc esi
	cmp esi, [my_file_size]
    je finish_copy

    cmp edx, 48
    je cont_copy
    cmp edx, 49
    je cont_copy
    jmp copy_loop
cont_copy:	
	mov [state+edi] , edx
	add edi, 4
	jmp copy_loop

finish_copy: 
	mov ebx, 0

loop_cells:
	mov eax, STKSZ
	mov edi, ebx
	mul edi
	add eax, STKSZ
	add eax, BIG_STACK
	mov edi, eax

	cmp ebx,0
	jne next_check
	mov dword[edi], scheduler
	mov esi, dword[t]
	mov dword[edi+4], esi
	mov esi, dword[k]
	mov dword[edi+8], esi
	jmp after_pushing
	next_check:
	cmp ebx,1
	jne its_cell
	mov dword[edi], printer
	jmp after_pushing
	its_cell:
	mov dword[edi], cell
	mov esi, dword[cell_i]
	mov dword[edi+4], esi
	mov esi, dword[cell_j]
	mov dword[edi+8], esi
	mov esi, dword[cell_num]
	mov dword[edi+12], esi
	inc dword[cell_j]
	mov esi,dword[cell_j]
	cmp esi, dword[WorldWidth]
	jne not_width
	mov dword[cell_j], 0
	inc dword[cell_i]
	not_width:
	inc dword[cell_num]
	after_pushing:
	    
	push 4
	call malloc
	add esp,4
	mov dword [eax], edi
	mov dword [CORS+ebx*4], eax

	inc ebx
	mov edx ,[num_of_cells]
	add edx,2
	cmp ebx, edx
	jne loop_cells

	mov	esp, ebp	; Function exit code
	pop	ebp
	ret

init_co_from_asm:
	push	EBP
	mov	EBP, ESP
	push	EBX


	mov	EBX, [EBP+8]
	mov	EBX, [EBX*4+CORS]

	call	co_init

	pop	EBX
	pop	EBP
	ret
	
co_init:
	pusha
	mov	[SPT], ESP
	mov	ESP,[EBX]   ; Get initial SP
	mov	EBP, ESP        ; Also use as EBP
	pushf                   ; and flags
	pusha                   ; and all other regs
	mov	[EBX],ESP    ; Save new SP in structure
	mov	ESP, [SPT]      ; Restore original SP
	popa
	ret

resume:
	pushf			; Save state of caller
	pusha
	mov	EDX, [CURR]
	mov	[EDX],ESP	; Save current SP
do_resume:
	mov	ESP, [EBX]  ; Load SP for resumed co-routine
	mov	[CURR], EBX
	popa			; Restore resumed co-routine state
	popf
	ret                     ; "return" to resumed co-routine!

start_co_from_asm:

	push	EBP
	mov	EBP, ESP
	pusha
	mov	[SPMAIN], ESP             ; Save SP of main code
	
	cmp dword [debug], 1
	jne not_debug2
	mov	EBX, 1
	jmp cont_start
	not_debug2:
	mov	EBX, 0
	cont_start:

	mov	EBX, [EBX*4+CORS]       ; and pointer to co-routine structure
	jmp	do_resume

end_co:
	mov ebx, 0

loop_free:		    
	mov eax, dword [CORS+ebx*4]
	push eax
	call free

	inc ebx
	mov edx ,[num_of_cells]
	add edx,2
	cmp ebx, edx
	jne loop_free

	mov	ESP, [SPMAIN]            ; Restore state of main code
	popa
	pop	EBP
	ret
		
cell:
	mov edi, dword [esp]
	mov dword[cell_i], edi	
	mov edi, dword [esp+4]
	mov dword[cell_j], edi	
	mov edi, dword [esp+8]
	mov dword[cell_num], edi	
	mov ecx,0
	mov ebp,0

findLeft:    ; i, j-1
 	mov esi, dword [cell_j]
 	cmp esi,0
 	jne j_isnt_zero 
	add edi,dword[WorldWidth]
	j_isnt_zero:
 	sub edi, 1

    mov eax, dword [state+edi*4]
    sub eax, 48
    cmp eax , 0
    je is_zero0
    inc ecx
    jmp finish_left
	is_zero0:
    inc ebp

finish_left:
findRight: ; i, j+1

	mov edi, dword [cell_num]
 	mov esi, dword [cell_j]
 	inc esi
 	cmp esi,dword [WorldWidth]
 	jne j_isnt_width 
	sub edi,dword[WorldWidth]
	j_isnt_width:
	inc edi

    mov eax, dword [state+edi*4]
    sub eax, 48
    cmp eax , 0
    je is_zero1
    inc ecx
    jmp finish_right
		is_zero1:
    inc ebp

finish_right:
findTopLeft: ; i-1, j-1

	mov edi, dword [cell_num]
 	mov esi, dword [cell_i]
 	cmp esi,0
 	jne i_isnt_zero 
 	mov esi, dword [WorldWidth]
 	mov eax, dword [WorldLength]
 	mul esi
 	add edi, eax
	i_isnt_zero:
 	sub edi, dword [WorldWidth]

 	mov esi, dword [cell_i]
    test esi,1
    jnz odd
	dec edi
	mov esi, dword [cell_j]
 	cmp esi, 0
    jne j_isnt_startline
 	add edi, dword [WorldWidth]
	j_isnt_startline:

	odd:
    mov eax, dword [state+edi*4]
    sub eax, 48
    cmp eax , 0
    je is_zero2
    inc ecx
    jmp finish_top_left
	is_zero2:
    inc ebp

finish_top_left:
findTopRight: ; i-1, j

	mov edi, dword [cell_num]
 	mov esi, dword [cell_i]
 	cmp esi,0
 	jne i_isnt_zero1 
 	mov esi, dword [WorldWidth]
 	mov eax, dword [WorldLength]
 	mul esi
 	add edi, eax
	i_isnt_zero1:
 	sub edi, dword [WorldWidth]

 	mov esi, dword [cell_i]
    test esi,1
    jz even
	inc edi
	mov esi, dword [cell_j]
 	inc esi
 	cmp esi, dword [WorldWidth]
    jne j_isnt_endline
 	sub edi, dword [WorldWidth]
	j_isnt_endline:

	even:
    mov eax, dword [state+edi*4]
    sub eax, 48
    cmp eax , 0
    je is_zero3
    inc ecx
    jmp finish_top_right
	is_zero3:
    inc ebp

finish_top_right:
findAboveLeft: ; i+1, j-1

	mov edi, dword [cell_num]
 	mov esi, dword [cell_i]
 	inc esi
 	cmp esi,dword [WorldLength]
 	jne i_isnt_length 
 	mov esi, dword [WorldWidth]
 	mov eax, dword [WorldLength]
 	mul esi
 	sub edi, eax
	i_isnt_length:
 	add edi, dword [WorldWidth]

 	mov esi, dword [cell_i]
    test esi,1
    jnz odd1
	dec edi
	mov esi, dword [cell_j]
 	cmp esi, 0
    jne j_isnt_startline1
 	add edi, dword [WorldWidth]
	j_isnt_startline1:

	odd1:
    mov eax, dword [state+edi*4]
    sub eax, 48
    cmp eax , 0

    je is_zero4
    inc ecx
    jmp finish_above_left
	is_zero4:
    inc ebp

finish_above_left:
findAboveRight: ; i+1, j

	mov edi, dword [cell_num]
 	mov esi, dword [cell_i]
 	inc esi
 	cmp esi,dword [WorldLength]
 	jne i_isnt_length1 
 	mov esi, dword [WorldWidth]
 	mov eax, dword [WorldLength]
 	mul esi
 	sub edi, eax
	i_isnt_length1:
 	add edi, dword [WorldWidth]

 	mov esi, dword [cell_i]
    test esi,1
    jz even1
	inc edi
	mov esi, dword [cell_j]
 	inc esi
 	cmp esi, dword [WorldWidth]
    jne j_isnt_endline1
 	sub edi, dword [WorldWidth]
	j_isnt_endline1:

	even1:
    mov eax, dword [state+edi*4]
    sub eax,48
    cmp eax , 0
    je is_zero5
    inc ecx
    jmp finish_above_right
	is_zero5:
    inc ebp

finish_above_right:
	mov esi, dword [cell_num]
    mov ebx, dword [state+esi*4]
    sub ebx, 48
    cmp ebx,0
    je i_am_zero

	i_am_one:
	cmp ecx,3
	jl i_am_dead
	cmp ecx,5
	jl stay_alive

	i_am_zero:
	cmp ecx,2
	jne i_am_dead	

	stay_alive:
    mov edi ,49
	jmp finish_cal
	
	i_am_dead:
    mov edi ,48

finish_cal:
	mov	EBX, [CORS]
	call	dword resume

	mov esi, dword [esp]
	mov dword[cell_i], esi	
	mov esi, dword [esp+4]
	mov dword[cell_j], esi	
	mov esi, dword [esp+8]
	mov dword[cell_num], esi	

	mov esi, dword [cell_num]	
    mov dword [state+esi*4], edi

	mov ecx , 0
	mov ebp , 0
	mov edi	, 0

	mov	EBX, [CORS]
	call	dword resume

	jmp cell