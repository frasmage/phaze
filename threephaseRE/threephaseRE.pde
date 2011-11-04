import peasy.*;
//import processing.opengl.*;

/*
 based on ThreePhase by Kyle McDonalds
 
 These three variables are the main "settings".
 
 zscale corresponds to how much "depth" the image has,
 zskew is how "skewed" the imaging plane is.
 
 These two variables are dependent on both the angle
 between the projector and camera, and the number of stripes.
 The sign on both is based on the direction of the stripes
 (whether they're moving up vs down)
 as well as the orientation of the camera and projector
 (which one is above the other).
 
 noiseTolerance can significantly change whether an image
 can be reconstructed or not. Start with it small, and work
 up until you start losing important parts of the image.
 */
float zscale = 120;
float zskew = 22;
float noiseTolerance = 0.10;
float xr = 0;
float yr = 0;
char[] words = {
  'c','u','l','t','u','r','e'
};
String[][] imageList = new String[10][3];
int curSet = 5; //current Image set to load

int inputWidth = 480;
int inputHeight = 720;

PFont font;

PeasyCam cam;

float[][] phase = new float[inputHeight][inputWidth];
boolean[][] mask = new boolean[inputHeight][inputWidth];
boolean[][] process = new boolean[inputHeight][inputWidth];
color[][] cols = new color[inputHeight][inputWidth];

void setup() {
  size(inputWidth, inputHeight, P3D);
  cam = new PeasyCam(this, width);

  font = createFont("helvetica",10);
  
  //setUp image lists, must be named "set1-1.jpg", etc.
  for (int i=0; i<imageList.length;i++) {
    for(int j=0;j<3;j++) {
      imageList[i][j] = "set"+(i+1)+"-"+(j+1)+".jpg";
    }
  }

  phaseWrap();
  phaseUnwrap();
}

void draw () {
  background(0);
  translate(0, -inputHeight / 2); 
  translate(0,0,zscale/2);
  rotateY(radians(xr));
  rotateX(radians(yr));
  int step = 2;
  for (int y = step; y < inputHeight; y += step) {
    float planephase = 0.5 - (y - (inputHeight / 2)) / zskew;
    for (int x = step; x < inputWidth; x += step)
      if (!mask[y][x]) {
        //stroke(map(y,0,inputHeight,0,255),map(x,0,inputWidth,0,255),255);
        stroke(cols[y][x]);
        fill(cols[y][x]);
        //point(x, y, (phase[y][x] - planephase) * zscale);
        textFont(font,8);
        text( words[(y*inputWidth+x)%words.length],x, y, (phase[y][x] - planephase) * zscale);
      }
  }
}

/*void mouseDragged() {
  xr += (mouseX-pmouseX);
  yr += (mouseY-pmouseY);
}*/

