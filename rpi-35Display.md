# Installation


* Install these manually
```
sudo apt-get install libraspberrypi-dev
sudo apt-get install xinput-calibrator

```
* Git Clone Repo and Install Driver
```
git clone https://github.com/goodtft/LCD-show.git
chmod -R 755 LCD-show
cd LCD-show/
sudo ./LCD35-show
```

# Issues
1. LC_ALL issue - You may need to add `GB` in place of `US` in LANG and etc. eg LANG = "en_GB.UTF-8". Raspberry PI default set to Great Britain
2. Inverted Touch points - X Co-ordinates inverted
Change the line 88 and add `swapxy=1` as below: 
```
dtoverlay=tft35a:rotate=90,swapxy=1
```

# References
## Links
* http://www.lcdwiki.com/3.5inch_RPi_Display
* https://github.com/goodtft/LCD-show
* https://celamon.wordpress.com/2017/01/09/3-5-touchscreen-display-for-raspberry-pi-based-on-noobs-2-1/
* https://cdn.sparkfun.com/assets/4/c/2/0/8/User_Guide_For_3.5_inch_LCD.pdf
* http://www.lcdwiki.com/res/Show_Direction_and_Touch/How_to_calibrate_the_resistance_touch_screen-V1.2.pdf

## Issues
* https://github.com/waveshare/LCD-show/issues/31
* 
