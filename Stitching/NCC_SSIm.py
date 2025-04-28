import numpy as np
import cv2

def normalize_image(image):
    """Normalize a grayscale image to range [0, 1] based on its own max value."""
    max_value = np.max(image)
    return image.astype(np.float32) / max_value if max_value != 0 else image  # Avoid division by zero

def calculate_ncc(image1, image2):
    """Compute Normalized Cross-Correlation (NCC) between two images."""
    image1 = normalize_image(image1)
    image2 = normalize_image(image2)
    
    mean1, mean2 = np.mean(image1), np.mean(image2)
    std1, std2 = np.std(image1), np.std(image2)
    
    if std1 == 0 or std2 == 0:
        return 0  # Avoid division by zero
    
    ncc = np.mean((image1 - mean1) * (image2 - mean2)) / (std1 * std2)
    return ncc

def calculate_ssim(image1, image2, C1=1e-4, C2=1e-4):
    """Compute Structural Similarity Index (SSIM) between two images."""
    image1 = normalize_image(image1)
    image2 = normalize_image(image2)
    
    # Compute mean
    mu1 = np.mean(image1)
    mu2 = np.mean(image2)
    
    # Compute variance
    sigma1_sq = np.var(image1)
    sigma2_sq = np.var(image2)
    
    # Compute covariance
    sigma_xy = np.cov(image1.flatten(), image2.flatten())[0][1]
    
    # Calculate SSIM using the formula
    numerator = (2 * mu1 * mu2 + C1) * (2 * sigma_xy + C2)
    denominator = (mu1**2 + mu2**2 + C1) * (sigma1_sq + sigma2_sq + C2)
    
    ssim = numerator / denominator
    return ssim




import cv2
import numpy as np

def calculate_rmse_cv2(img1, img2):
    """
    Calculates the Root Mean Squared Error (RMSE) between two images using OpenCV.

    Args:
        img1_path (str): Path to the first image.
        img2_path (str): Path to the second image.

    Returns:
        float: The RMSE value, or None if there's an error.
    """
    try:
       

        # Check if images loaded successfully
        if img1 is None or img2 is None:
            print("Error: Could not load one or both images.")
            return None

        # Ensure images have the same shape
        if img1.shape != img2.shape:
            print("Error: Images must have the same dimensions.")
            return None

        # Calculate squared difference
        squared_diff = (img1 - img2) ** 2

        # Calculate MSE
        mse = np.mean(squared_diff)

        # Calculate RMSE
        rmse = np.sqrt(mse)

        return rmse

    except Exception as e:
        print(f"An error occurred: {e}")
        return None





# Load images as grayscale (keep original depth)
img1 = cv2.imread(r"D:\PhD\ImagesBefore28\Stitch2x2\BQ1_stitched\h4_gt_c.tif", cv2.IMREAD_UNCHANGED)  # Load as is (12-bit)
img2 = cv2.imread(r"D:\PhD\ImagesBefore28\Stitch2x2\BQ1_stitched\h4_impro.tif", cv2.IMREAD_UNCHANGED)


rmse_value = calculate_rmse_cv2(img1, img2)

if rmse_value is not None:
    print(f"RMSE: {rmse_value}")
# Check if images are loaded
if img1 is None or img2 is None:
    print("Error loading images. Please check the file paths.")
else:
    # Calculate NCC
    ncc_value = calculate_ncc(img1, img2)
    print(f"NCC Value: {ncc_value}")

    # Calculate SSIM
    ssim_value = calculate_ssim(img1, img2)
    print(f"SSIM Value: {ssim_value}")
