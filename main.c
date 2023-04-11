#define F_CPU 8000000UL // 8MHz CPU Frequency to be considered by the delay macros
#include <avr/io.h>
#include <util/delay.h>
#include <stdbool.h>

unsigned char	ram[2], keypad[2];
unsigned char x, y;
int ascii[16];



unsigned char scan_row(int row){
	unsigned char temp;
	volatile unsigned char pressed_row;

	temp = 0x08;                      //ΑΡΧΙΚΟΠΟΙΩ ΣΤΟ 00001000
	PORTC = temp << row;              //ΚΑΝΩ ΑΡΙΣΤΕΡΗ ΟΛΙΣΘΗΣΗ ΩΣΤΕ ΝΑ ΕΧΩ ΤΗΝ ΑΝΤΙΣΤΟΙΧΗ ΓΡΑΜΜΗ 1
	_delay_ms(1);	                     //ΚΑΘΥΣΤΕΡΗΣΗ ΩΣΤΕ ΝΑ ΠΡΟΛΑΒΕΙ ΝΑ ΓΙΝΕΙ Η ΑΛΛΑΓΗ ΚΑΤΑΣΤΑΣΗΣ
	pressed_row = PINC & 0x0f;          //ΑΠΟΜΟΝΩΝΝΟΝΤΑΙ ΤΑ 4 LSB ΠΟΥ ΔΕΙΧΝΟΥΝ ΠΟΥ ΕΙΝΑΙ ΠΑΤΗΜΕΝΟΙ ΟΙ ΔΙΑΚΟΠΤΕΣ

	return pressed_row;               //ΕΠΙΣΤΡΕΦΕΤΑΙ Η ΘΕΣΗ ΠΟΥ ΕΙΝΑΙ ΠΑΤΗΜΕΝΟΙ ΟΙ ΔΙΑΚΟΠΤΕΣ
}


void scan_keypad() { //ΈΛΕΓΧΩ ΜΙΑ ΜΙΑ ΤΙΣ ΓΡΑΜΜΕΣ 
	unsigned char i; 
	
	i = scan_row(1);	// ΕΛΕΓΧΩ 1η ΓΡΑΜΜΗ
	keypad[1] = ((i & 0x0F) << 4 | (i & 0xF0) >> 4) ; //ΑΠΟΘΗΚΕΥΣΗ ΣΤΑ msb του keypad[1]

	i = scan_row(2);	// ΕΛΕΓΧΩ 2η ΓΡΑΜΜΗ
	keypad[1] += i;		// ΑΠΟΘΗΚΕΥΣΗ ΣΤΑ  lsb του keypad[1]
	
	i = scan_row(3);	// ΕΛΕΓΧΩ 3η ΓΡΑΜΜΗ
  	keypad[0] = ((i & 0x0F) << 4 | (i & 0xF0) >> 4);	// ΑΠΟΘΗΚΕΥΣΗ ΣΤΑ msb του keypad[0]

	i = scan_row(4);	// ΕΛΕΓΧΩ 4η ΓΡΑΜΜΗ
	keypad[0] += i;		// ΑΠΟΘΗΚΕΥΣΗ ΣΤΑ lsb του keypad[0]
}

