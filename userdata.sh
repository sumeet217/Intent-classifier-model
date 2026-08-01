set -e

export APP_DIR=/opt/intent-app
mkdir -p $APP_DIR
cd $APP_DIR

apt install -y
apt install git python3 python3-venv python3-pip nginx

git clone https://github.com/iam-veeramalla/Intent-classifier-model.git .
python3 -m venv ml-env
source ml-env/bin/activate

pip install --upgrade pip
python3 -m pip install requirements.txt

python3 model/train.py

# Gunicorn config systemd service

cat >/etc/systemd/system/intent_gunicorn.service <<'EOF'
[Unit]
Description=Gunicorn instance for Intent Classifier
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/intent-app
Environment="PATH=/opt/intent-app/.venv/bin"
ExecStart=/opt/intent-app/.venv/bin/gunicorn --workers 3 --bind 127.0.0.1:6000 wsgi:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# nginx config

cat >/etc/nginx/conf.d/intent_app.conf <<'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:6000/predict;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 60s;
        proxy_read_timeout 120s;
    }
}
EOF

# Remove default site if present to avoid duplicate default_server collision
if [ -L /etc/nginx/sites-enabled/default ] || [ -f /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default || true
fi

# start & enable services
systemctl daemon-reload
systemctl enable intent_gunicorn
systemctl start intent_gunicorn
systemctl enable nginx
systemctl restart nginx



