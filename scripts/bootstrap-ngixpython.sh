#!/bin/bash
yum install -y python3-pip nginx

pip3 install fastapi uvicorn

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

systemctl daemon-reload
systemctl start fastapi
systemctl enable fastapi

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

setsebool -P httpd_can_network_connect 1

systemctl start nginx
systemctl enable nginx
