class Cloud {
  // ------------------------------------------ //
  //                  PROPERTIES
  // ------------------------------------------ //
  public int mySet;
  public float noiseThreshold;
  public float zscale;
  public float zskew; 

  int inputWidth, inputHeight;
  float[][] phase, distance, depth;
  boolean[][] mask, process;
  color[][] colors;
  int[][] names;

  // ------------------------------------------ //
  //                  METHODS
  // ------------------------------------------ //

  //Constructor 1
  public Cloud (int setNum, float zsc,float zsk, float noises) {
    mySet = setNum;
    zscale = zsc;
    zskew =zsk;
    noiseThreshold=noises;

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
    
    phaseWrap();
    phaseUnwrap();
    makeDepth();
  }


  /*
   PHASE WRAP
   
   Go through all the pixels in the three phase images,
   and determine their wrapped phase. Ignore noisy pixels.
   */

  PImage fitToScreen(PImage img) {
    if(img.width > width)
      img.resize(width, (img.height * width) / img.width);
    else if(img.height > height)
      img.resize((img.width * height) / img.height, height);
    return img;
  }

  void loadImages() {
    phase1Image = fitToScreen(loadImage("img/set"+mySet+"-1.jpg"));
    phase2Image = fitToScreen(loadImage("img/set"+mySet+"-2.jpg"));
    phase3Image = fitToScreen(loadImage("img/set"+mySet+"-3.jpg"));
  }

  void phaseWrap() {
    float sqrt3 = sqrt(3);
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {     
        int i = x + y * inputWidth;  

        color color1 = phase1Image.pixels[i];
        color color2 = phase2Image.pixels[i];
        color color3 = phase3Image.pixels[i];

        float phase1 = averageBrightness(color1);
        float phase2 = averageBrightness(color2);
        float phase3 = averageBrightness(color3);

        float phaseRange = max(phase1, phase2, phase3) - min(phase1, phase2, phase3);

        mask[y][x] = phaseRange <= noiseThreshold;
        process[y][x] = !mask[y][x];
        distance[y][x] = phaseRange;

        // this equation can be found in Song Zhang's
        // "Recent progresses on real-time 3D shape measurement..."
        // and it is the "bottleneck" of the algorithm
        // it can be sped up with a look up table, which has the benefit
        // of allowing for simultaneous gamma correction.
        phase[y][x] = atan2(sqrt3 * (phase1 - phase3), 2 * phase2 - phase1 - phase3) / TWO_PI;

        // build color based on the lightest channels from all three images
        colors[y][x] = blendColor(blendColor(color1, color2, LIGHTEST), color3, LIGHTEST);
      }
    }

    for (int y = 1; y < inputHeight - 1; y++) {
      for (int x = 1; x < inputWidth - 1; x++) {
        if(!mask[y][x]) {
          distance[y][x] = (
          diff(phase[y][x], phase[y][x - 1]) +
            diff(phase[y][x], phase[y][x + 1]) +
            diff(phase[y][x], phase[y - 1][x]) +
            diff(phase[y][x], phase[y + 1][x])) / distance[y][x];
        }
      }
    }
  }

  float averageBrightness(color c) {
    return (red(c) + green(c) + blue(c)) / (255 * 3);
  }

  float diff(float a, float b) {
    float d = a < b ? b - a : a - b;
    return d < .5 ? d : 1 - d;
  }

  /*
  PHASE UNWRAP
   
   Use the wrapped phase information,  and propagate it across the boundaries.
   This implementation uses a priority-based propagation algorithm.
   
   Because the algorithm starts in the center and propagates outwards,
   so if you have noise (e.g.: a black background, a shadow) in
   the center, then it may not reconstruct your image.
   */

  PriorityQueue toProcess;
  long position;

  void phaseUnwrap() {
    int startX = inputWidth / 2;
    int startY = inputHeight / 2;

    toProcess = new PriorityQueue();
    toProcess.add(new WrappedPixel(startX, startY, 0, phase[startY][startX]));

    while(!toProcess.isEmpty()) {
      WrappedPixel cur = (WrappedPixel) toProcess.poll();
      int x = cur.x;
      int y = cur.y;
      if(process[y][x]) {
        phase[y][x] = cur.phase;
        process[y][x] = false;
        float d = cur.distance;
        float r = phase[y][x];
        if (y > 0)
          phaseUnwrap(x, y-1, d, r);
        if (y < inputHeight-1)
          phaseUnwrap(x, y+1, d, r);
        if (x > 0)
          phaseUnwrap(x-1, y, d, r);
        if (x < inputWidth-1)
          phaseUnwrap(x+1, y, d, r);
      }
    }
  }

  void phaseUnwrap(int x, int y, float d, float r) {
    if(process[y][x]) {
      float diff = phase[y][x] - (r - (int) r);
      if (diff > .5)
        diff--;
      if (diff < -.5)
        diff++;
      toProcess.add(new WrappedPixel(x, y, d + distance[y][x], r + diff));
    }
  }

  void makeDepth() {
    for (int y = 0; y < inputHeight; y += renderDetail) {
      float planephase = 0.5 - (y - (inputHeight / 2)) / zskew;
      for (int x = 0; x < inputWidth; x += renderDetail)
        if (!mask[y][x])
          depth[y][x] = (phase[y][x] - planephase) * zscale;
    }
  }

  class WrappedPixel implements Comparable {
    public int x, y;
    public float distance, phase;
    WrappedPixel(int x, int y, float distance, float phase) {
      this.x = x;
      this.y = y;
      this.distance = distance;
      this.phase = phase;
    }
    int compareTo(Object o) {
      if(o instanceof WrappedPixel) {
        WrappedPixel w = (WrappedPixel) o;
        if(w.distance == distance)
          return 0;
        if(w.distance < distance)
          return 1;
        else
          return -1;
      } 
      else
        return 0;
    }
  }
}

