from PIL import Image, ImageDraw, ImageFont
import os

# Create a new image with white background
width, height = 400, 300
image = Image.new("RGB", (width, height), "white")
draw = ImageDraw.Draw(image)

# Draw a red rectangle at the top-left corner
draw.rectangle([10, 10, 110, 60], outline="red", width=3)

# Draw a green ellipse at the center
draw.ellipse(
    [width // 2 - 50, height // 2 - 50, width // 2 + 50, height // 2 + 50],
    outline="green",
    width=3,
)

# Draw a blue line across the image
draw.line([0, 0, width, height], fill="blue", width=3)

# Draw a small black circle at (300, 200)
draw.ellipse([295, 195, 305, 205], fill="black")

# Annotate the shapes with their coordinates
font = ImageFont.load_default()

# Top-left rectangle coordinates
draw.text((10, 65), "(10, 10) to (110, 60)", fill="red", font=font)

# Center ellipse coordinates
draw.text(
    (width // 2 - 50, height // 2 + 55),
    f"({width//2 - 50}, {height//2 - 50}) to ({width//2 + 50}, {height//2 + 50})",
    fill="green",
    font=font,
)

# Line coordinates
draw.text((width - 100, height - 15), "(0, 0) to (400, 300)", fill="blue", font=font)

# Small circle coordinates
draw.text((310, 200), "(300, 200)", fill="black", font=font)

# Save and display the image
print("t")
image.save(os.path.join("img", "coordinate_system_example.png"))
