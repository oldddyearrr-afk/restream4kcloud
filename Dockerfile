# استخدام Ubuntu كصورة أساسية
FROM ubuntu:22.04

# تجنب التفاعل أثناء التثبيت
ENV DEBIAN_FRONTEND=noninteractive

# تحديث النظام وتثبيت المتطلبات
RUN apt-get update && apt-get install -y \
    nginx \
    ffmpeg \
    bash \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# إنشاء دليل العمل والمجلدات المطلوبة
WORKDIR /app
RUN mkdir -p /app/hls /app/logs

# نسخ ملفات المشروع
COPY nginx.conf /app/nginx.conf
COPY start.sh /app/start.sh

# جعل السكريبت قابل للتنفيذ
RUN chmod +x /app/start.sh

# إعداد متغيرات البيئة
ENV SOURCE_URL="http://188.241.219.157/ulke.bordo1453.befhjjjj/Orhantelegrammmm30conextionefbn/274122?token=ShJdY2ZmQQNHCmMZCDZXUh9GSHAWGFMD.ZDsGQVN.WGBFNX013GR9YV1QbGBp0QE9SWmpcXlQXXlUHWlcbRxFACmcDY1tXEVkbVAoAAQJUFxUbRFldAxdeUAdaVAFcUwcHAhwWQlpXQQMLTFhUG0FQQU1VQl4HWTsFVBQLVABGCVxEXFgeEVwNZgFcWVlZBxcDGwESHERcFxETWAxCCQgfEFNZQEBSRwYbX1dBVFtPF1pWRV5EFExGWxMmJxVJRlZKRVVaQVpcDRtfG0BLFU8XUEpvQlUVQRYEUA8HRUdeEQITHBZfUks8WgpXWl1UF1xWV0MSCkQERk0TDw1ZDBBcQG5AXVYRCQ1MCVVJ"
ENV HLS_TIME=3
ENV HLS_LIST_SIZE=5
ENV STREAM_QUALITY=720p

# كشف المنفذ
EXPOSE 5000

# تشغيل السكريپت مباشرة
CMD ["bash", "/app/start.sh"]
