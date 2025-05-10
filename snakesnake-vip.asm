; SNAKE GAME IN ASSEMBLY 8086


.MODEL SMALL
.STACK 100h
.DATA
    ; Constants
    SCREEN_WIDTH    EQU 80
    SCREEN_HEIGHT   EQU 25
    GAME_AREA_WIDTH EQU 78
    GAME_AREA_HEIGHT EQU 23
    
    ; Snake properties
    snake_head_x    DW 40      ; Initial X position
    snake_head_y    DW 12      ; Initial Y position
    snake_length    DW 5       ; Initial length
    snake_direction DB 0       ; 0=right, 1=left, 2=up, 3=down
    snake_speed     DW 3     ; M?c d?nh (Easy) � 60ms   
    
    ; Game state variables
    game_over       DB 0       ; 0=playing, 1=game over
    score           DW 0       ; Player score
    difficulty      DB 1       ; 1=Easy, 2=Medium, 3=Hard
    current_theme   DB 1       ; 1=Classic, 2=Blue, 3=Red
    game_paused     DB 0       ; 0=not paused, 1=paused
    
    ; Food properties
    food_x          DW 60      ; Initial food X position
    food_y          DW 12      ; Initial food Y position
    
    ; Snake body segments storage (max 100 segments)
    snake_body_x    DW 100 DUP(0)
    snake_body_y    DW 100 DUP(0)
    
    ; Obstacles (for medium and hard difficulties)
    max_obstacles   DB 20      ; Maximum number of obstacles
    obstacle_count  DB 0       ; Current number of obstacles
    obstacle_x      DW 20 DUP(0) ; Obstacle X positions
    obstacle_y      DW 20 DUP(0) ; Obstacle Y positions 
    
    
    old_tail_x      DW 0
    old_tail_y      DW 0
    
    ; Colors
    head_color      DB 10      ; Green
    body_color      DB 2       ; Dark green
    food_color      DB 12      ; Red
    border_color    DB 15      ; White
    obstacle_color  DB 4       ; Red
    bg_color        DB 0       ; Black
    
    ; Messages
    title_msg       DB 'SNAKE GAME', 0
    score_msg       DB 'Score: ', 0
    game_over_msg   DB 'GAME OVER! Press SPACE to restart or ESC to exit', 0
    pause_msg       DB 'GAME PAUSED - Press P to continue', 0
    
    ; Menu options
    menu_title      DB 'SNAKE GAME MENU', 0
    menu_start      DB '1. Start Game', 0
    menu_settings   DB '2. Settings', 0
    menu_exit       DB '3. Exit', 0
    
    ; Settings menu
    settings_title  DB 'SETTINGS', 0
    settings_theme  DB '1. Change Theme', 0
    settings_diff   DB '2. Difficulty', 0
    settings_back   DB '3. Back', 0
    
    ; Theme menu
    theme_title     DB 'SELECT THEME', 0
    theme_classic   DB '1. Classic', 0
    theme_blue      DB '2. Blue', 0
    theme_red       DB '3. Red', 0
    theme_back      DB '4. Back', 0
    
    ; Difficulty menu
    diff_title      DB 'SELECT DIFFICULTY', 0
    diff_easy       DB '1. Easy', 0
    diff_medium     DB '2. Medium', 0
    diff_hard       DB '3. Hard', 0
    diff_back       DB '4. Back', 0
    
    ; Difficulty descriptions
    diff_easy_desc  DB 'Slow snake, no obstacles', 0
    diff_med_desc   DB 'Medium speed, some obstacles', 0
    diff_hard_desc  DB 'Fast snake, many obstacles, special effects', 0
    
    ; Controls info
    controls_msg    DB 'Controls: WASD or Arrow Keys, P to pause, ESC to quit', 0
    
    ; Current menu state
    current_menu    DB 0       ; 0=main menu, 1=game, 2=settings, 3=theme, 4=difficulty
    
    ; Random number seed
    random_seed     DW 1234
    
    ; Timer variables
    last_time       DW 0       ; Last update time
    
    ; Direction control
    last_direction  DB 0       ; To prevent 180 degree turns

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    ; Set video mode (80x25 text mode with color)
    MOV AX, 3
    INT 10h
    
    ; Hide cursor
    MOV AH, 1
    MOV CX, 2000h      ; Set cursor out of view
    INT 10h
    
    ; Initialize random seed with timer value
    MOV AH, 0
    INT 1Ah            ; Get timer count in CX:DX
    MOV random_seed, DX
    
    ; Initialize the snake body positions
    CALL InitializeSnake
    
    ; Start with main menu
    MOV current_menu, 0
    
main_loop:
    CMP current_menu, 0
    JE show_main_menu
    CMP current_menu, 1
    JE start_game
    CMP current_menu, 2
    JE show_settings_menu
    CMP current_menu, 3
    JE show_theme_menu
    CMP current_menu, 4
    JE show_difficulty_menu
    JMP main_loop      ; Default case, loop back
    
show_main_menu:
    CALL ClearScreen
    CALL DisplayMainMenu
    CALL WaitForMenuInput
    JMP main_loop
    
show_settings_menu:
    CALL ClearScreen
    CALL DisplaySettingsMenu
    CALL WaitForMenuInput
    JMP main_loop
    
show_theme_menu:
    CALL ClearScreen
    CALL DisplayThemeMenu
    CALL WaitForMenuInput
    JMP main_loop
    
show_difficulty_menu:
    CALL ClearScreen
    CALL DisplayDifficultyMenu
    CALL WaitForMenuInput
    JMP main_loop
    
start_game:
    CALL ClearScreen
    CALL InitializeGame
    CALL PlayGame
    MOV current_menu, 0    ; Return to main menu after game ends
    JMP main_loop
    
