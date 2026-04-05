## Google Cloud Service account json base64 encode
# Linux/Mac:
base64 -w 0 jouw-key.json

# Windows (PowerShell):
[Convert]::ToBase64String([IO.File]::ReadAllBytes("jouw-key.json"))