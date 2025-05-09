.Model Small
.Stack 100h
.Data
    ;main menu
    t0 DB "   _____ _   _          _  ________ "
    t1 DB "  / ____| \ | |   /\   | |/ /  ____|"
    t2 DB " | (___ |  \| |  /  \  | ' /| |__   "
    t3 DB "  \___ \| . ` | / /\ \ |  < |  __|  "
    t4 DB "  ____) | |\  |/ ____ \| . \| |____ "
    t5 DB " |_____/|_| \_/_/    \_\_|\_\______|"
    main1 DB "Press any key to start..."
    menu1 DB "1. Play Game"
    menu2 DB "2. Settings"
    menu3 DB "3. High Scores"
    menu4 DB "4. Exit"
    
    ;settings menu
    set_title DB "== SETTINGS =="
    set1 DB "1. Speed: "
    set2 DB "2. Color Theme: "
    set3 DB "3. Back"
    speed_text DB "x1 "
    
    ;color settings
    theme_text DB "Default"
    themes DB "Default","Forest","Ocean","Sunset","Neon"
    snake_color     DB 02h      ; giá tr? m?c d?nh
    food_color      DB 04h
    bonus_color     DB 05h
    border_color    DB 0Ah
    obstacle_color  DB 07h
    back_color      DB 00h
    
    theme_count     DB 4        ; s? theme b?n có
    current_theme   DB 0
    
    ; 6 byte / theme  ?  4 theme = 24 byte
    theme_colors    DB 02h,04h,05h,0Ah,07h,00h    ; Theme-0
                    DB 0Ah,0Ch,04h,08h,01h,00h    ; Theme-1
                    DB 0Eh,02h,0Dh,05h,06h,00h    ; Theme-2
                    DB 02h,0Fh,08h,09h,0Ch,00h    ; Theme-3
    
    ;high scores
    hs_title DB "== HIGH SCORES =="
    hs_empty DB "No scores yet"
    hs_prompt DB "Press any key to continue..."
    high_scores DW 5 DUP(0)
    score_names DB "AAA", "AAA", "AAA", "AAA", "AAA"
    
    ;bild
    hlths DB "Lives:",3,3,3
    ;ingame
    letadd DW ? ; dia chi cua *
    hlth DB 6 ; /2 la luong mau
    
    ;new variables for speed
    speed_level DB 1  ; 1=normal, 2=x2, 3=x3, 5=x5
    delay_count DW 5000  ; base delay value
    
    ;bonus food variables
    bonus_active DB 0  ; 0=no bonus, 1=bonus active
    bonus_timer DW 0   ; timer for bonus food
    bonus_pos DW 0     ; position of bonus food
    bonus_type DB 0    ; type of bonus (1-3)
    bonus_value DB 0   ; point value of bonus food
    bonus_size DB 0    ; visual size indicator
    
    ;obstacle variables
    obstacle_active DB 0   ; 0=no obstacles, 1=obstacles active
    obstacle_timer DW 0    ; timer for obstacle generation
    obstacle_positions DW 10 DUP(0)  ; positions of obstacles
    obstacle_count DB 0    ; number of active obstacles
    max_obstacles DB 10    ; maximum number of obstacles
    
    ;Snake Info            
    start_position equ 1000 ; vi tri o giua man hinh
    sadd DW start_position, 100 Dup(0) ;dia chi cac ky tu cua ran tren console
    snake DB 8,100 Dup(0) ; cac ky tu cua ran
    snakel DB 1 
    ;end 
    
    sc DB "Score: $"
    score DB 0
    gmov DB "Game Over"
    endtxt DB "Restart ? (y / n)"
    
    two DW 2
    map DW 1755
    et DW 80
    
    random_seed DW 0   ; for better random number generation
    enter_name_msg DB "Enter your initials: $"

.Code
start:
    MOV AX, @Data
    MOV DS, AX
    
    MOV AX, 0b800h
    MOV ES, AX 
    
    MOV AH, 0
    MOV AL, 0
    INT 10h ; set man hinh 40 x 25
    
    CLD ;clear direction flag
    
    ;hide text cursor
    MOV AH, 1
    MOV CH, 2BH
    MOV CL, 0BH
    INT 10h
    
    ;initialize random seed
    MOV AH, 00h
    INT 1Ah
    MOV random_seed, DX  
    
main_loop:
    CALL clearall
    CALL main_menu
    JMP main_loop  ; return to main menu after game over

