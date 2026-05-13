FROM python:3.10-slim

WORKDIR /app
COPY requirements.txt .
RUN python -m pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 5001
CMD ["flask", "--app", "app", "run", "--host", "0.0.0.0", "--port", "5001"]
