.386
.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 649
area_height EQU 500
area DD 0
interval_x dd 649   ;;pt mancare
interval_y dd 500

counter DD 0 ; numara evenimentele de tip timer
counterOK dd 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

ultimacoada_x dd 0
ultimacoada_y dd 0
nr_coada dd 0                   ;verific cate elem am aduat in coada
aux dd 0                        ;verific daca a inceput jocul (aux=0 => nu a inceput   aux=1 => a inceput)
auxx dd 0                       ; verific daca am pus mancare (aux=0 => nu am pus,sau am sers-o    aux=1=>am pus si inca nu a mancat-o)
x_mancare dd 0
y_mancare dd 0              
symbol_width EQU 10
symbol_height EQU 20
desen_width EQU 40
desen_height EQU 40
snake_pos_x DD 40
snake_pos_y DD 170
lab_stanga_sus_x equ 20
lab_stanga_sus_y equ 50
lab_dreapta_sus_x equ 620
lab_dreapta_sus_y equ 50
lab_stanga_jos_x equ 20
lab_stanga_jos_y equ 450
lab_dreapta_jos_x equ 620
lab_dreapta_jos_y equ 450
lab_central_st_x equ 140
lab_central_y equ 190     ;lab central mare
lab_central_dr_x equ 490
lab_central_len equ 6
lab_c_mic_y1 equ 130      ;lab central mic sus
lab_c_mic_st_x equ 210
lab_c_mic_dr_x equ 420
lab_c_mic_y2 equ 310      ;lab central mic jos

limita_stanga equ 9
limita_dreapta equ 640
limita_sus equ 29
limita_jos equ 490
x equ 20                  ;;pozitia initiala a sarpelui
y equ 170
include digits.inc
include letters.inc
include desen.inc

button_x EQU 240
button_y EQU 290
button_width EQU 80 
button_height EQU 40

formatd dd "%d"

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
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
    cmp eax, '$'
	je make_snake
	cmp eax, '*'
	je labirint
	cmp eax, '+'
	je mancare
	cmp eax, '!'
	je coada
	cmp eax, ':'
	je puncte
	cmp eax, '#'
	je negru
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	jmp draw_text
labirint:
    mov eax,29
	lea esi,letters
	jmp draw_text
mancare:
    mov eax, 30
    lea esi, letters
	jmp draw_text
puncte:
    mov eax, 32
    lea esi, letters
	jmp draw_text
make_snake:
    mov eax, 27
    lea esi, letters
	jmp draw_text
coada:
    mov eax, 31
    lea esi, letters
	jmp draw_text
negru:
    mov eax, 28
	lea esi, letters
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
	cmp byte ptr [esi],1
	je simbol_pixel_negru
	cmp byte ptr [esi],2
	je simbol_pixel_verde
	cmp byte ptr [esi],3
	je simbol_pixel_albastru
	cmp byte ptr [esi],4
	je simbol_pixel_rosu
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_verde:
	mov dword ptr [edi], 53E720h
	jmp simbol_pixel_next
simbol_pixel_albastru:
	mov dword ptr [edi], 0412FFh
	jmp simbol_pixel_next
simbol_pixel_rosu:
	mov dword ptr [edi], 0FF3333H
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0h
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

desenn proc
push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, '^'
	je make_face
make_face:
	mov eax, 0
	lea esi, desen
	jmp draw_text
draw_text:
	mov ebx, desen_width
	mul ebx
	mov ebx, desen_height
	mul ebx
	add esi, eax
	mov ecx, desen_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, desen_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, desen_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	cmp byte ptr [esi],1
	je simbol_pixel_negru
	cmp byte ptr [esi],2
	je simbol_pixel_verde
	cmp byte ptr [esi],4
	je simbol_pixel_galben
	cmp byte ptr [esi],3
	je simbol_pixel_albastru
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_verde:
	mov dword ptr [edi], 53E720h
	jmp simbol_pixel_next
simbol_pixel_galben:
	mov dword ptr [edi], 0FFE733h
	jmp simbol_pixel_next
simbol_pixel_albastru:
	mov dword ptr [edi], 0412FFh
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0h
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
desenn endp

; un macro ca sa apelam mai usor desenarea 
make_desen_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call desenn
	add esp, 16
endm

line_horizontal macro x, y, len, color
local bucla_linie
    mov eax,y   ;eax=y
	mov ebx, area_width
	mul ebx     ;eax=y*area_width
	add eax,x   ;eax=y*area_width +x
	shl eax,2   ;eax=(y*area_width +x) *4
	add eax, area
	mov ecx,len
bucla_linie:
    mov dword ptr[eax], color
	add eax,4
	loop bucla_linie
endm

line_vertical macro x, y, len, color
local bucla_linie
    mov eax,y   ;eax=y
	mov ebx, area_width
	mul ebx     ;eax=y*area_width
	add eax,x   ;eax=y*area_width +x
	shl eax,2   ;eax=(y*area_width +x) *4
	add eax, area
	mov ecx,len
bucla_linie:
    mov dword ptr[eax], color
	add eax, area_width*4
	loop bucla_linie
