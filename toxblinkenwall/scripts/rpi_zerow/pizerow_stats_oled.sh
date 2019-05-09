#*********************************
#
# ToxBlinkenwall - stats script for OLED display on the Pi ZeroW
# (C)Zoff in 2017 - 2019
#
# https://github.com/zoff99/ToxBlinkenwall
#
#*********************************

# Copyright (c) 2017 Adafruit Industries
# Author: Tony DiCola & James DeVito
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# This example is for use on (Linux) computers that are using CPython with
# Adafruit Blinka to support CircuitPython libraries. CircuitPython does
# not support PIL/pillow (python imaging library)!

import time
import os, sys
import subprocess

from board import SCL, SDA
import board
import busio
from digitalio import DigitalInOut, Direction, Pull
from PIL import Image, ImageDraw, ImageFont
import adafruit_ssd1306


# Create the I2C interface.
i2c = busio.I2C(SCL, SDA)

# Create the SSD1306 OLED class.
# The first two parameters are the pixel width and pixel height.  Change these
# to the right size for your display!
disp = adafruit_ssd1306.SSD1306_I2C(128, 32, i2c)

# Input pins:
button_A = DigitalInOut(board.D5)
button_A.direction = Direction.INPUT
button_A.pull = Pull.UP

button_B = DigitalInOut(board.D6)
button_B.direction = Direction.INPUT
button_B.pull = Pull.UP

button_L = DigitalInOut(board.D27)
button_L.direction = Direction.INPUT
button_L.pull = Pull.UP

button_R = DigitalInOut(board.D23)
button_R.direction = Direction.INPUT
button_R.pull = Pull.UP

button_U = DigitalInOut(board.D17)
button_U.direction = Direction.INPUT
button_U.pull = Pull.UP

button_D = DigitalInOut(board.D22)
button_D.direction = Direction.INPUT
button_D.pull = Pull.UP

button_C = DigitalInOut(board.D4)
button_C.direction = Direction.INPUT
button_C.pull = Pull.UP


# Clear display.
disp.fill(0)
disp.show()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
image = Image.new('1', (width, height))

# Get drawing object to draw on image.
draw = ImageDraw.Draw(image)

# Draw a black filled box to clear the image.
draw.rectangle((0, 0, width, height), outline=0, fill=0)

# Draw some shapes.
# First define some constants to allow easy resizing of shapes.
padding = -2
top = padding
bottom = height-padding
# Move left to right keeping track of the current x position for drawing shapes.
x = 0

fifo_path = '../ext_keys.fifo'

try:
    os.mkfifo(fifo_path)
except Exception:
    pass


def measure_temp():
        temp = os.popen("vcgencmd measure_temp").readline()
        return (temp.replace("temp=","")).rstrip()

def send_event(txt):
    # print(txt)
    fifo_write = os.open(fifo_path, os.O_RDWR)
    os.write(fifo_write, txt.encode('UTF8'))
    os.close(fifo_write)


# Load default font.
font = ImageFont.load_default()

# Alternatively load a TTF font.  Make sure the .ttf font file is in the
# same directory as the python script!
# Some other nice fonts to try: http://www.dafont.com/bitmap.php
# font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 9)
# *does not work* font = ImageFont.truetype('/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf', 9)
# font = ImageFont.truetype('/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf', 9)

toggle = 0
toggle_char = ["+","*"]
need_draw = 0

while True:

    if button_A.value and button_B.value and button_C.value and button_U.value and button_L.value and button_R.value and button_D.value:
        # Draw a black filled box to clear the image.
        draw.rectangle((0, 0, width, height), outline=0, fill=0)

        # Shell scripts for system monitoring from here:
        # https://unix.stackexchange.com/questions/119126/command-to-display-memory-usage-disk-usage-and-cpu-load
        cmd = "hostname -I | cut -d\' \' -f1"
        IP = subprocess.check_output(cmd, shell=True).decode("utf-8")
        # cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: \" $(NF-2)}' | sed -e 's#,$##'"
        cmd = "top -bn1 | grep load |sed -e 's#^.*load average: ##'|cut -d\" \" -f1|sed -e 's#,$##'|awk '{ printf \"CPU Load: \" $0 }'"
        CPU = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%s MB\", $3,$2 }'"
        MemUsage = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "iwgetid -r 2>/dev/null"
        SSID = subprocess.check_output(cmd, shell=True).decode("utf-8")
        cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%d GB  %s\", $3,$2,$5}'"
        Disk = subprocess.check_output(cmd, shell=True).decode("utf-8")

        toggle = 1 - toggle

        # Write four lines of text.
        draw.text((x, top+0), "IP: "+IP, font=font, fill=255)
        draw.text((x, top+8), CPU, font=font, fill=255)
        draw.text((x, top+16), MemUsage, font=font, fill=255)
        draw.text((x, top+25), measure_temp() + "" + toggle_char[toggle]  + " " + SSID, font=font, fill=255)

        # Display image.
        disp.image(image)
        disp.show()

    for xy in range(0, 5):

        need_draw = 0
        if not button_U.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(20, 20/2), (30, 2/2), (40, 20/2)], outline=255, fill=0)  #Up
            need_draw = 1

        if not button_L.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(0, 30/2), (18, 21/2), (18, 41/2)], outline=255, fill=0)  #left
            need_draw = 1

        if not button_R.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(60, 30/2), (42, 21/2), (42, 41/2)], outline=255, fill=0) #right
            need_draw = 1

        if not button_D.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.polygon([(30, 60/2), (40, 42/2), (20, 42/2)], outline=255, fill=0) #down
            need_draw = 1

        if not button_C.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.rectangle((20, 22/2, 40, 40/2), outline=255, fill=0) #center
            send_event("hangup:\n")
            need_draw = 1

        if not button_A.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.ellipse((70, 40/2, 90, 60/2), outline=255, fill=0) #A button
            send_event("call:2\n")
            need_draw = 1

        if not button_B.value:
            if need_draw == 0:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
            draw.ellipse((100, 20/2, 120, 40/2), outline=255, fill=0) #B button
            send_event("call:1\n")
            need_draw = 1


        if need_draw == 1:
            disp.image(image)
            disp.show()
            need_draw = 0

        time.sleep(0.2)

