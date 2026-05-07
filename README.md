####Denoising

To denoise our images, we utilized an online GPU via Kaggle notebooks.
Create two folders—one containing clean images and the other containing noisy images—in matching order (by filename or index). Before running the denoising code, replace the input folder paths accordingly. The code expects images sized at 256×256 pixels.

###Stitching

Please use Stitchertsting.m file.
Prepare two separate folders—one for MIP images and one for hot images—in matching order (by filename or index). Imaging acquisition begins at the right-bottom corner and follows a snake-like raster pattern. The current code is designed for square-shaped images. Specify the mosaic size (e.g., number of tiles per row/column) when prompted by the program.


eachPTimgSize = 126;  % size of pt images, Size to cut from photothermal images. (If you provide large hot images, the programs cut a size of 126 pixels from the centre of MIP images at the final stitching stage)
featureSearchArea = 40; % percentage of overlap between images
pixelSizeofImg = 0.176; % in micrometer (pixel size, in this eg, each pixel curresponds to 176 nm)
distanceMoved = 21 ; % in micrometer (distance that you XY stage moved in each step)