; Main menu handler
main_menu_handler PROC
    show_menu:
        CALL clearall
        
        ; Display title
        MOV DI, 322
        LEA SI, t0
        MOV CX, 36
        d0:
            movsb
            INC DI
            LOOP d0
        
        MOV DI, 402
        LEA SI, t1
        MOV CX, 36
        d1:
            movsb
            INC DI
            LOOP d1
        
        MOV DI, 482
        LEA SI, t2
        MOV CX, 36
        d2:
            movsb
            INC DI
            LOOP d2 
        
        MOV DI, 562
        LEA SI, t3
        MOV CX, 36
        d3:
            movsb
            INC DI
            LOOP d3 
    
        MOV DI, 642
        LEA SI, t4
        MOV CX, 36
        d4:
            movsb
            INC DI
            LOOP d4
        
        MOV DI, 722
        LEA SI, t5
        MOV CX, 36
        d5:
            movsb
            INC DI
            LOOP d5
        
        ; Display menu options
        MOV DI, 962
        LEA SI, menu1
        MOV CX, 10
        m1:
            movsb
            INC DI
            LOOP m1
            
        MOV DI, 1042
        LEA SI, menu2
        MOV CX, 11
        m2:
            movsb
            INC DI
            LOOP m2
            
        MOV DI, 1122
        LEA SI, menu3
        MOV CX, 13
        m3:
            movsb
            INC DI
            LOOP m3
            
        MOV DI, 1202
        LEA SI, menu4
        MOV CX, 7
        m4:
            movsb
            INC DI
            LOOP m4
        
        ; Wait for key input
        wait_key:
            MOV AH, 0
            INT 16h
            
            CMP AL, '1'
            JE start_game
            CMP AL, '2'
            JE show_settings
            CMP AL, '3'
            JE show_highscores
            CMP AL, '4'
            JE exit_game
            
            JMP wait_key
            
    start_game:
        JMP startag
        
    show_settings:
        CALL settings_menu
        JMP show_menu
        
    show_highscores:
        CALL high_score_screen
        JMP show_menu
        
    exit_game:
        JMP ext
        
    RET
main_menu_handler ENDP

; Settings menu
settings_menu PROC
    CALL clearall
    
    ; Display title
    MOV DI, 482
    LEA SI, set_title
    MOV CX, 14
    s0:
        movsb
        INC DI
        LOOP s0
    
    ; Display speed setting
    MOV DI, 642
    LEA SI, set1
    MOV CX, 9
    s1:
        movsb
        INC DI
        LOOP s1
    
    ; Display current speed
    MOV AL, speed_level
    ADD AL, '0'
    MOV BYTE PTR ES:[DI], AL
    
    ; Display "x" for multiplication
    MOV BYTE PTR ES:[DI-1], 'x'
    
    ; Display color theme setting
    MOV DI, 722
    LEA SI, set2
    MOV CX, 15
    s2:
        movsb
        INC DI
        LOOP s2
    
    ; Display current theme
    XOR BH, BH
    MOV BL, current_theme
    MOV CL, 7  ; Theme name length
    MUL CL
    LEA SI, themes
    ADD SI, AX
    MOV CX, 7
    theme_name:
        MOVSB
        INC DI
        LOOP theme_name
    
    ; Display back option
    MOV DI, 802
    LEA SI, set3
    MOV CX, 7
    s3:
        movsb
        INC DI
        LOOP s3
    
    ; Wait for key input
    settings_wait:
        MOV AH, 0
        INT 16h
        
        CMP AL, '1'
        JE change_speed
        CMP AL, '2'
        JE change_theme
        CMP AL, '3'
        JE exit_settings
        
        JMP settings_wait
    
    change_speed:
        INC speed_level
        CMP speed_level, 6
        JNE update_delay
        MOV speed_level, 1
        
    update_delay:
        ; delay_count = 5000 / speed_level   (1?5 m?c)
        MOV     AX, 5000
        XOR     DX, DX
        MOV     BL, speed_level
        DIV     BL            ; AX = 5000 / BL
        MOV     delay_count, AX
        JMP     settings_menu
    
    change_theme:
        inc     current_theme

        mov     al, current_theme   ; AL = current_theme
        cmp     al, theme_count     ; so sánh AL v?i theme_count (ô nh?) 
        jb      short apply_ok      ; n?u current_theme < theme_count thì OK

        mov     current_theme, 0    ; ngu?c l?i, quay v? theme 0
    apply_ok:
        call    apply_theme
        jmp     settings_menu


    
    exit_settings:
        RET
settings_menu ENDP

