#!/usr/bin/env python3
"""
Safora — Crash/Fall Detection TFLite Model Training Pipeline
=============================================================

Generates a TFLite model that classifies 12-element accelerometer feature
vectors into 3 classes: normal (0), fall (1), crash (2).

Feature vector contract (from ml_feature_extractor.dart):
  [0]  SMV mean       (normalized: / 10G)
  [1]  SMV max        (normalized: / 10G)
  [2]  SMV min        (normalized: / 10G)
  [3]  SMV variance   (normalized: / 100)
  [4]  SMV range      (normalized: / 10G)
  [5]  SMA            (normalized)
  [6]  Jerk mean      (normalized: / 1000)
  [7]  Jerk max       (normalized: / 5000)
  [8]  Freefall ratio (0–1)
  [9]  Stillness ratio(0–1)
  [10] Dominant axis  (0.33–1.0)
  [11] ZCR            (0–1)

Model architecture:
  Input[12] → Dense(64, ReLU) → Dropout(0.3)
            → Dense(32, ReLU) → Dropout(0.2)
            → Dense(3, Softmax)

Synthetic data distributions are based on:
  - SisFall dataset (Sucerquia et al., 2017)
  - MobiAct dataset (Vavoulas et al., 2016)
  - WreckWatch (White et al., IEEE VTC, 2012)
  - SmartFall (Guo et al., IEEE EMBC, 2018)

Usage:
  pip install numpy tensorflow
  python3 train_crash_fall_model.py

Output:
  ../../assets/ml_models/crash_fall_model.tflite
"""

import os
import sys
import numpy as np

# ─── Constants ──────────────────────────────────────────────────
NUM_FEATURES = 12
NUM_CLASSES = 3
SAMPLES_PER_CLASS = 5000
TOTAL_SAMPLES = SAMPLES_PER_CLASS * NUM_CLASSES

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'ml_models')
OUTPUT_PATH = os.path.join(OUTPUT_DIR, 'crash_fall_model.tflite')

GRAVITY = 9.80665  # m/s²


# ═══════════════════════════════════════════════════════════════
# 1. SYNTHETIC DATA GENERATION
# ═══════════════════════════════════════════════════════════════

def _clip(x, lo=0.0, hi=1.0):
    """Clip value to [lo, hi]."""
    return np.clip(x, lo, hi)


def _rand(low, high, n=1):
    """Uniform random in [low, high]."""
    return np.random.uniform(low, high, size=n)


def _randn(mean, std, n=1):
    """Gaussian random with mean and std."""
    return np.random.normal(mean, std, size=n)


def generate_normal_samples(n: int) -> np.ndarray:
    """
    Generate feature vectors for normal activity (walking, standing, sitting).

    Physical basis:
    - SMV ≈ 1G during rest, 0.8–1.3G during walking
    - Low variance, low jerk, no freefall
    - Moderate stillness during sitting/standing
    """
    features = np.zeros((n, NUM_FEATURES), dtype=np.float32)

    # [0] SMV mean: 0.9–1.1G → normalized / 10G → 0.09–0.11
    features[:, 0] = _clip(_randn(0.10, 0.015, n))

    # [1] SMV max: 1.0–2.5G → normalized → 0.10–0.25
    features[:, 1] = _clip(_randn(0.15, 0.03, n))

    # [2] SMV min: 0.7–1.0G → normalized → 0.07–0.10
    features[:, 2] = _clip(_randn(0.085, 0.015, n))

    # [3] SMV variance: very low → 0.001–0.05
    features[:, 3] = _clip(_randn(0.01, 0.01, n), 0.0)

    # [4] SMV range: small → 0.02–0.15
    features[:, 4] = _clip(_randn(0.06, 0.03, n), 0.0)

    # [5] SMA: moderate → 0.25–0.45
    features[:, 5] = _clip(_randn(0.33, 0.05, n))

    # [6] Jerk mean: low (50–200 m/s³) → normalized /1000 → 0.05–0.2
    features[:, 6] = _clip(_randn(0.10, 0.04, n), 0.0)

    # [7] Jerk max: low (100–500 m/s³) → normalized /5000 → 0.02–0.10
    features[:, 7] = _clip(_randn(0.05, 0.02, n), 0.0)

    # [8] Freefall ratio: essentially 0
    features[:, 8] = _clip(_randn(0.01, 0.01, n), 0.0)

    # [9] Stillness ratio: moderate (varies by activity)
    features[:, 9] = _clip(_randn(0.5, 0.2, n))

    # [10] Dominant axis: gravity axis dominates → 0.6–0.9
    features[:, 10] = _clip(_randn(0.7, 0.1, n), 0.33)

    # [11] ZCR: moderate walking oscillation → 0.2–0.5
    features[:, 11] = _clip(_randn(0.35, 0.1, n))

    return features


