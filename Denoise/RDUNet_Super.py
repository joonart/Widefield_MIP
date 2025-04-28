### Residual dense test SSIM loss

import os
import numpy as np
import glob
import tensorflow as tf
from skimage import io
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
from tensorflow.keras.layers import (
    Input, Conv2D, MaxPooling2D, Conv2DTranspose, concatenate, BatchNormalization, Add, Activation
)
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import  ModelCheckpoint,EarlyStopping, ReduceLROnPlateau
from tensorflow.keras.metrics import MeanAbsoluteError
from tensorflow.keras.initializers import GlorotNormal, HeNormal, Orthogonal
from tensorflow.keras.callbacks import Callback
from tensorflow.keras.preprocessing.image import array_to_img

# ✅ Check GPU availability
gpus = tf.config.experimental.list_physical_devices('GPU')
if gpus:
    tf.config.set_visible_devices(gpus[0], 'GPU')
print("✅ GPU configured")

# ✅ Define dataset paths
base_path = "/kaggle/input/pet2903"
clean_folder = os.path.join(base_path, "Clean_data")
noisy_folder = os.path.join(base_path, "Noisy_data")
print("✅ Dataset paths defined")

# ✅ Function to load TIFF images
def load_images_from_folder(folder):
    images, filenames = [], []
    file_list = sorted(glob.glob(folder + "/*.tif"))
    for img_path in file_list:
        img = io.imread(img_path).astype(np.float32)  #, as_gray=True
        images.append(np.expand_dims(img, axis=-1))
        filenames.append(os.path.basename(img_path))
    return np.array(images), filenames

# ✅ Load clean and noisy images
clean_images, clean_filenames = load_images_from_folder(clean_folder)
noisy_images, noisy_filenames = load_images_from_folder(noisy_folder)
print("✅ Images loaded")

# ✅ Normalize images
clean_images /= np.max(clean_images, axis=(1, 2, 3), keepdims=True)
noisy_images /= np.max(noisy_images, axis=(1, 2, 3), keepdims=True)
print("✅ Images normalized")

# ✅ Split dataset
x_train, x_val, y_train, y_val, train_filenames, val_filenames = train_test_split(
    noisy_images, clean_images, noisy_filenames, test_size=0.2, random_state=42
)
x_val, x_test, y_val, y_test, val_filenames, test_filenames = train_test_split(
    x_val, y_val, val_filenames, test_size=0.5, random_state=42
)
print("✅ Dataset split into training, validation, and test sets")

# ✅ PReLU Activation
def prelu(x):
    return tf.keras.layers.PReLU()(x)

# ✅ Downsample Block
def downsample_block(input_layer, filters):
    x = Conv2D(filters, kernel_size=2, strides=2, padding='valid')(input_layer)
    x = prelu(x)
    return x

# ✅ Upsample Block
def upsample_block(upsample, concat_layer, out_filters):
    up = Conv2DTranspose(upsample.shape[-1], kernel_size=2, strides=2, padding='valid')(upsample)
    up = prelu(up)
    concat = concatenate([concat_layer, up], axis=-1)
    x = Conv2D(out_filters, kernel_size=3, padding='same')(concat)
    x = prelu(x)
    return x

# ✅ Input Block
def input_block(input_layer, out_filters):
    x = Conv2D(out_filters, kernel_size=3, padding='same')(input_layer)
    x = prelu(x)
    x = Conv2D(out_filters, kernel_size=3, padding='same')(x)
    x = prelu(x)
    return x

# ✅ Output Block
def output_block(input_layer, out_filters):
    x = Conv2D(input_layer.shape[-1], kernel_size=3, padding='same')(input_layer)
    x = prelu(x)
    x = Conv2D(out_filters, kernel_size=3, padding='same')(x)
    x = prelu(x)
    return x