endm

detremina_pozitie macro x, y
    mov eax,y
	mov ebx, area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax, area
endm


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	cmp eax, 3
	jz evt_tasta    ;s-a apasat o tasta
	
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
    mov eax, [ebp+arg2]
	cmp eax, button_x
	jl button_fail
	cmp eax, button_x+button_width
	jg button_fail
	mov eax,[ebp+arg3]
	cmp eax,button_y
	jl button_fail
	cmp eax, button_y+button_height
	jg button_fail

start_game:
    mov aux,1                              ;;aux=1 => a inceput jocul
	mov auxx,0                            ;;daca la jocul trecut nu a mancat mancarea, auxx ramane pe 1 si nu se mai pune mancare
    make_text_macro '#', area, 225, 60
	make_text_macro '#', area, 250, 60
	make_text_macro '#', area, 275, 60
	make_text_macro '#', area, 300, 60
	make_text_macro '#', area, 325, 60
	
	make_text_macro '#', area, 230, 145
	make_text_macro '#', area, 240, 145
	make_text_macro '#', area, 250, 145
	make_text_macro '#', area, 270, 145
	make_text_macro '#', area, 280, 145
	make_text_macro '#', area, 290, 145
	make_text_macro '#', area, 300, 145
	make_text_macro '#', area, 310, 145
	
	line_horizontal button_x, button_y, button_width, 0h
	line_horizontal button_x, button_y+button_height, button_width, 0h
	line_vertical button_x, button_y, button_height, 0h
	line_vertical button_x+button_width, button_y, button_height,0h
	
	make_text_macro '#', area, 260, 240
	make_text_macro '#', area, 270, 240
	make_text_macro '#', area, 280, 240
	make_text_macro '#', area, 290, 240
	make_text_macro '#', area, 300, 240
	
    mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0h
	push area
	call memset
	add esp, 12
	
	
	line_horizontal limita_stanga, limita_sus, limita_dreapta-limita_stanga, 0412FFh
	line_horizontal limita_stanga, limita_jos, limita_dreapta-limita_stanga, 0412FFh
	line_vertical limita_stanga, limita_sus, limita_jos-limita_sus, 0412FFh
	line_vertical limita_dreapta, limita_sus, limita_jos-limita_sus,0412FFh
	
	make_text_macro '*',area, lab_dreapta_sus_x, lab_dreapta_sus_y
	make_text_macro '*',area, lab_dreapta_sus_x-symbol_width, lab_dreapta_sus_y
	make_text_macro '*',area, lab_dreapta_sus_x-(2*symbol_width), lab_dreapta_sus_y
	make_text_macro '*',area, lab_dreapta_sus_x, lab_dreapta_sus_y+symbol_height
	make_text_macro '*',area, lab_dreapta_sus_x, lab_dreapta_sus_y+(2*symbol_height)
	
	make_text_macro '*',area, lab_dreapta_jos_x, lab_dreapta_jos_y
	make_text_macro '*',area, lab_dreapta_jos_x-symbol_width, lab_dreapta_jos_y
	make_text_macro '*',area, lab_dreapta_jos_x-(2*symbol_width), lab_dreapta_jos_y
	make_text_macro '*',area, lab_dreapta_jos_x, lab_dreapta_jos_y-symbol_height
	make_text_macro '*',area, lab_dreapta_jos_x, lab_dreapta_jos_y-(2*symbol_height)
	
	make_text_macro '*',area, lab_stanga_sus_x, lab_dreapta_sus_y
	make_text_macro '*',area, lab_stanga_sus_x+symbol_width, lab_dreapta_sus_y
	make_text_macro '*',area, lab_stanga_sus_x+(2*symbol_width), lab_dreapta_sus_y
	make_text_macro '*',area, lab_stanga_sus_x, lab_dreapta_sus_y+symbol_height
	make_text_macro '*',area, lab_stanga_sus_x, lab_dreapta_sus_y+(2*symbol_height)
	
	make_text_macro '*',area, lab_stanga_jos_x, lab_dreapta_jos_y
	make_text_macro '*',area, lab_stanga_jos_x+symbol_width, lab_dreapta_jos_y
	make_text_macro '*',area, lab_stanga_jos_x+(2*symbol_width), lab_dreapta_jos_y
	make_text_macro '*',area, lab_stanga_jos_x, lab_dreapta_jos_y-symbol_height
	make_text_macro '*',area, lab_stanga_jos_x, lab_dreapta_jos_y-(2*symbol_height)
	
	mov ecx,lab_central_len
	mov ebx,lab_central_y
   bucla_linie_1:
    make_text_macro '*',area, lab_central_st_x, ebx                ;;labirint stanga
	add ebx,symbol_height
	loop bucla_linie_1
	
	
	mov ecx,lab_central_len
	mov ebx,lab_central_y
   bucla_linie_2:
    make_text_macro '*',area, lab_central_dr_x, ebx                ;;labirint dreapta
	add ebx,symbol_height
	loop bucla_linie_2
	
	mov ecx,lab_central_len/2
	mov ebx,lab_c_mic_y1
   bucla_linie_3:
    make_text_macro '*',area, lab_c_mic_st_x, ebx                ;;labirint mic stanga sus
	add ebx,symbol_height
	loop bucla_linie_3
	
	mov ecx,lab_central_len/2
	mov ebx,lab_c_mic_y1
   bucla_linie_4:
    make_text_macro '*',area, lab_c_mic_dr_x, ebx                ;;labirint mic dreapta sus
	add ebx,symbol_height
	loop bucla_linie_4
	
	mov ecx,lab_central_len/2
	mov ebx,lab_c_mic_y2
   bucla_linie_5:
    make_text_macro '*',area, lab_c_mic_st_x, ebx                ;;labirint mic stanga jos
	add ebx,symbol_height
	loop bucla_linie_5
	
	mov ecx,lab_central_len/2
	mov ebx,lab_c_mic_y2
   bucla_linie_6:
    make_text_macro '*',area, lab_c_mic_dr_x, ebx                ;;labirint mic dreapta jos
	add ebx,symbol_height
	loop bucla_linie_6
	
	
	mov snake_pos_x, x
	mov snake_pos_y, y
	make_text_macro '$', area, snake_pos_x, snake_pos_y

	
	
	
    