apply_theme PROC
     push    si
     push    bx

     mov     al, current_theme
     xor     ah, ah            ; AX = theme index
     mov     bx, ax            ; BX = theme

     ; BX = BX * 6  (m?i theme 6 byte)
     shl     bx, 1             ; *2
     mov     ax, bx
     shl     ax, 2             ; *4
     add     bx, ax            ; *6  (2+4)

     lea     si, theme_colors
     add     si, bx            ; SI tr? t?i màu d?u c?a theme

     ; --- snake_color = [SI] ---
     mov     al, [si]
     mov     snake_color, al

     ; --- food_color = [SI+1] ---
     mov     al, [si+1]
     mov     food_color, al

     ; --- bonus_color = [SI+2] ---
     mov     al, [si+2]
     mov     bonus_color, al

     ; --- border_color = [SI+3] ---
     mov     al, [si+3]
     mov     border_color, al

     ; --- obstacle_color = [SI+4] ---
     mov     al, [si+4]
     mov     obstacle_color, al

     ; --- back_color = [SI+5] ---
     mov     al, [si+5]
     mov     back_color, al

     pop     bx
     pop     si
     ret
apply_theme ENDP


; High score screen
high_score_screen PROC
    CALL clearall
    
    ; Display title
    MOV DI, 482
    LEA SI, hs_title
    MOV CX, 16
    h0:
        movsb
        INC DI
        LOOP h0
    
    ; Check if there are any high scores
    CMP high_scores[0], 0
    JNE show_scores
    
    ; Display "No scores yet" message
    MOV DI, 642
    LEA SI, hs_empty
    MOV CX, 12
    h1:
        movsb
        INC DI
        LOOP h1
        
    JMP hs_wait
    
    show_scores:
        MOV DI, 642
        MOV SI, 0
        MOV CX, 5
        
    score_loop:
        PUSH CX
        
        ; Display score position (1-5)
        MOV AX, 6
        SUB AX, CX
        ADD AL, '0'
        MOV BYTE PTR ES:[DI], AL
        ADD DI, 2
        
        ; Display dot and space
        MOV BYTE PTR ES:[DI], '.'
        ADD DI, 2
        MOV BYTE PTR ES:[DI], ' '
        ADD DI, 2
        
        ; Display initials
        MOV BX, 5
        SUB BX, CX
        IMUL BX, 3  ; Each name is 3 chars
        MOV SI, BX  ; Use SI for indexing
        LEA BX, score_names
        ADD SI, BX
        
        MOV CX, 3
        init_loop:
            MOVSB
            INC DI
            LOOP init_loop
        
        ; Display space and score
        MOV BYTE PTR ES:[DI], ' '
        ADD DI, 2
        MOV BYTE PTR ES:[DI], '-'
        ADD DI, 2
        MOV BYTE PTR ES:[DI], ' '
        ADD DI, 2
        
        ; Convert score to decimal and display
        MOV BX, 5
        SUB BX, CX
        SHL BX, 1  ; Each score is a word (2 bytes)
        MOV AX, high_scores[BX]
        
        ; Skip if score is 0
        CMP AX, 0
        JE skip_score
        
        CALL display_number
        
    skip_score:
        ADD DI, 80  ; Move to next line
        POP CX
        LOOP score_loop
    
    ; Display prompt
    MOV DI, 1042
    LEA SI, hs_prompt
    MOV CX, 27
    hp:
        movsb
        INC DI
        LOOP hp
    
    hs_wait:
        MOV AH, 0
        INT 16h
        RET
high_score_screen ENDP

; Display a number in decimal
display_number PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0
    MOV BX, 10
    
    num_to_stack:
        XOR DX, DX
        DIV BX
        PUSH DX
        INC CX
        CMP AX, 0
        JNE num_to_stack
    
    print_num:
        POP DX
        ADD DL, '0'
        MOV BYTE PTR ES:[DI], DL
        ADD DI, 2
        LOOP print_num
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
display_number ENDP

