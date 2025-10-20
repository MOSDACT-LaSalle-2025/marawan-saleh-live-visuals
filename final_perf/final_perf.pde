/* 
Name:Marawan Saleh
Date:01/10/2025
Description: Live Perfermance 
Place of production: Barcelona
Instructions (if necessary): Control using 1-5 and 6-0 
*/
import ddf.minim.*;

ArrayList<Particle> particles;
int numParticles = 200;

int currentShape = 1;
int targetShape = 1;


int systemMode = 0; // 0 = wander, 1-5 = wave patterns


Minim minim;
AudioPlayer sfxSound;


class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float maxSpeed = 4;
  float maxForce = 0.1;
  float size = 10;
  color pColor;

  // Variable for shape cross-fading
  float shapeLerpFactor = 0;

  // Constructor
  Particle(float x, float y) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(random(0.5, 2));
    acceleration = new PVector(0, 0);
    pColor = color(random(150, 255), random(100, 255), random(200, 255), 200);
  }

  void update() {
    // --- Update Movement ---
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    acceleration.mult(0); 

    // --- Update Shape Transition ---
    if (currentShape != targetShape) {
      shapeLerpFactor = lerp(shapeLerpFactor, 1.0, 0.05);
      if (shapeLerpFactor > 0.99) {
        currentShape = targetShape;
      }
    } else {
      shapeLerpFactor = lerp(shapeLerpFactor, 0.0, 0.05);
    }

    // --- Wrap around edges (only in wander mode) ---
    if (systemMode == 0) {
      if (position.x < -size) position.x = width + size;
      if (position.x > width + size) position.x = -size;
      if (position.y < -size) position.y = height + size;
      if (position.y > height + size) position.y = -size;
    }
  }

  void applyForce(PVector force) {
    acceleration.add(force);
  }

  void seek(PVector target) {
    PVector desired = PVector.sub(target, position);
    float d = desired.mag();
    desired.normalize();

    if (d < 100) {
      float m = map(d, 0, 100, 0, maxSpeed);
      desired.mult(m);
    } else {
      desired.mult(maxSpeed);
    }

    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce);
    applyForce(steer);
  }

  // --- Display and Shape Drawing (Cross-fade) ---
  void display() {
    pushMatrix();
    translate(position.x, position.y);
    if (velocity.mag() > 0.1) {
      rotate(velocity.heading());
    }

    noStroke();
    
    // Draw the CURRENT shape, fading it OUT
    fill(red(pColor), green(pColor), blue(pColor), 200 * (1.0 - shapeLerpFactor));
    drawShape(currentShape);
    
    // Draw the TARGET shape, fading it IN (on top)
    fill(red(pColor), green(pColor), blue(pColor), 200 * shapeLerpFactor);
    drawShape(targetShape);

    popMatrix();
  }

  void drawShape(int shapeID) {
    switch(shapeID) {
      case 1: ellipse(0, 0, size, size); break; // Circle
      case 2: rectMode(CENTER); rect(0, 0, size, size); break; // Square
      case 3: triangle(0, -size * 0.7, -size * 0.7, size * 0.7, size * 0.7, size * 0.7); break; // Triangle
      case 4: rectMode(CENTER); rect(0, 0, size * 1.5, size * 0.3); break; // Line / Bar
      case 5: drawStar(0, 0, size/4, size/2, 5); break; // Star
      case 6: drawBlob(0, 0, size/2, map(noise(position.x * 0.01 + frameCount * 0.005), 0, 1, 0.5, 1.5)); break; // Custom Blob
    }
  }

  void drawStar(float x, float y, float radius1, float radius2, int npoints) {
    float angle = TWO_PI / npoints;
    float halfAngle = angle / 2.0;
    beginShape();
    for (float a = 0; a < TWO_PI; a += angle) {
      vertex(x + cos(a) * radius2, y + sin(a) * radius2);
      vertex(x + cos(a + halfAngle) * radius1, y + sin(a + halfAngle) * radius1);
    }
    endShape(CLOSE);
  }

  void drawBlob(float x, float y, float baseRadius, float noiseFactor) {
    beginShape();
    for (float a = 0; a < TWO_PI; a += 0.1) {
      float r = baseRadius + map(noise(cos(a) * noiseFactor, sin(a) * noiseFactor, frameCount * 0.005), 0, 1, -baseRadius/4, baseRadius/4);
      vertex(x + r * cos(a), y + r * sin(a));
    }
    endShape(CLOSE);
  }
}