evt_tasta:

genereaza_mancare:
    cmp auxx, 1
	je nu_genera
	rdtsc                                                                           ;;pozitia x random pt mancare
	mov ecx, 640-10    ;limita dreapta-symbol_width
	mov edx,0
	
	div ecx     ;edx=restul impartirii cu 630 (630=limita dreapta-symbol_width)              ;; LIMITA DREAPTA
	mov x_mancare,edx
	mov ebx,0
	mov ebx, limita_stanga
	cmp x_mancare,ebx                                                                        ;;VERIFICARE LIMITA STANGA
	jle genereaza_mancare
	

	rdtsc																		    ;; pozitia y random pt mancare
	mov ecx, 490-20    ;limita jos-symbol_height               
	mov edx,0
	div ecx     ;edx=restul impartirii cu 490 (490=limita jos)                               ;;LIMITA JOS
	mov y_mancare,edx
	
	mov ebx,0
	mov ebx, limita_sus
	cmp y_mancare,ebx                                                              ;;VERIFICARE LIMITA SUS
	jle genereaza_mancare
	
	detremina_pozitie x_mancare, y_mancare
	cmp dword ptr[eax], 0412FFh
	je genereaza_mancare
	
	mov ebx,0
	mov ebx, x_mancare
	add ebx, symbol_width
	detremina_pozitie ebx,y_mancare
	cmp dword ptr[eax], 0412FFh
	je genereaza_mancare
	
	mov ebx,0
	mov ebx, y_mancare
	add ebx, symbol_height
	detremina_pozitie x_mancare, ebx
	cmp dword ptr[eax], 0412FFh
	je genereaza_mancare
	
	mov ebx,0
	mov ebx, x_mancare
	add ebx, symbol_width
	mov edx,0
	mov edx,y_mancare
	add edx,symbol_height
	detremina_pozitie ebx, edx
	cmp dword ptr[eax], 0412FFh
	je genereaza_mancare
	
	make_text_macro '+',area, x_mancare,y_mancare
	mov auxx, 1
	
nu_genera:
    mov eax, [ebp+arg2]
	cmp eax,26h
	je sus
	cmp eax,27h
	je dreapta
	cmp eax,28h
	je jos
	cmp eax,25h
	je stanga
	
	jmp final_draw

sus:
    make_text_macro '#', area, snake_pos_x, snake_pos_y   ;colorez cu negru pr ca spatiu este alb
	sub snake_pos_y, symbol_height
	
	
	cmp snake_pos_y,limita_sus
	jle game_over
	
	cmp snake_pos_x,lab_stanga_sus_x
	je verif_y
	jmp sf
	verif_y:
	cmp snake_pos_y,(lab_stanga_sus_y+2*symbol_height)
	je game_over
	sf:
	
	cmp snake_pos_x,(lab_stanga_sus_x+symbol_width)
	je verif_y_2
	jmp sf1
	verif_y_2:
	cmp snake_pos_y,lab_stanga_sus_y
	je game_over
	sf1:
	
	cmp snake_pos_x,lab_stanga_sus_x+(2*symbol_width)
	je verif_y_3
	jmp sf2
verif_y_3:
	cmp snake_pos_y,lab_stanga_sus_y
	je game_over
	
	sf2:
	cmp snake_pos_x,lab_dreapta_sus_x
	je verif_y_4
	jmp sf3
verif_y_4:
	cmp snake_pos_y,lab_dreapta_sus_y+(2*symbol_height)
	je game_over
	sf3:
	
	cmp snake_pos_x,lab_dreapta_sus_x-symbol_width
	je verif_y_5
	jmp sf4
verif_y_5:
    cmp snake_pos_y,lab_dreapta_sus_y
    je game_over
    sf4:

	cmp snake_pos_x,lab_dreapta_sus_x-(2*symbol_width)
	je verif_y_6
	jmp sf5
