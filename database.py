from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any

from werkzeug.security import generate_password_hash

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "payroll.db"

ROLES = {"admin", "hr", "finance", "viewer"}


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    """Create local SQLite tables and seed starter login users."""
    with get_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                full_name TEXT,
                role TEXT NOT NULL CHECK(role IN ('admin', 'hr', 'finance', 'viewer')),
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS employees (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                employee_name TEXT NOT NULL,
                address TEXT,
                employer TEXT,
                job_title TEXT,
                department TEXT,
                email TEXT,
                phone TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS payroll_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                employee_id INTEGER NOT NULL,
                hours_worked REAL NOT NULL,
                hourly_rate REAL NOT NULL,
                regular_pay REAL NOT NULL,
                overtime_hours REAL NOT NULL,
                overtime_pay REAL NOT NULL,
                gross_pay REAL NOT NULL,
                tax_paid REAL NOT NULL,
                net_pay REAL NOT NULL,
                created_by INTEGER,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (employee_id) REFERENCES employees(id),
                FOREIGN KEY (created_by) REFERENCES users(id)
            )
            """
        )
        _ensure_payroll_created_by_column(conn)
        seed_users(conn)


def _ensure_payroll_created_by_column(conn: sqlite3.Connection) -> None:
    """Small migration for older local payroll.db files created before RBAC."""
    columns = conn.execute("PRAGMA table_info(payroll_records)").fetchall()
    column_names = {row[1] for row in columns}
    if "created_by" not in column_names:
        conn.execute("ALTER TABLE payroll_records ADD COLUMN created_by INTEGER")


def seed_users(conn: sqlite3.Connection) -> None:
    """Create demo users only when no users exist."""
    existing = conn.execute("SELECT COUNT(*) AS total FROM users").fetchone()["total"]
    if existing:
        return

    starter_users = [
        ("admin", "Admin User", "admin", "Admin@123"),
        ("hr", "HR User", "hr", "Hr@123"),
        ("finance", "Finance User", "finance", "Finance@123"),
        ("viewer", "Viewer User", "viewer", "Viewer@123"),
    ]
    conn.executemany(
        """
        INSERT INTO users (username, full_name, role, password_hash)
        VALUES (?, ?, ?, ?)
        """,
        [
            (username, full_name, role, generate_password_hash(password))
            for username, full_name, role, password in starter_users
        ],
    )


def get_user_by_username(username: str) -> dict[str, Any] | None:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT * FROM users WHERE username = ? AND is_active = 1",
            (username.strip(),),
        ).fetchone()
        return dict(row) if row else None


def get_user_by_id(user_id: int) -> dict[str, Any] | None:
    with get_connection() as conn:
        row = conn.execute(
            "SELECT id, username, full_name, role, is_active, created_at FROM users WHERE id = ? AND is_active = 1",
            (user_id,),
        ).fetchone()
        return dict(row) if row else None


def list_users() -> list[dict[str, Any]]:
    with get_connection() as conn:
        rows = conn.execute(
            "SELECT id, username, full_name, role, is_active, created_at FROM users ORDER BY id"
        ).fetchall()
        return [dict(row) for row in rows]


def create_user(data: dict[str, str]) -> int:
    username = data.get("username", "").strip()
    password = data.get("password", "")
    role = data.get("role", "").strip().lower()

    if not username:
        raise ValueError("Username is required.")
    if len(password) < 6:
        raise ValueError("Password must be at least 6 characters.")
    if role not in ROLES:
        raise ValueError("Invalid role selected.")

    with get_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO users (username, full_name, role, password_hash)
            VALUES (?, ?, ?, ?)
            """,
            (
                username,
                data.get("full_name", "").strip(),
                role,
                generate_password_hash(password),
            ),
        )
        return int(cur.lastrowid)


def create_employee(data: dict[str, str]) -> int:
    with get_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO employees (
                employee_name, address, employer, job_title, department, email, phone
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                data.get("employee_name", "").strip(),
                data.get("address", "").strip(),
                data.get("employer", "").strip(),
                data.get("job_title", "").strip(),
                data.get("department", "").strip(),
                data.get("email", "").strip(),
                data.get("phone", "").strip(),
            ),
        )
        return int(cur.lastrowid)


def get_employee_by_id(employee_id: int) -> dict[str, Any] | None:
    with get_connection() as conn:
        row = conn.execute("SELECT * FROM employees WHERE id = ?", (employee_id,)).fetchone()
        return dict(row) if row else None


def search_employees(query: str) -> list[dict[str, Any]]:
    query = query.strip()
    with get_connection() as conn:
        if query.isdigit():
            rows = conn.execute(
                "SELECT * FROM employees WHERE id = ? OR employee_name LIKE ? ORDER BY id DESC",
                (int(query), f"%{query}%"),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM employees WHERE employee_name LIKE ? ORDER BY id DESC",
                (f"%{query}%",),
            ).fetchall()
        return [dict(row) for row in rows]


def save_payroll_record(employee_id: int, result: Any, created_by: int | None = None) -> int:
    with get_connection() as conn:
        cur = conn.execute(
            """
            INSERT INTO payroll_records (
                employee_id, hours_worked, hourly_rate, regular_pay, overtime_hours,
                overtime_pay, gross_pay, tax_paid, net_pay, created_by
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                employee_id,
                float(result.hours_worked),
                float(result.hourly_rate),
                float(result.regular_pay),
                float(result.overtime_hours),
                float(result.overtime_pay),
                float(result.gross_pay),
                float(result.tax_paid),
                float(result.net_pay),
                created_by,
            ),
        )
        return int(cur.lastrowid)


def get_payroll_records(employee_id: int) -> list[dict[str, Any]]:
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT pr.*, u.username AS created_by_username
            FROM payroll_records pr
            LEFT JOIN users u ON pr.created_by = u.id
            WHERE pr.employee_id = ?
            ORDER BY pr.created_at DESC, pr.id DESC
            """,
            (employee_id,),
        ).fetchall()
        return [dict(row) for row in rows]
