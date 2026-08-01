# Intent Classifier

A lightweight text intent classification service built with **scikit-learn** and served via a **Flask + Gunicorn** REST API. The project includes a Docker image and Kubernetes manifests for production deployment.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [API Reference](#api-reference)
- [Local Setup](#local-setup)
- [Docker](#docker)
- [Kubernetes](#kubernetes)
- [VM Deployment (userdata)](#vm-deployment-userdata)

---

## Overview

| Component | Technology |
|-----------|-----------|
| Model | scikit-learn `MultinomialNB` + `CountVectorizer` pipeline |
| API | Flask, served with Gunicorn (4 workers) |
| Container | Python 3.12-slim Docker image |
| Orchestration | Kubernetes (Deployment + ClusterIP Service) |

The model is trained at image build time and the artifact is baked into the container — no external model registry required.

---

## Project Structure

```
.
├── app.py                  # Flask application (health + predict endpoints)
├── wsgi.py                 # Gunicorn entrypoint
├── dockerfile              # Multi-step Docker build
├── requirements.txt        # Python dependencies
├── userdata.sh             # Cloud VM bootstrap script (Nginx + Gunicorn + systemd)
├── model/
│   ├── train.py            # Trains the model and saves the artifact
│   ├── intent_model.py     # Model wrapper (load + predict)
│   └── artifacts/          # Generated at train time (intent_model.pkl)
└── k8s/
    ├── namespace.yml       # Kubernetes namespace
    ├── deployment.yml      # Deployment (2 replicas)
    └── service.yml         # ClusterIP Service (port 80 → 6000)
```

---

## API Reference

### `GET /health`

Returns service liveness status.

```json
{ "status": "ok" }
```

### `POST /predict`

Classifies the intent of a text input.

**Request**
```bash
curl -X POST http://localhost:6000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I want to cancel my subscription"}'
```

**Response**
```json
{ "intent": "complaint" }
```

**Supported intents:** `greeting`, `question`, `complaint`, `praise`

---

## Local Setup

```bash
# 1. Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Train the model
python3 model/train.py
# → Saves artifact to model/artifacts/intent_model.pkl

# 4. Start the API
python3 app.py
# → Listening on http://127.0.0.1:6000
```

---

## Docker

```bash
# Build the image (training runs inside the build)
docker build -t intent-classifier:latest -f dockerfile .

# Run the container
docker run -p 6000:6000 intent-classifier:latest
```

The image is available on Docker Hub:

```bash
docker pull sumeet02/intent-classifier:latest
```

---

## Kubernetes

Apply the manifests in order:

```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/deployment.yml
kubectl apply -f k8s/service.yml
```

| Resource | Details |
|----------|---------|
| Namespace | `intent-namespace` |
| Deployment | `intent-classifier`, 2 replicas |
| Service | `ClusterIP`, port `80` → container port `6000` |

To test from inside the cluster:

```bash
kubectl run curl-test --image=curlimages/curl -it --rm --restart=Never \
  -- curl -X POST http://intent-classifier.intent-namespace/predict \
     -H "Content-Type: application/json" \
     -d '{"text": "hello there"}'
```

---

## VM Deployment (userdata)

`userdata.sh` is a cloud-init bootstrap script that automates deployment on a fresh Ubuntu VM (e.g. AWS EC2):

- Clones the repo
- Creates a Python virtual environment and installs dependencies
- Trains the model
- Configures a **systemd** service for Gunicorn
- Configures **Nginx** as a reverse proxy on port `80`

Paste the contents of `userdata.sh` into your instance's **User Data** field at launch, or run it manually:

```bash
sudo bash userdata.sh
```
