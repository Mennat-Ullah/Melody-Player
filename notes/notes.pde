/*
  Melody
 Plays a melody 
 */
#include "pitches.h"
#include <DuinOs.h>
#include <DuinOs\queue.h>
#include <duinos\FreeRTOS.h>
#include <Keypad.h>
#include <LiquidCrystal.h>

const byte ROWS = 4; //four rows
const byte COLS = 4; //four columns
//define the cymbols on the buttons of the keypads
char hexaKeys[ROWS][COLS] = {
 {'1','2','3','A'}, 
 {'#','5','6','B'}, 
 {'0','8','9','C'},
 {'*','0','#','D'}
};
byte rowPins[ROWS] = {7, 6, 5, 4};   //connect to the row pinouts of the keypad
byte colPins[COLS] = {3, 2, 1, 0};  //connect to the column pinouts of the keypad
//initialize an instance of class NewKeypad
Keypad customKeypad = Keypad( makeKeymap(hexaKeys), rowPins, colPins, ROWS, COLS); 

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(13, 12, 11, 10, 9, 8);

// notes in the melody:
int melody[][14] = { {NOTE_C1 , NOTE_C1 , NOTE_G1 , NOTE_G1 , NOTE_A1 , NOTE_A1 , NOTE_G1 , NOTE_F1 , NOTE_F1 , NOTE_E1 , NOTE_E1 , NOTE_D1 , NOTE_D1 ,NOTE_C1},
{ NOTE_B0 , NOTE_C1 , NOTE_F1 , NOTE_D2 , NOTE_D1 , NOTE_D2 ,NOTE_A1 , NOTE_E2 , NOTE_B0 , NOTE_C1 , NOTE_F1 , NOTE_D2 , NOTE_D1 , NOTE_D2 } ,
{NOTE_G1 , NOTE_G1 , NOTE_F1 , NOTE_F1 , NOTE_E1 , NOTE_E1 , NOTE_D1 , NOTE_G1 , NOTE_G1 , NOTE_F1 , NOTE_F1 , NOTE_E1 , NOTE_E1 , NOTE_D1 }};

// note durations: 4 = quarter note, 8 = eighth note, etc.:
int noteDurations[][14] = { {4,4,4,4,4,4,8,4,4,4,4,4,4,8},
{4, 8, 8, 4,4,4,4,4 , 4, 8 ,8, 4,4 },
{4,4,4,4,4,4,8,4,4,4,4,4,4,8}};
 
char* name_note[] = {"note 1" , "note 2" , "note 3"}; 

byte bars[8][8] = {
  {B00000,B00000,B00000,B00000,B00000,B00000,B00000,B11111},
  {B00000,B00000,B00000,B00000,B00000,B00000,B11111,B11111},
  {B00000,B00000,B00000,B00000,B00000,B11111,B11111,B11111},
  {B00000,B00000,B00000,B00000,B11111,B11111,B11111,B11111},
  {B00000,B00000,B00000,B11111,B11111,B11111,B11111,B11111},
  {B00000,B00000,B11111,B11111,B11111,B11111,B11111,B11111},
  {B00000,B11111,B11111,B11111,B11111,B11111,B11111,B11111},
  {B11111,B11111,B11111,B11111,B11111,B11111,B11111,B11111}
};

int i_spekar = 0 ;
int i_LCD = 0 ;
int nameprint = 0 ;
int thisNote = 0 ;
boolean play ;
  
xQueueHandle QHandle ;

declareTaskLoop(LCD);
declareTaskLoop(Spekar);
taskLoop(LCD)
{
       lcd.clear();
      
        xQueueReceive( QHandle , &nameprint , (portTickType)10 ) ;
      
         // lcd.setCursor(col, row)
	lcd.setCursor(1 , 0);
	// print the number of seconds since reset:
	lcd.print(name_note[nameprint]);


        lcd.setCursor(0 , 1);
        int maxbar =  melody[i_spekar][thisNote] / 10  ;          
        for (int i=1; i <= maxbar && maxbar < 9 ; i++){
              lcd.write(byte(i));
           }
           
        delay(100);
}


taskLoop(Spekar)
{
   // iterate over the notes of the melody:
   for ( thisNote = 0; thisNote < 8; thisNote++) {

          // to calculate the note duration, take one second 
          // divided by the note type.
          //e.g. quarter note = 1000 / 4, eighth note = 1000/8, etc.
          int noteDuration = 1000/noteDurations[i_spekar][thisNote];  
          tone(A0, melody[i_spekar][thisNote],noteDuration); 
      
          // to distinguish the notes, set a minimum time between them.
          // the note's duration + 30% seems to work well:
          int pauseBetweenNotes = noteDuration * 1.30;
          delay(pauseBetweenNotes);
          // stop the tone playing:
          noTone(8);
  }
}

void setup() {
  
   for (int i=1; i < 9; i++){
    lcd.createChar(i,  bars[i-1]);
  }
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("Hello ");
   delay(100);
  lcd.clear();
   
  createTaskLoop(LCD, NORMAL_PRIORITY);
  createTaskLoop(Spekar, NORMAL_PRIORITY);
  
  QHandle = xQueueCreate(3 , 4 );
  xQueueSend( QHandle , &i_LCD , (portTickType)10  );

  
 }
 
void loop(){
    
   char customKey = customKeypad.getKey();
 // Serial.println(customKey);
  delay(100);
  
  if (customKey != NO_KEY)
  {
     if(customKey == '*')
    {
      if(i_LCD != 0)
        i_LCD -- ;
        // Serial.println(i_LCD);
    }
    else if(customKey == '#')
    {
      if(i_LCD != 2 )
        i_LCD ++ ;
        // Serial.println(i_LCD);
    }
    else if (customKey == '0')
    {
           if (play)
           {
             if ( i_spekar == i_LCD ){
               suspendTask(Spekar); 
               play = false ;
             }
             else
              i_spekar = i_LCD ;
           }
          else
          {
            i_spekar = i_LCD ;
            resumeTask(Spekar);
            play = true ; 
          }   
    } 

    xQueueSend( QHandle , &i_LCD , (portTickType)10 );
  
  }
}
  
  
