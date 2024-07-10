from PIL import Image, ImageDraw, ImageFont
import os

# Create a blank image with white background
width, height = 400, 200
image = Image.new("RGB", (width, height), "white")
draw = ImageDraw.Draw(image)

# Define the font and size
try:
    font = ImageFont.truetype("Arial.ttf", 40)  # macos
except OSError:
    font = ImageFont.truetype(
        "/usr/share/fonts/liberation-mono/LiberationMono-Regular.ttf"
    )  # linux

# Draw a rectangle (as a placeholder for a logo icon)
rectangle_width, rectangle_height = 100, 100
rect_x0, rect_y0 = 50, 50
rect_x1, rect_y1 = rect_x0 + rectangle_width, rect_y0 + rectangle_height
draw.rectangle([rect_x0, rect_y0, rect_x1, rect_y1], fill="blue", outline="black")

# Add some text next to the rectangle
text = "Pillow Demo"
text_x, text_y = rect_x1 + 20, rect_y0 + 30
draw.text((text_x, text_y), text, font=font, fill="black")

# Save the image to a file
print("Example #38: Writing logo.png!")
image.save(os.path.join("img", "logo.png"))
