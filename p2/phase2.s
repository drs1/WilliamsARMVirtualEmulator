;;; emulator for warm - phase 2
;;; (c) d.r.smith modsoussi bijan
	.requ	wpc, r15
	.requ	ci, r14
	.requ	op, r13
	.requ	lhs, r12
	.requ	dst, r11
	.requ 	rhs, r10
	.requ	shiftC, r9
	.requ	wCCR, r8
	.requ	cond, r5
	.requ	setCC, r4
	.requ	work0, r0
 	.requ	work1, r1
		
 	.equ	maskT, 0xc000000 	;27 and 26th bit
	.equ	maskA, 0x7800		;1 in 14,13,12th bit
	.equ	maskShift, 0x3F
	.equ	maskLow4, 0xf
	.equ	maskHigh4, 0xf0000000
	.equ	maskValue, 0x1ff
	.equ	maskExp, 0x1f00
	.equ	maskSetCC, 0x10000000
	
	lea	WARM,work0
	trap	$SysOverlay

;;; --------------------BEGIN FETCHING THE INSTRUCTION-------------------
;;; 5 INSTRUCTIONS
fetch:	mov	WARM(wpc),ci
	mov	ci, work0
	shr	$29, work0	;high 3 condition bits in work0
	cmovg	COND(work0), rip


	mov	$maskSetCC, setCC
	and	ci, setCC	; set if setCC > 0


type:	mov	$maskT, work0	;decipher type
	and	ci, work0
	shr	$31, work0	;work 0 holds the type
 	mov	TYPE(work0), rip ;jump on type
	
never:
;;; increment the program counter and start the loop all over again
	add 	$1, wpc
	jmp 	fetch
eq:
;;; check if the zero bit is set in the last wCCR
	
	
ne:
;;; check if the zero bit is not set in wCCR
lt:
;;; check if the negative bit is set
le:
;;; check if negative and zero are set
ge:
;;; check if negative is not set
gt:
;;; check if negative and zero are not set
COND:
	.data	always, 0, eq, ne, lt, le, ge, gt
	
	
;;; thoughts and improvements?
;;;
;;;
;;;
;;; 
;;; ----------------------END FETCH--------------------------------------

	
;;; types of instructions:
;;; arithmetic
;;; load/store
;;; branch

;;; ARITH
;;; 13 INSTRUCTIONS
arith:	mov 	ci,op
	shl	$4,op
	shr	$27,op
	mov 	$maskA, work0
	and 	ci,work0
	shr	$12, work0	;work 0 holds the addressing mode
	mov     ci, lhs		;get dst and lhs
	shr     $15, lhs
	and     $maskLow4, lhs
	mov     ci, dst
	shr     $19, dst
	and     $maskLow4, dst
	mov	ADDR(work0), rip

;;; LOAD/STORE
;;; -1 INSTRUCTIONS
ls:	

;;; BRANCH
;;; -1 INSTRUCTIONS
branch:

;;; thoughts and improvements?
;;;
;;;
;;;
;;; 
;;; -------------------END INSTRUCTION TYPES------------------------------

	
	
;;; -------------------BEGIN ADDRESSING MODES------------------------------
	
;;; Immediate Mode
;;; 7 INSTRUCTIONS
imd:	mov	ci, work0
	and	$maskExp, work0	;exponent
	shr	$9, work0
	mov	ci, rhs
	and	$maskValue, rhs	;value
	shl	work0, rhs	;shifted value in rhs
	mov     INSTR(op), rip
	
;;; Register Shifted by Immediate Mode
;;; 10 INSTRUCTIONS
rim:	mov	ci, rhs
	shl	$22, rhs
	shr	$28, rhs 	;now we have src reg 2 in rhs
	mov	REGS(rhs), rhs	;rhs now has the value that was in register number rhs
	mov	ci, shiftC
	and	$maskShift, shiftC	;shift count has the bits number to shift
	mov	ci, work0
	shl	$20, work0
	shr	$30, work0	;work1 now has the shop
	mov 	SHOP(work0),rip

;;; Register Shifted by Register Mode
;;; 11 INSTRUCTIONS
rsr:	mov	$maskLow4, shiftC	; shiftC := 15
	and 	ci, shiftC	; shiftC := shiftC & ci; to get shift register
	mov	REGS(shiftC), shiftC ; shiftC now has whatever was stored in the 
	mov	ci, rhs	
	shl	$22, rhs
	shr	$28, rhs	; rhs has rhs register
	mov	REGS(rhs), rhs	; rhs now has whatever was stored in rhs (memory)
	mov 	ci, work0
	shl	$20, work0
	shr	$30, work0	; work0 now has the shift op code
	mov	SHOP(work0), rip

;;; --------------------------BEGIN SHIFTING MODES-------------------------

	
;;; logical shift left
;;; 2 INSTRUCTIONS
lsl:	shl	shiftC, rhs
	mov     INSTR(op), rip

