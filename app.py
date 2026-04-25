import os
import logging
from flask import Flask, jsonify, request
import psycopg2
from psycopg2.extras import RealDictCursor

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)

logger = logging.getLogger(__name__)
app = Flask(__name__)


def get_db_connection():
    required = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"]

    for var in required:
        if var not in os.environ:
            raise RuntimeError(f"Missing required env var: {var}")

    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
    )


def init_db():
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    id SERIAL PRIMARY KEY,
                    content TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)


@app.route("/")
def index():
    return jsonify(message="Flask app is running"), 200


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


@app.route("/ready")
def ready():
    try:
        init_db()
        return jsonify(status="ready", database="ok"), 200
    except RuntimeError as e:
        return jsonify(status="not_ready", reason=str(e)), 503
    except Exception as e:
        logger.exception("Readiness check failed")
        return jsonify(status="not_ready", error=str(e)), 503


@app.route("/messages", methods=["POST"])
def create_message():
    data = request.get_json(silent=True) or {}
    content = data.get("content")

    if not content:
        return jsonify(error="content is required"), 400

    try:
        init_db()
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(
                    """
                    INSERT INTO messages (content)
                    VALUES (%s)
                    RETURNING id, content, created_at;
                    """,
                    (content,),
                )
                message = cur.fetchone()

        return jsonify(message), 201

    except RuntimeError as e:
        return jsonify(error=str(e)), 500
    except Exception as e:
        logger.exception("Failed to create message")
        return jsonify(error="failed to create message"), 500


@app.route("/messages", methods=["GET"])
def list_messages():
    try:
        init_db()
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT id, content, created_at
                    FROM messages
                    ORDER BY id DESC
                    LIMIT 20;
                """)
                messages = cur.fetchall()

        return jsonify(messages), 200

    except RuntimeError as e:
        return jsonify(error=str(e)), 500
    except Exception as e:
        logger.exception("Failed to list messages")
        return jsonify(error="failed to list messages"), 500