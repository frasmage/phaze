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
ThreePhaseCloud[] faces = new ThreePhaseCloud[setLim]; //face Objects, contains 3d pixel clouds
int curSet =0; //currently selected index
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
//see kyle's version to guess and check good values for your set
float[] zscales = {108,32,88,98,98,180,120,48,108};
float[] zskews = {28,49,28.5,35,35,34,27,30,26};
float[] noises = {.01,.07,.1,.1,.1,.15,0,.03,0};

//temp image objects to be used for processing
//image files must be in /img folder and 
//be named set#-1.jpg, set#-2.jpg and set#-3.jpg,
//where # is the set ID and 1,2,3 is the order of the images in sequence
PImage phase1Image, phase2Image, phase3Image;


int renderDetail =2;

// wapmorph variables for particule text rendering 
List<Particle> particles = new LinkedList<Particle>();
List<Particle> pcopy = new LinkedList<Particle>();
PFont ff;
PImage ww;
String[] sentence = new String[5];
Particle prt;
float rd,theta,x,y;

// twitter4j import and twitter connection -
import twitter4j.conf.*;
import twitter4j.internal.async.*;
import twitter4j.internal.org.json.*;
import twitter4j.internal.logging.*;
import twitter4j.json.*;
import twitter4j.internal.util.*;
import twitter4j.management.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import twitter4j.util.*;
import twitter4j.internal.http.*;
import twitter4j.*;
import twitter4j.internal.json.*;
String shown_message ="";
String consumer_key = "niYXDjx5pyzp8qlZXqaAw";
String consumer_secret = "mNfQyu7tQ2CceuQUrfCOInxSn447hF7wcT5IisjM8";
String oauth_token = "405995845-vg1cdDNo6nZogpFyR6muBIL3UJCvdStb7owAKcQU";
String oauth_token_secret = "r1bgGOScvcwzWUTq7tDQtV8cfOyL05iSJrcw";
AccessToken token;


void setup() {
  size(640, 720, P3D);
  
  //instantiate camera
  cam = new PeasyCam(this, width);
  
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
  
  //now that we are done with them, empty the image containers from memory
  phase1Image = null;
  phase2Image = null;
  phase3Image = null;

  // initiate text particules
  ff = loadFont("DejaVuSansMono-Bold-48.vlw");
  
  rd = width/2+150;
  theta = 0.0f;
   
  sentence[0] = "SYS10350.T103106.RA000.R0988060 02 W-ADISP-ID-ORD-PAG PIC S9(11) EXPLODE CPY TG0216 FROM SM.LIZ.XCRV.CPY COMP-3END EXPLODE CPY INC0XCOC FROM SM.LIZ.XCRV.CPY";
  sentence[1] = "Type glyphs are created and modified using"+'\n'+"a variety of illustration techniques.";
  sentence[2] = "Until the Digital Age,"+'\n'+"typography was a specialized occupation.";
  sentence[3] = "In contemporary use,"+'\n'+"the practice of typography is very"+'\n'+"broad, covering all aspects of letter design.";
  sentence[4] = "Choice of fonts is the"+'\n'+"primary aspect of text typography.";
 
    for(int i = 0; i < 20000; i++) {
 
      PVector a = new PVector();
      PVector v = new PVector();  
      x = width/2+(rd * cos(theta));
      y = height/2+(rd * sin(theta));
      PVector o = new PVector(x,y,0);
      PVector l = new PVector(x,y,0);
      theta += .1;    
      particles.add(new Particle(a,v,l, o, random(0.5f,1.0f)));
    }
    
  //write first message
 // queryTwitter();
 
}


void draw () {
  background(0);
  translate(-width / 2, -height / 2);
   moveYa();
  
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


void queryTwitter(){
  Twitter twitter = new TwitterFactory().getInstance();
  twitter.setOAuthConsumer(consumer_key, consumer_secret);
  token = new AccessToken(oauth_token, oauth_token_secret);
  twitter.setOAuthAccessToken(token);
 // twitter.setOAuthAccessToken(new AccessToken( oauth_token, oauth_token_secret) );
  try {
    
     Query query = new Query("culture");
     query.setRpp(1);
     QueryResult result = twitter.search(query);
 
     ArrayList tweets = (ArrayList) result.getTweets();
 
     for (int i = 0; i < tweets.size(); i++) {
       Tweet t = (Tweet) tweets.get(i);
       String user = t.getFromUser();
       String msg = t.getText();
       Date d = t.getCreatedAt();
       shown_message = "Tweet by " + user + " at " + d + ": " + msg;
       
       ww = crImage(shown_message,480,720,28);
       setPos();
     }  
 
  }
  catch (TwitterException te) {
    println("Couldn't connect: " + te);
  }
}



PImage crImage(String s, int w, int h, int fs)
{
  PGraphics pg = createGraphics(w,h,JAVA2D);
  pg.beginDraw();
  pg.background(254);
  pg.fill(250);
  pg.textAlign(CENTER);
  pg.textFont(ff, fs);
  pg.text(s, 0, 0, w, h);
  pg.endDraw();
  PImage pi = createImage(w,h,RGB);
  copy(pg, 0, 0, w, h, 0, 0, w, h);
  return pi;
}
 
 
void setPos()
{
  int i = 0;
  for(int x = 0; x < ww.width; x++) {
    for(int y = 0; y < ww.height; y++) {
      if(get(x,y) != -131587){
        i++; if (i ==20000) i = 19999;
        Particle p = (Particle) particles.get(i);
        p.setOrigin(new PVector(x,y+200,0));
      }
    }
  }
  for(int r = i; r<particles.size(); r++){
    Particle p = (Particle) particles.get(r);
    x = width/2+(rd * cos(theta));
    y = height/2+(rd * sin(theta));
    theta += .1;
    p.setOrigin(new PVector(x,y,0));
  }
}
 
void moveYa(){
   for (Particle p:particles){
      
     
    PVector actualVel = p.getVelocity();
    PVector attrito = PVector.mult(actualVel,-0.05);
    p.add_force(attrito);
     
    PVector origLoc = p.getOrigin();
    PVector diff = PVector.sub(origLoc,p.getLocation());
    diff.normalize();
    float factor = 0.5f; 
    diff.mult(factor);
    p.setAcceleration(diff);
    p.run();
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
    
  queryTwitter();
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
  //make sure are great enough to change 
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
