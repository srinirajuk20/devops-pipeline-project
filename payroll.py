from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import date
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from typing import Any

CURRENCY = "INR"
STANDARD_HOURS = Decimal("40")
TAX_RATE = Decimal("0.20")
OVERTIME_MULTIPLIER = Decimal("1.5")


@dataclass(frozen=True)
class PayrollResult:
    employee_name: str
    address: str
    employer: str
    hours_worked: Decimal
    hourly_rate: Decimal
    regular_pay: Decimal
    overtime_hours: Decimal
    overtime_pay: Decimal
    gross_pay: Decimal
    tax_paid: Decimal
    net_pay: Decimal
    currency: str = CURRENCY
    payslip_date: str = date.today().strftime("%d/%m/%Y")

    def as_display_dict(self) -> dict[str, str]:
        data: dict[str, Any] = asdict(self)
        money_fields = {
            "hourly_rate",
            "regular_pay",
            "overtime_pay",
            "gross_pay",
            "tax_paid",
            "net_pay",
        }
        for key, value in data.items():
            if isinstance(value, Decimal):
                data[key] = money(value) if key in money_fields else str(value)
        return data


def parse_decimal(value: str, field_name: str) -> Decimal:
    try:
        parsed = Decimal(value.strip())
    except (InvalidOperation, AttributeError):
        raise ValueError(f"{field_name} must be a valid number.") from None

    if parsed < 0:
        raise ValueError(f"{field_name} cannot be negative.")

    return parsed.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def money(value: Decimal) -> str:
    rounded = value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return f"{CURRENCY} {rounded}"


def calculate_payroll(form: dict[str, str]) -> PayrollResult:
    hours_worked = parse_decimal(form.get("hours_worked", ""), "Hours worked")
    hourly_rate = parse_decimal(form.get("hourly_rate", ""), "Hourly rate")

    regular_hours = min(hours_worked, STANDARD_HOURS)
    overtime_hours = max(hours_worked - STANDARD_HOURS, Decimal("0"))

    regular_pay = regular_hours * hourly_rate
    overtime_pay = overtime_hours * hourly_rate * OVERTIME_MULTIPLIER
    gross_pay = regular_pay + overtime_pay
    tax_paid = gross_pay * TAX_RATE
    net_pay = gross_pay - tax_paid

    return PayrollResult(
        employee_name=form.get("employee_name", "").strip(),
        address=form.get("address", "").strip(),
        employer=form.get("employer", "").strip(),
        hours_worked=hours_worked,
        hourly_rate=hourly_rate,
        regular_pay=regular_pay,
        overtime_hours=overtime_hours,
        overtime_pay=overtime_pay,
        gross_pay=gross_pay,
        tax_paid=tax_paid,
        net_pay=net_pay,
    )
