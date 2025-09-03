# استخدام Ubuntu كصورة أساسية محسنة
FROM ubuntu:22.04

# تجنب التفاعل أثناء التثبيت
ENV DEBIAN_FRONTEND=noninteractive

# تحديث النظام وتثبيت المتطلبات المحسنة
RUN apt-get update && apt-get install -y \
    nginx \
    ffmpeg \
    bash \
    curl \
    htop \
    net-tools \
    procps \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# إنشاء دليل العمل والمجلدات المطلوبة
WORKDIR /app
RUN mkdir -p /app/hls /app/logs /var/log/supervisor

# نسخ ملفات المشروع
COPY nginx.conf /app/nginx.conf
COPY start.sh /app/start.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# جعل السكريبت قابل للتنفيذ
RUN chmod +x /app/start.sh

# إعداد متغيرات البيئة
ENV SOURCE_URL=""
ENV HLS_TIME=3
ENV HLS_LIST_SIZE=5
ENV STREAM_QUALITY=720p
ENV NGINX_WORKERS=2

# كشف المنفذ
EXPOSE 5000

# استخدام supervisor لإدارة العمليات
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
