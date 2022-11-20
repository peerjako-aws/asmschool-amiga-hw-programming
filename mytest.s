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
        move.l  #(end-start)-1,d0
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
	move.l 4.w,a6					;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr _LVOOldOpenLibrary(a6)      ;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1),d4				;original copper ptr

	jsr _LVOCloseLibrary(a6)        ;closelibrary()

	move.w #$ac,d7					;start y position
	moveq #1,d6						;y add

	move.w CUSTOM+INTENAR,d5
	move.w CUSTOM+DMACONR,d3

	move.w #$138,d0
	bsr WaitRaster					;Wait for raster line 138 end of frame

	move.w #$7fff,CUSTOM+INTENA		;disable all bits in INTENA
	move.w #$7fff,CUSTOM+INTREQ		;disable all bits in INTREQ
	move.w #$7fff,CUSTOM+INTREQ		;disable all bits in INTREQ
	move.w #$7fff,CUSTOM+DMACON		;disable all bits in DMACON
	move.w #$87e0,CUSTOM+DMACON		;set 1000 (SET) 0111 (BLTPRI+DMAEN+BPLEN) 1110 (BLTEN+COPEN+SPREN) 0000 

hwinit:
	lea screen,a1
	move.w #bplsize-1,d0
.l:	
	move.b #0,(a1)+	;fill some random bytes into screen data
;	move.b CUSTOM+vhposr+1,(a1)+	;fill some random bytes into screen data
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
	cmp.b #$2a,CUSTOM+vhposr
	beq.b wframe2

;-----frame loop start---
	add.b #1,Spr+1
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
	move.w #$7fff,CUSTOM+DMACON
	or.w #$8200,d3
	move.w d3,CUSTOM+DMACON	;Restor old DMACON
	move.l d4,CUSTOM+COP1LC ;Restore old copperlist  
	or #$c000,d5
	move d5,CUSTOM+intena   ;Restore intena bits
	rts

WaitRaster:					;Wait for rasterline d0.w. Modifies d0-d2/a0.
	move.l #$1ff00,d2
	lsl.l #8,d0
	and.l d2,d0
	lea CUSTOM+VPOSR,a0
.wr:
	move.l (a0),d1
	and.l d2,d1
	cmp.l d1,d0
	bne.s .wr
	RTS


gfxname:
	dc.b "graphics.library",0

	EVEN
Spr:
	dc.w $2c40,$3c00				;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0110011111001100,%0001100000110000
	dc.w %1110011111001110,%0001100000110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0010000000001000
	dc.w %1111111111111110,%0001100000110000
	dc.w %0111111111111100,%0000011111000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w 0,0

NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0

Copper:
	dc.w $1fc,0						;slow fetch mode, AGA compatibility
	dc.w BPLCON0,$0200              ;Bit plane control register 0 - Enable color burst output signal
	dc.w DIWSTRT,$2c81              ;Display window start - 2c vert 81 hor - normal PAL
	dc.w DIWSTOP,$2cc1              ;Display window stop - 2c vert c1 hor - normal PAL
	dc.w DDFSTRT,$38                ;Display fetch start - hor pos 38
	dc.w DDFSTOP,$d0                ;Display fetch stop - hor pos d0
	dc.w BPL1MOD,0                  ;Odd numbered bitplane modulo
	dc.w BPL2MOD,0                  ;Even numbered bitplane modulo
	dc.w BPLCON1,0

	dc.w COLOR17,$e22
	dc.w COLOR18,$ff0
	dc.w COLOR19,$0ff

SprP:
	dc.w SPR0PTH,(Spr>>16)&$ffff
	dc.w SPR0PTL,(Spr)&$ffff

	dc.w SPR1PTH,(NullSpr>>16)&$ffff
	dc.w SPR1PTL,(NullSpr)&$ffff
	dc.w SPR2PTH,(NullSpr>>16)&$ffff
	dc.w SPR2PTL,(NullSpr)&$ffff
	dc.w SPR3PTH,(NullSpr>>16)&$ffff
	dc.w SPR3PTL,(NullSpr)&$ffff
	dc.w SPR4PTH,(NullSpr>>16)&$ffff
	dc.w SPR4PTL,(NullSpr)&$ffff
	dc.w SPR5PTH,(NullSpr>>16)&$ffff
	dc.w SPR5PTL,(NullSpr)&$ffff
	dc.w SPR6PTH,(NullSpr>>16)&$ffff
	dc.w SPR6PTL,(NullSpr)&$ffff
	dc.w SPR7PTH,(NullSpr>>16)&$ffff
	dc.w SPR7PTL,(NullSpr)&$ffff

CopBplP:
	dc.w BPL1PTH,(screen>>16)&$ffff ;Bit plane 1 pointers
	dc.w BPL1PTL,(screen)&$ffff
		
	dc.w COLOR00,$349
	dc.w $2b07,$fffe
	dc.w COLOR00,$56c
	dc.w $2c07,$fffe
	dc.w COLOR00,$113
	dc.w BPLCON0,$1200
	dc.w COLOR01,$979
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