# ✅ Denoising Block
def denoising_block(input_layer, inner_filters, out_filters):
    out_0 = Conv2D(inner_filters, kernel_size=3, padding='same')(input_layer)
    out_0 = prelu(out_0)

    out_1 = concatenate([input_layer, out_0], axis=-1)
    out_1 = Conv2D(inner_filters, kernel_size=3, padding='same')(out_1)
    out_1 = prelu(out_1)

    out_2 = concatenate([input_layer, out_0, out_1], axis=-1)
    out_2 = Conv2D(inner_filters, kernel_size=3, padding='same')(out_2)
    out_2 = prelu(out_2)

    out_3 = concatenate([input_layer, out_0, out_1, out_2], axis=-1)
    out_3 = Conv2D(out_filters, kernel_size=3, padding='same')(out_3)
    out_3 = prelu(out_3)

    return Add()([input_layer, out_3])

# ✅ RDUNet Model
def rdunet_model(input_shape, channels, base_filters):
    inputs = Input(input_shape)

    filters_0 = base_filters
    filters_1 = 2 * filters_0
    filters_2 = 4 * filters_0
    filters_3 = 8 * filters_0

    # Encoder
    out_0 = input_block(inputs, filters_0)
    out_0 = denoising_block(out_0, filters_0 // 2, filters_0)
    out_0 = denoising_block(out_0, filters_0 // 2, filters_0)
    out_1 = downsample_block(out_0, filters_1)

    out_1 = denoising_block(out_1, filters_1 // 2, filters_1)
    out_1 = denoising_block(out_1, filters_1 // 2, filters_1)
    out_2 = downsample_block(out_1, filters_2)

    out_2 = denoising_block(out_2, filters_2 // 2, filters_2)
    out_2 = denoising_block(out_2, filters_2 // 2, filters_2)
    out_3 = downsample_block(out_2, filters_3)

    # Bottleneck
    out_3 = denoising_block(out_3, filters_3 // 2, filters_3)
    out_3 = denoising_block(out_3, filters_3 // 2, filters_3)

    # Decoder
    out_4 = upsample_block(out_3, out_2, filters_2)
    out_4 = denoising_block(out_4, filters_2 // 2, filters_2)
    out_4 = denoising_block(out_4, filters_2 // 2, filters_2)

    out_5 = upsample_block(out_4, out_1, filters_1)
    out_5 = denoising_block(out_5, filters_1 // 2, filters_1)
    out_5 = denoising_block(out_5, filters_1 // 2, filters_1)

    out_6 = upsample_block(out_5, out_0, filters_0)
    out_6 = denoising_block(out_6, filters_0 // 2, filters_0)
    out_6 = denoising_block(out_6, filters_0 // 2, filters_0)

    outputs = output_block(out_6, channels)
    final_output = Add()([outputs, inputs])

    return Model(inputs=inputs, outputs=final_output)

# ✅ PSNR Metric
def psnr_metric(y_true, y_pred):
    return tf.image.psnr(y_true, y_pred, max_val=1.0)

def ssim_metric(y_true, y_pred):
    return tf.image.ssim(y_true, y_pred, max_val=1.0)

# ✅ Compile model

def charbonnier_loss(y_true, y_pred):
    return tf.reduce_mean(tf.sqrt((y_true - y_pred)**2 + 1e-6))  # Smooth L1 loss

input_shape = (256, 256, 1)
model = rdunet_model(input_shape, channels=1, base_filters=64) # Adjust base_filters as needed




model.compile(optimizer=Adam(learning_rate=0.00001), loss=charbonnier_loss, metrics=[MeanAbsoluteError(), psnr_metric, ssim_metric])


print("✅ Model compiled")

# ✅ Callbacks
early_stopping = EarlyStopping(monitor='val_loss', patience=3, restore_best_weights=True)
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, min_lr=1e-6)

# Custom callback to save every 5 epochs
class SaveEveryNthEpoch(Callback):
    def __init__(self, filepath, save_every=5):
        super(SaveEveryNthEpoch, self).__init__()
        self.filepath = filepath
        self.save_every = save_every
        self.epoch_counter = 0

    def on_epoch_end(self, epoch, logs=None):
        self.epoch_counter += 1
        if self.epoch_counter % self.save_every == 0:
            self.model.save(self.filepath.replace(".keras", f"_epoch_{self.epoch_counter}.keras"))

save_every_10_epochs = SaveEveryNthEpoch(filepath="/kaggle/working/PETcry25610_8_rdunet.keras", save_every=10)


print("✅ Callbacks set up")

# ✅ Train model
history = model.fit(
    x_train, y_train,
    batch_size=8,
    epochs=50,
    validation_data=(x_val, y_val),
    callbacks=[early_stopping, reduce_lr,save_every_10_epochs]
)



# ✅ Save model
model.save("/kaggle/working/PETcry25610_8_rdunet_epoch_50.keras")
print("✅ Model saved")

# ✅ Define and register the custom metric
@tf.keras.utils.register_keras_serializable()
def psnr_metric(y_true, y_pred):
    return tf.image.psnr(y_true, y_pred, max_val=1.0)

# ✅ Register custom SSIM metric
@tf.keras.utils.register_keras_serializable()
def ssim_metric(y_true, y_pred):
    return tf.image.ssim(y_true, y_pred, max_val=1.0)

model = tf.keras.models.load_model(
    "/kaggle/working/PETcry25610_8_rdunet_epoch_50.keras",
    custom_objects={"psnr_metric": psnr_metric, "ssim_metric": ssim_metric, "charbonnier_loss": charbonnier_loss}
)
print("✅ Model loaded")

# ✅ Predict on test set
predicted_clean_images = model.predict(x_test)
print("✅ Predictions generated")

# ✅ Save filenames
#filename_data = np.column_stack((test_filenames, test_filenames))
#np.savetxt("/kaggle/working/test_image_filenames_rdunet.txt", filename_data, fmt="%s", delimiter=",")
#print("✅ Test filenames saved")

num_samples = 5
fig, axes = plt.subplots(num_samples, 3, figsize=(10, num_samples * 3))

for i in range(num_samples):
    print(i)
    # Convert images using array_to_img (Keras utility)
    noisy_img = array_to_img(x_test[i])
    predicted_img = array_to_img(predicted_clean_images[i])
    ground_truth_img = array_to_img(y_test[i])

    axes[i, 0].imshow(noisy_img, cmap='gray')
    axes[i, 0].set_title("Noisy Image")

    axes[i, 1].imshow(predicted_img, cmap='gray')
    axes[i, 1].set_title("Predicted Clean Image")

    axes[i, 2].imshow(ground_truth_img, cmap='gray')
    axes[i, 2].set_title("Ground Truth")

    # ✅ Calculate PSNR and SSIM between Clean and Noisy Image
    psnr_noisy = psnr_metric(y_test[i], x_test[i]).numpy()
    ssim_noisy = tf.image.ssim(
        tf.expand_dims(y_test[i], 0), 
        tf.expand_dims(x_test[i], 0), 
        max_val=1.0
    ).numpy()[0]

    # ✅ Calculate PSNR and SSIM between Clean and Predicted Image
    psnr_predicted = psnr_metric(y_test[i], predicted_clean_images[i]).numpy()
    ssim_predicted = tf.image.ssim(
        tf.expand_dims(y_test[i], 0), 
        tf.expand_dims(predicted_clean_images[i], 0), 
        max_val=1.0
    ).numpy()[0]

    # ✅ Display PSNR and SSIM on Noisy Image
    axes[i, 0].text(0.05, 0.95, f"PSNR: {psnr_noisy:.2f}\nSSIM: {ssim_noisy:.3f}",
                    transform=axes[i, 0].transAxes, verticalalignment='top',
                    fontsize=8, color='white', bbox=dict(facecolor='black', alpha=0.5))

    # ✅ Display PSNR and SSIM on Predicted Image
    axes[i, 1].text(0.05, 0.95, f"PSNR: {psnr_predicted:.2f}\nSSIM: {ssim_predicted:.3f}",
                    transform=axes[i, 1].transAxes, verticalalignment='top',
                    fontsize=8, color='white', bbox=dict(facecolor='black', alpha=0.5))

    # Hide axis
    for j in range(3):
        axes[i, j].axis("off")

plt.tight_layout()  # Fix placement
plt.show()

print("✅ Visualization complete")
