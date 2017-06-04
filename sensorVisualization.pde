import processing.serial.*;

Serial myPort;
String val; 
float fVal;
float roundTemp;
float xOffSet = 1000;
float yOffSet = 400;
float planeWidth = 200;
float planeHeight = 200;
float perspective = 4000;
float gyroTrim;
float finalTrim;
float derTrim;
float prevErr;
float currErr;
float[] gyroTrimArray = new float[50];
int count = 30;
int zCount = 180;
double x = 0 * (Math.PI/180);
double y = 10 * (Math.PI/180);
double z = 0 * (Math.PI/180);
float[] planeX = new float[4];
float[] planeY = new float[4];
float[] Step1x = new float[4];
float[] Step1y = new float[4];
float[] tempVal = new float[3];
float[] zVal = new float[100];
float[] yVal = new float[100];
float[] xVal = new float[100];
float[] smoothZ = new float[100];
float[] smoothX = new float[100];
float[] smoothY = new float[100];
float[] temp = new float[30];
int modeCounter = 0;
float lastGoodVal;
final float yawRateSmooth = 0.01f;
float preVal = 0;
float prevRate = 0;
void setup()
{
  size(1400,800);
  
  String portName = Serial.list()[1]; 
  myPort = new Serial(this, portName, 9600);
}

String printer(float input){
  
  input *= 1000;
  input = Math.round(input);
  input /= 1000;
  
  return Float.toString(input);
  
}

float meanTrimmer(float[] input){
  int i;
  int j;
  float temp;
  float output;
  output = 0;

  for(i = 0; i < 29; i++){

    for(j = 0; j < 29 - i; j++){
      if(input[j] > input[j+1]){
        temp = input[j+1];
        input[j+1] = input[j];
        input[j] = temp;
      }
    }
  }

  for (i = 0; i < 10; i++){
     output += input[i + 10];
  }
  output /= 10;

  return output;

}


