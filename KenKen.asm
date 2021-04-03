.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Ken Ken",0
area_width EQU 1000
area_height EQU 500
area DD 0

counter DD 0 ; numara evenimentele de tip timer

n dd 6 ; nr de patrate pe orizontala este n-1 
m dd 6 ; nr de patrate pe verticala este m-1
		; n = m ca sa fie matrica patratica
incepere_grid_x dd 80
incepere_grid_y dd 100

patrat_width dd 60

x dd 0
y dd 0

symbol_index dd 0

work_matrix dd 25 dup(0)
suma_check dd 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

format DB "%d ", 0
format1 DB "%d %d ", 0
text_win DB "WIN    ", 0
text_fail db "FAIL   ", 0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include semne.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	
	; cmp eax, 32
	; je spatiu
	
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_semn
	cmp eax, '9'
	jg make_semn
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_semn:
	cmp eax, '%'
	jl make_space
	cmp eax, '-'
	jg make_space
	
	cmp eax, '+'
	jz semn_plus
	cmp eax, '-'
	je semn_minus
	cmp eax, '*'
	je semn_mul
	cmp eax, '%'
	je semn_div
	
	back:
	lea esi, semne
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	jmp draw_text
semn_plus:
	mov eax, 0
	jmp back
semn_minus:
	mov eax, 1
	jmp back
semn_mul:
	mov eax, 2
	jmp back
semn_div:
	mov eax, 3
	jmp back
	
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

deseneaza_linie_verticala macro x, y
	local bucla_linii_verticale
	pusha
	mov eax,x
	mov ebx,area_width
	mul ebx
	add eax,y
	mov ebx,4
	mul ebx
	add eax,[area]
	mov dword ptr [eax],0d0d0d0h
	
	push eax
	
	mov eax,patrat_width
	dec n
	mul n
	mov ecx,eax
	pop eax
	inc n
	bucla_linii_verticale: 
		mov ebx, area_width
		add eax,ebx
		add eax,ebx
		add eax,ebx
		add eax,ebx
		mov dword ptr [eax],0d0d0d0h
	loop bucla_linii_verticale
	popa
endm

deseneaza_linie_orizontala macro x, y
	local bucla_linii_orizontale
	pusha
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	add eax,[area]
	mov dword ptr [eax],0d0d0d0h
	push eax
	mov eax,patrat_width
	dec m
	mul m
	mov ecx,eax
	pop eax
	inc m
	bucla_linii_orizontale: 
		add eax,4
		mov dword ptr [eax],0d0d0d0h
	loop bucla_linii_orizontale
	popa
endm

linie_vert_colorata macro x, y
	local bucla_linie_vert
	pusha
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	add eax, [area]
	mov dword ptr [eax], 0A93226h
	mov ebx, area_width
	shl ebx, 2
	mov ecx, patrat_width
	bucla_linie_vert:
		add eax, ebx
		mov dword ptr [eax], 0A93226h
	loop bucla_linie_vert
	popa
endm

linie_vert_colorata_jum macro x, y
	local bucla_linie_vert
	pusha
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	add eax, [area]
	mov dword ptr [eax], 0A93226h
	mov ebx, area_width
	shl ebx, 2
	mov ecx, 30
	bucla_linie_vert:
		add eax, ebx
		mov dword ptr [eax], 0A93226h
	loop bucla_linie_vert
	popa
endm

linie_oriz_colorata macro x, y
	local bucla_linie_oriz
	pusha
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	add eax, [area]
	mov dword ptr [eax], 0A93226h

	mov ecx, patrat_width
	bucla_linie_oriz:
		add eax, 4
		mov dword ptr [eax], 0A93226h
	loop bucla_linie_oriz
	popa
endm

linie_oriz_colorata_mesaj macro x, y, culoare
	local bucla_linie_oriz
	pusha
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	add eax, [area]
	mov dword ptr [eax], culoare

	mov ecx, 80
	bucla_linie_oriz:
		add eax, 4
		mov dword ptr [eax], culoare
	loop bucla_linie_oriz
	popa
