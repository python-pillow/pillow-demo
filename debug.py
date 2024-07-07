import logging
from PIL import Image, ImageFilter

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def open_image(file_path):
    try:
        logger.debug(f"Opening image from {file_path}")
        img = Image.open(file_path)
        logger.debug(f"Image format: {img.format}, size: {img.size}, mode: {img.mode}")
        return img
    except Exception as e:
        logger.error(f"Error opening image: {e}")
        raise

def apply_filter(img, filter_type):
    try:
        logger.debug(f"Applying filter: {filter_type}")
        filtered_img = img.filter(filter_type)
        logger.debug("Filter applied successfully")
        return filtered_img
    except Exception as e:
        logger.error(f"Error applying filter: {e}")
        raise

def save_image(img, file_path):
    try:
        logger.debug(f"Saving image to {file_path}")
        img.save(file_path)
        logger.debug("Image saved successfully")
    except Exception as e:
        logger.error(f"Error saving image: {e}")
        raise

if __name__ == "__main__":
    try:
        # Example file paths
        input_file_path = 'hopper.ppm'
        output_file_path = 'blurred_hopper.ppm'

        # Open image
        img = open_image(input_file_path)

        # Apply filter
        filtered_img = apply_filter(img, ImageFilter.BLUR)

        # Save image
        save_image(filtered_img, output_file_path)
    except Exception as e:
        logger.critical(f"Critical error: {e}")
