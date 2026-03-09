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

RUN pip install --upgrade pip

RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt
RUN pip wheel --no-cache-dir --wheel-dir /wheels jsonschema

# ---------- FINAL IMAGE ----------
FROM base

COPY --from=builder /wheels /wheels

RUN pip install --no-cache-dir /wheels/*

# Whisper install
RUN pip install --no-cache-dir openai-whisper

# preload model
RUN python -c "import whisper; whisper.load_model('base')"

COPY . .

EXPOSE 8080

CMD ["gunicorn","--bind","0.0.0.0:8080","--workers","8","--timeout","600","app:app"]