endm
linie_vert_colorata_jum_mesaj macro x, y, culoare
	local bucla_linie_vert
	pusha
	mov eax, x
	mov ebx, area_width
	mul ebx
	add eax, y
	shl eax, 2
	add eax, [area]
	mov dword ptr [eax], culoare
	mov ebx, area_width
	shl ebx, 2
	mov ecx, 30
	bucla_linie_vert:
		add eax, ebx
		mov dword ptr [eax], culoare
	loop bucla_linie_vert
	popa
endm

colorare_grid_macro_clear macro x, y
	local bucla_umplere
	local bucla_linie_de_umplere
	pusha
	mov ecx, patrat_width
	sub ecx, 1
	
	bucla_umplere:
		mov ebx, x
		add ebx, ecx
		mov eax, ebx
		mov ebx, area_width
		mul ebx
		add eax, y
		add eax, 1
		shl eax, 2
		add eax, [area]
		mov dword ptr [eax],0ffffffh
		push eax
	
		mov eax, patrat_width
		sub eax, 2
		mov edx, ecx
		mov ecx, eax
		pop eax
		bucla_linie_de_umplere:
			add eax, 4
			mov dword ptr [eax], 0ffffffh
		loop bucla_linie_de_umplere
		mov ecx, edx
	loop bucla_umplere
	popa
	endm
	
colorare_grid_macro macro x, y
	local bucla_umplere
	local bucla_linie_de_umplere
	pusha
	mov ecx, patrat_width
	sub ecx, 1
	
	bucla_umplere:
		mov ebx, x
		add ebx, ecx
		mov eax, ebx
		mov ebx, area_width
		mul ebx
		add eax, y
		add eax, 1
		shl eax, 2
		add eax, [area]
		mov dword ptr [eax],0f0f0f0h
		push eax
	
		mov eax, patrat_width
		sub eax, 2
		mov edx, ecx
		mov ecx, eax
		pop eax
		bucla_linie_de_umplere:
			add eax, 4
			mov dword ptr [eax], 0f0f0f0h
		loop bucla_linie_de_umplere
		mov ecx, edx
	loop bucla_umplere
	popa
	endm

	umplere_casuta macro tx, ty, sy
		push esi
		lea esi, work_matrix
		cmp tx, 0
		je final
		cmp ty, 0
		je final
		mov eax, tx
		sub eax, 100
		mov edx, 0
		mov ecx, 60
		div ecx
		push eax
		
		mov eax, ty
		sub eax, 80
		mov ecx, 60
		mov edx, 0
		div ecx
		
		pop ebx
		
		;eax, ebx <- [0,4]; eax - y; ebx - x
		mov edx, 5
		mul edx
		add eax, ebx
		mov ebx, 4
		mul ebx
		mov symbol_index, eax
		
		; push symbol_index
		; push offset format
		; call printf
		; add esp, 4
		; push 0
		
		add esi, symbol_index
		mov dword ptr [esi], sy
		pop esi
	endm
	
colorare_grid proc
	push EBP
	mov EBP, ESP
	
	push ecx
	mov ebx, [ebp + arg1] ; ebx <- x
	mov eax, [ebp + arg2] ; eax <- y
	
	mov edx, 0 ; trebuie neaparat sa setam EDX cu 0
	sub eax, incepere_grid_x
	mov ecx, patrat_width
	div ecx

	push eax ; <-y incepere desen
	
	mov edx, 0
	mov eax, ebx
	sub eax, incepere_grid_y
	mov ecx, patrat_width
	div ecx
	; eax <-x incepere desen
	
	pop ebx ;ebx <-y incepere desen
	
	; aici trebuie pusa o functie de completare a unei matrici de rezolvare
	; eax,ebx -> [0,4]

	mov ecx, eax
	mov eax, patrat_width
	mul ecx
	add eax, incepere_grid_y
	
	xchg eax, ebx
	mov ecx, eax
	mov eax, patrat_width
	mul ecx
	add eax, incepere_grid_x
	
	;eax <- y
	;ebx <- x
	
	; push eax
	; push ebx
	; push offset format1
	; call printf
	; add esp, 12
	; push 0
	
	mov x, ebx
	mov y, eax
	colorare_grid_macro y, x
	
	final:
	mov ESP,EBP
	pop EBP
	ret
