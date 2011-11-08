/** 

 PHASIAL FEATURES 

<br />
<br /> By Sean Fraser & Stephane Dufour
<br /> Based on ThreePhase & Structure Light 3D Scanning by Kyle McDonald
<br /> Kyle's Original on OpenProcessing: http://www.openprocessing.org/visuals/?visualID=1995
<br /> Kyle's article on Instructibles: http://www.instructables.com/id/Structured-Light-3D-Scanning/
<br /> Structured Light Utilities: http://code.google.com/p/structured-light/downloads/list

*/
//Camera Manipulation library
import peasy.*;
PeasyCam cam;

// ------------------------------------------ //
//                  GLOBAL VARS
// ------------------------------------------ //
int renderDetail; //should be 1-2 for points or 4+ for text
int renderPoint = 2;
int renderText =5;
boolean displayMode = true; //false == points, true == text

//handlers for faces
int setLim = 9; //number of image sets, max index+1
ThreePhaseCloud[] faces = new ThreePhaseCloud[setLim]; //face Objects, contains 3d pixel clouds
int curSet =8; //currently selected index
ThreePhaseCloud currentFace; //handler for currently selected object

//holders for transition animation
float[][] targetDepth;
float[][] currentDepth;
color[][] targetColor;
color[][] currentColor;
float speed = .04; //rate of change per frame

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

//Variables for text animation
String keywordList = "Body, Mind, Soul, Inscription, Taboo, Culture, Values, Beliefs, Identity, Ideology, Control, Sublimation, Education, Extension, Cyborg, Technology, Evolution, Contours, Gender, Sexuality, Gaze, Growth, Performativity, Subversion, Acts, Construction, Regulation, Discourse, Discipline, Civilization, Power, Self, Other";
String[] keywords;
String twitterResponse;
String displayText;
int currTopic;
int nextSwitchLetter = 0;
int switchSpeed = 30;
int maxSwitchLength = int((480*720)/sq(renderText));
int nextLetter = maxSwitchLength;
PFont font;

//Variables for camera animation
float zDistance = 50;
float yRotation = PI/4;
float yRotIncrement =.005;
int rotDirection =1;

void setup() {
  size(480, 720, P3D);
  noSmooth();
  //instantiate camera
  //cam = new PeasyCam(this, width);
  font = createFont("helvetica", 30);
  textFont(font, 12);
  textAlign(CENTER);
  textMode(MODEL);
  
  //instantiate facial clouds
  for(int i =0;i<faces.length;i++) {
    faces[i] = new ThreePhaseCloud(i,zscales[i],zskews[i],noises[i]);
  }
  currentFace = faces[curSet]; //set to default
  
  //set global depth and color calculators to match default image
  targetDepth = faces[curSet].depth; //set to default
  currentDepth = faces[curSet].duplicateDepthArray(); //make a new array which is duplicate of default
  targetColor = faces[curSet].colors; //set to default
  currentColor = faces[curSet].duplicateColorArray(); //make a new array which is duplicate of default
  
  //set default render values
  if(displayMode){
    renderDetail = renderText;
  }else{
    renderDetail = renderPoint;
  }
  
  
  //set up text
  keywords = split(keywordList,", ");
  newTopic(); //generate new twitter call
  displayText = twitterResponse;
}