exit_game:
    ; Restore text mode
    MOV AX, 3
    INT 10h
    
    ; Show cursor
    MOV AH, 1
    MOV CX, 0607h
    INT 10h
    
    ; Exit to DOS
    MOV AX, 4C00h
    INT 21h
MAIN ENDP

; Initialize snake's initial body segments
InitializeSnake PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, snake_length
    MOV BX, 0          ; Index for body array
    
init_snake_loop:
    MOV AX, snake_head_x
    SUB AX, BX         ; Each segment is to the left of the head initially
    
    ; Calculate offset in the array (BX * 2)
    PUSH BX
    SHL BX, 1          ; BX = BX * 2
    MOV snake_body_x[BX], AX
    
    MOV AX, snake_head_y
    MOV snake_body_y[BX], AX
    
    POP BX             ; Restore original BX
    
    INC BX
    LOOP init_snake_loop
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
InitializeSnake ENDP

; Initialize game state
InitializeGame PROC
    PUSH AX
    
    MOV game_over, 0
    MOV score, 0
    MOV game_paused, 0
    
    ; Reset snake position and direction
    MOV snake_head_x, 40
    MOV snake_head_y, 12
    MOV snake_length, 5
    MOV snake_direction, 0    ; Moving right
    MOV last_direction, 0     ; Initialize last direction
    
    ; Set snake speed based on difficulty
    MOV AL, difficulty
    CMP AL, 1
    JE easy_speed
    CMP AL, 2
    JE medium_speed
    
    ; Hard speed
    MOV snake_speed, 3
    JMP speed_set
    
medium_speed:
    MOV snake_speed, 3
    JMP speed_set
    
easy_speed:
    MOV snake_speed, 3
    
speed_set:
    ; Initialize snake body
    CALL InitializeSnake
    
    ; Generate initial food
    CALL GenerateFood
    
    ; Generate obstacles based on difficulty
    MOV AL, difficulty
    CMP AL, 1
    JE no_obstacles
    
    ; Medium or Hard difficulty
    CALL GenerateObstacles
    
no_obstacles:
    ; Initialize last update time
    MOV AH, 0
    INT 1Ah
    MOV last_time, DX
    
    ; Clear keyboard buffer
    MOV AH, 0Ch
    MOV AL, 0
    INT 21h
    
    POP AX
    RET
InitializeGame ENDP

; Main game loop
PlayGame PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CALL RenderGame    ; Initial rendering
    
game_loop:
    ; Check if game is over
    CMP game_over, 1
    JE game_end
    
    ; Check for key press (non-blocking)
    CALL ProcessInput
    
    ; Check if game is paused
    CMP game_paused, 1
    JE game_loop
    
    
    ; Move snake in current direction
    MOV AL, snake_direction
    MOV last_direction, AL
    CALL MoveSnake
    
    ; Check for game over
    CMP game_over, 1
    JE game_end
    
    
    CALL UpdateScreen
    
    JMP game_loop
    
game_end:
    ; Display game over message
    CALL DisplayGameOver
    
restart_check:
    ; Check for key press
    MOV AH, 1
    INT 16h
    JZ restart_check    ; No key pressed
    
    ; Get the key
    MOV AH, 0
    INT 16h
    
    CMP AL, ' '        ; Space key
    JE restart_game
    
    CMP AL, 27         ; ESC key
    JE exit_to_menu
    
    JMP restart_check
    
restart_game:
    ; Clear keyboard buffer
    MOV AH, 0Ch
    MOV AL, 0
    INT 21h
    
    CALL InitializeGame
    JMP game_loop
    
exit_to_menu:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PlayGame ENDP

; Process keyboard input - non-blocking
ProcessInput PROC
    PUSH AX
    PUSH BX
    
    ; Check if key is pressed (non-blocking)
    MOV AH, 1
    INT 16h
    JZ no_input    ; No key pressed
    
    ; Get the key
    MOV AH, 0
    INT 16h
    
    ; First check scan codes for arrow keys
    CMP AH, 48h    ; Up arrow
    JE up_pressed
    
    CMP AH, 50h    ; Down arrow
    JE down_pressed
    
    CMP AH, 4Bh    ; Left arrow
    JE left_pressed
    
    CMP AH, 4Dh    ; Right arrow
    JE right_pressed
    
    ; Then check ASCII for WASD keys
    CMP AL, 'w'
    JE up_pressed
    CMP AL, 'W'
    JE up_pressed
    
    CMP AL, 's'
    JE down_pressed
    CMP AL, 'S'
    JE down_pressed
    
    CMP AL, 'a'
    JE left_pressed
    CMP AL, 'A'
    JE left_pressed
    
    CMP AL, 'd'
    JE right_pressed
    CMP AL, 'D'
    JE right_pressed
    
    CMP AL, 'p'
    JE pause_toggle
    CMP AL, 'P'
    JE pause_toggle
    
    CMP AL, 27     ; ESC key
    JE quit_game
    
    JMP no_input
    
up_pressed:
    ; Can't go up if currently going down
    MOV AL, last_direction
    CMP AL, 3      ; Down
    JE no_input
    
    MOV snake_direction, 2
    JMP input_done
    
down_pressed:
    ; Can't go down if currently going up
    MOV AL, last_direction
    CMP AL, 2      ; Up
    JE no_input
    
    MOV snake_direction, 3
    JMP input_done
    
left_pressed:
    ; Can't go left if currently going right
    MOV AL, last_direction
    CMP AL, 0      ; Right
    JE no_input
    
    MOV snake_direction, 1
    JMP input_done
    
right_pressed:
    ; Can't go left if currently going right
    MOV AL, last_direction
    CMP AL, 1      ; Left
    JE no_input
    
    MOV snake_direction, 0
    JMP input_done
    
