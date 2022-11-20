;------------------------------
; Example inspired by Photon's Tutorial:
;  https://www.youtube.com/user/ScoopexUs
;
;---------- Includes ----------
            INCDIR      "include"
            INCLUDE     "hw.i"
            INCLUDE     "funcdef.i"
            INCLUDE     "exec/exec_lib.i"
            INCLUDE     "graphics/graphics_lib.i"
            INCLUDE     "hardware/cia.i"

;---------- Const ----------

        section code,code_c

        lea     start(pc),a0
        lea     $20000,a1
        move.l  #(end-start)/2-1,d0
.copy:  move.w  (a0)+,(a1)+
        dbf     d0,.copy
        jmp     $20000

start:
    ORG $20000

CIAA        = $00bfe001
w	=320
h	=256
bplsize	=w*h/8

screen	=$60000

init:
	move.l 4.w,a6		;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr _LVOOldOpenLibrary(a6)      ;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1),d4	;original copper ptr

	jsr _LVOCloseLibrary(a6)        ;closelibrary()

	move.w #$ac,d7		;start y position
	moveq #1,d6		;y add
	move.w CUSTOM+intenar,d5
	move.w #$7fff,CUSTOM+intena	;disable all bits in INTENA

hwinit:
	lea screen,a1
	move.w #bplsize-1,d0
.l:	move.b $dff007,(a1)+
	dbf d0,.l
	
	move.l #Copper,CUSTOM+COP1LC
**************************
mainloop:
wframe:
	btst #0,CUSTOM+vhposr-1
	bne.b wframe
	cmp.b #$2a,CUSTOM+vhposr
	bne.b wframe
wframe2:
	cmp.b #$2a,$dff006
	beq.b wframe2

;-----frame loop start---

	add d6,d7		;add "1" to y position

	cmp #$f0,d7		;bottom check
	blo.b ok1
	neg d6			;change direction
ok1:

	cmp.b #$40,d7
	bhi.b ok2
	neg d6			;change direction
ok2:

	move.l #waitras1,a0
	move d7,d0
	moveq #6-1,d1
.l:
	move.b d0,(a0)
	add.w #1,d0
	add.w #8,a0
	DBF d1,.l

;-----frame loop end---

	btst #CIAB_GAMEPORT0,CIAA+ciapra
	bne.b mainloop
**************************
exit:
	move.l d4,CUSTOM+COP1LC ;Restore old copperlist  
	or #$c000,d5
	move d5,CUSTOM+intena   ;Restore intena bits
	rts


gfxname:
	dc.b "graphics.library",0

	EVEN
Copper:
	dc.w $1fc,0			;slow fetch mode, AGA compatibility
	dc.w BPLCON0,$0200              ;Bit plane control register 0 - Enable color burst output signal
	dc.w DIWSTRT,$2c81              ;Display window start - 2c vert 81 hor - normal PAL
	dc.w DIWSTOP,$2cc1              ;Display window stop - 2c vert 2c hor - normal PAL
	dc.w DDFSTRT,$38                ;Display fetch start - hor pos 38
	dc.w DDFSTOP,$d0                ;Display fetch stop - hor pos d0
	dc.w BPL1MOD,0                  ;Odd numbered bitplane modulo
	dc.w BPL2MOD,0                  ;Even number bitplane modulo

CopBplP:
	dc.w BPL1PTH,(screen>>16)&$ffff ;Bit plane 1 pointers
	dc.w BPL1PTL,(screen)&$ffff
		
	dc.w COLOR00,$349
	dc.w $2b07,$fffe
	dc.w COLOR00,$56c
	dc.w $2c07,$fffe
	dc.w COLOR00,$113
	dc.w BPLCON0,$1200
	dc.w COLOR02,$379
waitras1:
	dc.w $8007,$fffe
	dc.w COLOR00,$055
waitras2:
	dc.w $8107,$fffe
	dc.w COLOR00,$0aa
waitras3:
	dc.w $8207,$fffe
	dc.w COLOR00,$0ff
waitras4:
	dc.w $8307,$fffe
	dc.w COLOR00,$0aa
waitras5:
	dc.w $8407,$fffe
	dc.w COLOR00,$055
waitras6:
	dc.w $8507,$fffe
	dc.w COLOR00,$113

	dc.w $ffdf,$fffe
	dc.w $2c07,$fffe
	dc.w COLOR00,$56c
	dc.w $2d07,$fffe
	dc.w COLOR00,$349

	dc.w $ffff,$fffe
end: