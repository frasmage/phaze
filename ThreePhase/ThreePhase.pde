import peasy.*;

PeasyCam cam;

int inputWidth, inputHeight;
float[][] phase, distance, depth;
boolean[][] mask, process;
color[][] colors;
int[][] names;

boolean update, exportMesh, exportCloud;
int curSet =8;
float[] zscales = {108,32,88,98,98,180,120,48,108};
float[] zskews = {28,49,28.5,35,35,34,27,30,26};
float[] noises = {.01,.07,.1,.1,.1,.15,0,.03,0};

void setup() {
  size(480, 720, P3D);
  
  loadImages();
  inputWidth = phase1Image.width;
  inputHeight = phase1Image.height;
  phase = new float[inputHeight][inputWidth];
  distance = new float[inputHeight][inputWidth];
  depth = new float[inputHeight][inputWidth];
  mask = new boolean[inputHeight][inputWidth];
  process = new boolean[inputHeight][inputWidth];
  colors = new color[inputHeight][inputWidth];
  names = new int[inputHeight][inputWidth];
  
  cam = new PeasyCam(this, width);  
  setupControls();

  update = true;
}

void draw () {
  background(0);
  translate(-width / 2, -height / 2);
  
  if(update) {
    phaseWrap();
    phaseUnwrap();
    update = false;
  }
  
  makeDepth();
  
  noFill();
  for (int y = 0; y < inputHeight; y += renderDetail)
    for (int x = 0; x < inputWidth; x += renderDetail)
      if (!mask[y][x]) {
        stroke(colors[y][x], 255);
        point(x, y, depth[y][x]);
      }
  
  if(takeScreenshot) {
    saveFrame(getTimestamp() + ".png");
    takeScreenshot = false;
  }
  if(exportMesh) {
    doExportMesh();
    exportMesh = false;
  }
  if(exportCloud) {
    doExportCloud();
    exportCloud = false;
  }
}
