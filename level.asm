; Constants

screen_ptr = $04
color_ptr = $06
screen_col = $08
screen_ptr_dest = $0a
color_ptr_dest = $0c

COLOR_CHANGE_DELAY = 10

; Variables
ceil_height !byte 0            
floor_height !byte 0
message_index !byte 0
current_color !byte 1
current_color_change_delay !byte COLOR_CHANGE_DELAY
level_data !byte 1,2,3,4,5,6,7,8,7,6,5,4,3,2,1
level_index !byte 0

str_message       !scr "1amstudios.com  ", 0 


level_init    
                    ldy #0
                    +set16im 0, screen_col
                    
level_render_next_col
                    +set16 screen_base, screen_ptr
                    +set16im $d800, color_ptr
                    +add16 screen_ptr, screen_col, screen_ptr    ;increment screen row
                    +add16 color_ptr, screen_col, color_ptr      ;increment screen row
                    inc screen_col

                    dec current_color_change_delay
                    bne level_render_col
                    lda #COLOR_CHANGE_DELAY
                    sta current_color_change_delay
                    inc current_color
                    
level_render_col    
                    ldx level_index
                    lda level_data, x                            ; load ceiling height
                    sta ceil_height
                    tax                                          ; x now holds ceiling height

level_render_ceil
                    lda #$A0
                    sta (screen_ptr), y                          ; output to screen
                    lda current_color
                    sta (color_ptr), y                           ; and color ram

                    +add16im screen_ptr, 40, screen_ptr          ; increment screen row
                    +add16im color_ptr, 40, color_ptr            ; increment color row

                    dex                                          ; decrement ceiling counter
                    bne level_render_ceil                        ; if we're not at the bottom of the ceiling keep rendering the colum
level_skip_ceil 
                    ldx level_index
                    lda level_data, x                            ; load floor height
                    sta floor_height                             
                    inx                                          ; increment level data index
                    cpx #10
                    bne *+4                                      ; skip next line if we don't want to wrap to start of level data again
                                                                 ; +4 (2 for bne, 2 for ldx)
                    ldx #0                                       ; wrap around level data
                    stx level_index                              ; store updated level data index

                    lda #23                                      ; 
                    sec
                    sbc ceil_height
                    sbc floor_height
                    tax                                          ; x now holds the number of rows between end of ceiling and start of floor

                    
level_skip_to_floor
                    lda #$20
                    sta (screen_ptr), y                          ; output blank char to screen
                    +add16im screen_ptr, 40, screen_ptr          ; increment screen row
                    +add16im color_ptr, 40, color_ptr            ; increment color row
                    dex
                    bne level_skip_to_floor                      ; keep skipping rows until x == 0
                    ldx floor_height                             ; X now holds height of floor
level_render_floor
                    lda #$A0    
                    sta (screen_ptr), y                          ; output char to screen
                    lda current_color
                    sta (color_ptr), y                           ; and color ram
                    +add16im screen_ptr, 40, screen_ptr          ; increment screen row
                    +add16im color_ptr, 40, color_ptr            ; increment color row
                    dex                                          ; decrement floor counter
                    bne level_render_floor                       ; if we're not at the bottom of the floor keep rendering the column

                                                                 ; print message at bottom of screen
                    ldx message_index
                    lda str_message, x                           ; output char to screen
                    sta (screen_ptr), y
                    lda #1
                    sta (color_ptr), y                           ; and color ram
                    inx
                    cpx #16
                    bne *+4                                      ; jump over next 2 lines if we're not at 16 yet
                    ldx #0                    
                    stx message_index

                    lda screen_col                               
                    cmp #40                                      ; if we've rendered 40 columns, we're finished
                    beq level_render_done
                    
                    jmp level_render_next_col                    ; and we haven't hit column 30 yet, render the next column

level_render_done
                    rts                                          ; return from last jsr

level_render_last_col                                            ; this is used to render the rightmost column of the screen when we need
                                                                 ; new data to scroll in
                    ldy #0
                    +set16im 39, screen_col
                    jsr level_render_next_col
                    rts