pause_toggle:
    MOV AL, game_paused
    XOR AL, 1      ; Toggle pause
    MOV game_paused, AL
    
    CMP AL, 1
    JNE input_done
    
    ; If paused, show pause message
    CALL RenderGame
    
    MOV AH, 2
    MOV DH, 12     ; Row 12
    MOV DL, 25     ; Column 25
    INT 10h
    
    MOV SI, OFFSET pause_msg
    CALL PrintString
    
    JMP input_done
    
quit_game:
    MOV game_over, 1
    
input_done:
    ; Clear keyboard buffer
    MOV AH, 0Ch
    MOV AL, 0
    INT 21h
    
no_input:
    POP BX
    POP AX
    RET
ProcessInput ENDP

; Move the snake based on current direction
MoveSnake PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    ;--- Luu l?i du�i cu (segment cu?i c�ng) ---
    MOV CX, snake_length
    DEC CX               ; index cu?i = length-1
    SHL CX, 1            ; CX = offset = index*2
    ; CX d� ch?a offset = index*2
    MOV SI, CX
   ; load du�i cu X
    MOV AX, snake_body_x[SI]
    MOV old_tail_x, AX
  ; load du�i cu Y
    MOV AX, snake_body_y[SI]
    MOV old_tail_y, AX
    
    ; Store the current head position as first body segment
    MOV CX, snake_length
    DEC CX    ; Skip the last segment (will be removed if no food eaten)
    
    ; Shift all body segments
shift_loop:
    CMP CX, 0
    JE shift_done
    
    MOV BX, CX
    DEC BX          ; Calculate source index (current - 1)
    
    ; Calculate offset for destination (CX*2)
    PUSH BX
    MOV BX, CX
    SHL BX, 1      ; BX = CX * 2
    MOV DI, BX     ; DI = destination offset
    POP BX
    
    ; Calculate offset for source (BX*2)
    PUSH BX
    SHL BX, 1      ; BX = BX * 2
    MOV SI, BX     ; SI = source offset
    POP BX
    
    ; Move X coordinate
    MOV AX, snake_body_x[SI]
    MOV snake_body_x[DI], AX
    
    ; Move Y coordinate
    MOV AX, snake_body_y[SI]
    MOV snake_body_y[DI], AX
    
    DEC CX
    JMP shift_loop
    
shift_done:
    ; First segment gets the current head position
    MOV AX, snake_head_x
    MOV snake_body_x[0], AX
    
    MOV AX, snake_head_y
    MOV snake_body_y[0], AX
    
    ; Move head based on direction
    MOV AL, snake_direction
    
    CMP AL, 0
    JE move_right
    
    CMP AL, 1
    JE move_left
    
    CMP AL, 2
    JE move_up
    
    ; Direction 3 - move down
    INC snake_head_y
    JMP check_collisions
    
move_right:
    INC snake_head_x
    JMP check_collisions
    
move_left:
    DEC snake_head_x
    JMP check_collisions
    
move_up:
    DEC snake_head_y
    
check_collisions:
    ; Check for collisions with walls
    MOV AX, snake_head_x
    CMP AX, 0
    JLE collision
    
    CMP AX, GAME_AREA_WIDTH
    JGE collision
    
    MOV AX, snake_head_y
    CMP AX, 0
    JLE collision
    
    CMP AX, GAME_AREA_HEIGHT
    JGE collision
    
    ; Check collision with snake body
    MOV CX, snake_length
    DEC CX    ; Skip the head
    MOV SI, 0
    
body_collision_check:
    CMP CX, 0
    JE check_obstacles
    
    PUSH SI
    SHL SI, 1      ; SI = SI * 2 (calculate offset)
    
    MOV AX, snake_body_x[SI]
    CMP AX, snake_head_x
    JNE next_segment
    
    MOV AX, snake_body_y[SI]
    CMP AX, snake_head_y
    JE body_collision
    
next_segment:
    POP SI
    INC SI
    DEC CX
    JMP body_collision_check
    
body_collision:
    POP SI  ; Restore stack balance
    JMP collision
    
    ; Check collision with obstacles
check_obstacles:
    MOV CL, obstacle_count
    XOR CH, CH    ; Clear CH (we only need 8-bit count)
    MOV SI, 0
    
obstacle_collision_check:
    CMP CX, 0
    JE check_food    ; No obstacles or done checking
    
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    
    MOV AX, obstacle_x[SI]
    CMP AX, snake_head_x
    JNE next_obstacle
    
    MOV AX, obstacle_y[SI]
    CMP AX, snake_head_y
    JE obstacle_collision
    
next_obstacle:
    POP SI
    INC SI
    DEC CX
    JMP obstacle_collision_check
    
obstacle_collision:
    POP SI  ; Restore stack balance
    JMP collision
    
    ; Check if snake ate food
check_food:
    MOV AX, snake_head_x
    CMP AX, food_x
    JNE move_done
    
    MOV AX, snake_head_y
    CMP AX, food_y
    JNE move_done
    
    ; Snake ate food
    ; Increase score
    ADD score, 10
    
    ; Increase snake length
    INC snake_length
    
    ; Generate new food
    CALL GenerateFood
    
    ; If on hard difficulty, occasionally add new obstacle
    CMP difficulty, 3
    JNE move_done
    
    ; 25% chance of new obstacle on hard
    CALL Random
    AND AX, 3    ; Value 0-3
    CMP AX, 0
    JNE move_done
    
    CALL AddObstacle
    
    JMP move_done
    
collision:
    MOV game_over, 1
    
move_done:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MoveSnake ENDP