verif_y_6:
    cmp snake_pos_y,lab_dreapta_sus_y
    je game_over
    sf5:
	
	cmp snake_pos_x,lab_stanga_jos_x
	je verif_y_7
	
	cmp snake_pos_x,lab_stanga_jos_x+symbol_width
	je verif_y_7
	
	cmp snake_pos_x,lab_stanga_jos_x+(2*symbol_width)
	je verif_y_7
	jmp sf6
	
	verif_y_7:
	cmp snake_pos_y,lab_stanga_jos_y
	je game_over
	sf6:
	
	cmp snake_pos_x,lab_dreapta_jos_x
	je verif_y_8
	
	cmp snake_pos_x,lab_dreapta_jos_x-symbol_width
	je verif_y_8
	
	cmp snake_pos_x,lab_dreapta_jos_x-(2*symbol_width)
	je verif_y_8
	jmp sf7
	
	verif_y_8:
	cmp snake_pos_y,lab_dreapta_jos_y
	je game_over
	sf7:
	
	cmp snake_pos_x,lab_central_st_x
	je verif_y_9
	jmp sf8
	
	verif_y_9:
	cmp snake_pos_y,lab_central_y+ [(lab_central_len-1)*symbol_height]
	je game_over
	sf8:
	
	cmp snake_pos_x,lab_central_dr_x
	je verif_y_10
	jmp sf9
	
	verif_y_10:
	cmp snake_pos_y,lab_central_y+ [(lab_central_len-1)*symbol_height]
	je game_over
	sf9:
	
	cmp snake_pos_x,lab_c_mic_st_x
	je verif_y_11
	jmp sf10
	
	verif_y_11:
	cmp snake_pos_y,lab_c_mic_y1+[((lab_central_len/2) -1)*symbol_height]
	je game_over
	sf10:
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je verif_y_12
	jmp sf11
	
	verif_y_12:
	cmp snake_pos_y,lab_c_mic_y1+[((lab_central_len/2) -1)*symbol_height]
	je game_over
	sf11:
	
	cmp snake_pos_x,lab_c_mic_st_x
	je verif_y_13
	jmp sf12
	
	verif_y_13:
	cmp snake_pos_y,lab_c_mic_y2+[((lab_central_len/2) -1)*symbol_height]
	je game_over
	sf12:
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je verif_y_14
	jmp sf13
	
	verif_y_14:
	cmp snake_pos_y,lab_c_mic_y2+[((lab_central_len/2) -1)*symbol_height]
	je game_over
	sf13:
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    VERIFICARE MANCARE:
	mov ebx,0
	mov ebx, x_mancare                          ;;pun in ebx x_mancare pt ca nu pot sa compar doua variabile
	cmp snake_pos_x, ebx
	jge verif_x_mare
	cmp snake_pos_x,ebx
	jl verif_x_mic
	jmp sf14
	
	verif_x_mare:
	mov ebx,0
	mov ebx,x_mancare
	add ebx,symbol_width
	cmp snake_pos_x, ebx
	jle verif_y_15
	jmp sf14 
	
	verif_x_mic:
	mov ebx,0
	mov ebx, snake_pos_x
	add ebx, symbol_width
	cmp x_mancare,ebx
	jle verif_y_15
	jmp sf14

	
	verif_y_15:
	mov ebx,0
	mov ebx, y_mancare
	cmp snake_pos_y, ebx
	jle verif_y_mic
	cmp snake_pos_y, ebx
	jg verif_y_mare
	jmp sf14
	
	verif_y_mic:
	mov ebx,0
	mov ebx, snake_pos_y
	add ebx, symbol_height
	cmp y_mancare,ebx
	jle incrementare
	jmp sf14
	
	verif_y_mare:
	mov ebx,0
	mov ebx,y_mancare
	add ebx,symbol_height
	cmp snake_pos_y,ebx
	jle incrementare
	jmp sf14
	

	incrementare:
	make_text_macro '#', area, x_mancare, y_mancare
	inc counter
	; add ultimacoada_y,symbol_height
	; make_text_macro '!',area, snake_pos_x, ultimacoada_y   ;;adaug coada
	; add nr_coada,1
	mov auxx,0
	
	sf14:
	
	make_text_macro '$', area, snake_pos_x, snake_pos_y
	; cmp nr_coada,0                                                 ;;verific daca am coada; daca am, sterg ultima coada adaugata si desenez una cu o pozitie mai fos fata de sarpe
	; je final_draw
	; make_text_macro '#', area, snake_pos_x, ultimacoada_y
	; mov ebx,0
	; mov ebx,snake_pos_y
	; add ebx, symbol_height
	; make_text_macro '!',area, snake_pos_x, ebx  
    ; cmp auxx,0
    ; je final_draw	
    ; sub ultimacoada_y, symbol_height                                    ;; ;;modific ultima coada la pozitia corespunzatoare
	jmp final_draw
	
	

