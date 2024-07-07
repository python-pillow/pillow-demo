import io
from PIL import Image


# Function to read an image file into a buffer
def read_image_to_buffer(image_path):
    with open(image_path, "rb") as f:
        image_data = f.read()
    return io.BytesIO(image_data)


# Function to read an image from a buffer
def read_image_from_buffer(buffer):
    return Image.open(buffer)
