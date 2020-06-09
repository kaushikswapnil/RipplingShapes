class Shape
{
 PVector m_Pos, m_Vel, m_Acc;
 int m_Parent, m_Next;
 
 Shape(PVector pos) 
 {
  m_Pos = pos.copy();
  m_Vel = new PVector(0.0f, 0.0f);
  m_Acc = m_Vel.copy();
  
  m_Parent = -1;
  m_Next = -1;
 }
 
 void AddForce(PVector force)
 {
  m_Acc.add(PVector.div(force, g_ShapeMass)); 
 }
 
 void PhysicsUpdate()
 {
  m_Vel.add(m_Acc);
  float velMag = m_Vel.mag();
  m_Vel.normalize();
  m_Vel.mult(min(velMag, g_MaxVelLength));
  m_Pos.add(m_Vel);
  m_Acc.mult(0.0f);
 }
 
 void Update()
 {
  PhysicsUpdate();
  WrapAround(this);
 }
 
 void Display()
 {
   color shapeCol = color(map(m_Vel.heading(), 0.0f, TWO_PI, 0, 255), m_Vel.mag() == 0.0f ? 0 : 255, 255);
   stroke(shapeCol);
   fill(shapeCol);
   ellipse(m_Pos.x, m_Pos.y, 2 * g_ShapeRadius, 2 * g_ShapeRadius);  
 }
}