; Check and update high scores
update_high_scores PROC
    MOV AL, score
    XOR AH, AH
    
    ; Check if score is higher than any high score
    MOV SI, 8  ; Start from last high score
    MOV CX, 5
    
    check_hs_loop:
        CMP AX, high_scores[SI]
        JA update_hs
        SUB SI, 2
        LOOP check_hs_loop
    
    JMP no_update
    
    update_hs:
        ; Shift lower scores down
        MOV DI, 8
        MOV BX, SI
        
        shift_loop:
            CMP DI, BX
            JBE shift_done
            MOV DX, high_scores[DI-2]
            MOV high_scores[DI], DX
            
            ; Move name too
            PUSH AX
            PUSH BX
            MOV AX, DI
            SHR AX, 1  ; DIV 2
            MOV BX, AX
            IMUL BX, 3  ; Each name is 3 bytes
            LEA DI, score_names
            ADD DI, BX
            
            MOV AX, BX
            SUB AX, 3
            LEA SI, score_names
            ADD SI, AX
            
            MOV CX, 3
            REP MOVSB
            
            POP BX
            POP AX
            
            SUB DI, 2
            JMP shift_loop
        
        shift_done:
            ; Insert new score
            MOV high_scores[BX], AX
            
            ; Ask for player initials
            CALL enter_initials
    
    no_update:
        RET
update_high_scores ENDP

; Get player initials for high score
enter_initials PROC
    ; Display prompt
    MOV AH, 2
    MOV DH, 12
    MOV DL, 10
    MOV BH, 0
    INT 10h
    
    MOV AH, 9
    LEA DX, enter_name_msg
    INT 21h
    
    ; Get 3 characters
    MOV BX, SI
    SHR BX, 1  ; DIV 2
    IMUL BX, 3  ; Each name is 3 bytes
    LEA DI, score_names
    ADD DI, BX
    
    MOV CX, 3
    get_initial:
        MOV AH, 0
        INT 16h
        
        CMP AL, 13  ; Enter key
        JE init_done
        
        ; Only accept letters
        CMP AL, 'A'
        JB get_initial
        CMP AL, 'Z'
        JBE store_char
        CMP AL, 'a'
        JB get_initial
        CMP AL, 'z'
        JA get_initial
        
        ; Convert lowercase to uppercase
        AND AL, 0DFh
        
        store_char:
            MOV [DI], AL
            INC DI
            
            ; Echo character
            MOV DL, AL
            MOV AH, 2
            INT 21h
            
            LOOP get_initial
    
    init_done:
        RET
enter_initials ENDP

main_menu PROC
    ; Call our enhanced menu handler
    CALL main_menu_handler
    RET
main_menu ENDP

startag:
    CALL clearall
    
    MOV sadd, start_position ; dat ran o vi tri bat dau
    MOV score, 0
    MOV hlth, 6
    MOV snakel, 1
    MOV snake[0], 8
    MOV obstacle_active, 0
    MOV obstacle_count, 0
    MOV bonus_active, 0
      
    CALL bild 
    
    XOR CL, CL 
    XOR DL, DL ; xoa ky tu cu o buffer
    
    ; Initialize game loop
    MOV obstacle_timer, 0
    
    read: ; kiem tra input
        ; Apply delay based on speed setting
        PUSH CX
        PUSH DX
        MOV CX, 0
        MOV DX, delay_count
        MOV AH, 86h
        INT 15h
        POP DX
        POP CX
        
        ; Update bonus food timer if active
        CMP bonus_active, 1
        JNE check_obstacle_timer
        DEC bonus_timer
        CMP bonus_timer, 0
        JNE check_obstacle_timer
        
        ; Bonus food expired
        MOV bonus_active, 0
        MOV DI, bonus_pos
        ES: MOV WORD PTR [DI], 0
        
    check_obstacle_timer:
        ; Check if it's time to add obstacles
        INC obstacle_timer
        CMP obstacle_timer, 200
        JL check_input
        
        ; Reset timer
        MOV obstacle_timer, 0
        
        ; Only add obstacles if score is high enough (5+)
        CMP score, 5
        JL check_input
        
        ; Set obstacle active flag
        MOV obstacle_active, 1
        
        ; Add new obstacle if we have room
        MOV AL, obstacle_count
        CMP AL, max_obstacles       ; FIX - Loaded into AL first
        JAE check_input
        
        CALL add_obstacle
        
    check_input:
        MOV AH, 1
        INT 16H
        CMP  AH, 48h       ; scan ?
        JE   mu
        CMP  AH, 50h       ; scan ?
        JE   md
        CMP  AH, 4Bh       ; scan ?
        JE   ml
        CMP  AH, 4Dh       ; scan ?
        JE   mr

        
        JZ auto_move
        MOV AH, 0
        INT 16H ; lay input tu buffer
        AND AL, 0dfh  ; chuyen ky tu nhap vao in thuong -> in hoa
        MOV DL, AL
    
    process_movement:
        CMP DL, 'A'
        JNE right
        CALL ml
        MOV CL, DL
        JMP update_bonus
    
    right:
        CMP DL, 'D'
        JNE up
        CALL mr
        MOV CL, DL
        JMP update_bonus
    
    up:
        CMP DL, 'W'
        JNE down
        CALL mu 
        MOV CL, DL
        JMP update_bonus
    
    down:
        CMP DL, 'S'
        JNE auto_move
        CALL md
        MOV CL, DL
        JMP update_bonus
        
    auto_move:
        ; If no key pressed, continue in last direction
        CMP CL, 'W'
        JE auto_up
        CMP CL, 'A'
        JE auto_left
        CMP CL, 'S'
        JE auto_down
        CMP CL, 'D'
        JE auto_right
        JMP update_bonus
        
    auto_up:
        CALL mu
        JMP update_bonus
        
    auto_left:
        CALL ml
        JMP update_bonus
        
    auto_down:
        CALL md
        JMP update_bonus
        
    auto_right:
        CALL mr
        
    update_bonus:
        ; Random chance to spawn bonus food
        CMP bonus_active, 1
        JE read
        
        ; Random chance based on score
        MOV AH, 00h
        INT 1AH
        ADD DX, random_seed
        MOV random_seed, DX
        
        ; Chance increases with score
        MOV AL, score
        XOR AH, AH
        SHL AX, 1  ; Score * 2 = % chance
        CMP AX, 40
        JB set_chance
        MOV AX, 40  ; Max 40% chance
        
    set_chance:
        MOV CX, 100
        XOR DX, DX
        DIV CX
        
        MOV CX, DX  ; CX = random number % 100
        CMP CX, AX  ; Compare with chance
        JA read     ; If random > chance, don't spawn
        
        CALL spawn_bonus_food
        JMP read
    
