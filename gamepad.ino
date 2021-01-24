/* Program uses two potentiometers (A4, A5) and two push-buttons
* (2, 3) to function as a controller for Conway's Game of Life
* running on a Processing sketch on a connected computer.
* The push-buttons pause and reset the game, and the
* potentiometers are used to move around while paused similar
* to an Etch A Sketch.
*/

int data[4]; 
String transmission;

void setup() {
  Serial.begin(9600);
  pinMode(2, INPUT); // Reset button
  pinMode(3, INPUT); // Pause button
}

void loop() {
  data[0] = map(analogRead(A5), 0, 1023, 0, 255); // xPos
  delay(1); // ADC can only read values so quickly
  data[1] = map(analogRead(A4), 0, 1023, 0, 255); // yPos
  data[2] = map(digitalRead(3), 0, 1,    0, 255); // Pause
  data[3] = map(digitalRead(2), 0, 1,    0, 255); // Reset

  transmission = String(data[0])
                 + "," + String(data[1])
                 + "," + String(data[2])
                 + "," + String(data[3]);

  Serial.println(transmission);
  delay(30);  // Needed since Processing draw() only
              // loops 60 times a second
}
