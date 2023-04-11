; thiiiiisss

.include "m16def.inc"

;--------DATA SEGMENT-------------
.DSEG
	tmp: .byte 2


;--------CODE SEGMENT-------------
.CSEG
	.org 0x0
	rjmp RESET					;put the main program in the start of the RAM




RESET:
	.def temp=r16
	.def buttons_pressed=r17
	.def first_number=r18
	.def second_number=r19
	.def loop_error_counter=r20
	
	clr first_number
	clr second_number
	ldi loop_error_counter,4

    ldi temp,LOW(RAMEND)
	out SPL, temp
	ldi temp,HIGH(RAMEND)
	out SPH, temp				;initialize the stack

	ser temp
	out DDRB, temp				;PORTB (output)
	out DDRD, temp               ; αρχικοποίηση PORTD που συνδέεται η οθόνη, ως έξοδος
	ldi temp,(1<<PC7)|(1<<PC6)|(1<<PC5)|(1<<PC4)
	out DDRC,temp				;PORTC is used by READ4X4
	clr temp


main:
    rcall lcd_init_sim ; αρχικοποίηση οθόνης
	ldi r24, 15
	rcall scan_keypad_rising_edge_sim
	rcall keypad_to_ascii_sim ;παίρνουμε το ascii κωδικό του πλήκτρου που πατήθηκε
	adiw r24,0x00			; αν δεν εχει πατηθει καποιο πληκτρο
	breq main		; τοτε ελεγχει ξανα
	ldi r26, '1'
	ldi r27, '4'
	cp r24, r26
	brne PRE_ERROR
SECOND_ND:
	ldi r24, 15
    rcall scan_keypad_rising_edge_sim
	rcall keypad_to_ascii_sim ;παίρνουμε το ascii κωδικό του πλήκτρου που πατήθηκε
	adiw r24,0x00			; αν δεν εχει πατηθει καποιο πληκτρο
	breq SECOND_ND		; τοτε ελεγχει ξανα
	cp r24, r27
	rcall scan_keypad_rising_edge_sim
	breq SUCCESS
	rjmp ERROR


SUCCESS:					;reached here because both buttons where the right ones
	ser temp
	out PORTB,temp
	clr r24
	ldi r24,'W'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,'L'
	rcall lcd_data_sim
	ldi r24,'C'
	rcall lcd_data_sim
	ldi r24,'O'
	rcall lcd_data_sim
	ldi r24,'M'
	rcall lcd_data_sim
	ldi r24,'E'
	rcall lcd_data_sim
	ldi r24,' '
	rcall lcd_data_sim
	ldi r24,'1'
	rcall lcd_data_sim
	ldi r24,'4'
	rcall lcd_data_sim
	ldi r24,low(4000)
	ldi r25,high(4000)
	rcall wait_msec 
	clr temp
	out PORTB,temp
	rjmp main

PRE_ERROR:
    ldi r24, 15
	rcall scan_keypad_rising_edge_sim
	rcall keypad_to_ascii_sim ;παίρνουμε το ascii κωδικό του πλήκτρου που πατήθηκε
	adiw r24,0x00			; αν δεν εχει πατηθει καποιο πληκτρο
	breq PRE_ERROR   		; τοτε ελεγχει ξανα

ERROR:						;reached here(jumping SUCCESS flag) because one or two buttons wrong
	clr r24
	ldi r24,'A'
	rcall lcd_data_sim
	ldi r24,'L'
	rcall lcd_data_sim
	ldi r24,'A'
	rcall lcd_data_sim
	ldi r24,'R'
	rcall lcd_data_sim
	ldi r24,'M'
	rcall lcd_data_sim
	ldi r24,' '
	rcall lcd_data_sim
	ldi r24,'O'
	rcall lcd_data_sim
	ldi r24,'N'
	rcall lcd_data_sim
	
LOOP_ERROR:	
    ser temp
	out PORTB,temp				
	ldi r24,low(500)
	ldi r25,high(500)		
	rcall wait_msec
	clr temp
	out PORTB,temp
	ldi r24,low(500)
	ldi r25,high(500)		
	rcall wait_msec
	dec loop_error_counter
	cpi loop_error_counter,0
	brne LOOP_ERROR
	ldi loop_error_counter,4
	rjmp main