ext:
    MOV AH, 4CH
    INT 21h     
ends

; Add obstacle to game field
add_obstacle PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Generate random position
    MOV AH, 00h
    INT 1AH
    ADD DX, random_seed
    MOV random_seed, DX
    
    MOV AX, DX
    XOR DX, DX
    DIV map
    ADD DX, 162
    MOV BX, DX 
    
    ; Ensure position is valid (not on edge)
    CMP BX, 160 
    JBE find_new_pos
    CMP BX, 1920
    JAE find_new_pos
    
    MOV AX, BX
    MOV CL, 80
    DIV CL
    CMP AH, 0
    JZ find_new_pos
    
    MOV AX, BX
    ADD AX, 2
    MOV CL, 80
    DIV CL
    CMP AH, 0
    JZ find_new_pos
    
    ; Check if position is free
    MOV DI, BX
    ES: CMP WORD PTR [DI], 0
    JNE find_new_pos
    
    ; Store obstacle position
    MOV CL, obstacle_count
    XOR CH, CH
    SHL CX, 1  ; * 2 because each position is a word
    MOV SI, CX  ; FIX - Use SI instead of CX for indexing
    MOV obstacle_positions[SI], BX
    
    ; Place obstacle on screen
    XOR AH, AH
    MOV AL, current_theme
    MOV BL, 6  ; Each theme uses 6 color bytes
    MUL BL
    ADD AX, 4  ; Index of obstacle color
    MOV SI, AX  ; FIX - Use SI instead of AX for indexing
    MOV BL, theme_colors[SI]
    MOV BH, 219  ; Solid block character
    
    MOV CL, obstacle_count
    XOR CH, CH
    SHL CX, 1  ; * 2 because each position is a word
    MOV SI, CX  ; FIX - Use SI instead of CX for indexing
    MOV DI, obstacle_positions[SI]
    ES: MOV [DI], BX
    
    ; Increment obstacle count
    INC obstacle_count
    JMP done_adding
    
find_new_pos:
    ; Try a different position
    ADD random_seed, 37
    
done_adding:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
add_obstacle ENDP

; Spawn bonus food
spawn_bonus_food PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Generate random position for bonus food
    MOV AH, 00h
    INT 1AH
    ADD DX, random_seed
    MOV random_seed, DX
    
    MOV AX, DX
    XOR DX, DX
    DIV map
    ADD DX, 162
    MOV BX, DX 
    
    ; Ensure position is valid (not on edge)
    CMP BX, 160 
    JBE bonus_done
    CMP BX, 1920
    JAE bonus_done
    
    MOV AX, BX
    MOV CL, 80
    DIV CL
    CMP AH, 0
    JZ bonus_done
    
    MOV AX, BX
    ADD AX, 2
    MOV CL, 80
    DIV CL
    CMP AH, 0
    JZ bonus_done
    
    ; Check if position is free
    MOV DI, BX
    ES: CMP WORD PTR [DI], 0
    JNE bonus_done
    
    ; Generate random bonus type (1-3)
    MOV AH, 00h
    INT 1AH
    MOV AX, DX
    XOR DX, DX
    MOV CX, 3
    DIV CX
    INC DL  ; Type is 1-3
    MOV bonus_type, DL
    
    ; Set bonus value based on type
    CMP bonus_type, 1
    JE bonus_type1
    CMP bonus_type, 2
    JE bonus_type2
    JMP bonus_type3
    
