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

//handlers for faces
int setLim = 9; //number of image sets, max index+1
Cloud[] faces = new Cloud[setLim]; //face Objects, contains 3d pixel clouds
int curSet =0; //currently selected index
Cloud currentFace; //handler for currently selected object

//holders for transition animation
float[][] targetDepth;
float[][] currentDepth;
float[][] pastDepth;
float speed = .04;
color[][] targetColor;
color[][] currentColor;
color[][] pastColor;



//array of predetermined values, should have setLim values, 
//see kyle's version to guess and check good values for your set
float[] zscales = {108,32,88,98,98,180,120,48,108};
float[] zskews = {28,49,28.5,35,35,34,27,30,26};
float[] noises = {.01,.07,.1,.1,.1,.15,0,.03,0};

//temp image objects to be used for processing
PImage phase1Image, phase2Image, phase3Image;


int renderDetail =2;


void setup() {
  size(480, 720, P3D);
  
  //instantiate camera
  cam = new PeasyCam(this, width);
  
  //instantiate facial clouds
  for(int i =0;i<faces.length;i++) {
    faces[i] = new Cloud(i,zscales[i],zskews[i],noises[i]);
  }
  currentFace = faces[curSet]; //set to default
  currentDepth = pastDepth = targetDepth = faces[curSet].depth;
  currentColor = pastColor = targetColor = faces[curSet].colors;
  
  //now that we are done with them, empty the image containers from memory
  phase1Image = null;
  phase2Image = null;
  phase3Image = null;
  
}

void draw () {
  background(0);
  translate(-width / 2, -height / 2);
  
  
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
        //stroke(currentFace.colors[y][x], 255); //set stroke color
        stroke(currentColor[y][x],255);
        point(x, y, currentDepth[y][x]);
      }
    }
  }
}

void keyPressed() {
  //if key pressed is between 1 and setLim
  for(int i =0; i<setLim;i++) {
    if(key == char(49+i)) {
      //set current face to number key pressed
      curSet = i;
      currentFace = faces[curSet];
      targetDepth = faces[curSet].depth;
      targetColor = faces[curSet].colors;
    }
  }
}


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
  //make sure values are integers and make a change
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
