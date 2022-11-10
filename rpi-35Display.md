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

## Links
* http://www.lcdwiki.com/3.5inch_RPi_Display
* https://github.com/goodtft/LCD-show


# Issues
1. LC_ALL issue - You may need to add `GB` in place of `US` in LANG and etc. eg LANG = "en_GB.UTF-8". Raspberry PI default set to Great Britain
2. Inverted Touch points - X Co-ordinates inverted
Change the line 88 and add `swapxy=1` as below: 
```
dtoverlay=tft35a:rotate=90,swapxy=1
```
