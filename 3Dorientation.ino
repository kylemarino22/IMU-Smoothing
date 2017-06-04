#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_LSM303_U.h>
#include <Adafruit_L3GD20_U.h>
#include <Kalman.h>

/* Assign a unique ID to this sensor at the same time */
Adafruit_LSM303_Accel_Unified accel = Adafruit_LSM303_Accel_Unified(54321);
Adafruit_LSM303_Mag_Unified mag = Adafruit_LSM303_Mag_Unified(54321);
Adafruit_L3GD20 gyro = Adafruit_L3GD20();


typedef struct XYZ {
  float x, y, z;
} XYZ;


float roll, pitch, heading;

XYZ kalAngle;

XYZ gyroAngle;

XYZ gyro_calibrate;

XYZ accelXYZ;

XYZ magXYZ;

XYZ gyroRate;

Kalman kalmanX;
Kalman kalmanY;

bool run_once = false;

bool CALIBRATE = false;


XYZ calibrateGyro() {
  float tempX = 0;
  float tempY = 0;
  float tempZ = 0;
  for (int i = 0; i < 2000; i++) {
    gyro.read();
    tempX += gyro.data.x;
    tempY += gyro.data.y;
    tempZ += gyro.data.z;
    delay(3);
  }
  return XYZ {tempX / 2000, tempY / 2000, tempZ / 2000};
}



void setup(void)
{
#ifndef ESP8266
  while (!Serial);     // will pause Zero, Leonardo, etc until SerialUSB console opens
#endif
  Serial.begin(9600);
  Serial.println("Accelerometer Test"); Serial.println("");

  /* Initialise the sensor */
  if (!accel.begin())
  {
    /* There was a problem detecting the ADXL345 ... check your connections */
    Serial.println("Ooops, no LSM303 detected ... Check your wiring!");
    while (1);
  }

  mag.begin();
  gyro.begin(GYRO_RANGE_500DPS);
  delay(500);
  if (CALIBRATE == true) {
    gyro_calibrate = calibrateGyro();
  }
}

float computeRoll(XYZ accel) {
  return atan2(accel.y, accel.z);
}

float computePitch(float roll, XYZ accel) {
  float rollSin = sin(roll);
  float rollCos = cos(roll);
  return atan2(-accel.x, accel.y * rollSin + accel.z * rollCos);
}


void testComputeRoll() {
  XYZ accel = XYZ {0, 0, 0};
  Serial.print("roll for {0, 0, 0} is ");
  Serial.println(computeRoll(accel));
  accel = XYZ {0, 0, 10};
  Serial.print("roll for {0, 0, 10} is ");
  Serial.println(computeRoll(accel));
  accel = XYZ {5, 10, 10};
  Serial.print("roll for {5, 10, 10} is ");
  Serial.println(computeRoll(accel));
}

void testComputePitch() {
  XYZ accel = XYZ {5, 10, 10};
  Serial.print("pitch for roll=0.79 & {5, 10, 10} is ");
  Serial.println(computePitch(0.79, accel));

  accel = XYZ {0, 0, 10};
  Serial.print("pitch for roll=0 & {0, 0, 10} is ");
  Serial.println(computePitch(0.0, accel));
}

void testMag() {
  sensors_event_t event;
  mag.getEvent(&event);
  Serial.print("x=");
  Serial.println(event.magnetic.x);
}