scan_row_sim:
	out PORTC, r25 ; η αντίστοιχη γραμμή τίθεται στο λογικό ‘1’
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24,low(500) ; πρόσβασης
	ldi r25,high(500)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	nop
	nop ; καθυστέρηση για να προλάβει να γίνει η αλλαγή κατάστασης
	in r24, PINC ; επιστρέφουν οι θέσεις (στήλες) των διακοπτών που είναι πιεσμένοι
	andi r24 ,0x0f ; απομονώνονται τα 4 LSB όπου τα ‘1’ δείχνουν που είναι πατημένοι
	ret ; οι διακόπτες.

scan_keypad_sim:
	push r26 ; αποθήκευσε τους καταχωρητές r27:r26 γιατι τους
	push r27 ; αλλάζουμε μέσα στην ρουτίνα
	ldi r25 , 0x10 ; έλεγξε την πρώτη γραμμή του πληκτρολογίου (PC4: 1 2 3 A)
	rcall scan_row_sim
	swap r24 ; αποθήκευσε το αποτέλεσμα
	mov r27, r24 ; στα 4 msb του r27
	ldi r25 ,0x20 ; έλεγξε τη δεύτερη γραμμή του πληκτρολογίου (PC5: 4 5 6 B)
	rcall scan_row_sim
	add r27, r24 ; αποθήκευσε το αποτέλεσμα στα 4 lsb του r27
	ldi r25 , 0x40 ; έλεγξε την τρίτη γραμμή του πληκτρολογίου (PC6: 7 8 9 C)
	rcall scan_row_sim
	swap r24 ; αποθήκευσε το αποτέλεσμα
	mov r26, r24 ; στα 4 msb του r26
	ldi r25 ,0x80 ; έλεγξε την τέταρτη γραμμή του πληκτρολογίου (PC7: * 0 # D)
	rcall scan_row_sim
	add r26, r24 ; αποθήκευσε το αποτέλεσμα στα 4 lsb του r26
	movw r24, r26 ; μετέφερε το αποτέλεσμα στους καταχωρητές r25:r24
	clr r26 ; προστέθηκε για την απομακρυσμένη πρόσβαση
	out PORTC,r26 ; προστέθηκε για την απομακρυσμένη πρόσβαση
	pop r27 ; επανάφερε τους καταχωρητές r27:r26
	pop r26
	ret 


scan_keypad_rising_edge_sim:
	push r22 ; αποθήκευσε τους καταχωρητές r23:r22 και τους
	push r23 ; r26:r27 γιατι τους αλλάζουμε μέσα στην ρουτίνα
	push r26
	push r27
	rcall scan_keypad_sim ; έλεγξε το πληκτρολόγιο για πιεσμένους διακόπτες
	push r24 ; και αποθήκευσε το αποτέλεσμα
	push r25
	ldi r24 ,15 ; καθυστέρησε 15 ms (τυπικές τιμές 10-20 msec που καθορίζεται από τον
	ldi r25 ,0 ; κατασκευαστή του πληκτρολογίου – χρονοδιάρκεια σπινθηρισμών)
	rcall wait_msec
	rcall scan_keypad_sim ; έλεγξε το πληκτρολόγιο ξανά και απόρριψε
	pop r23 ; όσα πλήκτρα εμφανίζουν σπινθηρισμό
	pop r22
	and r24 ,r22
	and r25 ,r23
	ldi r26 ,low(tmp) ; φόρτωσε την κατάσταση των διακοπτών στην
	ldi r27 ,high(tmp) ; προηγούμενη κλήση της ρουτίνας στους r27:r26
	ld r23 ,X+
	ld r22 ,X
	st X ,r24 ; αποθήκευσε στη RAM τη νέα κατάσταση
	st -X ,r25 ; των διακοπτών
	com r23
	com r22 ; βρες τους διακόπτες που έχουν «μόλις» πατηθεί
	and r24 ,r22
	and r25 ,r23
	pop r27 ; επανάφερε τους καταχωρητές r27:r26
	pop r26 ; και r23:r22
	pop r23
	pop r22
	ret 

keypad_to_ascii_sim:
	push r26 ; αποθήκευσε τους καταχωρητές r27:r26 γιατι τους
	push r27 ; αλλάζουμε μέσα στη ρουτίνα
	movw r26 ,r24 ; λογικό ‘1’ στις θέσεις του καταχωρητή r26 δηλώνουν
	; τα παρακάτω σύμβολα και αριθμούς
	ldi r24 ,'*'
	; r26
	;C 9 8 7 D # 0 *
	sbrc r26 ,0
	rjmp return_ascii
	ldi r24 ,'0'
	sbrc r26 ,1
	rjmp return_ascii
	ldi r24 ,'#'
	sbrc r26 ,2
	rjmp return_ascii
	ldi r24 ,'D'
	sbrc r26 ,3 ; αν δεν είναι ‘1’παρακάμπτει την ret, αλλιώς (αν είναι ‘1’)
	rjmp return_ascii ; επιστρέφει με τον καταχωρητή r24 την ASCII τιμή του D.
	ldi r24 ,'7'
	sbrc r26 ,4
	rjmp return_ascii
	ldi r24 ,'8'
	sbrc r26 ,5
	rjmp return_ascii
	ldi r24 ,'9'
	sbrc r26 ,6
	rjmp return_ascii ;
	ldi r24 ,'C'
	sbrc r26 ,7
	rjmp return_ascii
	ldi r24 ,'4' ; λογικό ‘1’ στις θέσεις του καταχωρητή r27 δηλώνουν
	sbrc r27 ,0 ; τα παρακάτω σύμβολα και αριθμούς
	rjmp return_ascii
	ldi r24 ,'5'
	;r27
	;Α 3 2 1 B 6 5 4
	sbrc r27 ,1
	rjmp return_ascii
	ldi r24 ,'6'
	sbrc r27 ,2
	rjmp return_ascii
	ldi r24 ,'B'
	sbrc r27 ,3
	rjmp return_ascii
	ldi r24 ,'1'
	sbrc r27 ,4
	rjmp return_ascii ;
	ldi r24 ,'2'
	sbrc r27 ,5
	rjmp return_ascii
	ldi r24 ,'3' 
	sbrc r27 ,6
	rjmp return_ascii
	ldi r24 ,'A'
	sbrc r27 ,7
	rjmp return_ascii
	clr r24
	rjmp return_ascii
	return_ascii:
	pop r27 ; επανάφερε τους καταχωρητές r27:r26
	pop r26
	ret

write_2_nibbles_sim:
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(6000) ; πρόσβασης
	ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	push r24 ; στέλνει τα 4 MSB
	in r25, PIND ; διαβάζονται τα 4 LSB και τα ξαναστέλνουμε
	andi r25, 0x0f ; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
	andi r24, 0xf0 ; απομονώνονται τα 4 MSB και
	add r24, r25 ; συνδυάζονται με τα προϋπάρχοντα 4 LSB
	out PORTD, r24 ; και δίνονται στην έξοδο
	sbi PORTD, PD3 ; δημιουργείται παλμός Enable στον ακροδέκτη PD3
	cbi PORTD, PD3 ; PD3=1 και μετά PD3=0
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(6000) ; πρόσβασης
	ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	pop r24 ; στέλνει τα 4 LSB. Ανακτάται το byte.
	swap r24 ; εναλλάσσονται τα 4 MSB με τα 4 LSB
	andi r24 ,0xf0 ; που με την σειρά τους αποστέλλονται
	add r24, r25
	out PORTD, r24
	sbi PORTD, PD3 ; Νέος παλμός Enable
	cbi PORTD, PD3
	ret

lcd_data_sim:
	push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
	push r25 ; αλλάζουμε μέσα στη ρουτίνα
	sbi PORTD, PD2 ; επιλογή του καταχωρητή δεδομένων (PD2=1)
	rcall write_2_nibbles_sim ; αποστολή του byte
	ldi r24 ,43 ; αναμονή 43μsec μέχρι να ολοκληρωθεί η λήψη
	ldi r25 ,0 ; των δεδομένων από τον ελεγκτή της lcd
	rcall wait_usec
	pop r25 ;επανάφερε τους καταχωρητές r25:r24
	pop r24
	ret 

lcd_command_sim:
	push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
	push r25 ; αλλάζουμε μέσα στη ρουτίνα
	cbi PORTD, PD2 ; επιλογή του καταχωρητή εντολών (PD2=0)
	rcall write_2_nibbles_sim ; αποστολή της εντολής και αναμονή 39μsec
	ldi r24, 39 ; για την ολοκλήρωση της εκτέλεσης της από τον ελεγκτή της lcd.
	ldi r25, 0 ; ΣΗΜ.: υπάρχουν δύο εντολές, οι clear display και return home,
	rcall wait_usec ; που απαιτούν σημαντικά μεγαλύτερο χρονικό διάστημα.
	pop r25 ; επανάφερε τους καταχωρητές r25:r24
	pop r24
	ret 


lcd_init_sim:
	push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
	push r25 ; αλλάζουμε μέσα στη ρουτίνα

	ldi r24, 40 ; Όταν ο ελεγκτής της lcd τροφοδοτείται με
	ldi r25, 0 ; ρεύμα εκτελεί την δική του αρχικοποίηση.
	rcall wait_msec ; Αναμονή 40 msec μέχρι αυτή να ολοκληρωθεί.
	ldi r24, 0x30 ; εντολή μετάβασης σε 8 bit mode
	out PORTD, r24 ; επειδή δεν μπορούμε να είμαστε βέβαιοι
	sbi PORTD, PD3 ; για τη διαμόρφωση εισόδου του ελεγκτή
	cbi PORTD, PD3 ; της οθόνης, η εντολή αποστέλλεται δύο φορές
	ldi r24, 39
	ldi r25, 0 ; εάν ο ελεγκτής της οθόνης βρίσκεται σε 8-bit mode
	rcall wait_usec ; δεν θα συμβεί τίποτα, αλλά αν ο ελεγκτής έχει διαμόρφωση
	 ; εισόδου 4 bit θα μεταβεί σε διαμόρφωση 8 bit
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24,low(1000) ; πρόσβασης
	ldi r25,high(1000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	ldi r24, 0x30
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0
	rcall wait_usec 
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(1000) ; πρόσβασης
	ldi r25 ,high(1000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	ldi r24,0x20 ; αλλαγή σε 4-bit mode
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0
	rcall wait_usec
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(1000) ; πρόσβασης
	ldi r25 ,high(1000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	ldi r24,0x28 ; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
	rcall lcd_command_sim ; και εμφάνιση δύο γραμμών στην οθόνη
	ldi r24,0x0c ; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
	rcall lcd_command_sim
	ldi r24,0x01 ; καθαρισμός της οθόνης
	rcall lcd_command_sim
	ldi r24, low(1530)
	ldi r25, high(1530)
	rcall wait_usec
	ldi r24 ,0x06 ; ενεργοποίηση αυτόματης αύξησης κατά 1 της διεύθυνσης
	rcall lcd_command_sim ; που είναι αποθηκευμένη στον μετρητή διευθύνσεων και
	 ; απενεργοποίηση της ολίσθησης ολόκληρης της οθόνης
	pop r25 ; επανάφερε τους καταχωρητές r25:r24
	pop r24
	ret
 
 wait_msec:
	push r24			; 2 κύκλοι (0.250 μsec)
	push r25			; 2 κύκλοι (0.250 μsec)
	ldi r24,low(998)		; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
	ldi r25,high(998) 		; 1 κύκλος (0.125 μsec)
	rcall wait_usec			; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
	pop r25				; 2 κύκλοι (0.250 μsec)
	pop r24 			; 2 κύκλοι 
	sbiw r24 , 1			; 2 κύκλοι 
	brne wait_msec			; 1 ή 2 κύκλοι (0.125 or 0.250 μsec)
	ret				; 4 κύκλοι (0.500 μsec)

wait_usec:
	sbiw r24,1			; 2 κύκλοι (0.250 μsec)
	nop				; 1 κύκλος (0.125 μsec)
	nop				; 1 κύκλος (0.125 μsec)
	nop				; 1 κύκλος (0.125 μsec)
	nop				; 1 κύκλος (0.125 μsec)
	brne wait_usec			; 1 ή 2 κύκλοι (0.125 or 0.250 μsec)
	ret				; 4 κύκλοι (0.500 μsec)