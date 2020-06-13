class Shape
{
 PVector m_Pos, m_Vel, m_Acc;
 float m_Mass;
 
 Shape(PVector pos, float mass) 
 {
  m_Pos = pos.copy();
  m_Vel = new PVector(0.0f, 0.0f);
  m_Acc = m_Vel.copy();
  m_Mass = mass;
 }
 
 float GetRadius()
 {
  return m_Mass * g_ShapeMassRadiiMultiplier; 
 }
 
 void AddForce(PVector force)
 {
  m_Acc.add(PVector.div(force, m_Mass)); 
 }
 
 void PhysicsUpdate()
 { 
  m_Vel.add(m_Acc);
  m_Pos.add(m_Vel);
  
  m_Acc.mult(0.0f);
  m_Vel.mult(g_DragFactor);
 }
 
 void Update()
 {
  PhysicsUpdate();
  WrapAround(this);
 }
 
 void Display()
 {
   color shapeCol = g_Active ? g_MaxSpeedLastFrame > 0.0f ? color(map(m_Vel.mag(), 0.0f, g_MaxSpeedLastFrame, 0, 270), 360, m_Vel.mag() == 0.0f ? 0 : 360) : color(360, 360, 0) : color(0, 0, 360);
   stroke(shapeCol);
   fill(shapeCol);
   
   float diameter = 2 * GetRadius();
   ellipse(m_Pos.x, m_Pos.y, diameter, diameter);  
 }
}