void draw () {
  background(0);
  
  //process camera position
  rotateY(yRotation);
  //translate(-width / 2, -height / 2,zDistance);
  translate(0,0,zDistance);
  yRotation+=yRotIncrement*rotDirection;
  if(yRotation>PI/4){
    rotDirection = -1;
    nextFace();
  }else if(yRotation < -PI/4){
    rotDirection = 1;
    nextFace();
  }
  
  
  if(displayMode){
    nextLetter = 0;
    switchLetters();
  }
  
  //display each pixel in the currently selected face.
  noFill();
  for (int y = 0; y < currentFace.inputHeight; y += renderDetail){
    for (int x = 0; x < currentFace.inputWidth; x += renderDetail){
      
      //move pixel depth towards target 
      if(currentDepth[y][x] != targetDepth[y][x]){ //if not already there
        currentDepth[y][x] += (targetDepth[y][x]-currentDepth[y][x])*speed;
      }
      //adjust pixel colors
      if(currentColor[y][x] != targetColor[y][x]){ //if not already there
        currentColor[y][x] = mergeColors(currentColor[y][x], targetColor[y][x], speed);
      }
      
      
      if (!currentFace.mask[y][x]) { //if not black pixel
        //OPTION 1 use points to create a mesh of the face
        //use lower renderDetail (more dots)
        if(!displayMode){
          stroke(currentColor[y][x],255);
          point(x, y, currentDepth[y][x]);
        }
        
        //OPTION 2 use text to cover the face
        //use higher renderDetail (less glyphs)
        else{
          pushMatrix();
          translate(x,y, currentDepth[y][x]);
          fill(currentColor[y][x],255);
          text(getNextLetter(false),0,0,0);
          popMatrix();
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
        nextFace(i);
        break;
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
      maxSwitchLength =int((480*720)/sq(renderDetail));
    }
    
  }
}

//function returns color approaching target
color mergeColors(color current, color target, float speed){
  int ta = (target >> 24) & 0xFF;   // target alpha
  int tr = (target >> 16) & 0xFF;   // target red
  int tg = (target >> 8) & 0xFF;    // target green
  int tb = target & 0xFF;           // target blue
  int ca = (current >> 24) & 0xFF;  // current alpha
  int cr = (current >> 16) & 0xFF;  // current red
  int cg = (current >> 8) & 0xFF;   // current green
  int cb = current & 0xFF;          // current blue
  
  //calculate differences
  float vala = ((ta-ca)*speed);
  float valr = ((tr-cr)*speed);
  float valg = ((tg-cg)*speed);
  float valb = ((tb-cb)*speed);
  
  //make sure difference values are great enough to cause change
  //bitwise leftshift will only accept ints 
  if(vala > 0 && vala < 1){
    vala = 1;
  }else if(vala < 0 && vala > -1){
    vala = -1;
  }
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
  //make change
  ca +=(int) vala;
  cr +=(int) valr; //adjsut red
  cg +=(int) valg; //adjust green
  cb +=(int) valb; //adjust blue
  
  //store new values
  ca = ca << 24;
  cr = cr <<16;
  cg = cg <<8;
  return ca | cr | cg | cb;    
}

//function returns the next character in the list of words.
char getNextLetter(boolean ignore){
  nextLetter++;
  if(ignore){ //ignore commas and spaces
    while(displayText.charAt(nextLetter%displayText.length()) == ',' || 
      displayText.charAt(nextLetter%displayText.length()) == ' '){
      nextLetter++;
    }
  }
  return displayText.charAt((nextLetter-1)%displayText.length());
}

void switchLetters(){
  if(nextSwitchLetter+switchSpeed < maxSwitchLength){
    for(int i = 0; i<switchSpeed;i++){
      nextSwitchLetter++;
      
      if(displayText.charAt(nextSwitchLetter%displayText.length()) != twitterResponse.charAt(nextSwitchLetter%twitterResponse.length())){
        displayText = replaceCharAt(displayText,twitterResponse.charAt(nextSwitchLetter%twitterResponse.length()),nextSwitchLetter%displayText.length());
      }
    }
  }  
}

String replaceCharAt(String initial, char replacement, int position ) {        
 StringBuffer  buffer = new StringBuffer(initial); // Word in which we replace        
 buffer.setCharAt( position, replacement );    
 return (buffer.toString());
}

void nextFace(int nextSet){
  curSet = nextSet;
  currentFace = faces[curSet];
  targetDepth = faces[curSet].depth;
  targetColor = faces[curSet].colors;
  newTopic();
}

void nextFace(){
  int nextSet =int(random(setLim));
  if(curSet!=nextSet){ //if not the same face
    curSet = nextSet;
    currentFace = faces[curSet];
    targetDepth = faces[curSet].depth;
    targetColor = faces[curSet].colors;
    newTopic();
  }
  else{ //try again
    nextFace();
  }
}