; Render the game screen
RenderGame PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Clear screen
    ;CALL ClearScreen
    
    ; Draw border
    CALL DrawBorder
    
    ; Draw snake
    CALL DrawSnake
    
    ; Draw food
    CALL DrawFood
    
    ; Draw obstacles
    CALL DrawObstacles
    
    ; Display score
    MOV AH, 2
    MOV DH, 0    ; Row 0
    MOV DL, 2    ; Column 2
    INT 10h
    
    MOV SI, OFFSET score_msg
    CALL PrintString
    
    MOV AX, score
    CALL PrintNumber
    
    ; Display difficulty
    MOV AH, 2
    MOV DH, 0      ; Row 0
    MOV DL, 60     ; Column 60
    INT 10h
    
    MOV SI, OFFSET diff_title
    CALL PrintString
    
    MOV AH, 2
    MOV DH, 0      ; Row 0
    MOV DL, 75     ; Column 75
    INT 10h
    
    MOV AL, difficulty
    ADD AL, '0'    ; Convert to ASCII
    MOV AH, 0Eh
    INT 10h
    
    ; Display controls at bottom
    MOV AH, 2
    MOV DH, 24      ; Bottom row
    MOV DL, 10      ; Column 10
    INT 10h
    
    MOV SI, OFFSET controls_msg
    CALL PrintString
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
RenderGame ENDP

; Draw game border
DrawBorder PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Set color for border
    MOV AH, 0Eh
    MOV BL, border_color
    
    ; Draw top border
    MOV CX, GAME_AREA_WIDTH+1
    MOV DH, 0    ; Row 0
    MOV DL, 0    ; Start at column 0
    
top_border:
    PUSH CX
    
    ; Position cursor
    MOV AH, 2
    INT 10h
    
    ; Draw character
    MOV AH, 0Eh
    MOV AL, '-'
    INT 10h
    
    ; Next column
    INC DL
    POP CX
    LOOP top_border
    
    ; Draw bottom border
    MOV CX, GAME_AREA_WIDTH+1
    MOV DH, GAME_AREA_HEIGHT+1
    MOV DL, 0
    
bottom_border:
    PUSH CX
    
    ; Position cursor
    MOV AH, 2
    INT 10h
    
    ; Draw character
    MOV AH, 0Eh
    MOV AL, '-'
    INT 10h
    
    ; Next column
    INC DL
    POP CX
    LOOP bottom_border
    
    ; Draw left border
    MOV CX, GAME_AREA_HEIGHT
    MOV DH, 1    ; Start at row 1
    MOV DL, 0    ; Column 0
    
left_border:
    PUSH CX
    
    ; Position cursor
    MOV AH, 2
    INT 10h
    
    ; Draw character
    MOV AH, 0Eh
    MOV AL, '|'
    INT 10h
    
    ; Next row
    INC DH
    POP CX
    LOOP left_border
    
    ; Draw right border
    MOV CX, GAME_AREA_HEIGHT
    MOV DH, 1    ; Start at row 1
    MOV DL, GAME_AREA_WIDTH
    
right_border:
    PUSH CX
    
    ; Position cursor
    MOV AH, 2
    INT 10h
    
    ; Draw character
    MOV AH, 0Eh
    MOV AL, '|'
    INT 10h
    
    ; Next row
    INC DH
    POP CX
    LOOP right_border
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawBorder ENDP

; Draw the snake
DrawSnake PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Draw head
    MOV DH, BYTE PTR snake_head_y
    MOV DL, BYTE PTR snake_head_x
    
    MOV AH, 2       ; Set cursor position
    INT 10h
    
    MOV AH, 09h     ; Display character
    MOV AL, 'O'     ; Head character
    MOV BL, head_color
    MOV CX, 1       ; Only once
    INT 10h
    
    ; Draw body
    MOV CX, snake_length
    DEC CX          ; Skip the head
    MOV SI, 0
    
draw_body_loop:
    CMP CX, 0
    JE draw_body_done
    
    PUSH CX
    PUSH SI
    
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    
    MOV DH, BYTE PTR snake_body_y[SI]
    MOV DL, BYTE PTR snake_body_x[SI]
    
    MOV AH, 2       ; Set cursor position
    INT 10h
    
    MOV AH, 09h     ; Display character
    MOV AL, 'o'     ; Body character
    MOV BL, body_color
    MOV CX, 1       ; Only once
    INT 10h
    
    POP SI
    POP CX
    INC SI
    DEC CX
    JMP draw_body_loop
    
draw_body_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawSnake ENDP

; Draw the food
DrawFood PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV DH, BYTE PTR food_y
    MOV DL, BYTE PTR food_x
    
    MOV AH, 2       ; Set cursor position
    INT 10h
    
    MOV AH, 09h     ; Display character
    MOV AL, '*'     ; Food character
    MOV BL, food_color
    MOV CX, 1       ; Only once
    INT 10h
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawFood ENDP

; Draw obstacles
DrawObstacles PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Get obstacle count
    MOV CL, obstacle_count
    XOR CH, CH
    MOV SI, 0
    
draw_obstacle_loop:
    CMP CX, 0
    JE draw_obstacles_done
    
    PUSH CX
    PUSH SI
    
    SHL SI, 1      ; SI = SI * 2 (calculate offset)
    
    MOV DH, BYTE PTR obstacle_y[SI]
    MOV DL, BYTE PTR obstacle_x[SI]
    
    MOV AH, 2       ; Set cursor position
    INT 10h
    
    MOV AH, 09h     ; Display character
    MOV AL, '#'     ; Obstacle character
    MOV BL, obstacle_color
    MOV CX, 1       ; Only once
    INT 10h
    
    POP SI
    POP CX
    INC SI
    DEC CX
    JMP draw_obstacle_loop
    
draw_obstacles_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawObstacles ENDP

