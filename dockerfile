FROM python:3.12-slim

# Prevent Python from writing .pyc files and enable stdout/stderr flushing
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc libc-dev \
 && pip install --no-cache-dir -r requirements.txt \
 && apt-get remove -y gcc libc-dev \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

COPY . .

RUN python3 model/train.py

EXPOSE 6000

CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:6000", "app:app"]


