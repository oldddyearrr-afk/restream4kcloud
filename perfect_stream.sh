#!/bin/bash
# =============================
# Perfect HLS Stream with P2P
# =============================

# تنظيف شامل
pkill -f nginx 2>/dev/null || true
pkill -f ffmpeg 2>/dev/null || true
sleep 2

SOURCE_URL="http://hi-world.me:80/play/live.php?mac=00:1A:79:1E:00:37&stream=544835&extension=ts&play_token=xHWGoXetce&sn2="
WORK_DIR="/app"
STREAM_DIR="$WORK_DIR/stream"
HLS_DIR="$STREAM_DIR/hls"
LOGS_DIR="$STREAM_DIR/logs"
NGINX_CONF="/etc/nginx/nginx.conf"
PORT=${PORT:-8000}

# تحديث البورت داخل Nginx
sed -i "s/PORT_PLACEHOLDER/$PORT/" "$NGINX_CONF"

# تنظيف مجلد HLS
mkdir -p "$LOGS_DIR" "$HLS_DIR"
find "$HLS_DIR" -name "*.ts" -delete
find "$HLS_DIR" -name "*.m3u8" -delete

# تشغيل Nginx
nginx &
NGINX_PID=$!
sleep 2

# =============================
# دالة لتشغيل FFmpeg مع إعادة التشغيل التلقائية
# =============================
start_ffmpeg() {
    ffmpeg -hide_banner -loglevel error \
        -fflags +genpts \
        -user_agent "Mozilla/5.0 (compatible; Stream/1.0)" \
        -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
        -rw_timeout 10000000 \
        -i "$SOURCE_URL" \
        -c:v copy -c:a copy \
        -f hls \
        -hls_time 3 \
        -hls_list_size 6 \
        -hls_flags program_date_time+delete_segments+independent_segments \
        -hls_segment_filename "$HLS_DIR/seg_%03d.ts" \
        "$HLS_DIR/playlist.m3u8" &
    FFMPEG_PID=$!
}

start_ffmpeg

# =============================
# مراقبة FFmpeg وإعادة التشغيل
# =============================
monitor_ffmpeg() {
    while true; do
        sleep 15
        if ! kill -0 $FFMPEG_PID 2>/dev/null; then
            echo "🔄 FFmpeg crashed, restarting..."
            start_ffmpeg
        fi
    done
}

# =============================
# تنظيف segments قديمة لتخفيف الضغط
# =============================
cleanup_segments() {
    while true; do
        sleep 10
        SEGMENT_COUNT=$(ls -1 "$HLS_DIR"/seg_*.ts 2>/dev/null | wc -l)
        if [ "$SEGMENT_COUNT" -gt 8 ]; then
            ls -1t "$HLS_DIR"/seg_*.ts | tail -n +9 | xargs rm -f 2>/dev/null || true
        fi
    done
}

monitor_ffmpeg & cleanup_segments &
MONITOR_PID=$!; CLEANUP_PID=$!

# =============================
# تنظيف عند الإغلاق
# =============================
cleanup() {
    kill $FFMPEG_PID $NGINX_PID $MONITOR_PID $CLEANUP_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# إبقاء السكربت يعمل
while true; do sleep 60; done
