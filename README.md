# 🧭 AI/ML-Based Dead Reckoning Navigation System

An AI/ML-powered navigation system designed to provide **seamless movement and positioning during GNSS/GPS outages** using smartphone sensor data and deep learning.

The system processes **IMU (Inertial Measurement Unit)** data such as accelerometer and gyroscope readings to estimate movement characteristics when GPS/GNSS signals are unavailable or unreliable.

---

## 🚀 Features

* 📍 GNSS/GPS-independent movement estimation
* 📱 Smartphone-based IMU sensor processing
* 🤖 AI/ML-based speed and motion estimation
* 🧠 CNN + GRU deep learning model
* 📊 Time-series sensor data processing
* 🔄 Supports continuous navigation during GNSS outages
* ⚡ Designed for real-time navigation applications

---

## 🧠 How It Works

The system follows a sensor-to-prediction pipeline:

```text
Smartphone Sensors
       ↓
Data Collection
       ↓
Data Preprocessing
       ↓
Feature Extraction
       ↓
Time-Series Windowing
       ↓
CNN + GRU Model
       ↓
Movement / Speed Estimation
       ↓
Dead Reckoning Navigation
```

The model learns patterns from historical sensor data and uses these patterns to estimate movement when reliable GNSS positioning is unavailable.

---

## 🤖 Machine Learning Model

The current prototype uses a hybrid **CNN-GRU architecture**.

### CNN — Convolutional Neural Network

Extracts important local patterns and features from sequential sensor data.

### GRU — Gated Recurrent Unit

Captures temporal dependencies and movement patterns across consecutive sensor readings.

Combining CNN and GRU allows the model to learn both **sensor features and temporal motion patterns**.

---

## 📊 Dataset

The project uses smartphone and vehicle sensor datasets containing information such as:

* GPS Latitude & Longitude
* GPS Altitude
* GPS Speed
* GPS Accuracy
* GPS Orientation
* Accelerometer X/Y/Z
* Gyroscope Yaw/Pitch/Roll
* Gravity X/Y/Z
* Magnetic Field X/Y/Z
* Vehicle speed and motion parameters

GPS data is used as a reference during model development and evaluation.

---

## 🛠️ Tech Stack

* **Python**
* **TensorFlow / Keras**
* **NumPy**
* **Pandas**
* **Scikit-learn**
* **CNN**
* **GRU**
* **Matplotlib**
* **Jupyter / VS Code**

---

## 📁 Project Structure

```text
dead-reckoning/
│
├── data/
│   └── dataset.csv
│
├── prepare_data.py
├── train_cnn.py
├── train_cnn_gru.py
├── evaluate_cnn.py
│
├── speed_cnn_gru.keras
│
├── requirements.txt
└── README.md
```

---

## ⚙️ Installation

Clone the repository:

```bash
git clone https://github.com/karanjotsingh16/Dead-Reckoning-Navigation-System.git
cd dead-reckoning
```

Install dependencies:

```bash
pip install -r requirements.txt
```

---

## ▶️ Running the Project

### 1. Prepare the dataset

```bash
python prepare_data.py
```

### 2. Train the model

```bash
python train_cnn_gru.py
```

### 3. Evaluate the model

```bash
python evaluate_cnn.py
```

The trained model is saved as:

```text
speed_cnn_gru.keras
```

---

## 📈 Current Results

The current CNN-GRU prototype was trained on sequential sensor data for movement/speed estimation.

**Model:**

* CNN + GRU
* Input: Time-series sensor features
* Output: Speed estimation

**Current test MAE:** ~14.81 km/h

> Model performance is still being improved through preprocessing, feature engineering, architecture optimization, and sensor fusion.

---

## 🎯 Applications

This technology can be useful in environments where GNSS signals are weak or unavailable, including:

* 🚇 Tunnels
* 🏙️ Urban canyons
* 🏢 Indoor environments
* 🏔️ Areas with signal obstruction
* ✈️ GNSS-denied environments
* 🚗 Vehicle navigation
* 📱 Smartphone navigation

---

## 🔮 Future Scope

* Real-time IMU sensor streaming and processing
* Advanced GPS + IMU sensor fusion
* Kalman / Extended Kalman Filter integration
* Improved position and trajectory estimation
* Improved model accuracy through advanced feature engineering
* Support for additional smartphone sensors
* Offline map integration and enhanced route visualization
* Real-time navigation performance optimization
* Edge AI optimization for efficient on-device inference
* Robustness testing across different environments and device types



