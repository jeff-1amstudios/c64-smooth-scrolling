;vars
screen_buffer_nbr !byte 0
screen_base !word 0            ; plus 1 row
screen_back_buffer_base !word 0
raster_1 !byte 0
raster_2 !byte 0

ROWS_PER_COPY = 12

; --------- screen_clear was taken from https://gist.github.com/actraiser/8e335033b2622409bd96 -----

screen_clear        ldx #$00                                     ; set X to zero (black color code)
                    stx $d021                                    ; set background color
                    stx $d020                                    ; set border color
                    +set16im $0400, screen_base                  ; init screen pointers
                    +set16im $0800, screen_back_buffer_base

 
_screen_clear_loop
                    lda #$20                                     ; #$20 is a blank char
                    sta $0400,x                                  ; fill four areas with 256 spacebar characters
                    sta $0500,x 
                    sta $0600,x 
                    sta $06e8,x 
                    lda #$00                                     ; set foreground to black in Color Ram 
                    sta $d800,x  
                    sta $d900,x
                    sta $da00,x
                    sta $dae8,x
                    inx           
                    bne _screen_clear_loop                       ; did X overflow to zero yet?
                    rts                                          ; return from this subroutine

screen_init
                    lda $d016                                    ; d016 is VIC-II control register.
                    and #%11110111                               ; un-set bit 3 to enable 38 column mode
                    sta $d016
                    rts

screen_swap         lda screen_buffer_nbr                        ; toggle screen_buffer_number between 0 and 1
                    eor #$01 
                    sta screen_buffer_nbr
                    bne screen_swap_to_1
                                                                 ;set screen ptr to screen 0
                    lda $d018                                    ; top 4 bits of d018 holds the screen location in RAM
                    and #$0f                                     ; mask upper 4 bits
                    ora #$10                                     ; set upper 4 bits to '1'
                    sta $d018
                    +set16im $0400, screen_base
                    +set16im $0800, screen_back_buffer_base
                    rts

screen_swap_to_1                                                 ;set screen ptr to screen 1
                    lda $d018
                    and #$0f                  
                    ora #$20                  
                    sta $d018
                    +set16im $0800, screen_base
                    +set16im $0400, screen_back_buffer_base
                    rts

screen_shift_lower                                               ; copy the lower half of screen to back buffer
                    +set16 screen_base, screen_ptr
                    inc screen_ptr                               ; shift columns over by 1 while copying
                    +set16 screen_back_buffer_base, screen_ptr_dest
                    +add16im screen_ptr, 40*ROWS_PER_COPY, screen_ptr
                    +add16im screen_ptr_dest, 40*ROWS_PER_COPY, screen_ptr_dest
                    ldy #0                                       ; y is the current column
                    ldx #ROWS_PER_COPY                           ; x is the nbr of rows to copy
                    jmp video_ram_copy_line

screen_shift_upper
                    +set16 screen_base, screen_ptr
                    inc screen_ptr                               ; shift columns over by 1 at the same as copying to back buffer
                    +set16 screen_back_buffer_base, screen_ptr_dest
                    ldy #0                                       ; y is the current column
                    ldx #ROWS_PER_COPY                           ; x is the nbr of rows to copy
                    
video_ram_copy_line                                              ; copy a line of screen data to back buffer
                                                                 ; we unroll the loop for better performance 
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    
                    cpy #36
                    bne video_ram_copy_line

                                                                 ; now copy the last 3 bytes
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y
                    iny
                    lda (screen_ptr), y
                    sta (screen_ptr_dest), y

                    dex                                          ; have we copied all the rows?
                    beq video_ram_copy_done

                    ldy #0                                       ; reset column number
                    +add16im screen_ptr, 40, screen_ptr
                    +add16im screen_ptr_dest, 40, screen_ptr_dest
                    jmp video_ram_copy_line                      ; copy another line

video_ram_copy_done
                    rts

color_shift_upper                                                ; copy color RAM. Uses same code as screen_shift
                    +set16im $d801, screen_ptr
                    +set16im $d800, screen_ptr_dest
                    ldy #0                                       ; y is the current column
                    ldx #ROWS_PER_COPY                           ; nbr of rows to copy
                    jmp video_ram_copy_line

color_shift_lower
                    +set16im $d801+40*ROWS_PER_COPY, screen_ptr
                    +set16im $d800+40*ROWS_PER_COPY, screen_ptr_dest
                    ldy #0                                       ; y is the current column
                    ldx #ROWS_PER_COPY                           ; nbr of rows to copy
                    jmp video_ram_copy_line