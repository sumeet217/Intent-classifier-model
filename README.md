# Intent Classifier

A text intent classification service built with scikit-learn and Flask. The project includes Docker containerization and Kubernetes deployment manifests.

## Overview

This service classifies text into four categories: greeting, question, complaint, and praise. The model uses a Naive Bayes classifier with CountVectorizer for text processing.

**Tech Stack**
- Model: scikit-learn (MultinomialNB + CountVectorizer)
- API: Flask with Gunicorn
- Container: Python 3.12-slim
- Deployment: Kubernetes with Ingress

## Project Structure

```
.
├── app.py                  # Flask application
├── wsgi.py                 # Gunicorn entrypoint
├── dockerfile              # Docker build definition
├── requirements.txt        # Python dependencies
├── userdata.sh             # Cloud VM bootstrap script
├── model/
│   ├── train.py            # Model training script
│   ├── intent_model.py     # Model wrapper
│   └── model/              # Trained model artifact
└── k8s/                    # Kubernetes manifests
    ├── namespace.yml
    ├── deployment.yml
    ├── service.yml
    └── Ingress.yml
```

## API Endpoints

**GET /health**

Health check endpoint.

```json
{ "status": "ok" }
```

**POST /predict**

Classifies text intent.

Request:
```bash
curl -X POST http://localhost:6000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I want to cancel my subscription"}'
```

Response:
```json
{ "intent": "complaint" }
```

## Local Setup

```bash
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Train the model
python3 model/train.py

# Start the server
python3 app.py
```

The API will be available at `http://127.0.0.1:6000`

## Docker Deployment

Build and run the container:

```bash
docker build -t intent-classifier:latest -f dockerfile .
docker run -p 6000:6000 intent-classifier:latest
```

Or pull from Docker Hub:

```bash
docker pull sumeet02/intent-classifier:latest
```

## Kubernetes Deployment

Apply the manifests:

```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/deployment.yml
kubectl apply -f k8s/service.yml
kubectl apply -f k8s/Ingress.yml
```

The deployment creates 2 replicas in the `intent-namespace` namespace with a ClusterIP service routing traffic from port 80 to container port 6000.

Test from inside the cluster:

```bash
kubectl run curl-test --image=curlimages/curl -it --rm --restart=Never \
  -- curl -X POST http://intent-classifier.intent-namespace/predict \
     -H "Content-Type: application/json" \
     -d '{"text": "hello there"}'
```

## VM Deployment

The `userdata.sh` script automates deployment on Ubuntu VMs (AWS EC2, etc.). It sets up the application with Gunicorn and Nginx as a reverse proxy.

Usage:
```bash
sudo bash userdata.sh
```