dreapta:
    make_text_macro '#', area, snake_pos_x, snake_pos_y   ;colorez cu negru pr ca spatiu este alb
	add snake_pos_x, symbol_width
	cmp snake_pos_x, limita_dreapta
	jge game_over
	
	cmp snake_pos_y,lab_dreapta_jos_y
	je verif_x_1
	jmp sff
    verif_x_1:
	cmp snake_pos_x,lab_dreapta_jos_x-(2*symbol_width)
	je game_over
	sff:
	
	cmp snake_pos_y,lab_dreapta_jos_y-symbol_height
	je verif_x_2
	jmp sff2
	verif_x_2:
	cmp snake_pos_x,lab_dreapta_jos_x
	je game_over
	sff2:
	
	cmp snake_pos_y,lab_dreapta_jos_y-(2*symbol_height)
	je verif_x_3
	jmp sff3
	verif_x_3:
	cmp snake_pos_x,lab_dreapta_jos_x
	je game_over
	sff3:
	
	cmp snake_pos_y,lab_dreapta_sus_y+(2*symbol_height)
	je verif_x_4
	
	cmp snake_pos_y,lab_dreapta_sus_y+symbol_height
	je verif_x_4
	jmp sff4
	
	verif_x_4:
	cmp snake_pos_x,lab_dreapta_sus_x
	je game_over
	sff4:
	
	cmp snake_pos_y,lab_dreapta_sus_y
	je verif_x_5
	jmp sff5
	verif_x_5:
	cmp snake_pos_x,lab_dreapta_sus_x-(2*symbol_width)
	je game_over
	sff5:
	
	cmp snake_pos_y,lab_stanga_jos_y
	je verif_x_6
	
	cmp snake_pos_y,lab_stanga_jos_y-symbol_height
	je verif_x_6
	
	cmp snake_pos_y,lab_stanga_jos_y-(2*symbol_height)
	je verif_x_6
	jmp sff6
	
	verif_x_6:
	cmp snake_pos_x,lab_stanga_jos_x
	je game_over
	sff6:
	
	cmp snake_pos_y,lab_stanga_sus_y
	je verif_x_7
	
	cmp snake_pos_y,lab_stanga_sus_y+symbol_height
	je verif_x_7
	
	cmp snake_pos_y,lab_stanga_sus_y+(2*symbol_height)
	je verif_x_7
	jmp sff7
	
	verif_x_7:
	cmp snake_pos_x,lab_stanga_sus_x
	je game_over
	sff7:
	
	cmp snake_pos_y,lab_central_y                                                                ;
	je veriff_x_8                                                                                 ;
	                                                                                             ;
	cmp snake_pos_y,(lab_central_y+symbol_height)                                                ;
	je veriff_x_8                                                                                 ;
																								 ;
	cmp snake_pos_y,(lab_central_y+(2*symbol_height))                                            ;
	je veriff_x_8																				 ;
																							     ;
	cmp snake_pos_y,(lab_central_y+(3*symbol_height))                                            ;
	je veriff_x_8                                                                                 ;
	                                                                                             ;        verific lab central mare stanga si dreapta
	cmp snake_pos_y,(lab_central_y+(4*symbol_height))                                            ;
	je veriff_x_8                                                                                 ;
	                                                                                             ;
	cmp snake_pos_y,(lab_central_y+(5*symbol_height))                                            ;
	je veriff_x_8                                                                                 ;
	jmp sfff01                                                                                    ;
	                                                                                             ;
	veriff_x_8:                                                                                   ;
	cmp snake_pos_x,lab_central_st_x                                                             ;
	je game_over                                                                                 ;
	                                                                                             ;
	cmp snake_pos_x,lab_central_dr_x                                                             ;
	je game_over                                                                                 ;
	sfff01:                                                                                       ;
	
	cmp snake_pos_y,lab_c_mic_y1
	je veriff_x_9
	
	cmp snake_pos_y,lab_c_mic_y1+symbol_height
	je veriff_x_9
	
	cmp snake_pos_y,lab_c_mic_y1+(2*symbol_height)                                                ;        verific lab central mic stanga si dreapta  sus
	je veriff_x_9
	jmp sfff02
	
	veriff_x_9:
	cmp snake_pos_x,lab_c_mic_st_x
	je game_over
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je game_over
	sfff02:
	                                                                                              ;      verific lab central mic stanga si dreapta jos
	cmp snake_pos_y,lab_c_mic_y2
	je veriff_x_10
	
	cmp snake_pos_y,lab_c_mic_y2+symbol_height
	je veriff_x_10
	
	cmp snake_pos_y,lab_c_mic_y2+(2*symbol_height)
	je veriff_x_10
	jmp sfff03
	
	veriff_x_10:
	cmp snake_pos_x,lab_c_mic_st_x
	je game_over
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je game_over
	sfff03:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   VERIFICARE MANCARE:
	mov ebx,0
	mov ebx,y_mancare
	cmp snake_pos_y, ebx
	jle verif_yy_mic
	cmp snake_pos_y,ebx
	jg verif_yy_mare
	jmp sf01
	
	verif_yy_mic:
	mov ebx,0
	mov ebx, snake_pos_y
	add ebx, symbol_height
	cmp y_mancare,ebx
	jle verificare_x
	jmp sf01
	
	verif_yy_mare:
	mov ebx,0
	mov ebx,y_mancare
	add ebx,symbol_height
	cmp snake_pos_y,ebx
	jle verificare_x
	jmp sf01
	
	verificare_x:
	mov ebx,0
	mov ebx, x_mancare
	cmp snake_pos_x, ebx
	jle verif_xx_mic
	cmp snake_pos_x,ebx
	jg verif_xx_mare
	jmp sf01
	
	verif_xx_mic:
	mov ebx,0
	mov ebx,snake_pos_x
	add ebx, symbol_width
	cmp x_mancare, ebx
	jle incrementare2
	jmp sf01
	
	verif_xx_mare:
	mov ebx,0
	mov ebx, x_mancare
	add ebx, symbol_width
	cmp snake_pos_x,ebx
	jle incrementare2
	jmp sf01
	
	incrementare2:
	make_text_macro '#', area, x_mancare, y_mancare
	inc counter
	mov auxx,0
	
	sf01:
	
	
	make_text_macro '$', area, snake_pos_x, snake_pos_y
	jmp final_draw
