let aiSpeedModel = null;

window.aiSpeedModelLoad = async function (modelUrl) {
  await tf.ready();

  // Tell TensorFlow.js where its TFLite WASM files are.
  tflite.setWasmPath(
    'https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite@0.0.1-alpha.10/wasm-out/'
  );

  console.log('Loading AI Speed Model...');

  aiSpeedModel = await tflite.loadTFLiteModel(modelUrl);

  console.log('AI Speed Model loaded successfully');
};

window.aiSpeedModelPredictJson = async function (json) {
  if (!aiSpeedModel) {
    throw new Error('AI Speed Model is not loaded');
  }

  const data = JSON.parse(json);

  // Model expects [1, 20, 12]
  const input = tf.tensor([data], [1, 20, 12], 'float32');

  const prediction = aiSpeedModel.predict(input);

  const output = Array.isArray(prediction)
    ? prediction[0]
    : prediction;

  const result = output.dataSync()[0];

  input.dispose();
  output.dispose();

  return result;
};

window.aiSpeedModelDispose = function () {
  aiSpeedModel = null;
  console.log('AI Speed Model disposed');
};