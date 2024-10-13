from PIL import Image

# Open the two images
image1 = Image.open("scan1.jpg")
image2 = Image.open("scan2.jpg")

# Get dimensions of both images
image1_width, image1_height = image1.size
image2_width, image2_height = image2.size

# Create a new image that can fit both images on top of each other (vertically)
combined_image = Image.new(
    "RGB", (max(image1_width, image2_width), image1_height + image2_height)
)

# Paste the first image at (0, 0)
combined_image.paste(image1, (0, 0))

# Paste the second image below the first one
combined_image.paste(image2, (0, image1_height))

# Save the combined image
combined_image.save("combined_image_vertical.png")
