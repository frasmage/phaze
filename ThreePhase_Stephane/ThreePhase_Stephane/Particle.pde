class Particle {
  PVector or;
  PVector loc;
  PVector vel;
  PVector acc;
  float ms;
  float distance;
 
  Particle(PVector a, PVector v, PVector l, PVector o, float ms_) {
    acc = a;
    vel = v;
    loc = l;
    ms = ms_;
    or = o;
  }
 
  void run() {
    update();
    render();
  }
 
  void update() {
    vel.add(acc);
    loc.add(vel);
    acc = new PVector();
  }
  
  void render() {
    fill(0,80);
//    noStroke();
//    rectMode(CENTER);
//    rect(loc.x,loc.y,2,2);
    stroke(150);
    point(loc.x,loc.y);
  }
  
 void add_force(PVector force) {
    force.div(ms);
    vel.add(force);
  } 
  
 float getMass() {
    return ms;
  } 
   
  PVector getLocation() {
    return loc;
  }
  PVector getOrigin() {
    return or;
  }
  PVector getVelocity() {
    return vel;
  }
  void setLocation(PVector l){
    loc = l;   
  }
  void setOrigin(PVector l){
    or = l;   
  }
  void setAcceleration(PVector a){
    acc = a;
  }
}
