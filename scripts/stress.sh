sudo yum install -y stress-ng
stress-ng --cpu 0 --timeout 600s --metrics-brief --temp-path /tmp