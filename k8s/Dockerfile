FROM python:3.12-slim

# security: non-root runtime user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app               
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .                    

USER app
EXPOSE 80
CMD ["gunicorn", "--bind", "0.0.0.0:80", "main:app"] 
