import processing.sound.*;
import javafx.util.Pair; 

float g_SoundForceMultiplier = 90.0f;
float g_SoundForceSmoothing = 0.95f;

float g_CenterForceMultiplier = 0.95f;

float g_DragFactor = 0.99f;
float g_CollisionLossOfVelocity = 0.95f;

float g_ShapeMassRadiiMultiplier = 20.0f;

ArrayList<Shape> g_Shapes;

SoundFile g_SoundSample;
FFT g_Fft;

//int g_NumBandsPerSide = 8;
//int g_NumBands = g_NumBandsPerSide * g_NumBandsPerSide;
int g_NumBands = 8 * 8;

ArrayList<Pair<PVector, Float>> g_SoundForces;

float g_MaxSpeedLastFrame = 0.0f;

AudioIn in;

PVector g_Center;

boolean g_Active = false;

void setup()
{
  size(800, 800);
  
  g_Center = new PVector(width/2, height/2);
  
  colorMode(HSB, 360);
  g_Shapes = new ArrayList<Shape>();
  
  float initDist = width /20;

  for (float x = initDist/2; x < width; x += initDist)
    for (float y = initDist/2; y < height; y += initDist)
    {
      PVector shapePos = new PVector(x, y);
      g_Shapes.add(new Shape(shapePos, random(0.0f, 1.0f) < 0.8f ? random(0.25, 0.75f) : random(1.0f, 1.15f)));
    }
    
  CreateSoundBandsStructure();
  
  //in = new AudioIn(this, 0);
  //in.start();
     
  //g_SoundSample = new SoundFile(this, "Cantina_Blues_Take_the_Lead.mp3");
  g_SoundSample = new SoundFile(this, "Pepper_s_Funk.mp3");
  //g_SoundSample = new SoundFile(this, "The_Hunter.mp3");
  //g_SoundSample = new SoundFile(this, "Chubs.mp3");
  //g_SoundSample.play();
  //g_SoundSample.loop();

  // Create the FFT analyzer and connect the playing soundfile to it.
  g_Fft = new FFT(this, g_NumBands);
  //g_Fft.input(in);
  g_Fft.input(g_SoundSample);
}

void draw()
{
  background(0);
  
  FillFrameSoundForces();
  
  float maxSpeedThisFrame = 0.0f;
  
  for (int iterA = 0; iterA < g_Shapes.size(); ++iterA)
  {
    Shape shapeA = g_Shapes.get(iterA);
    
    PVector toCenter = PVector.sub(g_Center, shapeA.m_Pos);
    
    //Add center attraction force
    if (g_SoundSample.isPlaying())
    {
      toCenter.normalize();
      shapeA.AddForce(PVector.mult(toCenter, g_CenterForceMultiplier));
      
      for (Pair<PVector, Float> soundForce : g_SoundForces)
      {
       PVector force = PVector.sub(shapeA.m_Pos, soundForce.getKey());
       float forceMag = force.mag();
       forceMag = soundForce.getValue() * g_SoundForceMultiplier/forceMag;
       force.normalize();
       force.mult(forceMag);
       shapeA.AddForce(force);
      }
      
      shapeA.Update();
      
      for (int iterB = iterA + 1; iterB < g_Shapes.size(); ++iterB)
      {
        Shape shapeB = g_Shapes.get(iterB);
        ResolveCollisions(shapeA, shapeB);
      } 
    }
    else if (g_Active)
    {
      if (toCenter.mag() < shapeA.GetRadius())
      {
        float distToCenter = toCenter.mag();
        toCenter.normalize();
        float moveAmount = map(distToCenter, 0.0f, shapeA.GetRadius(), 0.0f, g_CenterForceMultiplier);
        if (moveAmount == 0.0f)
        {
          shapeA.m_Pos = g_Center;
        }
        else
        {
          shapeA.m_Pos = PVector.add(PVector.mult(toCenter, moveAmount), shapeA.m_Pos);
        }
      }
      else
      {
        toCenter.normalize();
        shapeA.AddForce(PVector.mult(toCenter, g_CenterForceMultiplier * 0.5f)); 
        shapeA.Update();
      }
    }
    
    float velMag = shapeA.m_Vel.mag();
    if (velMag > maxSpeedThisFrame)
    {
     maxSpeedThisFrame = velMag; 
    }
    
    shapeA.Display();
  }
  
  g_MaxSpeedLastFrame = maxSpeedThisFrame;
  //fill(255);
  //for (Pair<PVector, Float> soundForce : g_SoundForces)
  //{
  //  ellipse(soundForce.getKey().x, soundForce.getKey().y, 8.0f, 8.0f);
  //}
}

