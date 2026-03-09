# ---------- BASE ----------
FROM python:3.11-slim as base

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# ---------- SYSTEM DEPENDENCIES ----------
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    curl \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ---------- PYTHON DEPENDENCIES ----------
FROM base as builder

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install jsonschema

# ---------- FINAL IMAGE ----------
FROM base

COPY --from=builder /wheels /wheels

RUN pip install --no-cache-dir /wheels/*

# Whisper install (much faster)
RUN pip install --no-cache-dir openai-whisper

# preload model to avoid first request delay
RUN python -c "import whisper; whisper.load_model('base')"

COPY . .

EXPOSE 8080

CMD gunicorn \
    --bind 0.0.0.0:8080 \
    --workers ${GUNICORN_WORKERS:-8} \
    --timeout ${GUNICORN_TIMEOUT:-600} \
    app:app