jos:
    make_text_macro '#', area, snake_pos_x, snake_pos_y   ;colorez cu negru pr ca spatiu este alb
	add snake_pos_y, symbol_height
	cmp snake_pos_y,limita_jos
	jge game_over
	
	cmp snake_pos_x,lab_stanga_jos_x
	je veriff_y_1
	jmp sff8
	veriff_y_1:
	cmp snake_pos_y,lab_stanga_jos_y-(2*symbol_height)
	je game_over
	sff8:
	
	cmp snake_pos_x,lab_stanga_jos_x+symbol_width
	je veriff_y_2
	
	cmp snake_pos_x,lab_stanga_jos_x+(2*symbol_width)
	je veriff_y_2
	jmp sff9
	
	veriff_y_2:
	cmp snake_pos_y,lab_stanga_jos_y
	je game_over
	sff9:
	
	cmp snake_pos_x,lab_dreapta_jos_x
	je veriff_y_3
	jmp sff10
	
	veriff_y_3:
	cmp snake_pos_y,lab_dreapta_jos_y-(2*symbol_height)
	je game_over
	sff10:
	
	cmp snake_pos_x,lab_dreapta_jos_x-symbol_width
	je veriff_y_4
	
	cmp snake_pos_x,lab_dreapta_jos_x-(2*symbol_width)
	je veriff_y_4
	jmp sff11
	
	veriff_y_4:
	cmp snake_pos_y,lab_dreapta_jos_y
	je game_over
	sff11:
	
	cmp snake_pos_x,lab_stanga_sus_x
	je veriff_y_5
	
	cmp snake_pos_x,lab_stanga_sus_x+symbol_width
	je veriff_y_5
	
	cmp snake_pos_x,lab_stanga_sus_x+(2*symbol_width)
	je veriff_y_5
	jmp sff12
	
	veriff_y_5:
	cmp snake_pos_y,lab_stanga_sus_y
	je game_over
	sff12:
	
	cmp snake_pos_x,lab_dreapta_sus_x
	je veriff_y_6
	
	cmp snake_pos_x,lab_dreapta_sus_x-symbol_width
	je veriff_y_6
	
	cmp snake_pos_x,lab_dreapta_sus_x-(2*symbol_width)
	je veriff_y_6
	jmp sff13
	
	veriff_y_6:
	cmp snake_pos_y,lab_dreapta_sus_y
	je game_over
	sff13:
	
	cmp snake_pos_x,lab_central_st_x
	je veriff_y_7
	
	cmp snake_pos_x,lab_central_dr_x
	je veriff_y_7
	jmp sff14
	
	veriff_y_7:
	cmp snake_pos_y,lab_central_y
	je game_over
	sff14:
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je veriff_y_8
	
	cmp snake_pos_x,lab_c_mic_st_x
	je veriff_y_8
	jmp sff15
	
	veriff_y_8:
	cmp snake_pos_y,lab_c_mic_y1
	je game_over
	cmp snake_pos_y,lab_c_mic_y2
	je game_over
	sff15:
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;VERIFICARE MANCARE:
	
	mov ebx,0
	mov ebx, x_mancare
	cmp snake_pos_x,ebx
	jle veriff_xx_mic
	cmp snake_pos_x, ebx
	jg veriff_xx_mare
	jmp sf02
	
	veriff_xx_mic:
	mov ebx,0
	mov ebx, snake_pos_x
	add ebx, symbol_width
	cmp x_mancare, ebx
	jle verificare_y
	jmp sf02
	
	veriff_xx_mare:
	mov ebx,0
	mov ebx, x_mancare
	add ebx, symbol_width
	cmp snake_pos_x,ebx
	jle verificare_y
	jmp sf02
	
	verificare_y:
	mov ebx,0
	mov ebx, y_mancare
	cmp snake_pos_y,ebx
	jle veriff_yy_mic
	cmp snake_pos_y,ebx
	jg veriff_yy_mare
	jmp sf02
	
	veriff_yy_mic:
	mov ebx,0
	mov ebx, snake_pos_y
	add ebx, symbol_height
	cmp y_mancare,ebx
	jle incrementare3
	jmp sf02
	
	veriff_yy_mare:
	mov ebx,0
	mov ebx, y_mancare
	add ebx, symbol_height
	cmp snake_pos_y,ebx
	jle incrementare3
	jmp sf02
	
	incrementare3:
	make_text_macro '#', area, x_mancare, y_mancare
	inc counter
	mov auxx,0
	
	sf02:
	
	make_text_macro '$', area, snake_pos_x, snake_pos_y
	jmp final_draw