bonus_type1:
    MOV bonus_value, 3
    MOV bonus_size, 1
    JMP set_bonus
    
bonus_type2:
    MOV bonus_value, 5
    MOV bonus_size, 2
    JMP set_bonus
    
bonus_type3:
    MOV bonus_value, 8
    MOV bonus_size, 3
    
set_bonus:
    ; Set bonus active and position
    MOV bonus_active, 1
    MOV bonus_pos, BX
    
    ; Set timer based on speed (faster speed = less time)
    MOV AX, 200
    MOV BL, speed_level
    DIV BL
    MOV bonus_timer, AX
    
    ; Display bonus food
    MOV DI, bonus_pos
    XOR AH, AH
    MOV AL, current_theme
    MOV BL, 6  ; Each theme uses 6 color bytes
    MUL BL
    ADD AX, 2  ; Index of bonus food color
    MOV SI, AX  ; FIX - Use SI instead of AX for indexing
    MOV BL, theme_colors[SI]
    
    ; Character based on size
    MOV AL, bonus_size
    ADD AL, '0'  ; Convert to ASCII digit
    MOV AH, BL
    ES: MOV [DI], AX
    
bonus_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
spawn_bonus_food ENDP

;Game screen 
bild PROC ; ve border, score, lives, ran va * len man hinh
    ;start point
    CALL border 

    CALL print_score
    
    LEA SI, hlths
    MOV DI, 60
    MOV CX, 9
    loph:
        MOVSB
        INC DI 
        LOOP loph
        
    ; Apply snake color based on theme
    XOR AH, AH
    MOV AL, current_theme
    MOV BL, 6  ; Each theme uses 6 color bytes
    MUL BL
    MOV SI, AX  ; FIX - Use SI instead of AX for indexing
    MOV BL, theme_colors[SI]  ; Index 0 is snake color
    MOV AH, BL
        
    XOR DX, DX 
    MOV DI, sadd ; vi tri bat dau cua ran (o giua man hinh)
    MOV DL, snake 
    MOV DH, AH  ; Color attribute
    ES: MOV [DI], DX  ; dat ran len man hinh
        
    CALL place_food
    RET
bild ENDP  

;snake move:
;left:
ml PROC ; di chuyen sang trai
    PUSH DX 
    CALL shift_addrs
    SUB sadd, 2
    
    CALL eat
    
    CALL move_snake
    POP DX
RET    
ENDP
;right:
mr PROC ; di chuyen sang phai
    PUSH DX 
    CALL shift_addrs
    ADD sadd, 2
    
    CALL eat
    
    CALL move_snake 
    
    POP DX
    
RET    
ENDP
;up:
mu PROC ; di chuyen len tren
    PUSH DX 
    CALL shift_addrs
    SUB sadd, 80
    
    CALL eat
    
    CALL move_snake
    POP DX
RET    
ENDP
;down:
md PROC ; di chuyen xuong duoi
    PUSH DX 
    CALL shift_addrs
    ADD sadd, 80
    
    CALL eat
    
    CALL move_snake
    POP DX
RET    
ENDP

shift_addrs PROC
    PUSH AX
    XOR CH, CH
    XOR BH, BH
    MOV CL, snakel
    INC CL 
    MOV AL, 2
    MUL CL
    MOV BL, AL
    
    XOR DX, DX
    
    shiftsnake:
        MOV SI, BX  ; FIX - Use SI for indexing
        SUB SI, 2
        MOV DX, sadd[SI]
        MOV sadd[BX], DX
        SUB BX, 2 ; cac phan tu trong sadd cach nhau 2
                  ; vi sadd co kieu du lieu la DW
        LOOP shiftsnake:
    POP AX
    RET
ENDP