colorare_grid endp

	
click_casuta proc 
	push EBP
	mov EBP,ESP
	
	; se verifica daca sa facut un click in grid
	;[ebp + arg1] <- x
	;[ebp + arg2] <- y
	mov eax, [ebp + arg1]
	mov ebx, [ebp + arg2]
	
	mov ecx, incepere_grid_x
	cmp ebx, ecx
	jle iesire
	mov edx, 300
	add ecx, edx
	cmp ebx, ecx
	jge iesire
	sub ecx, edx
	
	mov ecx, incepere_grid_y
	cmp eax, ecx
	jle iesire
	add ecx, edx
	cmp eax, ecx
	jl suntem_in_grid
	
	; se verifica daca sa facut un click in buton
	mov ecx, 140
	cmp ebx, ecx
	jle iesire
	mov ecx, 200
	cmp ebx, ecx
	jge verf_clear
	
	mov ecx, 520
	cmp eax, ecx
	jle iesire
	add ecx, patrat_width
	cmp eax, ecx
	jl click_buton_1
	
	mov ecx, 600
	cmp eax, ecx
	jle iesire
	add ecx, patrat_width
	cmp eax, ecx
	jl click_buton_2
	
	mov ecx, 680
	cmp eax, ecx
	jle iesire
	add ecx, patrat_width
	cmp eax, ecx
	jl click_buton_3
	
	mov ecx, 760
	cmp eax, ecx
	jle iesire
	add ecx, patrat_width
	cmp eax, ecx
	jl click_buton_4
	
	mov ecx, 840
	cmp eax, ecx
	jle iesire
	add ecx, patrat_width
	cmp eax, ecx
	jl click_buton_5
	
	verf_clear:
	mov ecx, 320
	cmp ebx, ecx
	jl iesire
	add ecx, 30
	cmp ebx, ecx
	jg iesire
	
	mov ecx, 520
	cmp eax, ecx
	jl iesire
	add ecx, 120
	cmp eax, ecx
	jl check_if_clear
	
	mov ecx, 760
	cmp eax, ecx
	jl iesire
	add ecx, 120
	cmp eax, ecx
	jl click_buton_clear
	
	jmp iesire
	
	check_if_clear:
	
		lea esi, work_matrix
		mov edx, 5
		verificare_linii:
		
		mov suma_check, 0
		mov ecx, 5
		dec edx
		cmp edx, 0
		je incepere_verificare_coloane
		loop_verf_line:
			
			cmp dword ptr [esi], '1'
			je gasit_1
			cmp dword ptr [esi], '2'
			je gasit_2
			cmp dword ptr [esi], '3'
			je gasit_3
			cmp dword ptr [esi], '4'
			je gasit_4
			cmp dword ptr [esi], '5'
			je gasit_5
			
			jmp fin
			
			gasit_1:
			add suma_check, 1
			jmp fin
			gasit_2:
			add suma_check, 5
			jmp fin
			gasit_3:
			add suma_check, 7
			jmp fin
			gasit_4:
			add suma_check, 13
			jmp fin
			gasit_5:
			add suma_check, 37
			jmp fin
			
			fin:
			add esi, 4
		loop loop_verf_line
		
		cmp suma_check, 63 ; indicele ca o linie e corecta
		je verificare_linii
		cmp suma_check, 63
		jne fail
		
		incepere_verificare_coloane:
			lea esi, work_matrix
			add esi, 96
			mov ebx, 6
			verificare_coloane:
				dec ebx
				cmp ebx, 0
				je incepere_verificare_unitati ; aici vine verificare unita
				sub esi, 96
				
				push ebx
				push offset format
				call printf
				add esp, 8
				push 0
				
				push suma_check
				push offset format
				call printf
				add esp, 8
				push 0
				
				mov suma_check, 0
				mov ecx, 5
				
				loop_verf_col:
				
					cmp dword ptr [esi], '1'
					je gasit_1_c
					cmp dword ptr [esi], '2'
					je gasit_2_c
					cmp dword ptr [esi], '3'
					je gasit_3_c
					cmp dword ptr [esi], '4'
					je gasit_4_c
					cmp dword ptr [esi], '5'
					je gasit_5_c
					
					jmp fin_c
					
					gasit_1_c:
					add suma_check, 1
					jmp fin_c
					gasit_2_c:
					add suma_check, 5
					jmp fin_c
					gasit_3_c:
					add suma_check, 7
					jmp fin_c
					gasit_4_c:
					add suma_check, 13
					jmp fin_c
					gasit_5_c:
					add suma_check, 37
					jmp fin_c
					
					fin_c:
					add esi, 20
				loop loop_verf_col
		
		cmp suma_check, 63 ; indicele ca o linie e corecta
		je verificare_coloane
		cmp suma_check, 63
		jne fail
		
		incepere_verificare_unitati:
			; unitate_1 +3
			mov eax, work_matrix(0)
			mov ebx, work_matrix(20)
			sub eax, 48
			sub ebx, 48
			add eax, ebx
			cmp eax, 3
			jne fail
			
			; unitate_2 *20
			mov eax, work_matrix(4)
			mov ebx, work_matrix(8)
			sub eax, 48
			sub ebx, 48
			mul ebx
			cmp eax, 20
			jne fail
			
			; unitate_3 -2
			mov eax, work_matrix(12)
			mov ebx, work_matrix(32)
			sub eax, 48
			sub ebx, 48
			sub eax, ebx
			cdq
			xor eax, edx ; de la cdq este functia abs
			add eax, edx
			cmp eax, 2
			jne fail
			
			; unitate_4 %2
			mov eax, work_matrix(16)
			mov ebx, work_matrix(36)
			sub eax, 48
			sub ebx, 48
			mov edx, 0
			cmp eax, ebx
			jge continua_4
			xchg eax, ebx
			continua_4:
			div ebx
			cmp edx,0
			jne fail
			cmp eax, 2
			jne fail
			
			; unitate_5 *15
			mov eax, work_matrix(24)
			mov ebx, work_matrix(28)
			sub eax, 48
			sub ebx, 48
			mul ebx
			cmp eax, 15
			jne fail
			
			; unitate_6 +8
			mov eax, work_matrix(40)
			mov ebx, work_matrix(44)
			mov ecx, work_matrix(48)
			sub eax, 48
			sub ebx, 48
			sub ecx, 48
			add eax, ebx
			add eax, ecx
			cmp eax, 8
			jne fail
			
			; unitate_7 +7
			mov eax, work_matrix(52)
			mov ebx, work_matrix(56)
			sub eax, 48
			sub ebx, 48
			add eax, ebx
			cmp eax, 7
			jne fail
			
			; unitate_8 *36
			mov eax, work_matrix(60)
			mov ebx, work_matrix(64)
			mov ecx, work_matrix(80)
			mov edx, work_matrix(84)
			sub eax, 48
			sub ebx, 48
			sub ecx, 48
			sub edx, 48
			mul edx
			mul ebx
			mul ecx
			
			cmp eax, 36
			jne fail
			
			; unitate_9 %2
			mov eax, work_matrix(68)
			mov ebx, work_matrix(88)
			sub eax, 48
			sub ebx, 48
			mov edx, 0
			cmp eax, ebx
			jge continua_9
			xchg eax, ebx
			continua_9:
			div ebx
			cmp edx,0
			jne fail
			cmp eax, 2
			jne fail
			
			; unitate_10 -3
			mov eax, work_matrix(72)
			mov ebx, work_matrix(76)
			
			sub eax, 48
			sub ebx, 48
			sub eax, ebx
			
			cmp eax, 3
			je mai_departe_10
			cmp eax, -3
			je mai_departe_10
			jmp fail
			mai_departe_10:
			
			;unitate_11 -4
			mov eax, work_matrix(92)
			mov ebx, work_matrix(96)
			sub eax, 48
			sub ebx, 48
			sub eax, ebx
			cdq
			xor eax, edx ; de la cdq este functia abs
			add eax, edx
			cmp eax, 4
			jne fail
			jmp win
			
		
		fail:
		; temporar da mesaj
		mov suma_check, 0
		push offset text_fail
		call printf
		add esp, 4
		push 0
		linie_oriz_colorata_mesaj 240, 630, 0D1110Fh
		linie_vert_colorata_jum_mesaj 240, 630, 0D1110Fh
		linie_vert_colorata_jum_mesaj 240, 710, 0D1110Fh
		linie_oriz_colorata_mesaj 270, 630, 0D1110Fh
		make_text_macro 'F', area, 650, 245
		make_text_macro 'A', area, 660, 245
		make_text_macro 'I', area, 670, 245
		make_text_macro 'L', area, 680, 245
		jmp final
		
		win:
		
		mov suma_check, 0
		push offset text_win
		call printf
		add esp, 4
		push 0
		linie_oriz_colorata_mesaj 240, 630, 5CD33Eh
		linie_vert_colorata_jum_mesaj 240, 630, 5CD33Eh
		linie_vert_colorata_jum_mesaj 240, 710, 5CD33Eh
		linie_oriz_colorata_mesaj 270, 630, 5CD33Eh
		make_text_macro 'W', area, 655, 245
		make_text_macro 'I', area, 665, 245
		make_text_macro 'N', area, 675, 245
		jmp final
	
	click_buton_clear:
		mov suma_check, 0
		linie_oriz_colorata_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 710, 0FFFFFFh
		linie_oriz_colorata_mesaj 270, 630, 0FFFFFFh
		make_text_macro ' ', area, 655, 245
		make_text_macro ' ', area, 665, 245
		make_text_macro ' ', area, 675, 245
		make_text_macro ' ', area, 650, 245
		make_text_macro ' ', area, 660, 245
		make_text_macro ' ', area, 670, 245
		make_text_macro ' ', area, 680, 245
		mov ecx, 24
		lea esi, work_matrix
		mov dword ptr [esi], 0
		loop_clear:
			add esi, 4
			mov dword ptr [esi], 0
		loop loop_clear
	jmp final
	click_buton_1:
	; matricea corecta
	; mov work_matrix(0), '1'
	; mov work_matrix(4), '4'
	; mov work_matrix(8), '5'
	; mov work_matrix(12), '3'
	; mov work_matrix(16), '2'
	
	; mov work_matrix(20), '2'
	; mov work_matrix(24), '5'
	; mov work_matrix(28), '3'
	; mov work_matrix(32), '1'
	; mov work_matrix(36), '4'
	
	; mov work_matrix(40), '5'
	; mov work_matrix(44), '2'
	; mov work_matrix(48), '1'
	; mov work_matrix(52), '4'
	; mov work_matrix(56), '3'
	
	; mov work_matrix(60), '3'
	; mov work_matrix(64), '1'
	; mov work_matrix(68), '4'
	; mov work_matrix(72), '2'
	; mov work_matrix(76), '5'
	
	; mov work_matrix(80), '4'
	; mov work_matrix(84), '3'
	; mov work_matrix(88), '2'
	; mov work_matrix(92), '5'
	; mov work_matrix(96), '1'
	
		linie_oriz_colorata_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 710, 0FFFFFFh
		linie_oriz_colorata_mesaj 270, 630, 0FFFFFFh
		make_text_macro ' ', area, 655, 245
		make_text_macro ' ', area, 665, 245
		make_text_macro ' ', area, 675, 245
		make_text_macro ' ', area, 650, 245
		make_text_macro ' ', area, 660, 245
		make_text_macro ' ', area, 670, 245
		make_text_macro ' ', area, 680, 245
	
		umplere_casuta x, y, '1'
	jmp final
	click_buton_2:
		linie_oriz_colorata_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 710, 0FFFFFFh
		linie_oriz_colorata_mesaj 270, 630, 0FFFFFFh
		make_text_macro ' ', area, 655, 245
		make_text_macro ' ', area, 665, 245
		make_text_macro ' ', area, 675, 245
		make_text_macro ' ', area, 650, 245
		make_text_macro ' ', area, 660, 245
		make_text_macro ' ', area, 670, 245
		make_text_macro ' ', area, 680, 245
		umplere_casuta x, y, '2'
	jmp final
	click_buton_3:
		linie_oriz_colorata_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 710, 0FFFFFFh
		linie_oriz_colorata_mesaj 270, 630, 0FFFFFFh
		make_text_macro ' ', area, 655, 245
		make_text_macro ' ', area, 665, 245
		make_text_macro ' ', area, 675, 245
		make_text_macro ' ', area, 650, 245
		make_text_macro ' ', area, 660, 245
		make_text_macro ' ', area, 670, 245
		make_text_macro ' ', area, 680, 245
		umplere_casuta x, y, '3'
	jmp final
	click_buton_4:
		linie_oriz_colorata_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 710, 0FFFFFFh
		linie_oriz_colorata_mesaj 270, 630, 0FFFFFFh
		make_text_macro ' ', area, 655, 245
		make_text_macro ' ', area, 665, 245
		make_text_macro ' ', area, 675, 245
		make_text_macro ' ', area, 650, 245
		make_text_macro ' ', area, 660, 245
		make_text_macro ' ', area, 670, 245
		make_text_macro ' ', area, 680, 245
		umplere_casuta x, y, '4'
	jmp final
	click_buton_5:
		linie_oriz_colorata_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 630, 0FFFFFFh
		linie_vert_colorata_jum_mesaj 240, 710, 0FFFFFFh
		linie_oriz_colorata_mesaj 270, 630, 0FFFFFFh
		make_text_macro ' ', area, 655, 245
		make_text_macro ' ', area, 665, 245
		make_text_macro ' ', area, 675, 245
		make_text_macro ' ', area, 650, 245
		make_text_macro ' ', area, 660, 245
		make_text_macro ' ', area, 670, 245
		make_text_macro ' ', area, 680, 245
		umplere_casuta x, y, '5'
	jmp final
	
	suntem_in_grid:
	push ebx
	push eax
	call colorare_grid
	add esp, 8
	jmp final
	
	iesire:
	mov x, 0
	mov y, 0
	final:
	
	mov ESP,EBP
	pop EBP
	ret
