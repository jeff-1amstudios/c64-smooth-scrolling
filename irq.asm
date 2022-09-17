; consts 
irq_delay_default = 0
FIRST_VIS_LINE = 50
START_COPYING_UPPER_COLOR_RAM_LINE = 65
BEGIN_VBLANK_LINE = 245
SYSTEM_IRQ_HANDLER = $ea81


; vars
xscroll             !byte 7


irq_setup           sei                                          ; disable interrupts
                    ldy #$7f                                     ; 01111111 
                    sty $dc0d                                    ; turn off CIA timer interrupt
                    lda $dc0d                                    ; cancel any pending IRQs
                    lda #$01
                    sta $d01a                                    ; enable VIC-II Raster Beam IRQ
                    lda $d011                                    ; bit 7 of $d011 is the 9th bit of the raster line counter.
                    and #$7f                                     ; make sure it is set to 0
                    sta $d011
                    +set_raster_interrupt START_COPYING_UPPER_COLOR_RAM_LINE, irq_line_65
                    cli                                          ; enable interupts
                    rts

; -----------------------------------------------------------------------
irq_line_65
                    dec $d019                                    ; set interrupt handled flag
                    lda xscroll                                  
                    bne *+5                                      ; if xscroll != 0, skip next line
                                                                 ; if we're on the last screen draw before swapping, 
                                                                 ; copy top half of color RAM behind the beam 
                    jsr color_shift_upper

                    +set_raster_interrupt BEGIN_VBLANK_LINE, irq_begin_vblank
                    jmp SYSTEM_IRQ_HANDLER       ; call system IRQ handler

; -----------------------------------------------------------------------                    
irq_begin_vblank
                    dec $d019                                    ; set interrupt handled flag
                    dec xscroll                                  ; decrement xscroll

                    bmi irq_swap_screens                         ; if xscroll wraps back past 0, we need to swap screen buffers 
                                                                 ; and shift color RAM
                    +update_x_scroll xscroll                     ; set softscroll register

                    lda xscroll
                    cmp #4                                       ; if x==4, copy to back buffer now
                    bne *+8                                      ; otherwise, skip next 2 lines
                    jsr screen_shift_upper                       ; copy top half of screen
                    jmp irq_handler_exit
    
                    cmp #2                                       ; if x==2, copy to back buffer
                    bne irq_handler_exit
                    jsr screen_shift_lower                       ; copy lower half of screen
                    jmp irq_handler_exit
                    
irq_swap_screens             
                    lda #7                                       ; reset xscroll
                    sta xscroll
                    +update_x_scroll xscroll

                    jsr screen_swap                              ; swap screen to back buffer
                    jsr color_shift_lower                        ; shift lower color ram.
                    jsr level_render_last_col                    ; draw new column at right edge of screen

irq_handler_exit    
                    +set_raster_interrupt START_COPYING_UPPER_COLOR_RAM_LINE, irq_line_65
                    jmp SYSTEM_IRQ_HANDLER       ; call system IRQ handler