void setup() {
  size(800, 600);
  particles = new ArrayList<Particle>();
  for (int i = 0; i < numParticles; i++) {
    particles.add(new Particle(random(width), random(height)));
  }
  rectMode(CENTER);
  
  // sound
  minim = new Minim(this);

  sfxSound = minim.loadFile("sfx.mp3"); 
}

void draw() {
  background(10, 10, 20, 100); 
  
  float time = frameCount * 0.01;

  for (int i = 0; i < particles.size(); i++) {
    Particle p = particles.get(i);
    float ratio = (float)i / numParticles;


    switch(systemMode) {
      case 0: // Wander (Flow Field)
        float noiseFactor = 0.01;
        float angle = noise(p.position.x * noiseFactor, p.position.y * noiseFactor, time * 0.1) * TWO_PI * 4;
        PVector noiseForce = PVector.fromAngle(angle);
        noiseForce.setMag(0.05);
        p.applyForce(noiseForce);
        break;
        
      case 1: // Key '6': Horizontal Sine Wave
        float targetX = ratio * width;
        float targetY = height/2 + sin(ratio * TWO_PI * 3 + time * 2) * (height/3);
        p.seek(new PVector(targetX, targetY));
        break;
        
      case 2: // Key '7': Vertical Sine Wave
        float targetY2 = ratio * height;
        float targetX2 = width/2 + sin(ratio * TWO_PI * 4 + time * 2) * (width/3);
        p.seek(new PVector(targetX2, targetY2));
        break;
        
      case 3: // Key '8': Breathing Circle
        float angle3 = ratio * TWO_PI;
        float radius3 = (height/3) + sin(time * 1.5) * (height/4);
        float targetX3 = width/2 + cos(angle3) * radius3;
        float targetY3 = height/2 + sin(angle3) * radius3;
        p.seek(new PVector(targetX3, targetY3));
        break;
        
      case 4: // Key '9': Lissajous Figure
        float angle4 = ratio * TWO_PI + time;
        float targetX4 = width/2 + cos(angle4 * 3) * (width/3);
        float targetY4 = height/2 + sin(angle4 * 2) * (width/3);
        p.seek(new PVector(targetX4, targetY4));
        break;
        
      case 5: // Key '0': Figure-Eight
        float angle5 = ratio * TWO_PI;
        float targetX5 = width/2 + sin(angle5 + time) * (width/3);
        float targetY5 = height/2 + sin(2 * angle5 + time) * (width/3);
        p.seek(new PVector(targetX5, targetY5));
        break;
    }

    p.update();
    p.display();
  }
}


void stop() {
  sfxSound.close();
  minim.stop();
  super.stop();
}

// cntrols
void keyPressed() {
  boolean playSound = false; // Flag to control sound


  if (key >= '1' && key <= '5') {
    targetShape = key - '0'; // Set target shape (1-5)
    systemMode = 0;          // Set mode to WANDER
    
  }

 
    targetShape = 6;         
    systemMode = 1;          
    playSound = true; 
  }
  if (key == '7') { systemMode = 2; playSound = true; }
  if (key == '8') { systemMode = 3; playSound = true; }
  if (key == '9') { systemMode = 4; playSound = true; }
  if (key == '0') { systemMode = 5; playSound = true; }
  

  if (playSound) {
    sfxSound.rewind(); 
    sfxSound.play();
  }
}
