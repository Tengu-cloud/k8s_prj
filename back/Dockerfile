FROM python:3.12-alpine

WORKDIR /app

COPY app.py .

RUN addgroup -S group1 && adduser -S user1 -G group1

USER user1

EXPOSE 8080

CMD ["python", "app.py"]