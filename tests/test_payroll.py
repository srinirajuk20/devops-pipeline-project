from decimal import Decimal

from payroll import calculate_payroll


def test_regular_pay_without_overtime():
    result = calculate_payroll({"hours_worked": "40", "hourly_rate": "100", "employee_name": "Asha"})
    assert result.regular_pay == Decimal("4000.00")
    assert result.overtime_hours == Decimal("0.00")
    assert result.overtime_pay == Decimal("0.000")
    assert result.gross_pay == Decimal("4000.000")
    assert result.net_pay == Decimal("3200.0000")


def test_overtime_pay_is_time_and_half():
    result = calculate_payroll({"hours_worked": "45", "hourly_rate": "100", "employee_name": "Asha"})
    assert result.overtime_hours == Decimal("5.00")
    assert result.overtime_pay == Decimal("750.000")
    assert result.gross_pay == Decimal("4750.000")


def test_negative_hours_rejected():
    try:
        calculate_payroll({"hours_worked": "-1", "hourly_rate": "100"})
    except ValueError as exc:
        assert "cannot be negative" in str(exc)
    else:
        raise AssertionError("Expected ValueError")
