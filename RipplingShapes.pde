import processing.sound.*;

float g_ShapeRadius = 20.0f;
float g_ShapeMass = 1.0f;
int g_NumCellsOnSide = 8;
float g_CellSize;
float g_MaxVelLength = 1.0f;

ArrayList<Shape> g_Shapes;
Cell[] g_Cells = new Cell[g_NumCellsOnSide*g_NumCellsOnSide];

SoundFile g_SoundSample;
FFT g_Fft;

void setup()
{
  size(800, 800);
  
  for (int iter = 0; iter < g_NumCellsOnSide * g_NumCellsOnSide; ++iter)
  {
    g_Cells[iter] = new Cell();
  }
  
  g_CellSize = width / g_NumCellsOnSide;
  
  colorMode(HSB, 255);
  g_Shapes = new ArrayList<Shape>();

  for (float x = g_CellSize/2; x < width; x += g_CellSize)
    for (float y = g_CellSize/2; y < height; y += g_CellSize)
    {
      PVector shapePos = new PVector(x, y);
      g_Shapes.add(new Shape(shapePos));
      int cellIndex = GetCellIndexForPos(shapePos);
      Register(g_Shapes.size()-1, cellIndex);
    }
      
      
  g_SoundSample = new SoundFile(this, "Chubs.mp3");
  g_SoundSample.loop();

  // Create the FFT analyzer and connect the playing soundfile to it.
  g_Fft = new FFT(this, g_NumCellsOnSide * g_NumCellsOnSide);
  g_Fft.input(g_SoundSample);
}

void draw()
{
  background(0);
  //background (0, 0, 0);
  
  for (int iterA = 0; iterA < g_Shapes.size(); ++iterA)
  {
    Shape shapeA = g_Shapes.get(iterA);
    shapeA.Update();
    shapeA.Display();
    
    int posParentIndex = GetCellIndexForPos(shapeA.m_Pos);
    if (posParentIndex != shapeA.m_Parent)
    {
      Deregister(iterA, shapeA.m_Parent);
      Register(iterA, posParentIndex);
    }
    
    for (int iterB = iterA + 1; iterB < g_Shapes.size(); ++iterB)
    {
      Shape shapeB = g_Shapes.get(iterB);
      ResolveCollisions(shapeA, shapeB);
    }    
  }
  
  for (int row = 0; row < g_NumCellsOnSide; ++row)
  {
    for (int col = 0; col < g_NumCellsOnSide; ++col)
    {
      int cellNo = col + (g_NumCellsOnSide * row);
      
      Cell cellA = g_Cells[cellNo];
      
      int child = cellA.m_FirstChild;
    }
  }
}

void ResolveCollisions(Shape a, Shape b)
{
  if (a.m_Pos.dist(b.m_Pos) < 2 * g_ShapeRadius)
  {
   PVector dirAtoB = PVector.sub(b.m_Pos, a.m_Pos);
   dirAtoB.normalize();
   
   float aForceMag = max(1.0f, a.m_Vel.mag());
   a.AddForce(PVector.mult(dirAtoB, aForceMag * -1.0f));
   
   float bForceMag = max(1.0f, b.m_Vel.mag());
   b.AddForce(PVector.mult(dirAtoB, bForceMag));
  }
}

void WrapAround(Shape shape)
{
  if (shape.m_Pos.x < g_ShapeRadius)
  {
    shape.m_Pos.x = g_ShapeRadius;
    
    if (shape.m_Vel.x < 0.0f)
    {
     //shape.m_Vel.x *= -1.0f; 
    }
  }
  
  if (shape.m_Pos.x > width - g_ShapeRadius)
  {
    shape.m_Pos.x = width - g_ShapeRadius;
    
    if (shape.m_Vel.x > 0.0f)
    {
     //shape.m_Vel.x *= -1.0f; 
    }
  }
  
  if (shape.m_Pos.y < g_ShapeRadius)
  {
    shape.m_Pos.y = g_ShapeRadius;
    
    if (shape.m_Vel.y < 0.0f)
    {
     //shape.m_Vel.y *= -1.0f; 
    }
  }
  
  if (shape.m_Pos.y > height - g_ShapeRadius)
  {
    shape.m_Pos.y = height - g_ShapeRadius;
    
    if (shape.m_Vel.y > 0.0f)
    {
     //shape.m_Vel.y *= -1.0f; 
    }
  }
}

void Register(int shapeIndex, int cellIndex)
{
  Shape shape = g_Shapes.get(shapeIndex);
  Cell cell = g_Cells[cellIndex];
  int tmp = cell.m_FirstChild;
  shape.m_Next = tmp;
  shape.m_Parent = cellIndex;
  cell.m_FirstChild = shapeIndex;
}

void Deregister(int shapeIndex, int cellIndex)
{
  Shape shape = g_Shapes.get(shapeIndex);
  Cell cell= g_Cells[cellIndex];
  
  int child = cell.m_FirstChild;
  int prevChild = -1;
  while (child != -1)
  {
   if (child == shapeIndex)
   {
     if (prevChild != -1)
     {
       g_Shapes.get(prevChild).m_Next = shape.m_Next;
     }
     else
     {
       cell.m_FirstChild = shape.m_Next;
     }
     
     shape.m_Next = -1;
     shape.m_Parent = -1;
   }
   
   prevChild = child;
   child = g_Shapes.get(child).m_Next;
  }
}

boolean IsInCell(int shapeIndex, int cellIndex)
{
  Cell cell= g_Cells[cellIndex];
  
  int child = cell.m_FirstChild;

  while (child != -1)
  {
    if (child == shapeIndex)
    {
      return true;
    }
    
    child = g_Shapes.get(child).m_Next;
  }
  
  return false;
}

int GetCellIndexForPos(PVector pos)
{
  int col = max(0, min(floor(pos.x/width), g_NumCellsOnSide));
  int row = max(0, min(floor(pos.y/height), g_NumCellsOnSide));
  
  int cellIndex = col + (g_NumCellsOnSide * row);
  return cellIndex;
}

boolean CellExists(int row, int col)
{
  if (row < 0 || row >= g_NumCellsOnSide || col < 0 || col >= g_NumCellsOnSide)
  {
    return false;
  }
  
  return true;
}
