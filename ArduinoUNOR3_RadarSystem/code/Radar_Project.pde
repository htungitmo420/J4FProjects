import processing.serial.*;

Serial myPort;

String PORT = "COM4";
int BAUD = 9600;

final int MAX_ANGLE = 180;
final int MIN_ANGLE = 0;
final int MAX_RANGE_CM = 40;
final float EMA_ALPHA = 0.20;
final int HOLD_MS = 700;

int iAngle = 90;
int rawDist = -1;
float filteredDist = -1;
int lastUpdateMs = 0;

float[] distByAngle = new float[MAX_ANGLE + 1];
int[] timeByAngle = new int[MAX_ANGLE + 1];

PFont font;

void setup() {
  size(1920, 1080);
  smooth(8);

  for (int a = 0; a <= MAX_ANGLE; a++) {
    distByAngle[a] = -1;
    timeByAngle[a] = -999999;
  }

  myPort = new Serial(this, PORT, BAUD);
  myPort.bufferUntil('.');

  font = createFont("Consolas", 26);
  textFont(font);
}

void draw() {
  noStroke();
  fill(0, 35);
  rect(0, 0, width, height);

  drawGrid();
  drawSweep();
  drawDetections();
  drawHUD();
}

// ================== SERIAL ==================
void serialEvent(Serial myPort) {
  String data = myPort.readStringUntil('.');
  if (data == null) return;

  data = trim(data);
  if (data.length() == 0) return;

  if (data.charAt(data.length()-1) == '.') {
    data = data.substring(0, data.length()-1);
  }

  int comma = data.indexOf(',');
  if (comma < 0) return;

  int a, d;
  try {
    a = int(data.substring(0, comma));
    d = int(data.substring(comma + 1));
  } catch(Exception e) {
    return;
  }

  a = constrain(a, 0, MAX_ANGLE);
  if (d < 0 || d > 500) d = -1;

  iAngle = a;
  rawDist = d;
  lastUpdateMs = millis();

  if (rawDist >= 0) {
    if (filteredDist < 0) filteredDist = rawDist;
    else filteredDist = lerp(filteredDist, rawDist, EMA_ALPHA);

    distByAngle[iAngle] = filteredDist;
    timeByAngle[iAngle] = millis();
  } else {}
}

void drawGrid() {
  pushMatrix();
  translate(width/2, height*0.93);

  float R = min(width*0.48, height*0.85);

  noFill();
  stroke(0, 255, 90);
  strokeWeight(2);

  for (int k = 1; k <= 4; k++) {
    float rr = (R/4) * k;
    arc(0, 0, rr*2, rr*2, PI, TWO_PI);
  }

  for (int deg = 0; deg <= 180; deg += 30) {
    float x = -R*cos(radians(deg));
    float y = -R*sin(radians(deg));
    line(0, 0, x, y);
  }

  fill(0, 255, 90);
  textAlign(LEFT, CENTER);
  for (int k = 1; k <= 4; k++) {
    int cm = (MAX_RANGE_CM/4) * k;
    float rr = (R/4) * k;
    text(cm + " cm", rr + 14, -10);
  }

  textAlign(CENTER, CENTER);
  float labelR = R + 34;
  int[] labels = {30, 60, 90, 120, 150};

  for (int deg : labels) {
    float tx = -labelR * cos(radians(deg));
    float ty = -labelR * sin(radians(deg));
    text(str(deg), tx, ty);
  }

  popMatrix();
}

void drawSweep() {
  pushMatrix();
  translate(width/2, height*0.93);

  float R = min(width*0.48, height*0.85);
  float a = radians(iAngle);

  noStroke();
  float span = radians(8);
  beginShape();
  fill(0, 255, 90, 18);
  vertex(0, 0);
  for (float t = a - span; t <= a + span; t += radians(0.4)) {
    vertex(-R*cos(t), -R*sin(t));
  }
  endShape(CLOSE);

  stroke(0, 255, 90);
  strokeWeight(4);
  line(0, 0, -R*cos(a), -R*sin(a));

  popMatrix();
}

void drawDetections() {
  pushMatrix();
  translate(width/2, height*0.93);

  float R = min(width*0.48, height*0.85);

  for (int a = 0; a <= MAX_ANGLE; a++) {
    float d = distByAngle[a];
    if (d < 0 || d > MAX_RANGE_CM) continue;

    if (millis() - timeByAngle[a] > HOLD_MS) continue;

    float r = map(d, 0, MAX_RANGE_CM, 0, R);
    float ang = radians(a);

    float x = -r*cos(ang);
    float y = -r*sin(ang);

    int age = millis() - timeByAngle[a];
    float alpha = map(age, 0, HOLD_MS, 220, 40);

    noStroke();
    fill(255, 60, 60, alpha);
    ellipse(x, y, 10, 10);
  }

  popMatrix();
}

void drawHUD() {
  boolean inRange = (rawDist >= 0 && rawDist <= MAX_RANGE_CM);
  String status = inRange ? "CO VAT CAN" : "KHONG CO / NGOAI TAM";

  int dt = millis() - lastUpdateMs;

  int pad = 18;
  int panelW = 430;
  int panelH = 220;
  int xL = 30;
  int yL = 30;

  noStroke();
  fill(0, 170);
  rect(xL, yL, panelW, panelH, 16);

  fill(0, 255, 90);
  textAlign(LEFT, TOP);
  textSize(26);
  text("OBJECT INFO", xL + pad, yL + pad);

  textSize(22);
  int ty = yL + pad + 46;

  text("Angle: " + iAngle + "°", xL + pad, ty); ty += 32;
  text("Distance (raw): " + (rawDist < 0 ? "--" : rawDist + " cm"), xL + pad, ty); ty += 32;
  text("Distance (filtered): " + (filteredDist < 0 ? "--" : nf(filteredDist, 0, 1) + " cm"), xL + pad, ty); ty += 32;

  if (inRange) fill(255, 60, 60);
  else fill(180);
  textSize(24);
  text("Status: " + status, xL + pad, yL + panelH - pad - 28);


  int xR = width - panelW - 30;
  int yR = 30;

  noStroke();
  fill(0, 170);
  rect(xR, yR, panelW, panelH, 16);

  fill(0, 255, 90);
  textAlign(LEFT, TOP);
  textSize(26);
  text("SYSTEM", xR + pad, yR + pad);

  textSize(22);
  int ty2 = yR + pad + 46;

  text("Port: " + PORT, xR + pad, ty2); ty2 += 32;
  text("Baud: " + BAUD, xR + pad, ty2); ty2 += 32;
  text("Last update: " + dt + " ms", xR + pad, ty2); ty2 += 32;
  text("FPS: " + int(frameRate), xR + pad, ty2); ty2 += 32;

  text("EMA alpha: " + nf(EMA_ALPHA, 0, 2), xR + pad, ty2); ty2 += 32;
  text("Hold: " + HOLD_MS + " ms", xR + pad, ty2);
}
