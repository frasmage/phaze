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


//array of predetermined values, should have setLim values, 
//see kyle's version to guess and check good values for your set
float[] zscales = {108,32,88,98,98,180,120,48,108};
float[] zskews = {28,49,28.5,35,35,34,27,30,26};
float[] noises = {.01,.07,.1,.1,.1,.15,0,.03,0};

//temp image objects to be used for processing
PImage phase1Image, phase2Image, phase3Image;



void setup() {
  size(480, 720, P3D);
  
  //instantiate camera
  cam = new PeasyCam(this, width);
  
  //instantiate facial clouds
  for(int i =0;i<faces.length;i++) {
    faces[i] = new Cloud(i,zscales[i],zskews[i],noises[i]);
  }
  currentFace = faces[curSet]; //set to default
  
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
  for (int y = 0; y < currentFace.inputHeight; y += currentFace.renderDetail){
    for (int x = 0; x < currentFace.inputWidth; x += currentFace.renderDetail){
      if (!currentFace.mask[y][x]) {
        stroke(currentFace.colors[y][x], 255); //set stroke color
        point(x, y, currentFace.depth[y][x]);
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
    }
  }
}

