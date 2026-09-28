import numpy as np
import tensorflow as tf
from sklearn.metrics import mean_absolute_error, mean_squared_error


# ============================================================
# LOAD TFLITE MODEL
# ============================================================

MODEL_PATH = "speed_model.tflite"

print("Loading TFLite model...")

interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input shape:", input_details[0]["shape"])
print("Output shape:", output_details[0]["shape"])


# ============================================================
# LOAD S1 TEST DATA
# ============================================================

print("\nLoading S1 data...")

X = np.load("X_s1_invariant.npy")
y = np.load("y_s1_invariant.npy")

print("X shape:", X.shape)
print("y shape:", y.shape)


# ============================================================
# RUN TFLITE PREDICTIONS
# ============================================================

predictions = []

for i in range(len(X)):

    sample = X[i:i+1].astype(np.float32)

    interpreter.set_tensor(
        input_details[0]["index"],
        sample
    )

    interpreter.invoke()

    prediction = interpreter.get_tensor(
        output_details[0]["index"]
    )

    predictions.append(prediction[0][0])


predictions = np.array(predictions)


# ============================================================
# EVALUATE
# ============================================================

mae = mean_absolute_error(
    y,
    predictions
)

rmse = mean_squared_error(
    y,
    predictions
) ** 0.5


# ============================================================
# RESULTS
# ============================================================

print()
print("======================================")
print("TFLITE S1 TEST RESULTS")
print("======================================")

print("MAE :", mae, "km/h")
print("RMSE:", rmse, "km/h")

print()
print("First 10 predictions:")
print(predictions[:10])

print()
print("First 10 actual speeds:")
print(y[:10])