;;; logical shift right
;;; 2 INSTRUCTIONS
lsr:	shr	shiftC, rhs
	mov     INSTR(op), rip

;;; arithmetic shift right
;;; 2 INSTRUCTIONS
asr:	sar	shiftC, rhs
	mov     INSTR(op), rip
	
;;; rotate right shift
;;; 7 INSTRUCTIONS
ror:	mov	rhs, work0
	mov	$32, work1	
	sub	shiftC, work1	;work1 := 32-shr
	shl	work1, work0	;work1 is low shr bits shifted (32-shr) to the left
	shr	shiftC, rhs	;work2 is the highest (32-shr) bits shifted shr to the right
	add	work0, rhs
	mov     INSTR(op), rip


	
;;; thoughts and possible improvements?
;;;
;;;
;;; 
;;; 
;;;
;;;
;;; 
;;;
;;; -------------------------END SHIFTING MODES----------------------

;;; Register Product Mode
;;; 8 INSTRUCTIONS
rpm:	mov	$maskLow4, work0
	and	ci, work0	; work0 now has src reg 3
	mov	ci, rhs
	shl	$22, rhs
	shr	$28, rhs	; rhs now has src reg 2
	mov	REGS(rhs), rhs	; rhs now has whatever was stored in the correspondent register
	mov	REGS(work0), work0 ;work0 now has whatever was stored in the correspondent register
	mul	work0, rhs
;;; thoughts and possible improvements?
;;;
;;;
;;;
;;;
;;;
;;; 
;;; -------------------------END ADDRESSING MODES--------------------------


	




;;; -------------------------BEGIN OPERATIONS------------------------------------
;;; operations finished and tested with all three cases:
;;; add
;;; sub
;;; mul
;;; mla
;;; div


;;; thoughts and improvements for all operations:
;;; the adding one to the wpc is a terrible monkey patch
;;; how can we jump back up with a reloaded wpc in one instruction?

	
;;; 4 INSTRUCTION(S)	
add:	add	REGS(lhs), rhs
	mov	rhs, REGS(dst)
	add	$1, wpc
	jmp 	fetch

;;; thoughts and possible improvements?
;;; not really, this seems like the most straghtforward
;;; we can do
	


;;; -1 INSTRUCTION(S)	
adc:

;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
;;; 5 INSTRUCTION(S)
;;; backwards (like div)
sub:	mov	REGS(lhs), work0
	sub	rhs, work0
	mov	work0, REGS(dst)
	add	$1, wpc
	jmp 	fetch
;;; thoughts and improvements?
;;;	generally, sub and divide do the opposite of what we want them to
;;;	it would be easier if we didn't have to move into work reg's to get
;;;	things done
;;;
;;;
	
	
;;; 5 INSTRUCTION(S)	
cmp:	mov 	REGS(lhs), work0
	sub 	rhs, work0
	mov	ccr, wCCR
	add	$1, wpc
	jmp 	fetch
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;

	
;;; -1 INSTRUCTION(S)	
eor:	

;;; thoughts and improvepments?
;;;
;;;
;;;
;;;
;;;


;;; -1 INSTRUCTION(S)	
orr:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)	
and: 

	
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
;;; -1 INSTRUCTION(S)
	
tst:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
;;; 4 INSTRUCTION(S)
mul:	mul	REGS(lhs), rhs
	mov	rhs, REGS(dst)
	add	$1, wpc
	jmp	fetch
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
	
;;; 5 INSTRUCTION(S)
;;; backwards (like sub)
div:	mov 	REGS(lhs), work0
	div	rhs, work0
	mov	work0, REGS(dst)
	add	$1, wpc
	jmp	fetch

	
;;; thoughts and improvements?
;;;	
;;;
;;;
;;;
;;;
	
	
;;; 3 INSTRUCTION(S)
mov:	mov	rhs, REGS(dst)
	add	$1, wpc
	jmp 	fetch
;;; thoughts and improvements?
;;; as simple as it gets
	

;;; -1 INSTRUCTION(S)
mvn:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)	
swi:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
	
;;; -1 INSTRUCTION(S)		
ldm:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
	
;;; -1 INSTRUCTION(S)		
stm:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
ldr:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
str:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
ldu:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)	
stu:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
adr:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
bf:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
bb:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
blf:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	

;;; -1 INSTRUCTION(S)		
blb:
;;; thoughts and improvements?
;;;
;;;
;;;
;;;
;;;
	
	
REGS:
	.data	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
INSTR:
	.data 	add,adc,sub,cmp,eor,orr,and,tst,mul,0,div,mov,mvn,swi,ldm,stm,ldr,str,ldu,stu,adr,0,0,0,bf,bb,blf,blb
TYPE:
	.data	arith, arith, ls, branch
COND:
	.data	always, never, eq, ne, lt, le, ge, gt
ADDR:
	.data 	imd, imd, imd, imd, rim, rsr, rpm
SHOP:
	.data	lsl, lsr, asr, ror
WARM:	 