XYZ calculateGyro(XYZ gyro, XYZ calibrate, float currentRead, float lastRead) {

  float testX = (gyro.x - calibrate.x)  * 0.0175;
  float testY = (gyro.y - calibrate.y)  * 0.0175;
  float testZ = (gyro.z - calibrate.z)  * 0.0175;



  if (!(testZ < 0.05 && testZ > -0.05)) {
    gyro.z += testZ * (((float)(currentRead - lastRead)) / 1000);
  }
  else {
    testZ = 0;
  }

  if (!(testY < 0.05 && testY > -0.05)) {
    gyro.y += testY * (((float)(currentRead - lastRead)) / 1000);
  }
  else {
    testY = 0;
  }

  if (!(testX < 0.05 && testX > -0.05)) {
    gyro.x += testX * (((float)(currentRead - lastRead)) / 1000);
  }
  else {
    testX = 0;
  }

  gyro.x += gyro.y * sin(testZ * (3.1415 / 180));
  gyro.y -= gyro.x * sin(testZ * (3.1415 / 180));

  gyroRate = {testX, testY, testZ};



  return XYZ{gyro.x, gyro.y, gyro.y};
}


int lastRead;
int currentRead;

XYZ gyroXYZ;

void loop(void)
{
  //testComputeRoll();
  //testComputePitch();
  //testMag();
  /* Get a new sensor event */
  sensors_event_t event;

  gyro.read();
  currentRead = millis();
  float finalX;
  float finalY;
  if (run_once) {
    gyroXYZ = calculateGyro(XYZ {gyro.data.x, gyro.data.y, gyro.data.z}, gyro_calibrate, currentRead, lastRead);
  }
  else {
    accel.getEvent(&event);
    accelXYZ = XYZ {event.acceleration.x, event.acceleration.y, event.acceleration.z};

    roll = computeRoll(accelXYZ);
    pitch = computePitch(roll, accelXYZ);
    pitch *=  180 / PI;
    roll *= 180 / PI;
    
    kalmanX.setAngle(roll);
    kalmanY.setAngle(pitch);
    gyroXYZ.x = roll;
    gyroXYZ.y = pitch;
  }

  

  accel.getEvent(&event);
  accelXYZ = XYZ {event.acceleration.x, event.acceleration.y, event.acceleration.z};

  roll = computeRoll(accelXYZ);
  pitch = computePitch(roll, accelXYZ);

  //kalmanX.setAngle(roll);
  //kalmanY.setAngle(pitch);

  



  heading *=  180 / PI;
  roll *= 180 / PI;
  pitch *= 180 / PI;

  if ((roll < -90 && kalAngle.x > 90) || (roll > 90 && kalAngle.x < -90)) {
    kalmanX.setAngle(roll);
    kalAngle.x = roll;
    gyroXYZ.x = roll;
  }
  else {
    
    kalAngle.x = kalmanX.getAngle(roll, gyroRate.x, (double)(currentRead - lastRead)/1000);
    
  }

  if (abs(kalAngle.x) > 90) {
    gyroRate.y = -gyroRate.y;
  }

  kalAngle.y = kalmanY.getAngle(pitch, gyroRate.y, (double)(currentRead - lastRead)/1000);

  if (gyroXYZ.x < -180 || gyroXYZ.x > 180) {
    gyroXYZ.x = kalAngle.x;
  }
  if (gyroXYZ.y < -180 || gyroXYZ.y > 180) {
    gyroXYZ.y = kalAngle.y;
  }

  mag.getEvent(&event);
  magXYZ = XYZ {event.magnetic.x, event.magnetic.y, event.magnetic.z};

  float rollSin = sin(kalAngle.x* PI/180);
  float rollCos = cos(kalAngle.x* PI/180);
  float pitchSin = sin(kalAngle.y* PI/180);
  float pitchCos = cos(kalAngle.y* PI/180);
  
  heading = atan2(magXYZ.z * rollSin - magXYZ.y * rollCos,
                  magXYZ.x * pitchCos +
                  magXYZ.y * pitchSin * rollSin +
                  magXYZ.z * pitchSin * rollCos);

  heading *= 180/PI;
  
  Serial.print(kalAngle.x); Serial.print(" ");
  Serial.print(kalAngle.y); Serial.print(" ");
  Serial.println(heading);

  lastRead = currentRead;
  delay(100);
  /* Delay before the next sample */
  run_once = true;
}

