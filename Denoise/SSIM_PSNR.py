import numpy as np
import os
from skimage.metrics import peak_signal_noise_ratio as psnr
from skimage.metrics import structural_similarity as ssim
from PIL import Image
import tifffile


def load_image(image_path):
    """Loads a TIFF image without any data type conversion."""
    try:
        image = tifffile.imread(image_path)
        return image
    except Exception as e:
        print(f"Error loading TIFF: {e}")
        return None


def normalize_image_16bit(image):
    """Normalize 16-bit image to the range [0, 1]."""
    max_val = np.max(image)  # Maximum value for 16-bit images
    if max_val == 0:
        raise ValueError("Cannot normalize with max_val 0.")
    return image.astype(np.float64) / max_val

def compute_metrics(original, denoised):
    """Compute PSNR and SSIM between two images."""
    psnr_value = psnr(original, denoised, data_range=1.0)
    ssim_value, _ = ssim(original, denoised, data_range=1.0, full=True)
    return psnr_value, ssim_value

def main():
    # Define image paths (Update as per your system)
    original_image_path = r"path_clean_img.tif"
    denoised_image_path = r"path_denoised_img.tif"
    
    try:
        # Load images
        original = load_image(original_image_path)
        denoised = load_image(denoised_image_path)
        
        # Print debugging info
        print(f"Original shape: {original.shape}, dtype: {original.dtype}")
        print(f"Denoised shape: {denoised.shape}, dtype: {denoised.dtype}")
        
        # Normalize images
        original = normalize_image_16bit(original)
        denoised = normalize_image_16bit(denoised)
        
        # Compute metrics
        psnr_value, ssim_value = compute_metrics(original, denoised)
        
        # Print results
        print(f"PSNR: {psnr_value:.2f} dB")
        print(f"SSIM: {ssim_value:.4f}")
    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