stanga:
    make_text_macro '#', area, snake_pos_x, snake_pos_y   ;colorez cu negru pr ca spatiu este alb
	sub snake_pos_x, symbol_width
	cmp snake_pos_x,limita_stanga
	jl game_over
	
	cmp snake_pos_y,lab_stanga_sus_y
	je veriff_x_1
	jmp sfff1
	veriff_x_1:
	cmp snake_pos_x,lab_stanga_sus_x+(2*symbol_width)
	je game_over
	sfff1:
	
	cmp snake_pos_y,lab_stanga_sus_y+symbol_height
	je veriff_x_2
	
	cmp snake_pos_y,lab_stanga_sus_y+(2*symbol_height)
	je veriff_x_2
	jmp sfff2
	
	veriff_x_2:
	cmp snake_pos_x,lab_stanga_sus_x
	je game_over
	sfff2:
	
	cmp snake_pos_y,lab_stanga_jos_y
	je veriff_x_3
	jmp sfff3
	veriff_x_3:
	cmp snake_pos_x,lab_stanga_jos_x+(2*symbol_width)
	je game_over
	sfff3:
	
	cmp snake_pos_y,lab_stanga_jos_y-symbol_height
	je veriff_x_4
	
	cmp snake_pos_y,lab_stanga_jos_y-(2*symbol_height)
	je veriff_x_4
	jmp sfff4
	
	veriff_x_4:
	cmp snake_pos_x,lab_stanga_jos_x
	je game_over
	sfff4:
	
	cmp snake_pos_y,lab_dreapta_sus_y
	je veriff_x_5
	
	cmp snake_pos_y,lab_dreapta_sus_y+symbol_height
	je veriff_x_5
	
	cmp snake_pos_y,lab_dreapta_sus_y+(2*symbol_height)
	je veriff_x_5
	jmp sfff5
	
	veriff_x_5:
	cmp snake_pos_x,lab_dreapta_sus_x
	je game_over
	sfff5:
	
	cmp snake_pos_y,lab_dreapta_jos_y
	je veriff_x_6
	
	cmp snake_pos_y,lab_dreapta_jos_y-symbol_height
	je veriff_x_6
	
	cmp snake_pos_y,lab_dreapta_jos_y-(2*symbol_height)
	je veriff_x_6
	jmp sfff6
	
	veriff_x_6:
	cmp snake_pos_x,lab_dreapta_jos_x
	je game_over
	sfff6:
	
	cmp snake_pos_y,lab_central_y                                                                ;
	je verif_x_8                                                                                 ;
	                                                                                             ;
	cmp snake_pos_y,(lab_central_y+symbol_height)                                                ;
	je verif_x_8                                                                                 ;
																								 ;
	cmp snake_pos_y,(lab_central_y+(2*symbol_height))                                            ;
	je verif_x_8																				 ;
																							     ;
	cmp snake_pos_y,(lab_central_y+(3*symbol_height))                                            ;
	je verif_x_8                                                                                 ;
	                                                                                             ;        verific lab central mare stanga si dreapta
	cmp snake_pos_y,(lab_central_y+(4*symbol_height))                                            ;
	je verif_x_8                                                                                 ;
	                                                                                             ;
	cmp snake_pos_y,(lab_central_y+(5*symbol_height))                                            ;
	je verif_x_8                                                                                 ;
	jmp sfff7                                                                                    ;
	                                                                                             ;
	verif_x_8:                                                                                   ;
	cmp snake_pos_x,lab_central_st_x                                                             ;
	je game_over                                                                                 ;
	                                                                                             ;
	cmp snake_pos_x,lab_central_dr_x                                                             ;
	je game_over                                                                                 ;
	sfff7:                                                                                       ;
	
	cmp snake_pos_y,lab_c_mic_y1
	je verif_x_9
	
	cmp snake_pos_y,lab_c_mic_y1+symbol_height
	je verif_x_9
	
	cmp snake_pos_y,lab_c_mic_y1+(2*symbol_height)                                                ;        verific lab central mic stanga si dreapta  sus
	je verif_x_9
	jmp sfff8
	
	verif_x_9:
	cmp snake_pos_x,lab_c_mic_st_x
	je game_over
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je game_over
	sfff8:
	                                                                                              ;      verific lab central mic stanga si dreapta jos
	cmp snake_pos_y,lab_c_mic_y2
	je verif_x_10
	
	cmp snake_pos_y,lab_c_mic_y2+symbol_height
	je verif_x_10
	
	cmp snake_pos_y,lab_c_mic_y2+(2*symbol_height)
	je verif_x_10
	jmp sfff9
	
	verif_x_10:
	cmp snake_pos_x,lab_c_mic_st_x
	je game_over
	
	cmp snake_pos_x,lab_c_mic_dr_x
	je game_over
	sfff9:
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;VERIFICARE MANCARE:
	mov ebx, 0
	mov ebx,y_mancare
	cmp snake_pos_y,ebx
	jle verif__y_mic
	cmp snake_pos_y,ebx
	jg verif__y_mare
	jmp sf03
	
	verif__y_mic:
	mov ebx,0
	mov ebx, snake_pos_y
	add ebx, symbol_height
	cmp y_mancare,ebx
	jle verificare_x3
	jmp sf03
	
	verif__y_mare:
	mov ebx,0
	mov ebx, y_mancare
	add ebx, symbol_height
	cmp snake_pos_y,ebx
	jle verificare_x3
	jmp sf03
	
	verificare_x3:
	mov ebx, x_mancare
	cmp snake_pos_x,ebx
	jge verif__x_mare
	jmp sf03
	
	verif__x_mare:
	mov ebx,0
	mov ebx, x_mancare
	add ebx, symbol_width
	cmp snake_pos_x,ebx
	jle incrementare4
	jmp sf03
	
	incrementare4:
	make_text_macro '#', area, x_mancare, y_mancare
	inc counter
	mov auxx,0
	
	sf03:
	
	
	make_text_macro '$', area, snake_pos_x, snake_pos_y
    ; cmp nr_coada,0                                                 ;;verific daca am coada; daca am, sterg ultima coada adaugata si desenez una cu o pozitie mai fos fata de sarpe
	; je final_draw
	; make_text_macro '#', area, ultimacoada_x, ultimacoada_y
	; mov ebx,0
	; mov ebx,snake_pos_x
	; add ebx, symbol_width
	; make_text_macro '!',area, ebx, snake_pos_y                      
	; mov ultimacoada_x,ebx                                          ;; ;;modific ultima coada la pozitia corespunzatoare
	jmp final_draw
	
