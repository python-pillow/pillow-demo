from PIL import Image, ImageDraw
import os

# Create a new RGBA image with transparency
transparent_img = Image.new("RGBA", (400, 300), (0, 0, 0, 0))

# Draw a red rectangle on the transparent image
draw = ImageDraw.Draw(transparent_img)
draw.rectangle([(100, 100), (300, 200)], fill=(255, 0, 0, 128))

# Load another image to overlay onto
background_img = Image.open(os.path.join("img", "pillow-logo-light-text.png"))

# Resize the overlay image to fit the background
overlay_img = transparent_img.resize(background_img.size, Image.BICUBIC)

# Composite the overlay onto the background
final_img = Image.alpha_composite(background_img.convert("RGBA"), overlay_img)
final_img.save("final_image.png")
