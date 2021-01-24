// UiBooster library for creating UI to prompt user for screen size input
import uibooster.*;
import uibooster.components.*;
import uibooster.model.*;
import uibooster.model.formelements.*;
import uibooster.utils.*;

// Import Serial class for sending & receiving data using the serial communication protocol
import processing.serial.*;


// Create Serial object named myPort
Serial myPort;

// String variable to store incoming information from Arduino
String data;

// Integer variables for recording current cursor location on the display window
int xPos = 0;
int yPos = 0;

// Screen resolution
int w = 0;
int h = 0;

// Boolean variable to determine when to pause the simulation
boolean pause = false;
// Used to determine the initial signal of the pause button being pressed
boolean prevPauseSignal = false;
// Tracks paused / unpaused to determine behavior when paused button is pressed
boolean isPaused = false;
// Detect when user wants to reset the game
boolean reset = false;

// Size of cells
int cellSize = 5;

// How likely for a cell to be alive at start (in percentage)
float probabilityOfAliveAtStart = 15;

// Variables for timer
int interval = 100;
int lastRecordedTime = 0;

// Colors for active/inactive cells
color alive = color(0, 200, 0);
color dead = color(0);

// Array of cells
int[][] cells; 
// Buffer to record the state of the cells and use this while changing the others in the interations
int[][] cellsBuffer;

void settings(){
  // Resolution warning
  new UiBooster().showWarningDialog("The higher the resolution the more delay in Serial communication. Try 256x256.", "WARN");
  
  // Create UI to prompt for screen width and height
  while (w < 128 || w > displayWidth)
    w = int(new UiBooster().showTextInputDialog("Enter width between 128 and "  + displayWidth  + "."));
  while (h < 128 || h > displayHeight)
    h = int(new UiBooster().showTextInputDialog("Enter height between 128 and " + displayHeight + "."));

  // To use variables as parameters for size(), place it in settings() instead of setup()
  size (w, h);
  noSmooth();
}

void setup() {
  // Instantiate arrays 
  cells = new int[width/cellSize][height/cellSize];
  cellsBuffer = new int[width/cellSize][height/cellSize];

  // This stroke will draw the background grid
  stroke(48);

  // Initialization of cells
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      float state = random (100);
      if (state > probabilityOfAliveAtStart) { 
        state = 0;
      }
      else {
        state = 1;
      }
      cells[x][y] = int(state); // Save state of each cell
    }
  }
  background(0); // Fill in black in case cells don't cover all the windows
  
  // Initialize myPort as a Serial object if Arduino port is detected
  // Port needed here is system dependent, use println(Serial.list()) to list ports
  if (Serial.list().length > 1)
    myPort = new Serial(this, Serial.list()[1], 9600);
  else
    exit();
}

void draw() {
  // Check if there is information from the Arduino
  if (myPort.available() > 0){
    // If there is, read the string in the serial buffer into data
    data = myPort.readStringUntil('\n');
    // Ensure data was read correctly
    if (data != null){
      // Break up the string into three elements and place in string array
      String list[] = (split(data, ','));
      // Check for expected number of values
      if (list.length == 4){
        // Map x and y values to chosen screen resolution
        xPos = int(map(float(list[0]), 0, 255, 0, float(w) - 1));
        yPos = int(map(float(list[1]), 0, 255, 0, float(h) - 1));
        if (int(list[2]) == 0)
          pause = false;
        else if (int(list[2]) == 255)
          pause = true;
        if (list[3].length() == 3)       // Necessary because list[3] includes newline character
          reset = false;                 // as two additional characters, so list[3] is either
        else if (list[3].length() == 5)  // "0\n" or "255\n". The latter being True
          reset = true;
      }
      println(xPos + " " + yPos + " " + pause + " " + reset);
    }
  }

  // Draw grid
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      if (cells[x][y]==1) {
        fill(alive); // If alive
      }
      else {
        fill(dead); // If dead
      }
      rect (x*cellSize, y*cellSize, cellSize, cellSize);
    }
  }
  
  // Check if pause button was just pressed. If so, switch between pause / unpause
  if (pause && !prevPauseSignal){
    isPaused = !isPaused;
    println("game state CHANGED: " + isPaused);
  }
  prevPauseSignal = pause;
  
  // Iterate if timer ticks
  if (millis()-lastRecordedTime>interval) {
    if (!isPaused) {
      iteration();
      lastRecordedTime = millis();
    }
  }
  
  // Create new cells manually on pause
  if (isPaused) {
    // Map and avoid out of bound errors
    int xCellOver = int(map(xPos, 0, width, 0, width/cellSize));
    xCellOver = constrain(xCellOver, 0, width/cellSize-1);
    int yCellOver = int(map(yPos, 0, height, 0, height/cellSize));
    yCellOver = constrain(yCellOver, 0, height/cellSize-1);

    // Check against cells in buffer
    if (cellsBuffer[xCellOver][yCellOver]==1) { // Cell is alive
      cells[xCellOver][yCellOver]=0; // Kill
      fill(dead); // Fill with kill color
    }
    else { // Cell is dead
      cells[xCellOver][yCellOver]=1; // Make alive
      fill(alive); // Fill alive color
    }
  }
  else if (pause && !isPaused) { // And then save to buffer once unpaused
    // Save cells to buffer (so we opeate with one array keeping the other intact)
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        cellsBuffer[x][y] = cells[x][y];
      }
    }
  }
  
  if (reset){
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        float state = random (100);
        if (state > probabilityOfAliveAtStart) {
          state = 0;
        }
        else {
          state = 1;
        }
        cells[x][y] = int(state); // Save state of each cell
      }
    }
  }
}

void iteration() { // When the clock ticks
  // Save cells to buffer (so we opeate with one array keeping the other intact)
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      cellsBuffer[x][y] = cells[x][y];
    }
  }

  // Visit each cell:
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      // And visit all the neighbours of each cell
      int neighbours = 0; // We'll count the neighbours
      for (int xx=x-1; xx<=x+1;xx++) {
        for (int yy=y-1; yy<=y+1;yy++) {  
          if (((xx>=0)&&(xx<width/cellSize))&&((yy>=0)&&(yy<height/cellSize))) { // Make sure you are not out of bounds
            if (!((xx==x)&&(yy==y))) { // Make sure to to check against self
              if (cellsBuffer[xx][yy]==1){
                neighbours ++; // Check alive neighbours and count them
              }
            } // End of if
          } // End of if
        } // End of yy loop
      } //End of xx loop
      // We've checked the neigbours: apply rules!
      if (cellsBuffer[x][y]==1) { // The cell is alive: kill it if necessary
        if (neighbours < 2 || neighbours > 3) {
          cells[x][y] = 0; // Die unless it has 2 or 3 neighbours
        }
      } 
      else { // The cell is dead: make it live if necessary      
        if (neighbours == 3 ) {
          cells[x][y] = 1; // Only if it has 3 neighbours
        }
      } // End of if
    } // End of y loop
  } // End of x loop
} // End of function
