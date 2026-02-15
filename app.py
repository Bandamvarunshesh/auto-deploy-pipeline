from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify(status="ok", version=os.getenv("APP_VERSION", "DEV"))

@app.get("/")
def home():
    return "Auto Deployment Pipeline system\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
