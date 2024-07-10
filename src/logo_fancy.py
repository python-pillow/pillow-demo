from PIL import Image, ImageDraw, ImageFont
import os


# Function to create a gradient background
def create_gradient(width, height, start_color, end_color):
    base = Image.new("RGB", (width, height), start_color)
    top = Image.new("RGB", (width, height), end_color)
    mask = Image.new("L", (width, height))
    mask_data = []

    for y in range(height):
        mask_data.extend([int(255 * (y / height))] * width)

    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base


# Create a blank image with a gradient background
width, height = 600, 300
start_color = (0, 128, 255)  # Blue
end_color = (255, 255, 255)  # White
image = create_gradient(width, height, start_color, end_color)
draw = ImageDraw.Draw(image)

# Draw a circle (as a placeholder for a logo icon)
circle_radius = 60
circle_center = (150, 150)
draw.ellipse(
    [
        (circle_center[0] - circle_radius, circle_center[1] - circle_radius),
        (circle_center[0] + circle_radius, circle_center[1] + circle_radius),
    ],
    fill="orange",
    outline="black",
)

# Define the font and size
try:
    font_path = "Arial.ttf"  # macos
except OSError:
    font_path = "/usr/share/fonts/liberation-mono/LiberationMono-Regular.ttf"  # linux
font = ImageFont.truetype(font_path, 50)
font_bold = ImageFont.truetype(font_path, 70)

# Add styled text next to the circle
text = "Pillow Demo"
text_x, text_y = circle_center[0] + circle_radius + 20, circle_center[1] - 40
draw.text((text_x, text_y), text, font=font, fill="darkblue")

# Add additional text below
subtitle = "Fancy Logo"
subtitle_x, subtitle_y = text_x, text_y + 60
draw.text((subtitle_x, subtitle_y), subtitle, font=font_bold, fill="darkred")

# Save the image to a file
print("Example #39: Writing logo_fancy.png!")
image.save(os.path.join("img", "logo_fancy.png"))
