!cpu 6510
!to "./build/test.prg",cbm

!source "defs.asm"
!source "macros.asm"

* = $0801                                       ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39           ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00                   ; BASIC op-codes to execute 'SYS 49152'  (49152 = 0xc000)


* = $c000                                       ; start address for 6502 code

init    
                jsr screen_clear                ; clear and initialize screen
                jsr screen_init
                jsr level_init                  ; draw initial level to screen

                jsr irq_setup                   ; initialize our IRQ

                jmp *                           ; loop while waiting for IRQs


!source "screen.asm"
!source "level.asm"
!source "irq.asm"

