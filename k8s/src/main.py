from flask import Flask, render_template, jsonify, send_file, redirect, url_for
from prometheus_client import generate_latest
from datetime import datetime
import pytz
from metrics import gandalf_requests, colombo_requests

app = Flask(__name__)

# ----- Routes --------------------------------------------------------------

@app.route("/")
def index():
    # lightweight landing page that links to the required paths
    return redirect(url_for("gandalf"))

@app.route("/gandalf")
def gandalf():
    gandalf_requests.inc()
    image_url = (
        "https://static1.colliderimages.com/wordpress/wp-content/"
        "uploads/2024/10/why-gandalf-needs-a-staff-in-the-lord-of-the-rings.jpg"
    )
    colombo_time = get_colombo_time()
    return render_template(
        "index.html",
        image_url=image_url,
        colombo_time=colombo_time,
    )

@app.route("/colombo")
def colombo():
    colombo_requests.inc()
    return render_template("colombo.html", colombo_time=get_colombo_time())

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": "text/plain; version=0.0.4"}

@app.route("/colombo/time")
def colombo_time_api():
    return jsonify({"colombo_time": get_colombo_time()})

# ----- Helpers -------------------------------------------------------------

def get_colombo_time() -> str:
    return datetime.now(pytz.timezone("Asia/Colombo")).strftime("%Y-%m-%d %H:%M:%S")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
