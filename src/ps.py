from PIL import Image, PSDraw

# Define the PostScript file
ps_file = open("output.ps", "wb")

# Create a PSDraw object
ps = PSDraw.PSDraw(ps_file)

# Start the document
ps.begin_document()

# Set the text to be drawn
text = "Hopper"

# Define the PostScript font
font_name = "Helvetica-Narrow-Bold"
font_size = 36

# Calculate text size (approximation as PSDraw doesn't provide direct method)
# Assuming average character width as 0.6 of the font size
text_width = len(text) * font_size * 0.6
text_height = font_size

# Set the position (top-center)
page_width, page_height = 595, 842  # A4 size in points
text_x = (page_width - text_width) // 2
text_y = page_height - text_height - 50  # Distance from the top of the page

# Load the image
image_path = "img/hopper.ppm"  # Update this with your image path
with Image.open(image_path) as im:
    # Resize the image if it's too large
    im.thumbnail((page_width - 100, page_height // 2))

    # Define the box where the image will be placed
    img_width, img_height = im.size
    img_x = (page_width - img_width) // 2
    img_y = text_y + text_height - 200  # 200 points below the text

    # Draw the image (75 dpi)
    ps.image((img_x, img_y, img_x + img_width, img_y + img_height), im, 75)

# Draw the text
ps.setfont(font_name, font_size)
ps.text((text_x, text_y), text)

# End the document
ps.end_document()
ps_file.close()
