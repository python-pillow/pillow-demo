from PIL import Image, PSDraw
import os

im = Image.open(os.path.join("img", "hopper.ppm"))
title = "hopper"
fp = open("postscript_hopper.ps", "wb")
ps = PSDraw.PSDraw(fp)
ps.begin_document(title)
# ps.image((0, 0, 128, 128), im, 0)
ps.image((128, 128, 0, 0), im, 0)
ps.setfont("HelveticaNarrow-Bold", 36)
ps.text((0, 0), title)
ps.end_document()