eat PROC ; kiem tra ran co va cham voi border, *, hay tu an chinh no khong
    PUSH AX 
    PUSH CX 
    
    MOV DI, sadd 
    ES: CMP WORD PTR [DI], 0 
    JZ no
    ES: CMP BYTE PTR [DI], 20h
    JZ wall
    
    ; Check if hit obstacle (solid block character)
    ES: CMP BYTE PTR [DI], 219
    JE wallk
    
    ; Check if ate normal food
    ES: CMP WORD PTR [DI], 0404h
    JE addf
    
    ; Check if number character (1-3) for bonus food
    ES: CMP BYTE PTR [DI], '1'
    JE add_bonus
    ES: CMP BYTE PTR [DI], '2'
    JE add_bonus
    ES: CMP BYTE PTR [DI], '3'
    JE add_bonus
    
    ; Otherwise snake hit itself
    JMP wallk

    add_bonus:
        ; Get bonus value
        MOV AL, bonus_value
        ADD score, AL
        
        MOV bonus_active, 0
        MOV bonus_pos, 0
        
        ; Grow snake based on bonus size
        XOR BH, BH
        MOV BL, snakel
        MOV AL, bonus_size
        ADD BL, AL
        MOV snakel, BL
        
        ; Set all new segments to body character
        MOV CX, 0
        MOV CL, bonus_size
        XOR DI, DI       ; Xóa DI (d?t v? 0)
        MOV DL, snakel   ; T?i giá tr? 8-bit vào thanh ghi 8-bit
        MOV DI, DX       ; Gán giá tr? 16-bit vào DI
        SUB DI, CX
        
    bonus_grow_loop:
        MOV snake[DI], 8
        INC DI
        LOOP bonus_grow_loop
        
        ES: MOV WORD PTR [DI], 0
        CALL print_score
        CALL place_food
        JMP no
        
    addf:
        INC score
        MOV letadd, 0 
        XOR BH, BH
        MOV BL, snakel
        MOV snake[BX], 8
        ES: MOV WORD PTR [DI], 0
        INC snakel
        CALL print_score
        CALL place_food
        JMP no
        
    wall:
        CMP DI, 160 
        JBE wallk ; cham tuong tren
        CMP DI, 1920
        JAE wallk  ; cham tuong duoi
        MOV AX, DI
        MOV BL, 80
        DIV BL
        CMP AH, 0
        JZ wallk ; cham tuong trai
        MOV AX, DI
        ADD AX, 2
        MOV BL, 80
        DIV BL
        CMP AH, 0
        JZ wallk ; cham tuong phai
        JMP no
        
    wallk:
        XOR BH, BH
        MOV BL, hlth
        SUB hlth, 2
        CMP hlth, 0
        JNZ rest
        MOV SI, BX  ; FIX - Use SI for indexing
        ADD SI, 72
        ES: MOV WORD PTR [SI], 0
        POP CX
        POP AX
        CALL game_over 
        
    rest:
        MOV SI, BX  ; FIX - Use SI for indexing
        ADD SI, 72
        ES: MOV WORD PTR [SI], 0 
        MOV SI, BX  ; FIX - Use SI for indexing
        ADD SI, 2
        MOV hlths[SI], 0
        POP CX
        POP AX
        CALL restart
        
    no:
        POP CX
        POP AX
RET
ENDP 

place_food PROC ; dat * o vi tri ngau nhien
    PUSH AX
    PUSH DX
    lap:    
        MOV AH, 00h
        INT 1AH ; lay system time, luu o DX
        ADD DX, random_seed
        MOV random_seed, DX
        
        MOV AX, DX
        XOR DX, DX
        DIV map
        ADD DX, 162
        MOV BX, DX 
        
        MOV AX, DX  
        XOR DX, DX
        DIV two
        CMP DX, 0
        JNE lap
        
    XOR DX, DX 
    MOV AX, BX
    DIV et
    CMP DX, 0
    JE inleft
    
    XOR DX, DX    
    MOV AX, BX
    ADD AX, 2
    DIV et
    CMP DX, 0
    JE inright

    inleft:
        ADD BX, 2
        JMP check_position
        
    inright:
        SUB BX, 2
        
    check_position:
        ; Make sure food doesn't spawn on obstacles
        MOV DI, BX
        ES: CMP WORD PTR [DI], 0
        JNE lap  ; Position not empty, try again
        
    spawn:
        ; Set food color based on theme
        XOR AH, AH
        MOV AL, current_theme
        MOV CL, 6  ; Each theme uses 6 color bytes
        MUL CL
        ADD AX, 1  ; Index 1 is food color
        MOV SI, AX  ; FIX - Use SI instead of AX for indexing
        MOV CL, theme_colors[SI]
        MOV CH, 4  ; Red/food color attribute
        MOV DX, 0404h
        MOV DH, CL
        
        MOV DI, BX
        ES: MOV [DI], DX
        MOV letadd, BX
    POP DX
    POP AX 
    RET