def generate_fall_samples(n: int) -> np.ndarray:
    """
    Generate feature vectors for fall events.

    Physical basis (from SisFall/MobiAct research):
    - Brief freefall period (0.2–0.5s at ~0G)
    - Impact spike (3–8G peak)
    - Post-impact stillness (lying on ground)
    - High jerk at impact moment
    """
    features = np.zeros((n, NUM_FEATURES), dtype=np.float32)

    # [0] SMV mean: elevated from impact → 0.15–0.30
    features[:, 0] = _clip(_randn(0.22, 0.04, n))

    # [1] SMV max: impact peak 3–8G → normalized → 0.30–0.80
    features[:, 1] = _clip(_randn(0.50, 0.12, n))

    # [2] SMV min: freefall dips → 0.01–0.04
    features[:, 2] = _clip(_randn(0.025, 0.012, n), 0.0)

    # [3] SMV variance: high due to impact → 0.10–0.50
    features[:, 3] = _clip(_randn(0.25, 0.10, n))

    # [4] SMV range: large (freefall to impact) → 0.25–0.75
    features[:, 4] = _clip(_randn(0.45, 0.12, n))

    # [5] SMA: elevated from impact energy → 0.40–0.70
    features[:, 5] = _clip(_randn(0.55, 0.08, n))

    # [6] Jerk mean: high (500–3000 m/s³) → 0.15–0.45
    features[:, 6] = _clip(_randn(0.30, 0.08, n))

    # [7] Jerk max: impact spike (1500–5000 m/s³) → 0.30–0.80
    features[:, 7] = _clip(_randn(0.55, 0.12, n))

    # [8] Freefall ratio: distinctive pre-impact freefall → 0.10–0.40
    features[:, 8] = _clip(_randn(0.22, 0.08, n))

    # [9] Stillness ratio: high post-fall lying still → 0.30–0.70
    features[:, 9] = _clip(_randn(0.50, 0.12, n))

    # [10] Dominant axis: changes during fall → 0.40–0.75
    features[:, 10] = _clip(_randn(0.55, 0.10, n), 0.33)

    # [11] ZCR: single impact → low → 0.05–0.20
    features[:, 11] = _clip(_randn(0.12, 0.05, n))

    return features


def generate_crash_samples(n: int) -> np.ndarray:
    """
    Generate feature vectors for vehicle crash events.

    Physical basis (from WreckWatch/EDR data):
    - Very high sustained impact (5–16G peak, from NHTSA EDR data)
    - No preceding freefall (unlike falls — already in contact with vehicle)
    - Sustained vibration/oscillation after impact
    - Extremely high jerk values
    - Less post-impact stillness than falls (vehicle may still be moving)
    """
    features = np.zeros((n, NUM_FEATURES), dtype=np.float32)

    # [0] SMV mean: very high from sustained impact → 0.25–0.55
    features[:, 0] = _clip(_randn(0.38, 0.08, n))

    # [1] SMV max: severe impact 5–16G → normalized → 0.50–1.0
    features[:, 1] = _clip(_randn(0.75, 0.14, n))

    # [2] SMV min: no freefall, but dips during oscillation → 0.05–0.12
    features[:, 2] = _clip(_randn(0.08, 0.02, n), 0.0)

    # [3] SMV variance: very high → 0.30–0.80
    features[:, 3] = _clip(_randn(0.50, 0.14, n))

    # [4] SMV range: dramatic → 0.40–0.95
    features[:, 4] = _clip(_randn(0.65, 0.14, n))

    # [5] SMA: very high energy → 0.60–0.95
    features[:, 5] = _clip(_randn(0.78, 0.08, n))

    # [6] Jerk mean: very high (2000–10000 m/s³) → 0.40–0.85
    features[:, 6] = _clip(_randn(0.60, 0.12, n))

    # [7] Jerk max: extreme spike → 0.60–1.0
    features[:, 7] = _clip(_randn(0.80, 0.10, n))

    # [8] Freefall ratio: ~0 (no freefall in vehicle crash)
    features[:, 8] = _clip(_randn(0.02, 0.015, n), 0.0)

    # [9] Stillness ratio: low (vehicle vibration continues) → 0.05–0.20
    features[:, 9] = _clip(_randn(0.10, 0.04, n))

    # [10] Dominant axis: crash direction dominates → 0.50–0.85
    features[:, 10] = _clip(_randn(0.65, 0.10, n), 0.33)

    # [11] ZCR: high oscillation from crash vibration → 0.40–0.70
    features[:, 11] = _clip(_randn(0.55, 0.10, n))

    return features


