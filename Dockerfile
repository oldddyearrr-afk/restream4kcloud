FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PORT=8000

# تثبيت الحزم الضرورية
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    nginx \
    bash \
    curl \
    ca-certificates \
    tzdata \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# نسخ الملفات
COPY . .

# إنشاء مجلدات HLS و Logs
RUN mkdir -p stream/hls stream/logs \
    && mkdir -p /var/log/nginx /var/lib/nginx /run \
    && chmod +x perfect_stream.sh \
    && chmod 755 stream/hls

# نسخ nginx.conf template
RUN cp stream/nginx.conf.template /etc/nginx/nginx.conf.template

EXPOSE 8000

CMD ["./perfect_stream.sh"]
