//3D Spectrogram with NeuroSky MindWave eeg power Input
//Modified by kylejanzen 2011 - http://kylejanzen.wordpress.com
//Based on script wwritten by John Locke 2011 - http://gracefulspoon.com

/**** Modified by Sean Montgomery 2013/04/05 ****
* http://produceconsumerobot.com/
* https://github.com/produceconsumerobot
* 
* Reads data from the NeuroSky MindWave and plots the eeg power data 
* in a 3D Spectrogram.
*
* Tested working with Processing 2.0b8
* 
* Required Software:
* neurosky library (customized, https://github.com/produceconsumerobot/ThinkGear-Java-socket)
* org.json library (https://github.com/agoransson/JSON-processing)
* MindWaveSpectrogram.pde
************************************************/

import neurosky.*;
import org.json.*;
//import arduinoscope.*;


Waveform eegPower3D;


PFont font;

float camzoom;
float maxX = 0;float maxY = 0;float maxZ = 0;
float minX = 0;float minY = 0;float minZ = 0;

int nBands = 10;
String[] powerNames = {"", "Delta", "Theta", "Alpha1", "Alpha2", 
  "Beta1", "Beta2", "Gamma1", "Gamma2", ""};
float[] powerData = new float[nBands];
float[] smoothPowerData = new float[nBands];
float smoothingFactor = 0.95;
float zFactor = 0.01f;
float zoomFactor = 8.f;


String saveDir = ".\\";

/*
boolean recording;
Oscilloscope oScope;
float timeWindow = 2f; // seconds
int mindwaveSamplingRate = 512; // Hz
float[] rot = {0,0,0};
*/

ThinkGearSocket neuroSocket;



void setup()
{
  size(1400,700,P3D); //screen proportions
  noStroke();

  background(255);
  
  /*
  int[] dimv = new int[2];
  dimv[0] = width; // 130 margin for text
  dimv[1] = height/6;
  int[] posv = new int[2];
  posv[0]=0;
  posv[1]=0;
  oScope = new Oscilloscope(this, posv, dimv);
  oScope.setLine_color(color((int)random(255), (int)random(127)+127, 255)); 
  oScope.setPointsPerWindow(int(timeWindow * mindwaveSamplingRate)); // requires customized arduinoscope
  */
  
  float w = float (width/nBands);
  float x = w;
  float y = 0;
  float z = 50;
  float radius = 10;
  eegPower3D = new Waveform(x,y,z,radius);
  
  ThinkGearSocket neuroSocket = new ThinkGearSocket(this);
  neuroSocket.setRawArraySize(16); // Receive 16 rawEEG samples at a time, requires customized neurosky library

  try {
    neuroSocket.start();
  } 
  catch (Exception e) {
    //println("Is ThinkGear running??");
  } 

}
void draw()
{
  background(0);

  
  directionalLight(126,126,126,sin(radians(frameCount)),cos(radians(frameCount)),1);
  ambientLight(102,102,102);

  if (frameCount>200)
  {
    for(int i = 0; i < nBands; i++){
      float zoom = 1;
      float jitter = (smoothPowerData[i]*zoomFactor*zFactor);
      //println(jitter);
      PVector foc = new PVector(eegPower3D.x+jitter, eegPower3D.y+jitter, 0);
      PVector cam = new PVector(zoom, zoom, -zoom);
      camera(foc.x+cam.x+50,foc.y+cam.y+50,foc.z+cam.z,foc.x,foc.y,foc.z,0,0,1);
    }
  }

  eegPower3D.update();
  eegPower3D.textdraw();

  eegPower3D.plotTrace();
}
void stop()
{
  neuroSocket.stop();
  super.stop();
}

public void eegEvent(int delta, int theta, int low_alpha, int high_alpha, int low_beta, int high_beta, int low_gamma, int mid_gamma) {
  powerData[0] = 0;
  powerData[1] = delta;
  powerData[2] = theta;
  powerData[3] = low_alpha;
  powerData[4] = high_alpha;
  powerData[5] = low_beta;
  powerData[6] = high_beta;
  powerData[7] = low_gamma;
  powerData[8] = mid_gamma;
  powerData[9] = 500;
}

