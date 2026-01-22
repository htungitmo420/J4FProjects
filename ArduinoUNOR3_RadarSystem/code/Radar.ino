#include <Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

Servo myServo;

const int trigPin   = 10;
const int echoPin   = 11;
const int servoPin  = 12;
const int buzzerPin = 8;

const int OBSTACLE_CM = 40;

const int MIN_ANGLE = 0;
const int MAX_ANGLE = 180;
const int STEP_ANGLE = 1;
const int SERVO_DELAY_MS = 30;

unsigned long lastLcdUpdateMs = 0;
const unsigned long LCD_UPDATE_INTERVAL_MS = 120;

int calculateDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  unsigned long t = pulseIn(echoPin, HIGH, 25000UL);
  if (t == 0) return -1;

  return (int)(t * 0.0343 / 2.0);
}

void updateBuzzer(int cm) {
  bool hasObstacle = (cm > 0 && cm <= OBSTACLE_CM);
  if (hasObstacle) tone(buzzerPin, 1000);
  else noTone(buzzerPin);
}

void updateLCD(int cm) {
  unsigned long now = millis();
  if (now - lastLcdUpdateMs < LCD_UPDATE_INTERVAL_MS)
    return;
  lastLcdUpdateMs = now;

  bool hasObstacle = (cm > 0 && cm <= OBSTACLE_CM);

  lcd.setCursor(0, 0);
  if (hasObstacle)
    lcd.print("Co vat can     ");
  else
    lcd.print("Khong co vat   ");

  lcd.setCursor(0, 1);
  lcd.print("Dist: ");
  if (cm < 0)
    lcd.print("---");
  else {
    if (cm < 100) lcd.print(" ");
    if (cm < 10)  lcd.print(" ");
    lcd.print(cm);
  }
  lcd.print(" cm   ");
}

void sendToProcessing(int angle, int cm) {
  Serial.print(angle);
  Serial.print(",");
  Serial.print(cm);
  Serial.print(".");
}

void setup() {
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);

  Serial.begin(9600);

  myServo.attach(servoPin);

  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Radar start...");
  delay(500);
  lcd.clear();

  noTone(buzzerPin);
}

void loop() {
  for (int i = MIN_ANGLE; i <= MAX_ANGLE; i += STEP_ANGLE) {
    myServo.write(i);
    delay(SERVO_DELAY_MS);

    int d = calculateDistance();
    sendToProcessing(i, d);
    updateBuzzer(d);
    updateLCD(d);
  }

  for (int i = MAX_ANGLE; i >= MIN_ANGLE; i -= STEP_ANGLE) {
    myServo.write(i);
    delay(SERVO_DELAY_MS);

    int d = calculateDistance();
    sendToProcessing(i, d);
    updateBuzzer(d);
    updateLCD(d);
  }
}