;--------------------------------------------------------
; Ch? c?p nh?t tail cu (erase), head m?i (draw) v� score
;--------------------------------------------------------
UpdateScreen PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ;-- Erase tail cu --
    MOV AX, old_tail_y
    MOV DH, AL

    ;-- L?y old_tail_x v�o DL --
    MOV AX, old_tail_x
    MOV DL, AL
    MOV AH, 2
    INT 10h
    MOV AH, 0Eh
    MOV AL, ' '      ; ho?c k� t? n?n
    INT 10h

    ;-- V? d?u m?i -- 
    MOV AX, snake_head_y
    MOV DH, AL
    MOV AX, snake_head_x
    MOV DL, AL
    MOV AH, 2
    INT 10h
    MOV AH, 09h
    MOV AL, 'O'
    MOV BL, head_color
    MOV CX, 1
    INT 10h

    ;-- V? segment body d?u ti�n (ch? head cu) --
    MOV SI, 0                  ; offset = 0*2
    MOV AX, snake_body_y[SI]   ; AX = word [snake_body_y + SI]
    MOV DH, AL                 ; DH = low-byte = Y

    MOV AX, snake_body_x[SI]   ; AX = word [snake_body_x + SI]
    MOV DL, AL                 ; DL = low-byte = X  

    MOV AH, 2
    INT 10h
    MOV AH, 09h
    MOV AL, 'o'
    MOV BL, body_color
    MOV CX, 1
    INT 10h

    ;-- C?p nh?t score ? g�c (n?u c?n) --
    MOV AH, 2
    MOV DH, 0
    MOV DL, 7       ; c?t sau �Score: �
    INT 10h
    MOV AX, score
    CALL PrintNumber 
    
    CALL DrawFood

    POP DX
    POP CX
    POP BX
    POP AX
    RET
UpdateScreen ENDP


; Generate food at random position
GenerateFood PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
generate_food_retry:
    ; Generate random X position (1 to GAME_AREA_WIDTH-1)
    CALL Random
    MOV DX, 0
    MOV BX, GAME_AREA_WIDTH-1
    DIV BX          ; DX = remainder (0 to WIDTH-2)
    INC DX          ; Adjust to 1 to WIDTH-1
    MOV food_x, DX
    
    ; Generate random Y position (1 to GAME_AREA_HEIGHT-1)
    CALL Random
    MOV DX, 0
    MOV BX, GAME_AREA_HEIGHT-1
    DIV BX          ; DX = remainder (0 to HEIGHT-2)
    INC DX          ; Adjust to 1 to HEIGHT-1
    MOV food_y, DX
    
    ; Check if food overlaps with snake head
    MOV AX, food_x
    CMP AX, snake_head_x
    JNE check_body_overlap
    
    MOV AX, food_y
    CMP AX, snake_head_y
    JE generate_food_retry
    
    ; Check if food overlaps with snake body
check_body_overlap:
    MOV CX, snake_length
    MOV SI, 0
    
check_body_loop:
    CMP CX, 0
    JE check_obstacle_overlap
    
    PUSH SI
    SHL SI, 1      ; SI = SI * 2 (calculate offset)
    
    MOV AX, snake_body_x[SI]
    CMP AX, food_x
    JNE next_body_check
    
    MOV AX, snake_body_y[SI]
    CMP AX, food_y
    JE food_body_overlap
    
next_body_check:
    POP SI
    INC SI
    DEC CX
    JMP check_body_loop
    
food_body_overlap:
    POP SI  ; Restore stack balance
    JMP generate_food_retry
    
    ; Check if food overlaps with obstacles
check_obstacle_overlap:
    MOV CL, obstacle_count
    XOR CH, CH
    MOV SI, 0
    
check_obstacle_loop:
    CMP CX, 0
    JE food_valid    ; No more obstacles to check
    
    PUSH SI
    SHL SI, 1      ; SI = SI * 2 (calculate offset)
    
    MOV AX, obstacle_x[SI]
    CMP AX, food_x
    JNE next_obstacle_check
    
    MOV AX, obstacle_y[SI]
    CMP AX, food_y
    JE food_obstacle_overlap
    
next_obstacle_check:
    POP SI
    INC SI
    DEC CX
    JMP check_obstacle_loop
    
food_obstacle_overlap:
    POP SI  ; Restore stack balance
    JMP generate_food_retry
    
food_valid:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GenerateFood ENDP

; Generate obstacles based on difficulty
GenerateObstacles PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Clear existing obstacles
    MOV obstacle_count, 0
    
    ; Skip if easy difficulty
    CMP difficulty, 1
    JE obstacles_done
    
    ; Determine number of obstacles based on difficulty
    MOV BL, difficulty
    DEC BL          ; 1 for medium, 2 for hard
    MOV AL, 7       ; Base number of obstacles
    MUL BL          ; AL = 7 * difficulty modifier
    MOV CL, AL      ; Number of obstacles to generate
    
    ; For hard mode, add some more for extra challenge
    CMP difficulty, 3
    JNE set_obstacle_count
    ADD CL, 6
    
set_obstacle_count:
    ; Make sure not to exceed max obstacles
    CMP CL, max_obstacles
    JLE obstacle_count_ok
    MOV CL, max_obstacles
    
obstacle_count_ok:
    MOV obstacle_count, CL
    MOV SI, 0      ; Obstacle index
    
