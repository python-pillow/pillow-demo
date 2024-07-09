from PIL import Image
import os

# Create a palette image
palette_image = Image.new("P", (256, 1))
# Generate a palette of 256 colors (RGB triplets)
palette = []
for i in range(256):
    palette.extend((i, 0, 0))  # Red shades
palette_image.putpalette(palette)

# Create a grayscale image to apply the palette to
width, height = 256, 256
grayscale_image = Image.new("L", (width, height))
for x in range(width):
    for y in range(height):
        grayscale_image.putpixel((x, y), x)

# Convert the grayscale image to use the custom palette
palette_applied_image = grayscale_image.convert("P", palette=Image.ADAPTIVE, colors=256)

# Save the images
print("Example #35: Writing palette_image.png!")
palette_image.save(os.path.join("img", "palette_image.png"))
print("Example #35: Writing grayscale_image.png!")
grayscale_image.save(os.path.join("img", "grayscale_image.png"))
print("Example #35: Writing palette_applied_image.png!")
palette_applied_image.save(os.path.join("img", "palette_applied_image.png"))