int scan_keypad_rising_edge() {
	//ΕΛΕΓΧΟΣ ΤΟΥ ΠΛΗΚΤΡΟΛΟΓΙΟΥ ΓΙΑ ΔΙΑΚΟΠΤΕΣ ΠΟΥ ΕΙΝΑΙ ΠΙΕΣΜΕΝΟΙ ΕΝΩ ΠΡΙΝ ΟΧΙ
	
	scan_keypad();	// ΕΛΕΓΧΩ 1η ΦΟΡΑ ΤΟ ΠΛΗΚΤΡΟΛΟΓΙΟ
	
	unsigned char tmp_keypad[2]; //ΕΝΔΙΑΜΕΣΟΣ ΒΟΗΘΗΤΙΚΟΣ ΠΙΝΑΚΑΣ
	
	tmp_keypad[0] = keypad[0];	
	tmp_keypad[1] = keypad[1];	
	
	_delay_ms(15);	//ΕΦΑΡΜΟΖΩ ΚΑΘΥΣΤΕΡΗΣΗ ΓΙΑ ΑΠΟΦΥΓΗ ΣΠΙΝΘΥΡΙΣΜΩΝ 
	
	scan_keypad();	//ΕΛΕΓΧΩ 2η ΦΟΡΑ ΤΟ ΠΛΗΚΤΡΟΛΟΓΙΟ
	
	keypad[0] &= tmp_keypad[0];	// ΣΥΓΚΡΙΝΟΥΜΕ ΜΕ ΤΙΣ ΠΡΟΗΓΟΥΜΕΝΕΣ ΤΙΜΕΣ
	keypad[1] &= tmp_keypad[1];
	
	tmp_keypad[0] = ram[0];	// ΑΝΑΚΑΛΩ ΑΠΟ ΤΗ ΜΝΗΜΗ ΤΙΣ ΠΑΛΙΕΣ ΤΙΜΕΣ
	tmp_keypad[1] = ram[1];	
	
	ram[0] = keypad[0];	// ΣΩΖΩ ΩΣ ΠΑΛΙΕΣ ΤΙΣ ΝΕΕΣ ΤΙΜΕΣ 
	ram[1] = keypad[1];	
	
	keypad[0] &= ~tmp_keypad[0];	// ΒΡΙΣΚΩ ΤΙ ΕΧΕΙ ΠΑΤΗΘΕΙ
	keypad[1] &= ~tmp_keypad[1];	
	
	return (keypad[0] || keypad[1]); 
}

//ΣΥΝΑΡΤΗΣΗ ΓΙΑ ΝΑ ΕΠΙΣΤΡΕΦΕΙ ΤΗΝ ΤΙΜΗ ASCII ΤΟΥ ΠΛΗΚΤΡΟΥ ΠΟΥ ΠΑΤΗΘΗΚΕ 
unsigned char keypad_to_ascii(){
	volatile int j;
	volatile unsigned int temp;
     
	 	for (j=0; j<8; j++){                 //ΨΑΧΝΩ ΣΤΟΝ ΜΙΣΟ ΠΡΩΤΟ ΠΙΝΑΚΑ (ΠΟΥ ΕΧΕΙ ΤΙΣ ΤΙΜΕΣ ΤΩΝ 2 ΤΕΛΕΥΤΑΙΩΝ ΓΡΑΜΜΩΝ)
         temp = 0x01;
		 temp = temp << j;
		 if (keypad[0] & temp){            //ΑΝ ΒΡΩ ΤΗΝ ΤΕΛΙΚΗ ΚΑΤΑΣΤΑΣΗ
			  return ascii[j];             //ΕΠΙΣΤΡΕΦΩ ΤΟΝ ΚΑΤΑΛΛΗΛΟ ASCII ΚΩΔΙΚΟ
		  }
		}
		for (j=0; j<8; j++){                 //ΨΑΧΝΩ ΣΤΟΝ ΔΕΥΤΕΡΟ ΠΡΩΤΟ ΠΙΝΑΚΑ (ΠΟΥ ΕΧΕΙ ΤΙΣ ΤΙΜΕΣ ΤΩΝ 2 ΠΡΩΤΩΝ ΓΡΑΜΜΩΝ)
			temp = 0x01;
			temp = temp << j;
			if (keypad[1] & temp){          //ΑΝ ΒΡΩ ΤΗΝ ΤΕΛΙΚΗ ΚΑΤΑΣΤΑΣΗ
				return ascii[j+8];          //ΕΠΙΣΤΡΕΦΩ ΤΟΝ ΚΑΤΑΛΛΗΛΟ ASCII ΚΩΔΙΚΟ
			}
		}
	return 1;                            //ΑΝ ΔΝ ΤΟ ΒΡΕΙ ΓΥΡΝΑ 1(ΔΕΝ ΘΑ ΦΤΑΣΕΙ ΕΔΩ ΠΟΤΕ)
}