void ResolveCollisions(Shape a, Shape b)
{
  if (a.m_Pos.dist(b.m_Pos) < (a.GetRadius() + b.GetRadius()))
  {
    PVector aU = PVector.mult(a.m_Vel, g_CollisionLossOfVelocity);
    PVector bU = PVector.mult(b.m_Vel, g_CollisionLossOfVelocity);
    float aM = a.m_Mass;
    float bM = b.m_Mass;
    
    float aMminusbM = aM - bM;
    float aMplusbM = aM + bM;
    
    a.m_Vel = PVector.div(PVector.add(PVector.mult(aU, aMminusbM), PVector.mult(bU, 2 * bM)), aMplusbM);
    b.m_Vel = PVector.div(PVector.add(PVector.mult(bU, -aMminusbM), PVector.mult(aU, 2 * aM)), aMplusbM);
   //PVector dirAtoB = PVector.sub(b.m_Pos, a.m_Pos);
   //dirAtoB.normalize();
   
   //float aForceMag = max(1.0f, a.m_Vel.mag());
   //a.AddForce(PVector.mult(dirAtoB, aForceMag * -1.0f));
   
   //float bForceMag = max(1.0f, b.m_Vel.mag());
   //b.AddForce(PVector.mult(dirAtoB, bForceMag));
  }
}

void FillFrameSoundForces()
{
  g_Fft.analyze();
  
  for (int iter = 0; iter < g_NumBands; ++iter)
  {
    Pair<PVector, Float> curSoundForce = (g_SoundForces.get(iter));
    
    float newMag = curSoundForce.getValue() + ((g_Fft.spectrum[iter] - curSoundForce.getValue()) * g_SoundForceSmoothing);
    g_SoundForces.set(iter, new Pair(curSoundForce.getKey(), newMag));
  }
}

void CreateSoundBandsStructure()
{
  g_SoundForces = new ArrayList<Pair<PVector, Float>>();
  
  //float bandDist = width/g_NumBandsPerSide;
  //for (float x = bandDist/2; x < width; x+= bandDist)
  //{
  //  for (float y = bandDist/2; y < height; y+= bandDist)
  //  {
  //    g_SoundForces.add(new Pair(new PVector(x, y), 0.0f));
  //  }
  //}
  int numPrevCircleBands = 0;
  for (int iter = 0; iter < g_NumBands;)
  {
    float radius = map(iter, 0, g_NumBands, 0.0f, width/40);
    int numCircleBands = numPrevCircleBands == 0 ? 1 : 4 * numPrevCircleBands;
    
    if (iter + numCircleBands >= g_NumBands)
    {
     numCircleBands = g_NumBands - iter; 
    }
    
    float angle = 0.0f;
    float angleAdd = TWO_PI/numCircleBands;
    for (int innerIter = 0; innerIter < numCircleBands; ++innerIter)
    {
     PVector bandPos = PVector.add(g_Center, PVector.mult(PVector.fromAngle(angle), radius));
     g_SoundForces.add(new Pair(bandPos, 0.0f));
     
     angle += angleAdd;
    }
    
    iter += numCircleBands;
    numPrevCircleBands = numCircleBands;
    
    if (iter == g_NumBands)
    {
     break; 
    }
  }
}

void WrapAround(Shape shape)
{
  float shapeRadius = shape.GetRadius();
  if (shape.m_Pos.x < shapeRadius)
  {
    shape.m_Pos.x = shapeRadius;
    
    if (shape.m_Vel.x < 0.0f)
    {
     shape.m_Vel.x = 0.0f; 
    }
  }
  
  if (shape.m_Pos.x > width - shapeRadius)
  {
    shape.m_Pos.x = width - shapeRadius;
    
    if (shape.m_Vel.x > 0.0f)
    {
     shape.m_Vel.x = 0.0f; 
    }
  }
  
  if (shape.m_Pos.y < shapeRadius)
  {
    shape.m_Pos.y = shapeRadius;
    
    if (shape.m_Vel.y < 0.0f)
    {
     shape.m_Vel.y = 0.0f; 
    }
  }
  
  if (shape.m_Pos.y > height - shapeRadius)
  {
    shape.m_Pos.y = height - shapeRadius;
    
    if (shape.m_Vel.y > 0.0f)
    {
     shape.m_Vel.y = 0.0f; 
    }
  }
}

void keyPressed()
{
 if (key == ' ')
 {
  if (g_Active == false)
  {
   g_SoundSample.play(); 
  }
  else
  {
   g_SoundSample.stop();
  }
  
  g_Active = !g_Active;
 }
}