click_casuta endp

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x click-ului (orizontala - stanga -> dreapta)
; arg3 - y click-ului(verticala - sus -> jos)
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	
	curatare:
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255 ; asta e codul pentru culoare
	push area
	call memset
	add esp, 12
	
	deseneaza_linie_orizontala incepere_grid_x, incepere_grid_y
	deseneaza_linie_orizontala 140, incepere_grid_y
	deseneaza_linie_orizontala 200, incepere_grid_y
	deseneaza_linie_orizontala 260, incepere_grid_y
	deseneaza_linie_orizontala 320, incepere_grid_y
	deseneaza_linie_orizontala 380, incepere_grid_y
	
	deseneaza_linie_verticala incepere_grid_x, 100
	deseneaza_linie_verticala incepere_grid_x, 160
	deseneaza_linie_verticala incepere_grid_x, 220
	deseneaza_linie_verticala incepere_grid_x, 280
	deseneaza_linie_verticala incepere_grid_x, 340
	deseneaza_linie_verticala incepere_grid_x, 400
	
	; patrat width este de 60
	
	linie_oriz_colorata incepere_grid_x, 100
	linie_oriz_colorata incepere_grid_x, 160
	linie_oriz_colorata incepere_grid_x, 220
	linie_oriz_colorata incepere_grid_x, 280
	linie_oriz_colorata incepere_grid_x, 340
	
	linie_oriz_colorata 380, 100
	linie_oriz_colorata 380, 160
	linie_oriz_colorata 380, 220
	linie_oriz_colorata 380, 280
	linie_oriz_colorata 380, 340
	
	linie_vert_colorata 80, 100
	linie_vert_colorata 140, 100
	linie_vert_colorata 200, incepere_grid_y
	linie_vert_colorata 260, incepere_grid_y
	linie_vert_colorata 320, incepere_grid_y
	
	linie_vert_colorata 80, 400
	linie_vert_colorata 140, 400
	linie_vert_colorata 200, 400
	linie_vert_colorata 260, 400
	linie_vert_colorata 320, 400
	
	; pana aici am incadrat gridul
	
	; unitatiile sunt scrise de la prima linie in jos
	linie_vert_colorata 80, 160
	linie_vert_colorata 140, 160
	linie_oriz_colorata 200, 100
	; prima unitate +3
	
	linie_vert_colorata 80, 280
	linie_oriz_colorata 140, 160
	linie_oriz_colorata 140, 220
	; unitate *20
	
	linie_vert_colorata 140, 280
	linie_vert_colorata 80, 340
	linie_vert_colorata 140, 340
	linie_oriz_colorata 200, 280
	; unitate -2
	
	linie_oriz_colorata 200, 340
	; unitate %2
	
	linie_oriz_colorata 200, 160
	linie_oriz_colorata 200, 220
	; unitate *15
	
	linie_oriz_colorata 260, 100
	linie_oriz_colorata 260, 160
	linie_oriz_colorata 260, 220
	linie_vert_colorata 200, 280
	;unitate +8
	
	linie_oriz_colorata 260, 280
	linie_oriz_colorata 260, 340
	; unitate +7
	
	linie_vert_colorata 260, 220
	linie_vert_colorata 320, 220
	; unitate *36
	
	linie_vert_colorata 260, 280
	linie_vert_colorata 320, 280
	; unitate +2
	
	linie_oriz_colorata 320, 280
	linie_oriz_colorata 320, 340
	;unitate -3 si -4 mai jos
	
	linie_oriz_colorata 140, 520
	linie_oriz_colorata 200, 520
	linie_vert_colorata 140, 520
	linie_vert_colorata 140, 580
	; 1
	
	linie_oriz_colorata 140, 600
	linie_oriz_colorata 200, 600
	linie_vert_colorata 140, 600
	linie_vert_colorata 140, 660
	; 2
	
	linie_oriz_colorata 140, 680
	linie_oriz_colorata 200, 680
	linie_vert_colorata 140, 680
	linie_vert_colorata 140, 740
	; 3
	
	linie_oriz_colorata 140, 760
	linie_oriz_colorata 200, 760
	linie_vert_colorata 140, 760
	linie_vert_colorata 140, 820
	; 4
	
	linie_oriz_colorata 140, 840
	linie_oriz_colorata 200, 840
	linie_vert_colorata 140, 840
	linie_vert_colorata 140, 900
	; 5
	
	linie_oriz_colorata 320, 760
	linie_oriz_colorata 320, 820
	linie_vert_colorata_jum 320, 760
	linie_vert_colorata_jum 320, 880
	linie_oriz_colorata 350, 760
	linie_oriz_colorata 350, 820
	; CLEAR
	
	linie_oriz_colorata 320, 520
	linie_oriz_colorata 320, 580
	linie_vert_colorata_jum 320, 520
	linie_vert_colorata_jum 320, 640
	linie_oriz_colorata 350, 520
	linie_oriz_colorata 350, 580
	; CHECK
	
	jmp afisare_litere
	
