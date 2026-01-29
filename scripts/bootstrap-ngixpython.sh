#!/bin/bash
# 1. Instalar solo lo necesario (sin update completo para ganar velocidad)
yum install -y python3-pip nginx

# 2. Instalar FastAPI y Uvicorn
pip3 install fastapi uvicorn

# 3. Crear la App en Python
mkdir -p /home/ec2-user/app
cat << 'EOF' > /home/ec2-user/app/main.py
from fastapi import FastAPI
import socket

app = FastAPI()

@app.get("/")
def read_root():
    hostname = socket.gethostname()
    return {
        "message": "Hello from Python! (Fixed Version)",
        "server_id": hostname,
        "status": "It Works! 🚀"
    }
EOF

# 4. --- FIX IMPORTANTE: Crear servicio Systemd ---
# Esto garantiza que Python arranque como un servicio real y no muera
cat << 'EOF' > /etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI App
After=network.target

[Service]
User=root
WorkingDirectory=/home/ec2-user/app
ExecStart=/usr/local/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Recargar demonios y arrancar Python
systemctl daemon-reload
systemctl start fastapi
systemctl enable fastapi

# 5. Configurar NGINX como Reverse Proxy
cat << 'EOF' > /etc/nginx/conf.d/fastapi.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Ajuste de config por defecto
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat << 'EOF' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
EOF

# 6. --- FIX CRÍTICO: SELinux ---
# Permitir que NGINX hable con la red (puerto 8000)
setsebool -P httpd_can_network_connect 1

# 7. Arrancar NGINX
systemctl start nginx
systemctl enable nginx