generate_obstacles_loop:
    CMP SI, CX
    JGE obstacles_done
    
    ; Generate random X position (1 to GAME_AREA_WIDTH-1)
    CALL Random
    MOV DX, 0
    PUSH BX
    MOV BX, GAME_AREA_WIDTH-1
    DIV BX          ; DX = remainder (0 to WIDTH-2)
    POP BX
    INC DX          ; Adjust to 1 to WIDTH-1
    
    ; Store X position using index
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV obstacle_x[SI], DX
    POP SI
    
    ; Generate random Y position (1 to GAME_AREA_HEIGHT-1)
    CALL Random
    MOV DX, 0
    PUSH BX
    MOV BX, GAME_AREA_HEIGHT-1
    DIV BX          ; DX = remainder (0 to HEIGHT-2)
    POP BX
    INC DX          ; Adjust to 1 to HEIGHT-1
    
    ; Store Y position using index
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV obstacle_y[SI], DX
    POP SI
    
    ; Check if obstacle overlaps with snake or starting area
    ; Give some space around starting position
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV AX, obstacle_x[SI]
    POP SI
    
    SUB AX, snake_head_x
    JNS check_pos_x_diff  ; Jump if not negative
    NEG AX           ; Take absolute value
    
check_pos_x_diff:
    CMP AX, 5
    JL generate_obstacles_loop  ; Too close to snake head X
    
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV AX, obstacle_y[SI]
    POP SI
    
    SUB AX, snake_head_y
    JNS check_pos_y_diff  ; Jump if not negative
    NEG AX           ; Take absolute value
    
check_pos_y_diff:
    CMP AX, 5
    JL generate_obstacles_loop  ; Too close to snake head Y
    
    ; Check if overlaps with existing obstacles
    PUSH SI          ; Save current obstacle index
    MOV BX, 0        ; Start checking from first obstacle
    
check_existing_obstacles:
    CMP BX, SI
    JGE obstacle_position_valid
    
    ; Compare X positions
    PUSH SI
    PUSH BX
    
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    SHL BX, 1       ; BX = BX * 2 (calculate offset)
    
    MOV AX, obstacle_x[SI]
    CMP AX, obstacle_x[BX]
    
    POP BX
    POP SI
    
    JNE next_obstacle_overlap_check
    
    ; Compare Y positions
    PUSH SI
    PUSH BX
    
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    SHL BX, 1       ; BX = BX * 2 (calculate offset)
    
    MOV AX, obstacle_y[SI]
    CMP AX, obstacle_y[BX]
    
    POP BX
    POP SI
    
    JE obstacle_overlap_found
    
next_obstacle_overlap_check:
    INC BX
    JMP check_existing_obstacles
    
obstacle_overlap_found:
    POP SI           ; Restore obstacle index
    JMP generate_obstacles_loop
    
obstacle_position_valid:
    POP SI           ; Restore obstacle index
    
    INC SI          ; Next obstacle
    JMP generate_obstacles_loop
    
obstacles_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GenerateObstacles ENDP

; Add a single new obstacle (for hard mode during gameplay)
AddObstacle PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Check if we already have max obstacles
    MOV AL, obstacle_count
    CMP AL, max_obstacles
    JGE add_obstacle_done
    
    ; Get current obstacle index
    XOR AH, AH
    MOV SI, AX      ; SI = obstacle_count (current index)
    
add_obstacle_retry:
    ; Generate random X position (1 to GAME_AREA_WIDTH-1)
    CALL Random
    MOV DX, 0
    PUSH BX
    MOV BX, GAME_AREA_WIDTH-1
    DIV BX          ; DX = remainder (0 to WIDTH-2)
    POP BX
    INC DX          ; Adjust to 1 to WIDTH-1
    
    ; Store X position
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV obstacle_x[SI], DX
    POP SI
    
    ; Generate random Y position (1 to GAME_AREA_HEIGHT-1)
    CALL Random
    MOV DX, 0
    PUSH BX
    MOV BX, GAME_AREA_HEIGHT-1
    DIV BX          ; DX = remainder (0 to HEIGHT-2)
    POP BX
    INC DX          ; Adjust to 1 to HEIGHT-1
    
    ; Store Y position
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV obstacle_y[SI], DX
    POP SI
    
    ; Check if overlaps with snake head
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV AX, obstacle_x[SI]
    POP SI
    
    CMP AX, snake_head_x
    JNE check_obstacle_body_overlap
    
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV AX, obstacle_y[SI]
    POP SI
    
    CMP AX, snake_head_y
    JE add_obstacle_retry
    
    ; Check if overlaps with snake body
check_obstacle_body_overlap:
    MOV CX, snake_length
    MOV BX, 0
    
check_obstacle_body_loop:
    CMP CX, 0
    JE check_obstacle_food_overlap
    
    ; Check X coordinate
    PUSH SI
    PUSH BX
    
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    SHL BX, 1       ; BX = BX * 2 (calculate offset)
    
    MOV AX, snake_body_x[BX]
    CMP AX, obstacle_x[SI]
    
    POP BX
    POP SI
    
    JNE next_obstacle_body_check
    
    ; Check Y coordinate
    PUSH SI
    PUSH BX
    
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    SHL BX, 1       ; BX = BX * 2 (calculate offset)
    
    MOV AX, snake_body_y[BX]
    CMP AX, obstacle_y[SI]
    
    POP BX
    POP SI
    
    JE add_obstacle_retry
    
next_obstacle_body_check:
    INC BX
    DEC CX
    JMP check_obstacle_body_loop
    
    ; Check if overlaps with food
check_obstacle_food_overlap:
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV AX, obstacle_x[SI]
    POP SI
    
    CMP AX, food_x
    JNE obstacle_add_valid
    
    PUSH SI
    SHL SI, 1       ; SI = SI * 2 (calculate offset)
    MOV AX, obstacle_y[SI]
    POP SI
    
    CMP AX, food_y
    JE add_obstacle_retry
    
obstacle_add_valid:
    ; Increment obstacle count
    INC obstacle_count
    
add_obstacle_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
AddObstacle ENDP

