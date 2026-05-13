from __future__ import annotations

from functools import wraps
from typing import Callable, TypeVar

from flask import Flask, flash, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash

from database import (
    ROLES,
    create_employee,
    create_user,
    get_employee_by_id,
    get_payroll_records,
    get_user_by_id,
    get_user_by_username,
    init_db,
    list_users,
    save_payroll_record,
    search_employees,
)
from payroll import calculate_payroll

app = Flask(__name__)
app.config["SECRET_KEY"] = "change-this-secret-key-before-production"
init_db()

F = TypeVar("F", bound=Callable)


def current_user() -> dict | None:
    user_id = session.get("user_id")
    if not user_id:
        return None
    return get_user_by_id(int(user_id))


@app.context_processor
def inject_user() -> dict:
    return {"current_user": current_user(), "roles": sorted(ROLES)}


def login_required(view: F) -> F:
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not current_user():
            flash("Please log in first.", "error")
            return redirect(url_for("login", next=request.path))
        return view(*args, **kwargs)

    return wrapped  # type: ignore[return-value]


def role_required(*allowed_roles: str) -> Callable[[F], F]:
    def decorator(view: F) -> F:
        @wraps(view)
        def wrapped(*args, **kwargs):
            user = current_user()
            if not user:
                flash("Please log in first.", "error")
                return redirect(url_for("login", next=request.path))
            if user["role"] not in allowed_roles:
                flash("You do not have permission to access that page.", "error")
                return redirect(url_for("index"))
            return view(*args, **kwargs)

        return wrapped  # type: ignore[return-value]

    return decorator


@app.get("/login")
def login():
    if current_user():
        return redirect(url_for("index"))
    return render_template("login.html")


@app.post("/login")
def login_post():
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "")
    user = get_user_by_username(username)

    if not user or not check_password_hash(user["password_hash"], password):
        flash("Invalid username or password.", "error")
        return render_template("login.html", username=username), 401

    session.clear()
    session["user_id"] = user["id"]
    session["role"] = user["role"]
    flash(f"Logged in as {user['username']} ({user['role']}).", "success")
    return redirect(request.args.get("next") or url_for("index"))


@app.get("/logout")
def logout():
    session.clear()
    flash("Logged out successfully.", "success")
    return redirect(url_for("login"))


@app.get("/")
@login_required
def index():
    return render_template("index.html", result=None, error=None, form={}, employee=None, records=[])


@app.post("/employees")
@role_required("admin", "hr")
def add_employee():
    form = request.form.to_dict()
    if not form.get("employee_name", "").strip():
        return render_template("index.html", result=None, error="Employee name is required.", form=form, employee=None, records=[]), 400
    employee_id = create_employee(form)
    flash("Employee created successfully.", "success")
    return redirect(url_for("employee_detail", employee_id=employee_id))


@app.get("/employees/search")
@login_required
def employee_search():
    query = request.args.get("q", "")
    employees = search_employees(query) if query.strip() else []
    return render_template("search.html", query=query, employees=employees)


@app.get("/employees/<int:employee_id>")
@login_required
def employee_detail(employee_id: int):
    employee = get_employee_by_id(employee_id)
    if employee is None:
        return render_template("search.html", query=str(employee_id), employees=[], error="Employee not found."), 404
    records = get_payroll_records(employee_id)
    return render_template("index.html", result=None, error=None, form=employee, employee=employee, records=records)


@app.post("/employees/<int:employee_id>/calculate")
@role_required("admin", "hr", "finance")
def calculate(employee_id: int):
    employee = get_employee_by_id(employee_id)
    if employee is None:
        return render_template("search.html", query=str(employee_id), employees=[], error="Employee not found."), 404

    form = request.form.to_dict()
    form.update(employee)
    try:
        result = calculate_payroll(form)
    except ValueError as exc:
        records = get_payroll_records(employee_id)
        return render_template("index.html", result=None, error=str(exc), form=form, employee=employee, records=records), 400

    user = current_user()
    save_payroll_record(employee_id, result, created_by=user["id"] if user else None)
    records = get_payroll_records(employee_id)
    flash("Payroll calculated and saved.", "success")
    return render_template("index.html", result=result.as_display_dict(), error=None, form=form, employee=employee, records=records)


@app.get("/admin/users")
@role_required("admin")
def users():
    return render_template("users.html", users=list_users())


@app.post("/admin/users")
@role_required("admin")
def add_user():
    try:
        create_user(request.form.to_dict())
    except ValueError as exc:
        return render_template("users.html", users=list_users(), error=str(exc), form=request.form), 400
    except Exception as exc:
        return render_template("users.html", users=list_users(), error=f"Could not create user: {exc}", form=request.form), 400

    flash("User created successfully.", "success")
    return redirect(url_for("users"))


@app.get("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