void initialize_ascii_table(void){
	ascii[0] = '*';
	ascii[1] = '0';
	ascii[2] = '#';
	ascii[3] = 'D';
	ascii[4] = '7';
	ascii[5] = '8';
	ascii[6] = '9';
	ascii[7] = 'C';
	ascii[8] = '4';
	ascii[9] = '5';
	ascii[10] = '6';
	ascii[11] = 'B';
	ascii[12] = '1';
	ascii[13] = '2';
	ascii[14] = '3';
	ascii[15] = 'A';
}


unsigned char read4x4(void){
	char ascii_code;     

	if (!scan_keypad_rising_edge()){      //ΑΝ ΔΕΝ ΠΑΤΗΣΕ ΓΥΡΝΑ ΜΗΔΕΝ
		return 0;
	}
	ascii_code = keypad_to_ascii();     //ΑΝ ΠΑΤΗΣΕ ΓΥΡΝΑ ΤΟΝ ΚΑΤΑΛΛΗΛΟ ASCII ΚΩΔΙΚΟ
	//ΜΕ ΒΑΣΗ ΤΟΝ ΠΙΝΑΚΑ ΠΟΥ ΦΤΑΞΑΜΕ, ΤΟΝ ΟΠΟΙΟ ΚΑΙ ΕΠΙΣΤΡΕΦΕΙ
	return ascii_code;
}

int main(void){
	int i;
	volatile unsigned char first_number, second_number;

	DDRB = 0Xff;                           // ΟΡΙΖΩ ΤΟ PORTB ΩΣ ΕΞΟΔΟ
	DDRC = 0xf0;                           // ΟΡΙΖΩ ΤΑ 4MSBΤΟΥ PORTC ΩΣ ΕΞΟΔΟ

	initialize_ascii_table();              // ΑΡΧΙΚΟΠΟΙΩ ΤΟΝ ΠΙΝΑΚΑ ΜΕ ΤΟΥΣ ASCII ΚΩΔΙΚΟΥΣ
	while (1){
	    PORTB = 0; //ΑΡΧΙΚΟΠΟΙΗΣΗ ΣΤΟ ΜΗΔΕΝ ΤΗΣ ΘΥΡΑΣ ΕΞΟΔΟΥ
		do{
			first_number = read4x4();   //ΔΙΑΒΑΖΩ ΤΟΝ 1ο ΑΡΙΘΜΟ
		}
		while(!first_number);          //ΚΟΛΛΑΕΙ ΜΕΧΡΙ ΝΑ ΔΙΑΒΑΣΩ ΤΟΝ 1ο

		do{
			second_number = read4x4();  //ΔΙΑΒΑΖΩ ΤΟΝ 2ο ΑΡΙΘΜΟ
		}
		while(!second_number);          //ΠΕΡΙΜΕΝΩ ΜΕΧΡΙ ΝΑ ΔΙΑΒΑΣΤΕΙ ΚΑΙ Ο 2ος
        
		scan_keypad_rising_edge();      // ΕΛΕΓΧΩ ΑΛΛΗ ΜΙΑ ΦΟΡΑ ΤΟ ΠΛΗΚΤΡΟΛΟΓΙΟ
		
		if ((first_number == '1') & (second_number == '4')){ //ΑΝ ΕΙΝΑΙ Ο ΑΡΙΘΜΟΣ ΤΗΣ ΟΜΑΔΑΣ ΜΑΣ
			PORTB = 0Xff;              //ΑΝΑΒΩ ΤΑ LED ΓΙΑ 4 sec
			_delay_ms(4000);
			PORTB = 0X00;
		}
		else{                           //ΑΛΛΙΩΣ ΑΝΑΒΟΣΒΗΝΩ ΓΙΑ 4sec
			for (i=0; i<4; i++){
				PORTB = 0Xff;
				_delay_ms(500);
				PORTB = 0X00;
				_delay_ms(500);
			}
		}
	}

	return 0;
}