place_food ENDP

move_snake PROC
    XOR CH, CH
    XOR SI, SI
    XOR DL, DL
    MOV CL, snakel
    XOR BX, BX
    
    ; Apply snake color based on theme
    PUSH AX
    XOR AH, AH
    MOV AL, current_theme
    MOV BL, 6  ; Each theme uses 6 color bytes
    MUL BL
    MOV SI, AX  ; FIX - Use SI instead of AX for indexing
    MOV BL, theme_colors[SI]  ; Index 0 is snake color
    MOV AH, BL
    POP AX
    
    XOR SI, SI  ; Reset SI for next loop
    
    l1mr:
        MOV DI, sadd[SI]
        MOV DL, snake[BX]
        MOV DH, AH  ; Use theme color
        ES: MOV [DI], DX
        ADD SI, 2
        INC BX
        LOOP l1mr
    MOV DI, sadd[SI] 
    ES: MOV WORD PTR [DI], 0
    RET
move_snake ENDP

border PROC ; ve border
    MOV AH, 0
    MOV AL, 0
    INT 10h  ; chuyen man hinh -> 40 x 25
    
    ; Set border color based on theme
    XOR AH, AH
    MOV AL, current_theme
    MOV BL, 6  ; Each theme uses 6 color bytes
    MUL BL
    ADD AX, 3  ; Index 3 is border color
    MOV SI, AX  ; FIX - Use SI instead of AX for indexing
    MOV BL, theme_colors[SI]
    MOV BH, BL
    
    MOV AH, 6
    MOV AL, 0 
    ; BH already set to border color
    
    MOV CH, 1
    MOV CL, 0
    MOV DH, 1
    MOV DL, 39
    INT 10h ; tren
  
    MOV CH, 1
    MOV CL, 0
    MOV DH, 24
    MOV DL, 0
    INT 10h ; trai
   
    MOV CH, 24
    MOV CL, 0
    MOV DH, 24
    MOV DL, 39
    INT 10h ; duoi
    
    MOV CH, 1
    MOV CL, 39
    MOV DH, 24
    MOV DL, 39
    INT 10h ; phai

RET
ENDP

print_score PROC
    MOV AH, 2
    MOV DH, 0
    MOV DL, 0
    MOV BH, 0
    INT 10h ; di chuyen con tro ve vi tri (0, 0)
    
    MOV AH, 9
    LEA DX, sc
    INT 21h
    
    MOV AX, 0
    MOV AL, score
    MOV CX, 0
    MOV BX, 10
    PUSH_STACK:
        MOV DX, 0
        DIV BX
        INC CX
        PUSH DX
        CMP AX, 0
        JNE PUSH_STACK
        
    POP_STACK:
        POP AX  ; AX = Stack.top() ; Stack.pop()
        MOV DL, AL
        ADD DL, '0'
        MOV AH, 2
        INT 21h
        LOOP POP_STACK 
    RET
print_score ENDP

restart PROC
    CALL clearall
    MOV snakel, 1
    MOV BX, start_position
    MOV sadd, BX  
    MOV snake[0], 8
    MOV bonus_active, 0
    JMP startag
ENDP

game_over PROC
    MOV hlths[6], 3
    MOV hlths[7], 3
    MOV hlths[8], 3
    MOV hlth, 6
    MOV snakel, 1
    
    ; Update high scores
    CALL update_high_scores
    
    MOV DI, 992
    LEA SI, gmov
    MOV CX, 9
    loop1:
        movsb 
        INC DI
        LOOP loop1
        
    MOV DI, 1064
    LEA SI, endtxt
    MOV CX, 17
    loop2:
        movsb 
        INC DI
        LOOP loop2 
        
    option:         
        MOV AH, 7
        INT 21h
        CMP AL, 'y'   
        JE restart_game
        CMP AL, 'n'
        JE main_menu
        JMP option
        
    restart_game:
        MOV score, 0
        JMP startag
        
    to_main:
        MOV score, 0
        JMP main_loop
ENDP

clearall PROC
    XOR CX, CX
    MOV DH, 24
    MOV DL, 39
    MOV BH, 7
    MOV AX, 700h
    INT 10h 
RET
ENDP
