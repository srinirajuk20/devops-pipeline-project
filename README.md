# Employee Payroll Web App with RBAC

Browser-based Flask payroll app with SQLite storage and local role-based access control.

## Features
- Login/logout
- SQLite database
- NI number removed
- Add/search/retrieve employees by ID or name
- Calculate and save weekly payroll records
- User roles/groups: admin, hr, finance, viewer
- Admin-only user management

## Demo users

| Username | Password | Role |
|---|---|---|
| admin | Admin@123 | admin |
| hr | Hr@123 | hr |
| finance | Finance@123 | finance |
| viewer | Viewer@123 | viewer |

## Role permissions

| Role | Permissions |
|---|---|
| admin | Add employees, calculate payroll, search, manage users |
| hr | Add employees, calculate payroll, search |
| finance | Search employees and calculate payroll |
| viewer | Search/read only |

## Run locally

```bash
python3 -m venv ~/venvs/employee_payroll_web
source ~/venvs/employee_payroll_web/bin/activate
pip install -r requirements.txt
flask --app app run --host=0.0.0.0 --port=5001
```

## Docker

```bash
docker build -t employee-payroll-app .
docker run -d -p 5001:5001 --restart unless-stopped --name payroll-app employee-payroll-app:latest
```

With your current Vagrant forwarding:

```text
5001 guest => 8081 host
```

Open from host browser:

```text
http://127.0.0.1:8081
```

## Database

The SQLite database file `payroll.db` is created automatically. For production, use PostgreSQL/RDS and SSO/OIDC instead of local demo users.
