from PIL import Image
import os

im = Image.open(os.path.join("img", "hopper.ppm"))
print(im.getbands())
