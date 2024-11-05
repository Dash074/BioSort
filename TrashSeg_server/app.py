import tensorflow as tf
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
import base64
from PIL import Image
import io

# Load the model
model = tf.keras.models.load_model(r'D:\Projects\FastAPI\TrashSeg\xception_modelv2.h5')  # Update with your model file name

app = FastAPI()

# Define request model
class PredictionRequest(BaseModel):
    image_base64: str  # Expecting image data as a base64-encoded string

# Define prediction route
@app.post("/predict/")
async def predict(request: PredictionRequest):
    try:
        # Decode the base64 image string
        image_data = base64.b64decode(request.image_base64)
        image = Image.open(io.BytesIO(image_data))

        # Resize to the expected input size for your model (e.g., 224x224)
        image = image.resize((224, 224))

        # Convert image to NumPy array
        image_array = np.array(image)

        # Check if it's RGB or grayscale
        if image_array.shape[-1] == 4:  # In case the image has an alpha channel (RGBA)
            image_array = image_array[..., :3]  # Remove the alpha channel

        # Normalize the image
        image_array = image_array.astype(np.float32) / 255.0

        # Reshape for the model (batch size of 1, 224x224, 3 channels)
        image_array = np.expand_dims(image_array, axis=0)

        # Make prediction
        predictions = model.predict(image_array)

        # Assuming binary classification (0 for biodegradable, 1 for non-biodegradable)
        predicted_class = int(predictions[0][0] > 0.5)
        
        # Log the prediction
        print(f"Predictions: {predictions}, Predicted Class: {predicted_class}")

        # Return prediction result
        return {"prediction": predicted_class}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
