from PIL import Image, ImageOps
import random
import os


def replace_palette_with_random_colors(image_path):
    # Open the image
    img = Image.open(image_path)

    # Convert image to 'P' mode (indexed color mode) if not already
    img = ImageOps.posterize(img, 8)  # Reduce colors to 8-bit
    img = img.convert("P", palette=Image.ADAPTIVE, colors=256)  # Convert to 'P' mode

    # Get the palette
    # palette = img.getpalette()

    # Generate random colors
    new_palette = []
    for i in range(256):  # Assuming 256-color palette
        new_color = (
            random.randint(0, 255),
            random.randint(0, 255),
            random.randint(0, 255),
        )
        new_palette.extend(new_color)

    # Replace the image palette with the new random palette
    img.putpalette(new_palette)

    # Save the modified image
    img.save(os.path.join("img", "output_image_with_random_palette.png"))
    print("Image with random palette saved successfully.")


# Example usage:
replace_palette_with_random_colors(os.path.join("img", "hopper.ppm"))
