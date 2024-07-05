from PIL import Image, ImageOps, ImageFilter, ImageEnhance, ImageSequence, PSDraw
import code
from rich.console import Console
from rich.rule import Rule
from merge import merge
from roll import roll
from buffer import read_image_from_buffer, read_image_to_buffer
import readline
import rlcompleter  # noqa

console = Console()
readfunc = readline.parse_and_bind("tab: complete")

# ===============================================================================
# Example #0 Welcome!
# ===============================================================================
console.print(Rule("[bold magenta]Welcome![/bold magenta]"))
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #1 Open image and print info
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#using-the-image-class
# ===============================================================================
console.print(Rule("[bold magenta]Example #1[/bold magenta]"))
im = Image.open("hopper.ppm")
print(im.format, im.size, im.mode)
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #2 Rotate image 90 degrees clockwise (270 degrees counter clockwise)
# ===============================================================================
console.print(Rule("[bold magenta]Example #2[/bold magenta]"))
im = im.rotate(270)
im.save("rotated_hopper.jpg")
print("Example #2: Saved rotated hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #3 Convert to jpeg
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#convert-files-to-jpeg
# ===============================================================================
console.print(Rule("[bold magenta]Example #3[/bold magenta]"))
im = Image.open("hopper.ppm")
im.save("hopper.jpg")
print("Example #3: Saved jpeg hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #4 Create JPEG thumbnail
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#create-jpeg-thumbnails
# ===============================================================================
console.print(Rule("[bold magenta]Example #4[/bold magenta]"))
im = Image.open("hopper.ppm")
im.thumbnail([64, 64])
im.save("thumbnail_hopper.jpg")
print("Example #4: Saved thumbnail hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #5 Crop image
# ===============================================================================
console.print(Rule("[bold magenta]Example #5[/bold magenta]"))
im = Image.open("hopper.ppm")
region = im.crop([0, 0, 64, 64])
region.save("cropped_hopper.jpg")
print("Example #5: Saved cropped hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #6 Pasting image
# ===============================================================================
console.print(Rule("[bold magenta]Example #6[/bold magenta]"))
im = Image.open("hopper.ppm")
region = im.crop([0, 0, 64, 64])
region = region.transpose(Image.Transpose.ROTATE_180)
im.paste(region, (0, 0, 64, 64))
im.save("pasted_hopper.jpg")
print("Example #6: Saved pasted hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #7 Roll image
# ===============================================================================
console.print(Rule("[bold magenta]Example #7[/bold magenta]"))
im = Image.open("hopper.ppm")
im = roll(im, 64)
im.save("rolled_hopper.jpg")
print("Example #7: Saved rolled hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #8 Merging images
# ===============================================================================
console.print(Rule("[bold magenta]Example #8[/bold magenta]"))
hopper = Image.open("hopper.ppm")
alex = Image.open("img/alex-pillow.jpg")
im = merge(hopper, alex)
im.save("merged_hopper.png")
print("Example #8: Saved merged hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #8 Merging images (and resize)
# ===============================================================================
console.print(Rule("[bold magenta]Example #8[/bold magenta]"))
hopper = Image.open("hopper.ppm")
alex = Image.open("img/alex-pillow.jpg")
im = merge(hopper, alex)
im.save("merged_resized_hopper.png")
im = Image.open("merged_resized_hopper.png")
im = im.resize([128, 128])
im.save("merged_resized_hopper.png")
print("Example #8: Saved merged and resized hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #9 Split and merge bands
# ===============================================================================
console.print(Rule("[bold magenta]Example #9[/bold magenta]"))
im = Image.open("hopper.ppm")
r, g, b = im.split()
im = Image.merge("RGB", (b, g, r))
im.save("rebanded_hopper.jpg")
print("Example #9: Saved rebanded hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #10 Create JPEG thumbnail with resize
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#geometrical-transforms
# ===============================================================================
console.print(Rule("[bold magenta]Example #10[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.resize([64, 64])
im.save("resized_hopper.jpg")
print("Example #10: Saved resized hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #11 Transpose image left to right
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #11[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
im.save("flip_left_right_hopper.jpg")
print("Example #11: Saved flipped hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #12 Transpose image top to bottom
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #12[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
im.save("flip_top_bottom_hopper.jpg")
print("Example #12: Saved flipped hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #13 Rotate image 90 degrees with transpose
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.transpose(Image.Transpose.ROTATE_90)
im.save("rotated_hopper_90.jpg")
print("Example #13: Saved rotated hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #14 Rotate image 180 degrees with transpose
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.transpose(Image.Transpose.ROTATE_180)
im.save("rotated_hopper_180.jpg")
print("Example #14: Saved rotated hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #15 Rotate image 270 degrees with transpose
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.transpose(Image.Transpose.ROTATE_270)
im.save("rotated_hopper_270.jpg")
print("Example #15: Saved rotated hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #16 Relative resize image with contain
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
ImageOps.contain(im, (100, 150)).save("contained_hopper.png")
print("Example #16: Saved contained hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #17 Relative resize image with cover
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
ImageOps.cover(im, (100, 150)).save("covered_hopper.png")
print("Example #17: Saved covered hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #18 Relative resize image with fit
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
ImageOps.fit(im, (100, 150)).save("fitted_hopper.png")
print("Example #18: Saved fitted hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #19 Relative resize image with pad
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
ImageOps.pad(im, (100, 150), color="#f00").save("padded_hopper.png")
print("Example #19: Saved padded hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #20 Convert mode
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#converting-between-modes
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.convert("L")
im.save("converted_hopper.jpg")
print("Example #20: Saved converted hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #21 Image enhancement
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#image-enhancement
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.filter(ImageFilter.DETAIL)
im.save("enhanced_hopper.jpg")
print("Example #21: Saved enhanced hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #22 Point operations
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#point-operations
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = im.point(lambda i: i * 20)
im.save("transformed_hopper.jpg")
print("Example #22: Saved transformed hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #23 Process bands
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#processing-individual-bands
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
# split the image into individual bands
source = im.split()
r, g, b = 0, 1, 2
# select regions where red is less than 100
mask = source[r].point(lambda i: i < 100 and 255)
# process the green band
out = source[g].point(lambda i: i * 0.7)
# paste the processed band back, but only where red was < 100
source[g].paste(out, None, mask)
# build a new multiband image
im = Image.merge(im.mode, source)
im.save("masked_hopper.jpg")
print("Example #23: Saved masked hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #24 Enhance image
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#enhancement
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
im = ImageEnhance.Contrast(im)
im = im.enhance(1.3)
im.save("contrasted_hopper.jpg")
print("Example #24: Saved contrasted hopper!")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #25 Image sequences
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#image-sequences
# https://github.com/aclark4life/snorkle-gif
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("snorkle.gif")
i = 1
for frame in ImageSequence.Iterator(im):
    frame.save(f"snorkle_{i}.png")
    print(f"Example #25: Saved snorkle frame {i}!")
    i += 1
print("Example #25: Saved all frames.")
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #26 Print postscript
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#postscript-printing
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
im = Image.open("hopper.ppm")
title = "hopper"
fp = open("postscript_hopper.ps", "wb")
ps = PSDraw.PSDraw(fp)
ps.begin_document(title)
ps.image((0, 0, 128, 128), im, 0)
ps.setfont("HelveticaNarrow-Bold", 36)
ps.text((0, 0), title)
ps.end_document()
print("Example #26: Saved postscript hopper!")
code.interact(local=globals(), readfunc=readfunc)
# ===============================================================================
# Example #27 Reading from an open file
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#reading-from-an-open-file
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
print("Example #27: Opened hopper.ppm!")
with open("hopper.ppm", "rb") as fp:
    im = Image.open(fp)
    print(im)
code.interact(local=globals(), readfunc=readfunc)
# ===============================================================================
# Example #28 Reading from binary data
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#reading-from-binary-data
# ===============================================================================
console.print(Rule("[bold magenta]Example[/bold magenta]"))
buffer = read_image_to_buffer("hopper.ppm")
print("Example #28: Read to buffer")
print(type(buffer))
code.interact(local=globals(), readfunc=readfunc)
im = read_image_from_buffer(buffer)
print("Example #28: Read from buffer")
print(im)
code.interact(local=globals(), readfunc=readfunc)