; Display game over message
DisplayGameOver PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Position cursor in center of screen
    MOV AH, 2
    MOV DH, 12
    MOV DL, 25
    INT 10h
    
    ; Set color
    MOV BL, 12    ; Bright red
    
    ; Print game over message
    MOV SI, OFFSET game_over_msg
    CALL PrintString
    
    ; Show final score
    MOV AH, 2
    MOV DH, 14
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET score_msg
    CALL PrintString
    
    MOV AX, score
    CALL PrintNumber
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplayGameOver ENDP

; Display main menu
DisplayMainMenu PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Position cursor for title
    MOV AH, 2
    MOV DH, 5
    MOV DL, 35
    INT 10h
    
    ; Print title
    MOV SI, OFFSET menu_title
    CALL PrintString
    
    ; Print menu options
    MOV AH, 2
    MOV DH, 8
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET menu_start
    CALL PrintString
    
    MOV AH, 2
    MOV DH, 10
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET menu_settings
    CALL PrintString
    
    MOV AH, 2
    MOV DH, 12
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET menu_exit
    CALL PrintString
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplayMainMenu ENDP

; Display settings menu
DisplaySettingsMenu PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Position cursor for title
    MOV AH, 2
    MOV DH, 5
    MOV DL, 35
    INT 10h
    
    ; Print title
    MOV SI, OFFSET settings_title
    CALL PrintString
    
    ; Print settings options
    MOV AH, 2
    MOV DH, 8
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET settings_theme
    CALL PrintString
    
    MOV AH, 2
    MOV DH, 10
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET settings_diff
    CALL PrintString
    
    MOV AH, 2
    MOV DH, 12
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET settings_back
    CALL PrintString
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplaySettingsMenu ENDP

; Display theme menu
DisplayThemeMenu PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Position cursor for title
    MOV AH, 2
    MOV DH, 5
    MOV DL, 35
    INT 10h
    
    ; Print title
    MOV SI, OFFSET theme_title
    CALL PrintString
    
    ; Print theme options
    MOV AH, 2
    MOV DH, 8
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET theme_classic
    CALL PrintString
    
    ; Show current selection
    CMP current_theme, 1
    JNE check_blue
    
    MOV AH, 2
    MOV DL, 50
    INT 10h
    
    MOV AH, 0Eh
    MOV AL, '<'
    INT 10h
    
check_blue:
    MOV AH, 2
    MOV DH, 10
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET theme_blue
    CALL PrintString
    
    ; Show current selection
    CMP current_theme, 2
    JNE check_red
    
    MOV AH, 2
    MOV DL, 50
    INT 10h
    
    MOV AH, 0Eh
    MOV AL, '<'
    INT 10h
    
check_red:
    MOV AH, 2
    MOV DH, 12
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET theme_red
    CALL PrintString
    
    ; Show current selection
    CMP current_theme, 3
    JNE theme_back_option
    
    MOV AH, 2
    MOV DL, 50
    INT 10h
    
    MOV AH, 0Eh
    MOV AL, '<'
    INT 10h
    
theme_back_option:
    MOV AH, 2
    MOV DH, 14
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET theme_back
    CALL PrintString
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplayThemeMenu ENDP

; Display difficulty menu
DisplayDifficultyMenu PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Position cursor for title
    MOV AH, 2
    MOV DH, 5
    MOV DL, 35
    INT 10h
    
    ; Print title
    MOV SI, OFFSET diff_title
    CALL PrintString
    
    ; Print difficulty options
    MOV AH, 2
    MOV DH, 8
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET diff_easy
    CALL PrintString
    
    ; Show current selection
    CMP difficulty, 1
    JNE check_medium
    
    MOV AH, 2
    MOV DL, 50
    INT 10h
    
    MOV AH, 0Eh
    MOV AL, '<'
    INT 10h
    
    ; Show description
    MOV AH, 2
    MOV DH, 9
    MOV DL, 36
    INT 10h
    
    MOV SI, OFFSET diff_easy_desc
    CALL PrintString
    
check_medium:
    MOV AH, 2
    MOV DH, 11
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET diff_medium
    CALL PrintString
    
    ; Show current selection
    CMP difficulty, 2
    JNE check_hard
    
    MOV AH, 2
    MOV DL, 50
    INT 10h
    
    MOV AH, 0Eh
    MOV AL, '<'
    INT 10h
    
    ; Show description
    MOV AH, 2
    MOV DH, 12
    MOV DL, 36
    INT 10h
    
    MOV SI, OFFSET diff_med_desc
    CALL PrintString
    
check_hard:
    MOV AH, 2
    MOV DH, 14
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET diff_hard
    CALL PrintString
    
    ; Show current selection
    CMP difficulty, 3
    JNE diff_back_option
    
    MOV AH, 2
    MOV DL, 50
    INT 10h
    
    MOV AH, 0Eh
    MOV AL, '<'
    INT 10h
    
    ; Show description
    MOV AH, 2
    MOV DH, 15
    MOV DL, 36
    INT 10h
    
    MOV SI, OFFSET diff_hard_desc
    CALL PrintString
    
diff_back_option:
    MOV AH, 2
    MOV DH, 17
    MOV DL, 35
    INT 10h
    
    MOV SI, OFFSET diff_back
    CALL PrintString
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DisplayDifficultyMenu ENDP

; Wait for menu input and process selection
WaitForMenuInput PROC
    PUSH AX
    PUSH BX
    
menu_input_loop:
    ; Wait for key press
    MOV AH, 0
    INT 16h
    
    ; Process input based on current menu
    CMP current_menu, 0
    JE process_main_menu
    
    CMP current_menu, 2
    JE process_settings_menu
    
    CMP current_menu, 3
    JE process_theme_menu
    
    CMP current_menu, 4
    JE process_difficulty_menu
    
    JMP menu_input_done
    