button_fail:
    jmp afisare_litere
game_over:
    mov counter,0   ;;score=0
    mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	mov aux,1           ;;daca e 1 nu se afiseaza literele (a fost setata pe 1 cand a inceput jocul)
	make_text_macro 'G', area, 230, 145
	make_text_macro 'A', area, 240, 145
	make_text_macro 'M', area, 250, 145
	make_text_macro 'E', area, 260, 145
	make_text_macro 'O', area, 280, 145
	make_text_macro 'V', area, 290, 145
	make_text_macro 'E', area, 300, 145
	make_text_macro 'R', area, 310, 145
	make_desen_macro '^',area, 260,200
	line_horizontal button_x, button_y, button_width, 0FF0000h
	line_horizontal button_x, button_y+button_height, button_width, 0FF0000h
	line_vertical button_x, button_y, button_height, 0FF0000h
	line_vertical button_x+button_width, button_y, button_height,0FF0000h
	
	make_text_macro 'R', area, 245, 300
	make_text_macro 'E', area, 255, 300
	make_text_macro 'S', area, 265, 300
	make_text_macro 'T', area, 275, 300
	make_text_macro 'A', area, 285, 300
	make_text_macro 'R', area, 295, 300
	make_text_macro 'T', area, 305, 300
	
evt_timer:
;	inc counter
	
afisare_litere:
    make_text_macro 'S', area, 250, 6
	make_text_macro 'C', area, 260, 6
	make_text_macro 'O', area, 270, 6
	make_text_macro 'R', area, 280, 6
	make_text_macro 'E', area, 290, 6
	make_text_macro ':', area, 300, 6

	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 330, 6
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 320, 6
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 310, 6
	
	;scriem un mesaj                                           ;il scriem daca nu a inceput jocul
	cmp aux,1
	je final_draw
	make_text_macro 'S', area, 225, 100
	make_text_macro 'N', area, 250, 100
	make_text_macro 'A', area, 275, 100
	make_text_macro 'K', area, 300, 100
	make_text_macro 'E', area, 325, 100
	
	make_text_macro 'G', area, 230, 200
	make_text_macro 'E', area, 240, 200
	make_text_macro 'T', area, 250, 200
	make_text_macro 'R', area, 270, 200
	make_text_macro 'E', area, 280, 200
	make_text_macro 'A', area, 290, 200
	make_text_macro 'D', area, 300, 200
	make_text_macro 'Y', area, 310, 200

	line_horizontal button_x, button_y, button_width, 0FF0000h
	line_horizontal button_x, button_y+button_height, button_width, 0FF0000h
	line_vertical button_x, button_y, button_height, 0FF0000h
	line_vertical button_x+button_width, button_y, button_height,0FF0000h
	
	make_text_macro 'S', area, 255, 300
	make_text_macro 'T', area, 265, 300
	make_text_macro 'A', area, 275, 300
	make_text_macro 'R', area, 285, 300
	make_text_macro 'T', area, 295, 300
	
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