def generate_dataset():
    """Generate balanced synthetic dataset."""
    print(f"Generating {TOTAL_SAMPLES} synthetic samples ({SAMPLES_PER_CLASS} per class)...")

    X_normal = generate_normal_samples(SAMPLES_PER_CLASS)
    X_fall = generate_fall_samples(SAMPLES_PER_CLASS)
    X_crash = generate_crash_samples(SAMPLES_PER_CLASS)

    X = np.vstack([X_normal, X_fall, X_crash])
    y = np.array(
        [0] * SAMPLES_PER_CLASS +  # normal
        [1] * SAMPLES_PER_CLASS +  # fall
        [2] * SAMPLES_PER_CLASS,   # crash
        dtype=np.int32
    )

    # Shuffle
    indices = np.random.permutation(len(X))
    X, y = X[indices], y[indices]

    print(f"  Feature shape: {X.shape}")
    print(f"  Label shape:   {y.shape}")
    print(f"  Feature range: [{X.min():.4f}, {X.max():.4f}]")

    return X, y


# ═══════════════════════════════════════════════════════════════
# 2. MODEL CREATION & TRAINING
# ═══════════════════════════════════════════════════════════════

def create_model():
    """Create the Keras model matching our inference contract."""
    import tensorflow as tf

    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(NUM_FEATURES,), name='features'),
        tf.keras.layers.Dense(64, activation='relu', name='dense_1'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(32, activation='relu', name='dense_2'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(NUM_CLASSES, activation='softmax', name='output'),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    return model


def train_model(model, X, y):
    """Train the model with early stopping."""
    import tensorflow as tf

    print("\nTraining model...")
    print(model.summary())

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_accuracy',
            patience=8,
            restore_best_weights=True,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=4,
            min_lr=1e-6,
        ),
    ]

    history = model.fit(
        X, y,
        epochs=80,
        batch_size=64,
        validation_split=0.2,
        callbacks=callbacks,
        verbose=1,
    )

    # Final metrics
    val_loss, val_acc = model.evaluate(X, y, verbose=0)
    print(f"\nFinal accuracy: {val_acc:.4f}")
    print(f"Final loss:     {val_loss:.4f}")

    return history


# ═══════════════════════════════════════════════════════════════
# 3. TFLITE EXPORT
# ═══════════════════════════════════════════════════════════════

def export_tflite(model):
    """Convert Keras model to TFLite and save."""
    import tensorflow as tf

    print(f"\nExporting TFLite model...")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Float32 (no quantization) — maintains accuracy, small enough for mobile (~10KB)
    tflite_model = converter.convert()

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(OUTPUT_PATH, 'wb') as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"  Saved: {OUTPUT_PATH}")
    print(f"  Size:  {size_kb:.1f} KB")

    return tflite_model


def verify_model(tflite_model):
    """Verify model I/O shapes and run test inference."""
    import tensorflow as tf

    print("\nVerifying model...")

    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"  Input:  shape={input_details[0]['shape']}, dtype={input_details[0]['dtype']}")
    print(f"  Output: shape={output_details[0]['shape']}, dtype={output_details[0]['dtype']}")

    # Verify shapes match our Dart contract
    assert input_details[0]['shape'].tolist() == [1, NUM_FEATURES], \
        f"Input shape mismatch: {input_details[0]['shape']}"
    assert output_details[0]['shape'].tolist() == [1, NUM_CLASSES], \
        f"Output shape mismatch: {output_details[0]['shape']}"

    # Test inference with synthetic normal, fall, crash vectors
    test_cases = {
        'normal': np.array([[0.10, 0.15, 0.085, 0.01, 0.06, 0.33, 0.10, 0.05,
                             0.01, 0.50, 0.70, 0.35]], dtype=np.float32),
        'fall':   np.array([[0.22, 0.50, 0.025, 0.25, 0.45, 0.55, 0.30, 0.55,
                             0.22, 0.50, 0.55, 0.12]], dtype=np.float32),
        'crash':  np.array([[0.38, 0.75, 0.08,  0.50, 0.65, 0.78, 0.60, 0.80,
                             0.02, 0.10, 0.65, 0.55]], dtype=np.float32),
    }

    class_names = ['normal', 'fall', 'crash']

    print("\n  Test inference results:")
    for label, features in test_cases.items():
        interpreter.set_tensor(input_details[0]['index'], features)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])[0]
        predicted = class_names[np.argmax(output)]
        print(f"    {label:>6s} input → predicted: {predicted:>6s}  "
              f"[normal={output[0]:.3f}, fall={output[1]:.3f}, crash={output[2]:.3f}]")

        if label != predicted:
            print(f"    ⚠️  Mismatch: expected {label}, got {predicted}")

    print("\n✅ Model verification complete!")


# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

def main():
    print("=" * 60)
    print("Safora — Crash/Fall Detection Model Training")
    print("=" * 60)

    np.random.seed(42)

    # Step 1: Generate data
    X, y = generate_dataset()

    # Step 2: Create & train model
    model = create_model()
    train_model(model, X, y)

    # Step 3: Export to TFLite
    tflite_model = export_tflite(model)

    # Step 4: Verify
    verify_model(tflite_model)

    print(f"\n🏁 Done! Model ready at: {os.path.abspath(OUTPUT_PATH)}")


if __name__ == '__main__':
    main()