void draw()
{
  background(#f4f5f7);
  stroke(0,0,0);
  
  for(int i = 1; i < 4; i ++){
    line(0,200*i - 100 ,500,200*i - 100);
  }
  strokeWeight(3); 
  for(int i = 1; i < 4; i ++){
    line(0,200*i,500,200*i);
  }
  
  line(500,0,500,800);
  strokeWeight(1); 
  
  if ( myPort.available() > 0) 
  {  
  val = myPort.readStringUntil('\n');  
    if(val != null && val != "NaN"){
      for(int i = 0; i < 2; i++){
        int pos = val.indexOf(" ");
        if(pos != -1){
          
        tempVal[i] = parseFloat(val.substring(0,pos));
        val = val.substring(pos+1);
        }
        else
          tempVal[i] = parseFloat(val.substring(0));
        
      }
    }
  } 
  
  zVal[zVal.length - 1] = tempVal[0];
  yVal[yVal.length - 1] = tempVal[1]/10;
  //xVal[xVal.length - 1] = tempVal[0];

println(tempVal[0]);
println(tempVal[1]/10);
  

 
  for(int i = 0; i < zVal.length - 1; i ++){
   zVal[i] = zVal[i + 1];
  }
  
   for(int i = 0; i < xVal.length - 1; i ++){
   xVal[i] = xVal[i + 1];
  }
   for(int i = 0; i < yVal.length - 1; i ++){
   yVal[i] = yVal[i + 1];
  }
   for(int i = 0; i < smoothZ.length - 1; i ++){
   smoothZ[i] = smoothZ[i + 1];
  }
   for(int i = 0; i < smoothX.length - 1; i ++){
   smoothX[i] = smoothX[i + 1];
  }
   for(int i = 0; i < smoothZ.length - 1; i ++){
   smoothY[i] = smoothY[i + 1];
  }
  for(int i = 0; i < gyroTrimArray.length - 1; i ++){
   gyroTrimArray[i] = gyroTrimArray[i + 1];
  }
  

  
  for(int i = 0; i < 30;i++){
   temp[i] = zVal[zVal.length - 30 + i]; 
    
  }
  
    smoothZ[zVal.length - 1] = meanTrimmer(temp);
  float tempSum = 0;
  for(int i = 5; i >0 ;i--){
   tempSum += xVal[xVal.length - i -1];
    
  }
  smoothX[smoothX.length - 1] = tempSum / 5;
    
  
  for(int i = 0; i < 30;i++){
   temp[i] = yVal[yVal.length - 30 + i]; 
    
  }
    
  smoothY[yVal.length - 1] = meanTrimmer(temp);
  

 
  
    
      
    
    
  for(int i = 0; i < zVal.length-1 ; i++){
   stroke(0, 0, 0);
   line(i * 5, ((zVal[i] * -5) +100), (i+1) * 5, ((zVal[i + 1]* -5) +100)); 
  }
  
  for(int i = 0; i < smoothZ.length-1 ; i++){
   stroke(255, 102, 0);
   line((i * 5)-75, ((smoothZ[i] * -5) +100 ), ((i+1) * 5)-75, ((smoothZ[i + 1]* -5)  +100)); 
  }
  
  for(int i = 0; i < xVal.length-1 ; i++){
   stroke(0, 0, 0);
   line(i * 5, ((xVal[i] * -5) +300), (i+1) * 5, ((xVal[i + 1]* -5) +300)); 
  }
  
  for(int i = 0; i < smoothX.length-1 ; i++){
   stroke(0, 102, 0);
   line(i * 5, ((smoothX[i] * -5) +300 ), (i+1) * 5, ((smoothX[i + 1]* -5)  +300)); 
  }
  
  for(int i = 0; i < yVal.length-1 ; i++){
   stroke(0, 0, 0);
   line(i * 5, ((yVal[i] * -5) +500), (i+1) * 5, ((yVal[i + 1]* -5) +500)); 
  }
  
  for(int i = 0; i < smoothY.length-1 ; i++){
   stroke(255, 0, 0);
   line(i * 5, ((smoothY[i] * -5) +500 ), (i+1) * 5, ((smoothY[i + 1]* -5)  +500)); 
  }
  
  float a = smoothZ[smoothZ.length - 1];
  a = (0.0379 * a * a * a) + (-0.0043 * a * a) + (4.337 * a) -1.073;
  a *= 0.97;
  gyroTrimArray[gyroTrimArray.length - 1] = yVal[yVal.length - 15] - a/10;
  float gyroSum = 0;
  for(int i = 0; i < gyroTrimArray.length; i++){
    gyroSum += gyroTrimArray[i];
    
  }
  print(gyroSum);
  gyroTrim = gyroSum / (gyroTrimArray.length - 1);
  
  
  
  
  //gyroTrim +=  (xVal[xVal.length - 15] - a/10)*0.07;
  //finalTrim = (xVal[xVal.length - 15] - a/10) * 0.3;
  //currErr = xVal[xVal.length - 15] - a/10;
  //derTrim = (prevErr - currErr)*0.4;
  //finalTrim += gyroTrim + derTrim;
  //print(gyroTrim + " here");
  if(gyroTrim != gyroTrim){
   gyroTrim = 0; 
  }
  xVal[xVal.length - 1] =  yVal[yVal.length - 1] - gyroTrim;
  //prevErr = currErr;
  

  text(printer(yVal[yVal.length - 1]), 10,410,100,100);
  fill(255, 0, 0);
  text(printer(xVal[xVal.length - 1]*10), 10,210,100,100);
  fill(255, 0, 0);
  text(printer(smoothZ[smoothZ.length - 1]), 10,10,100,100);
  fill(255, 0, 0);
  
  
  text(printer(a), 10,610,100,100);
  fill(255, 0, 0);
  
  
  if(smoothY[smoothY.length - 1] < 0){
   if(a > 0){
    a =180 - a;
   }
   else{
   a += 180;
   a *= -1;
   }
    
    
  }
  
  delay(30);
}