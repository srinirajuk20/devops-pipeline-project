from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return "DevOps Project Running-Test Version-6 for Blue/green Testing."

@app.route("/health")
def health():
    return jsonify(status="ok")

if __name__ == "__main__":
     app.run(host="0.0.0.0", port=5000)


import os
import psycopg2

DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME")
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASSWORD")

def get_db_connection():
        return psycopg2.connect(
                        host=DB_HOST,
                                database=DB_NAME,
                                        user=DB_USER,
                                                password=DB_PASS
                                                    )

        @app.route("/db")
        def db_check():
                conn = get_db_connection()
                    cur = conn.cursor()
                        cur.execute("SELECT NOW();")
                            result = cur.fetchone()
                                conn.close()
                                    return f"DB Time: {result}"
