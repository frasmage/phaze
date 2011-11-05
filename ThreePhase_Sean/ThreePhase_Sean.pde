

/** PHASIAL FEATURES 
<br />By Sean Fraser & Stephane Dufour
<br />Based on ThreePhase & Structure Light 3D Scanning by Kyle McDonald
<br />Kyle's Original on OpenProcessing: http://www.openprocessing.org/visuals/?visualID=1995
<br />Kyle's article on Instructibles: http://www.instructables.com/id/Structured-Light-3D-Scanning/
<br />Structured Light Utilities: http://code.google.com/p/structured-light/downloads/list
*/
//Camera Manipulation library
import peasy.*;
PeasyCam cam;


// ------------------------------------------ //
//                  GLOBAL VARS
// ------------------------------------------ //
int renderDetail =2; //should be 1-2 for points or 4+ for text
boolean displayMode = false;

//handlers for faces
int setLim = 9; //number of image sets, max index+1
ThreePhaseCloud[] faces = new ThreePhaseCloud[setLim]; //face Objects, contains 3d pixel clouds
int curSet =8; //currently selected index
ThreePhaseCloud currentFace; //handler for currently selected object

//holders for transition animation
float[][] targetDepth;
float[][] currentDepth;
float[][] pastDepth;
float speed = .04;
color[][] targetColor;
color[][] currentColor;
color[][] pastColor;

//array of predetermined values, should have setLim # of values, 
//see kyle's version to guess and check good values for your image sets
float[] zscales = {108,32,88,98,98,180,120,48,108};
float[] zskews = {28,49,28.5,35,35,34,27,30,26};
float[] noises = {.01,.07,.1,.1,.1,.15,0,.03,0};

//temp image objects to be used for processing
//image files must be in /img folder and 
//be named set#-1.jpg, set#-2.jpg and set#-3.jpg,
//where # is the set ID and 1,2,3 is the order of the images in sequence
PImage phase1Image, phase2Image, phase3Image;

//text to be mapped
String keywords = "Body, Mind, Soul, Inscription, Taboo, Culture, Values, Beliefs, Identity, Ideology, Control, Sublimation, Education, Extension, Cyborg, Technology, Evolution, Contours, Gender, Sexuality, Gaze, Growth, Performativity, Subversion, Acts, Construction, Regulation, Discourse, Discipline, Civilization, Power, Self, Other";
int nextLetter = 0;
PFont font;


void setup() {
  size(480, 720, PD);
  
  //instantiate camera
  cam = new PeasyCam(this, width);
  font = createFont("helvetica", 30);
  textFont(font, 12);
  
  //instantiate facial clouds
  for(int i =0;i<faces.length;i++) {
    faces[i] = new ThreePhaseCloud(i,zscales[i],zskews[i],noises[i]);
  }
  currentFace = faces[curSet]; //set to default
  
  //set global depth and color calculators to default
  pastDepth = targetDepth = faces[curSet].depth; //set to default
  currentDepth = new float[faces[curSet].inputHeight][faces[curSet].inputHeight];
  currentDepth = faces[curSet].duplicateDepthArray(); //make a new array which is duplicate of default
  pastColor = targetColor = faces[curSet].colors; //set to default
  currentColor = faces[curSet].duplicateColorArray(); //make a new array which is duplicate of default
  
  
}

void draw () {
  background(0);
  translate(-width / 2, -height / 2);
  nextLetter = 0;
  
  //display each pixel in the currently selected face.
  noFill();
  for (int y = 0; y < currentFace.inputHeight; y += renderDetail){
    for (int x = 0; x < currentFace.inputWidth; x += renderDetail){
      
      //move pixel depth towards target 
      if(currentDepth[y][x] != targetDepth[y][x]){
        currentDepth[y][x] += (targetDepth[y][x]-currentDepth[y][x])*speed;
      }
      //adjust pixel colors
      if(currentColor[y][x] != targetColor[y][x]){
        currentColor[y][x] = mergeColors(currentColor[y][x], targetColor[y][x]);
      }
      
      if (!currentFace.mask[y][x]) {
        //OPTION 1 use points to create a mesh of the face
        //use lower renderDetail (more dots)
        if(!displayMode){
          stroke(currentColor[y][x],255);
          point(x, y, currentDepth[y][x]);
        }
        
        //OPTION 2 use text to cover the face
        //use higher renderDetail (less glyphs)
        else{
          fill(currentColor[y][x],255);
          text(getNextLetter(false),x, y, currentDepth[y][x]);
        }
      }
    }
  }
}

void keyPressed() {
  //if key pressed is between 1 and setLim
  for(int i =0; i<setLim;i++) {
    if(key == char(49+i)) {
      if(i!=curSet){
        //set current face to number key pressed
        curSet = i;
        currentFace = faces[curSet];
        targetDepth = faces[curSet].depth;
        targetColor = faces[curSet].colors;
      }
    }
  }
  if(key == 'm' || key == 'M'){
    if(displayMode){
      displayMode = false;
      renderDetail = 2;
    }else{
      displayMode = true;
      renderDetail = 5;
    }
    
  }
}

//function returns color approach target
//
color mergeColors(color current, color target){
  int tr = (target >> 16) & 0xFF;  // Faster way of getting red
  int tg = (target >> 8) & 0xFF;   // Faster way of getting green
  int tb = target & 0xFF;          // Faster way of getting blue
  int cr = (current >> 16) & 0xFF;  // Faster way of getting red
  int cg = (current >> 8) & 0xFF;   // Faster way of getting green
  int cb = current & 0xFF;          // Faster way of getting blue
  
  float valr = ((tr-cr)*speed);
  float valg = ((tg-cg)*speed);
  float valb = ((tb-cb)*speed);
  //make sure are great enough to cause change 
  if(valr > 0 && valr < 1){
    valr = 1;
  }else if(valr < 0 && valr > -1){
    valr = -1;
  }
  if(valg > 0 && valg < 1){
    valg = 1;
  }else if(valg < 0 && valg > -1){
    valg = -1;
  }
  if(valb > 0 && valb < 1){
    valb = 1;
  }else if(valb < 0 && valb > -1){
    valb = -1;
  }
  cr += int(valr); //adjsut red
  cg += int(valg); //adjust green
  cb += int(valb); //adjust blue
  
  //store new values
  cr = cr <<16;
  cg = cg <<8;
  return cr | cg | cb;    
}

//function returns the next character in the list of words.
char getNextLetter(boolean ignore){
  nextLetter++;
  if(ignore){ //ignore commas and spaces
    if(keywords.charAt(nextLetter%keywords.length()) == ','){
      nextLetter++;
    }
    if (keywords.charAt(nextLetter%keywords.length()) == ' '){
      nextLetter++;
    }
  }x  
  return keywords.charAt((nextLetter-1)%keywords.length());
}


