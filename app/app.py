from flask import Flask, jsonify
import os
import psycopg2

app = Flask(__name__)


def get_db_connection():
        return psycopg2.connect(
                        host=os.environ.get("DB_HOST"),
                                database=os.environ.get("DB_NAME"),
                                        user=os.environ.get("DB_USER"),
                                                password=os.environ.get("DB_PASSWORD"),
                                                    )


        @app.route("/")
        def home():
                return "DevOps Project Running"


            @app.route("/health")
            def health():
                    return jsonify(status="ok"), 200


                @app.route("/db")
                def db_check():
                        try:
                                    conn = get_db_connection()
                                            cur = conn.cursor()
                                                    cur.execute("SELECT NOW();")
                                                            result = cur.fetchone()
                                                                    cur.close()
                                                                            conn.close()

                                                                                    return jsonify(
                                                                                                        status="ok",
                                                                                                                    message="Database connection successful",
                                                                                                                                db_time=str(result[0])
                                                                                                                                        ), 200

                                                                                        except Exception as e:
                                                                                                    return jsonify(
                                                                                                                        status="error",
                                                                                                                                    message="Database connection failed",
                                                                                                                                                error=str(e)
                                                                                                                                                        ), 500


                                                                                                    if __name__ == "__main__":
                                                                                                            app.run(host="0.0.0.0", port=5000)
