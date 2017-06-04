# IMU-Smoothing
This is a program that converts gyroscope, accelerometer, and magnetometer values to generate pitch, roll, and yaw angles that are resistant to vibrations. 

# How It Works
It uses the calculations provided by the datasheet to generate pitch, roll, and orientation values from the acclerometer/ magnetometer sensors. Since these are susceptible to vibration, a kalman algorithm is used to integrate gyroscope values as well. This combination provides fast and accurate pitch, roll, and yaw values. The kalman.h library is used for this program. 