void rawEvent(int[] raw) {
  /*
  for (int r : raw) {
    oScope.addData(int(r * 4) + 512);
  }
  */
}

void poorSignalEvent(int sig) {
}

public void attentionEvent(int attentionLevel) {
}

void meditationEvent(int meditationLevel) {
}

void blinkEvent(int blinkStrength) {
}


class Waveform
{
  float x,y,z;
  float radius;

  PVector[] pts = new PVector[nBands];

  PVector[] trace = new PVector[0];

  Waveform(float incomingX, float incomingY, float incomingZ, float incomingRadius)
  {
    x = incomingX;
    y = incomingY;
    z = incomingZ;
    radius = incomingRadius;
  }
  void update()
  {
    plot();
  }
  void plot()
  {
    for(int i = 0; i < nBands; i++)
    {
      int w = int(width/nBands);
      
      smoothPowerData[i] = smoothPowerData[i]*smoothingFactor + powerData[i]*(1-smoothingFactor);

      x = i*w;
      y = frameCount*5;
      z = height/4-smoothPowerData[i]*zFactor;

      stroke(0);
      point(x, y, z);
      pts[i] = new PVector(x, y, z);
      //increase size of array trace by length+1
      trace = (PVector[]) expand(trace, trace.length+1);
      //always get the next to last
      trace[trace.length-1] = new PVector(pts[i].x, pts[i].y, pts[i].z);
    }
  }
  void textdraw()
  {
    for(int i =0; i<nBands; i++){
      pushMatrix();
      translate(pts[i].x, pts[i].y, pts[i].z);
      rotateY(PI/2);
      rotateZ(PI/2);
      fill(255,200);
      /*
      if (recording) {
        fill(255,0,0);
      } 
      */
      
      text(powerNames[i],0,0,0);
      if (i==0) { 
        
      }
      popMatrix();
      /*
      pushMatrix();
        translate(pts[nBands-1].x, pts[nBands-1].y, 0);
        rotateY(rot[1]);
        rotateZ(rot[2]);
        rotateX(rot[0]);
         oScope.draw();
         println("x=" + rot[0] + ",y=" + rot[1] + ",z=" + rot[2]);
      popMatrix();
      */
    }
  }
  void plotTrace()
  {
    stroke(255,80);
    int inc = nBands;

    for(int i=1; i<trace.length-inc; i++)
    {
      if(i%inc != 0)
      {
        beginShape(TRIANGLE_STRIP);

        float value = (trace[i].z*100);
        float m = map(value, -500, 20000, 0, 255);
        fill(m*2, 125, -m*2, 140);
        vertex(trace[i].x, trace[i].y, trace[i].z);
        vertex(trace[i-1].x, trace[i-1].y, trace[i-1].z);
        vertex(trace[i+inc].x, trace[i+inc].y, trace[i+inc].z);
        vertex(trace[i-1+inc].x, trace[i-1+inc].y, trace[i-1+inc].z);
        endShape(CLOSE);
      }
    }
  }
}
void keyPressed()
{
  //if (key == 'r') recording = !recording; // toggle recording
  if (key == 's') {
    String[] fName = {saveDir, "MindWaveSpectrogram", nf(year(),4), nf(month(),2), nf(day(),2), 
      nf(hour(),2), nf(minute(),2), nf(second(),2), "jpg"};
    String saveFileName = join(fName, '.');
    saveFrame(saveFileName);
  }
  
  if (key == CODED) {
    if (keyCode  == DOWN) zFactor = zFactor*0.75;
    if (keyCode  == UP) zFactor = zFactor*1.33;
    if (keyCode == LEFT)  zoomFactor = zoomFactor*2;
    if (keyCode == RIGHT)  zoomFactor = zoomFactor/2;
  }
  
  /*
  if (key == 'z') {
    int n = 2;
    rot[n] = rot[n] + PI/4;
    if (rot[n] > (PI)) rot[n] = -PI*3/4;
  }
  if (key == 'x') {
    int n = 1;
    rot[n] = rot[n] + PI/4;
    if (rot[n] > (PI)) rot[n] = -PI*3/4;
  }
  if (key == 'c') {
    int n = 0;
    rot[n] = rot[n] + PI/4;
    if (rot[n] > (PI)) rot[n] = -PI*3/4;
  }
  */
  
}
