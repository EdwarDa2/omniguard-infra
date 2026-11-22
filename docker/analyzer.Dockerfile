FROM python:3.12-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1

COPY omniguard-analyzer-python/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY omniguard-analyzer-python/analyzer.py \
     omniguard-analyzer-python/detector.py \
     omniguard-analyzer-python/notifier.py \
     ./

ENTRYPOINT ["python", "analyzer.py"]
