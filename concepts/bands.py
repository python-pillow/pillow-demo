from PIL import Image

im = Image.open("hopper.ppm")
print(im.getbands())