evt_click:
	
	; verificare daca sa dat click in grid, daca nu se sterge marcajul colorat de click
	; also se sterge afisarea butoanelor
	
	cmp x, 0
	je inceput_click
	cmp y, 0
	je inceput_click
	
	colorare_grid_macro_clear y, x
	
	inceput_click:
	push [ebp+arg3]; y
	push [ebp+arg2]; x
	call click_casuta 
	add esp, 8
	
	
	
	jmp afisare_litere
	
evt_timer:
	inc counter
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	make_text_macro 'K', area, 680, 80
	make_text_macro 'E', area, 690, 80
	make_text_macro 'N', area, 700, 80
	make_text_macro 'K', area, 720, 80
	make_text_macro 'E', area, 730, 80
	make_text_macro 'N', area, 740, 80
	
	make_text_macro '1', area, 530, 150
	make_text_macro '2', area, 610, 150
	make_text_macro '3', area, 690, 150
	make_text_macro '4', area, 770, 150
	make_text_macro '5', area, 850, 150
	
	make_text_macro '+', area, 101, 81
	make_text_macro '3', area, 111, 81
	; +3
	
	make_text_macro '*', area, 161, 81
	make_text_macro '2', area, 171, 81
	make_text_macro '0', area, 181, 81
	; +20
	
	make_text_macro '-', area, 281, 81
	make_text_macro '2', area, 291, 81
	; -2
	
	make_text_macro '%', area, 341, 81
	make_text_macro '2', area, 351, 81
	; %2
	
	make_text_macro '*', area, 161, 141
	make_text_macro '1', area, 171, 141
	make_text_macro '5', area, 181, 141
	; *15
	
	make_text_macro '+', area, 101, 201
	make_text_macro '8', area, 111, 201
	; +8
	
	make_text_macro '+', area, 281, 201
	make_text_macro '7', area, 291, 201
	; -7
	
	make_text_macro '*', area, 101, 261
	make_text_macro '3', area, 111, 261
	make_text_macro '6', area, 121, 261
	; *36
	
	make_text_macro '%', area, 221, 261
	make_text_macro '2', area, 231, 261
	; %2
	
	make_text_macro '-', area, 281, 261
	make_text_macro '3', area, 291, 261
	; -3
	
	make_text_macro '-', area, 281, 321
	make_text_macro '4', area, 291, 321
	; -4
	
	; punem in grid elementele din matrice
	make_text_macro work_matrix(0), area, 130, 110
	make_text_macro work_matrix(4), area, 190, 110
	make_text_macro work_matrix(8), area, 250, 110
	make_text_macro work_matrix(12), area, 310, 110
	make_text_macro work_matrix(16), area, 370, 110
	
	make_text_macro work_matrix(20), area, 130, 170
	make_text_macro work_matrix(24), area, 190, 170
	make_text_macro work_matrix(28), area, 250, 170
	make_text_macro work_matrix(32), area, 310, 170
	make_text_macro work_matrix(36), area, 370, 170
	
	make_text_macro work_matrix(40), area, 130, 230
	make_text_macro work_matrix(44), area, 190, 230
	make_text_macro work_matrix(48), area, 250, 230
	make_text_macro work_matrix(52), area, 310, 230
	make_text_macro work_matrix(56), area, 370, 230
	
	make_text_macro work_matrix(60), area, 130, 290
	make_text_macro work_matrix(64), area, 190, 290
	make_text_macro work_matrix(68), area, 250, 290
	make_text_macro work_matrix(72), area, 310, 290
	make_text_macro work_matrix(76), area, 370, 290
	
	make_text_macro work_matrix(80), area, 130, 350
	make_text_macro work_matrix(84), area, 190, 350
	make_text_macro work_matrix(88), area, 250, 350
	make_text_macro work_matrix(92), area, 310, 350
	make_text_macro work_matrix(96), area, 370, 350
	
	make_text_macro 'C', area, 795, 325
	make_text_macro 'L', area, 805, 325
	make_text_macro 'E', area, 815, 325
	make_text_macro 'A', area, 825, 325
	make_text_macro 'R', area, 835, 325
	
	make_text_macro 'C', area, 555, 325
	make_text_macro 'H', area, 565, 325
	make_text_macro 'E', area, 575, 325
	make_text_macro 'C', area, 585, 325
	make_text_macro 'K', area, 595, 325
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
