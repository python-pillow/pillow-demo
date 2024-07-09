from PIL import Image, ImageOps, ImageFilter, ImageEnhance, ImageSequence, PSDraw
import code
from rich.console import Console
from rich.rule import Rule
from merge import merge
from roll import roll
from batch import compress_image
from buffer import read_image_from_buffer, read_image_to_buffer
from pathlib import Path
from pprint import pprint
import glob
import os
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
im = Image.open(os.path.join("img", "hopper.ppm"))
print(im.format, im.size, im.mode)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #2 Rotate image 90 degrees clockwise (270 degrees counter clockwise)
# ===============================================================================
console.print(Rule("[bold magenta]Example #2[/bold magenta]"))
im = im.rotate(270)
im.save(os.path.join("img", "rotated_hopper.jpg"))
print("Example #2: Saved rotated hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #3 Convert to jpeg
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#convert-files-to-jpeg
# ===============================================================================
console.print(Rule("[bold magenta]Example #3[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im.save(os.path.join("img", "hopper.jpg"))
print("Example #3: Saved jpeg hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #4 Create JPEG thumbnail
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#create-jpeg-thumbnails
# ===============================================================================
console.print(Rule("[bold magenta]Example #4[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im.thumbnail([64, 64])
im.save(os.path.join("img", "thumbnail_hopper.jpg"))
print("Example #4: Saved thumbnail hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #5 Crop image
# ===============================================================================
console.print(Rule("[bold magenta]Example #5[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
region = im.crop([0, 0, 64, 64])
region.save(os.path.join("img", "cropped_hopper.jpg"))
print("Example #5: Saved cropped hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #6 Pasting image
# ===============================================================================
console.print(Rule("[bold magenta]Example #6[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
region = im.crop([0, 0, 64, 64])
region = region.transpose(Image.Transpose.ROTATE_180)
im.paste(region, (0, 0, 64, 64))
im.save(os.path.join("img", "pasted_hopper.jpg"))
print("Example #6: Saved pasted hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #7 Roll image
# ===============================================================================
console.print(Rule("[bold magenta]Example #7[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = roll(im, 64)
im.save(os.path.join("img", "rolled_hopper.jpg"))
print("Example #7: Saved rolled hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #8 Merging images
# ===============================================================================
console.print(Rule("[bold magenta]Example #8[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
alex = Image.open("img/alex-pillow.jpg")
im = merge(im, alex)
im.save(os.path.join("img", "merged_hopper.png"))
print("Example #8: Saved merged hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #8 Merging images (and resize)
# ===============================================================================
console.print(Rule("[bold magenta]Example #8[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
alex = Image.open("img/alex-pillow.jpg")
im = merge(im, alex)
im.save(os.path.join("img", "merged_resized_hopper.png"))
im = Image.open(os.path.join("img", "merged_resized_hopper.png"))
im = im.resize([128, 128])
im.save(os.path.join("img", "merged_resized_hopper.png"))
print("Example #8: Saved merged and resized hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #9 Split and merge bands
# ===============================================================================
console.print(Rule("[bold magenta]Example #9[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
r, g, b = im.split()
im = Image.merge("RGB", (b, g, r))
im.save(os.path.join("img", "rebanded_hopper.jpg"))
print("Example #9: Saved rebanded hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #10 Create JPEG thumbnail with resize
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#geometrical-transforms
# ===============================================================================
console.print(Rule("[bold magenta]Example #10[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.resize([64, 64])
im.save(os.path.join("img", "resized_hopper.jpg"))
print("Example #10: Saved resized hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #11 Transpose image left to right
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #11[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
im.save(os.path.join("img", "flip_left_right_hopper.jpg"))
print("Example #11: Saved flipped hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #12 Transpose image top to bottom
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #12[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
im.save(os.path.join("img", "flip_top_bottom_hopper.jpg"))
print("Example #12: Saved flipped hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #13 Rotate image 90 degrees with transpose
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #13[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.transpose(Image.Transpose.ROTATE_90)
im.save(os.path.join("img", "rotated_hopper_90.jpg"))
print("Example #13: Saved rotated hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #14 Rotate image 180 degrees with transpose
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #14[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.transpose(Image.Transpose.ROTATE_180)
im.save(os.path.join("img", "rotated_hopper_180.jpg"))
print("Example #14: Saved rotated hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #15 Rotate image 270 degrees with transpose
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#transposing-an-image
# ===============================================================================
console.print(Rule("[bold magenta]Example #15[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.transpose(Image.Transpose.ROTATE_270)
im.save(os.path.join("img", "rotated_hopper_270.jpg"))
print("Example #15: Saved rotated hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #16 Relative resize image with contain
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example #16[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
ImageOps.contain(im, (100, 150)).save(os.path.join("img", "contained_hopper.png"))
print("Example #16: Saved contained hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #17 Relative resize image with cover
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example #17[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
ImageOps.cover(im, (100, 150)).save(os.path.join("img", "covered_hopper.png"))
print("Example #17: Saved covered hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #18 Relative resize image with fit
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example #18[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
ImageOps.fit(im, (100, 150)).save(os.path.join("img", "fitted_hopper.png"))
print("Example #18: Saved fitted hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #19 Relative resize image with pad
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#relative-resizing
# ===============================================================================
console.print(Rule("[bold magenta]Example #19[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
ImageOps.pad(im, (100, 150), color="#f00").save(
    os.path.join("img", "padded_hopper.png")
)
print("Example #19: Saved padded hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #20 Convert mode
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#converting-between-modes
# ===============================================================================
console.print(Rule("[bold magenta]Example #20[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.convert("L")
im.save(os.path.join("img", "converted_hopper.jpg"))
print("Example #20: Saved converted hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #21 Image enhancement
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#image-enhancement
# ===============================================================================
console.print(Rule("[bold magenta]Example #21[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.filter(ImageFilter.DETAIL)
im.save(os.path.join("img", "enhanced_hopper.jpg"))
print("Example #21: Saved enhanced hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #22 Point operations
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#point-operations
# ===============================================================================
console.print(Rule("[bold magenta]Example #22[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = im.point(lambda i: i * 20)
im.save(os.path.join("img", "transformed_hopper.jpg"))
print("Example #22: Saved transformed hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #23 Process bands
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#processing-individual-bands
# ===============================================================================
console.print(Rule("[bold magenta]Example #23[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
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
im.save(os.path.join("img", "masked_hopper.jpg"))
print("Example #23: Saved masked hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #24 Enhance image
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#enhancement
# ===============================================================================
console.print(Rule("[bold magenta]Example #24[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
im = ImageEnhance.Contrast(im)
im = im.enhance(1.3)
im.save(os.path.join("img", "contrasted_hopper.jpg"))
print("Example #24: Saved contrasted hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #25 Image sequences
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#image-sequences
# https://github.com/aclark4life/snorkle-gif
# ===============================================================================
console.print(Rule("[bold magenta]Example #25[/bold magenta]"))
im = Image.open(os.path.join("img", "snorkle.gif"))
i = 1
for frame in ImageSequence.Iterator(im):
    frame.save(os.path.join("img", f"snorkle_{i}.png"))
    print(f"Example #25: Saved snorkle frame {i}!")
    i += 1
print("Example #25: Saved all frames.")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #26 Print postscript
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#postscript-printing
# ===============================================================================
console.print(Rule("[bold magenta]Example #26[/bold magenta]"))
im = Image.open(os.path.join("img", "hopper.ppm"))
title = "hopper"
fp = open("postscript_hopper.ps", "wb")
ps = PSDraw.PSDraw(fp)
ps.begin_document(title)
ps.image((0, 0, 128, 128), im, 0)
ps.setfont("HelveticaNarrow-Bold", 36)
ps.text((0, 0), title)
ps.end_document()
print("Example #26: Saved postscript hopper!")
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #27 Reading from an open file
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#reading-from-an-open-file
# ===============================================================================
console.print(Rule("[bold magenta]Example #27[/bold magenta]"))
print("Example #27: Opened hopper.ppm!")
with open(os.path.join("img", "hopper.ppm"), "rb") as fp:
    im = Image.open(fp)
    print(im)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #28 Reading from binary data
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#reading-from-binary-data
# ===============================================================================
console.print(Rule("[bold magenta]Example #28[/bold magenta]"))
buffer = read_image_to_buffer(os.path.join("img", "hopper.ppm"))
print("Example #28: Read to buffer")
print(type(buffer))
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

console.print(Rule("[bold magenta]Example #28[/bold magenta]"))
im = read_image_from_buffer(buffer)
print("Example #28: Read from buffer")
print(im)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #29 Batch processing
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#batch-processing
# ===============================================================================
console.print(Rule("[bold magenta]Example #29[/bold magenta]"))
batch_dir = os.path.join("img", "batch")
if not os.path.isdir(batch_dir):
    print("Creating batch/")
    os.mkdir(batch_dir)
paths = glob.glob(os.path.join("img", "*.png"))
for path in paths:
    image = os.path.join("img", "batch", "".join([os.path.basename(path[:-4]), ".jpg"]))
    print(image)
    compress_image(path, image)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #29 Batch processing
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#batch-processing
# ===============================================================================
console.print(Rule("[bold magenta]Example #29[/bold magenta]"))
paths = Path(".").glob(os.path.join("img", "*.png"))
for path in paths:
    image = os.path.join("img", "batch", "".join([path.stem, ".jpg"]))
    print(image)
    compress_image(path, image)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #30
# https://pillow.readthedocs.io/en/stable/handbook/tutorial.html#reading-in-draft-mode
# ===============================================================================
console.print(Rule("[bold magenta]Example #30[/bold magenta]"))
print("Example #30: Opening hopper.jpg for draft mode!")
with Image.open(os.path.join("img", "hopper.jpg")) as im:
    print("original =", im.mode, im.size)
    im.draft("L", (100, 100))
    print("draft =", im.mode, im.size)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #31
# https://pillow.readthedocs.io/en/stable/handbook/concepts.html#bands
# ===============================================================================
console.print(Rule("[bold magenta]Example #31[/bold magenta]"))
print("Example #31: Get hopper bands!")
im = Image.open(os.path.join("img", "hopper.ppm"))
print(im.getbands())
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #32
# https://pillow.readthedocs.io/en/stable/handbook/concepts.html#modes
# ===============================================================================
console.print(Rule("[bold magenta]Example #32[/bold magenta]"))
print("Example #32: Get hopper modes!")
im = Image.open(os.path.join("img", "hopper.ppm"))
print(im.mode)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #33
# https://pillow.readthedocs.io/en/stable/handbook/concepts.html#size
# ===============================================================================
console.print(Rule("[bold magenta]Example #33[/bold magenta]"))
print("Example #33: Get hopper size!")
im = Image.open(os.path.join("img", "hopper.ppm"))
print(im.size)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #34
# https://pillow.readthedocs.io/en/stable/handbook/concepts.html#coordinate-system
# ===============================================================================
console.print(Rule("[bold magenta]Example #34[/bold magenta]"))
import cart
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #35
# https://pillow.readthedocs.io/en/stable/handbook/concepts.html#info
# ===============================================================================
console.print(Rule("[bold magenta]Example #34[/bold magenta]"))
print("Example #33: Get hopper info!")
im = Image.open(os.path.join("img", "hopper.ppm"))
print(im.info)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)

# ===============================================================================
# Example #36
# https://pillow.readthedocs.io/en/stable/handbook/concepts.html#info
# ===============================================================================
console.print(Rule("[bold magenta]Example #34[/bold magenta]"))
print("Example #33: Get alex-pillow info!")
im = Image.open(os.path.join("img", "alex-pillow.jpg"))
pprint(im.info)
console.print(Rule())
code.interact(local=globals(), readfunc=readfunc)