process_main_menu:
    CMP AL, '1'
    JE start_game_selected
    
    CMP AL, '2'
    JE settings_selected
    
    CMP AL, '3'
    JE exit_selected
    
    JMP menu_input_loop
    
process_settings_menu:
    CMP AL, '1'
    JE theme_selected
    
    CMP AL, '2'
    JE difficulty_selected
    
    CMP AL, '3'
    JE settings_back_selected
    
    JMP menu_input_loop
    
process_theme_menu:
    CMP AL, '1'
    JE classic_theme_selected
    
    CMP AL, '2'
    JE blue_theme_selected
    
    CMP AL, '3'
    JE red_theme_selected
    
    CMP AL, '4'
    JE theme_back_selected
    
    JMP menu_input_loop
    
process_difficulty_menu:
    CMP AL, '1'
    JE easy_difficulty_selected
    
    CMP AL, '2'
    JE medium_difficulty_selected
    
    CMP AL, '3'
    JE hard_difficulty_selected
    
    CMP AL, '4'
    JE difficulty_back_selected
    
    JMP menu_input_loop
    
start_game_selected:
    MOV current_menu, 1    ; Change to game mode
    JMP menu_input_done
    
settings_selected:
    MOV current_menu, 2    ; Change to settings menu
    JMP menu_input_done
    
exit_selected:
    ; Exit the game
    MOV AX, 4C00h
    INT 21h
    
settings_back_selected:
    MOV current_menu, 0    ; Return to main menu
    JMP menu_input_done
    
theme_selected:
    MOV current_menu, 3    ; Go to theme menu
    JMP menu_input_done
    
difficulty_selected:
    MOV current_menu, 4    ; Go to difficulty menu
    JMP menu_input_done
    
classic_theme_selected:
    MOV current_theme, 1
    ; Set classic theme colors
    MOV head_color, 10     ; Green
    MOV body_color, 2      ; Dark green
    MOV food_color, 12     ; Red
    MOV border_color, 15   ; White
    MOV obstacle_color, 4  ; Red
    JMP theme_back_selected
    
blue_theme_selected:
    MOV current_theme, 2
    ; Set blue theme colors
    MOV head_color, 9      ; Bright blue
    MOV body_color, 1      ; Blue
    MOV food_color, 14     ; Yellow
    MOV border_color, 15   ; White
    MOV obstacle_color, 5  ; Magenta
    JMP theme_back_selected
    
red_theme_selected:
    MOV current_theme, 3
    ; Set red theme colors
    MOV head_color, 12     ; Bright red
    MOV body_color, 4      ; Red
    MOV food_color, 14     ; Yellow
    MOV border_color, 15   ; White
    MOV obstacle_color, 1  ; Blue
    JMP theme_back_selected
    
theme_back_selected:
    MOV current_menu, 2    ; Return to settings menu
    JMP menu_input_done
    
easy_difficulty_selected:
    MOV difficulty, 1
    JMP difficulty_back_selected
    
medium_difficulty_selected:
    MOV difficulty, 2
    JMP difficulty_back_selected
    
hard_difficulty_selected:
    MOV difficulty, 3
    JMP difficulty_back_selected
    
difficulty_back_selected:
    MOV current_menu, 2    ; Return to settings menu
    
menu_input_done:
    ; Clear keyboard buffer
    MOV AH, 0Ch
    MOV AL, 0
    INT 21h
    
    POP BX
    POP AX
    RET
WaitForMenuInput ENDP

; Print a string from DS:SI (zero-terminated)
PrintString PROC
    PUSH AX
    PUSH SI
    
print_loop:
    MOV AL, [SI]
    CMP AL, 0
    JE print_done
    
    MOV AH, 0Eh    ; BIOS teletype output
    INT 10h
    
    INC SI
    JMP print_loop
    
print_done:
    POP SI
    POP AX
    RET
PrintString ENDP

; Print number in AX
PrintNumber PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10      ; Divisor
    MOV CX, 0       ; Digit counter
    
    ; Handle zero case
    CMP AX, 0
    JNE extract_digits
    
    MOV AH, 0Eh
    MOV AL, '0'
    INT 10h
    JMP print_number_done
    
extract_digits:
    ; Extract digits in reverse order
    CMP AX, 0
    JE print_digits
    
    MOV DX, 0
    DIV BX          ; AX = AX / 10, DX = remainder
    
    PUSH DX         ; Save remainder on stack
    INC CX          ; Increment digit counter
    
    JMP extract_digits
    
print_digits:
    ; Print digits in correct order
    CMP CX, 0
    JE print_number_done
    
    POP DX          ; Get digit from stack
    ADD DL, '0'     ; Convert to ASCII
    
    MOV AH, 0Eh
    MOV AL, DL
    INT 10h
    
    DEC CX          ; Decrement digit counter
    JMP print_digits
    
print_number_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNumber ENDP

; Clear the screen
ClearScreen PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Set video mode to clear screen
    MOV AX, 3
    INT 10h
    
    ; Hide cursor
    MOV AH, 1
    MOV CX, 2000h
    INT 10h
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ClearScreen ENDP

; Generate a pseudo-random number
; Returns random value in AX
Random PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    ; Linear congruential generator: X_next = (a*X + c) mod m
    MOV AX, 25173       ; Multiplier (a)
    MUL random_seed     ; DX:AX = a * X
    ADD AX, 13849       ; Add increment (c)
    ; We're using 16-bit operations, so mod 2^16 is automatic
    
    ; Update seed for next call
    MOV random_seed, AX
    
    POP DX
    POP CX
    POP BX
    RET
Random ENDP

END MAIN