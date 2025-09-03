#!/bin/bash

# تحقق من البرامج المطلوبة
command -v ffmpeg >/dev/null 2>&1 || { echo "FFmpeg not found"; exit 1; }
command -v nginx >/dev/null 2>&1 || { echo "Nginx not found"; exit 1; }

# إعداد متغيرات البيئة
export SOURCE_URL="${SOURCE_URL:-http://188.241.219.157/ulke.bordo1453.befhjjjj/Orhantelegrammmm30conextionefbn/274122?token=ShJdY2ZmQQNHCmMZCDZXUh9GSHAWGFMD.ZDsGQVN.WGBFNX013GR9YV1QbGBp0QE9SWmpcXlQXXlUHWlcbRxFACmcDY1tXEVkbVAoAAQJUFxUbRFldAxdeUAdaVAFcUwcHAhwWQlpXQQMLTFhUG0FQQU1VQl4HWTsFVBQLVABGCVxEXFgeEVwNZgFcWVlZBxcDGwESHERcFxETWAxCCQgfEFNZQEBSRwYbX1dBVFtPF1pWRV5EFExGWxMmJxVJRlZKRVVaQVpcDRtfG0BLFU8XUEpvQlUVQRYEUA8HRUdeEQITHBZfUks8WgpXWl1UF1xWV0MSCkQERk0TDw1ZDBBcQG5AXVYRCQ1MCVVJ}"
export HLS_TIME="${HLS_TIME:-3}"
export HLS_LIST_SIZE="${HLS_LIST_SIZE:-5}"
export STREAM_QUALITY="${STREAM_QUALITY:-720p}"

echo "🚀 Starting HLS Stream Server..."
echo "📊 Configuration: HLS Time: ${HLS_TIME}s, List Size: ${HLS_LIST_SIZE}, Quality: ${STREAM_QUALITY}"

# تحديد مجلد العمل
WORK_DIR=$(pwd)
LOG_DIR="$WORK_DIR/logs"

# إنشاء المجلدات المطلوبة
mkdir -p "$WORK_DIR/hls" "$LOG_DIR"

# تنظيف الملفات القديمة
find "$WORK_DIR/hls" -name "*.ts" -delete 2>/dev/null || true
find "$WORK_DIR/hls" -name "*.m3u8" -delete 2>/dev/null || true

# عرض SOURCE_URL للتأكد
echo "🔗 Source URL: $SOURCE_URL"

echo "🌐 Starting Nginx server..."
nginx -c "$WORK_DIR/nginx.conf" -g "daemon off;" > "$LOG_DIR/nginx.log" 2>&1 &
NGINX_PID=$!

# انتظار بدء Nginx
sleep 3
if ! kill -0 $NGINX_PID 2>/dev/null; then
    echo "❌ Failed to start Nginx"
    cat "$LOG_DIR/nginx.log"
    exit 1
fi

echo "✅ Nginx started successfully (PID: $NGINX_PID)"

# إعدادات جودة مختلفة
case $STREAM_QUALITY in
    "480p")
        QUALITY_PRESET="-vf scale=854:480 -b:v 1000k -maxrate 1200k -bufsize 2000k"
        ;;
    "720p")
        QUALITY_PRESET="-vf scale=1280:720 -b:v 2500k -maxrate 3000k -bufsize 5000k"
        ;;
    "1080p")
        QUALITY_PRESET="-vf scale=1920:1080 -b:v 4500k -maxrate 5000k -bufsize 8000k"
        ;;
    *)
        QUALITY_PRESET="-c:v copy"
        ;;
esac

echo "📺 Starting FFmpeg stream (Quality: $STREAM_QUALITY)..."

# بدء FFmpeg
ffmpeg -hide_banner -loglevel error \
    -fflags +genpts+flush_packets \
    -avoid_negative_ts make_zero \
    -user_agent "Mozilla/5.0 (compatible; HLS-Server/1.0)" \
    -reconnect 1 \
    -reconnect_at_eof 1 \
    -reconnect_streamed 1 \
    -reconnect_delay_max 5 \
    -timeout 10000000 \
    -rw_timeout 10000000 \
    -analyzeduration 2000000 \
    -probesize 2000000 \
    -thread_queue_size 1024 \
    -i "$SOURCE_URL" \
    $QUALITY_PRESET \
    -c:a aac -b:a 128k -ar 44100 \
    -f hls \
    -hls_time $HLS_TIME \
    -hls_list_size $HLS_LIST_SIZE \
    -hls_flags delete_segments+independent_segments+omit_endlist \
    -hls_allow_cache 0 \
    -hls_segment_filename "$WORK_DIR/hls/segment%03d.ts" \
    -start_number 0 \
    "$WORK_DIR/hls/playlist.m3u8" > "$LOG_DIR/ffmpeg.log" 2>&1 &

FFMPEG_PID=$!

# انتظار بدء FFmpeg
sleep 5
if ! kill -0 $FFMPEG_PID 2>/dev/null; then
    echo "❌ Failed to start FFmpeg"
    cat "$LOG_DIR/ffmpeg.log"
    exit 1
fi

echo "✅ FFmpeg started successfully (PID: $FFMPEG_PID)"
echo "✅ HLS Stream Server started successfully!"
echo "🌐 Access the stream at: http://0.0.0.0:5000"
echo "📺 Direct M3U8 link: http://0.0.0.0:5000/hls/playlist.m3u8"

# دالة التنظيف
cleanup() {
    echo "🛑 Shutting down all services..."
    [ ! -z "$FFMPEG_PID" ] && kill $FFMPEG_PID 2>/dev/null || true
    [ ! -z "$NGINX_PID" ] && kill $NGINX_PID 2>/dev/null || true
    echo "✅ All services stopped"
    exit 0
}

# تعيين signal handlers
trap cleanup SIGTERM SIGINT SIGQUIT

# مراقبة FFmpeg مع إعادة التشغيل
restart_count=0
while true; do
    sleep 15
    
    # التحقق من FFmpeg
    if ! kill -0 $FFMPEG_PID 2>/dev/null; then
        restart_count=$((restart_count + 1))
        echo "⚠️ FFmpeg stopped (restart #$restart_count)"
        
        if [ $restart_count -gt 5 ]; then
            echo "❌ Too many restarts. Exiting..."
            exit 1
        fi
        
        echo "🔄 Restarting FFmpeg in 5 seconds..."
        sleep 5
        
        # تنظيف
        find "$WORK_DIR/hls" -name "*.ts" -delete 2>/dev/null || true
        find "$WORK_DIR/hls" -name "*.m3u8" -delete 2>/dev/null || true
        
        # إعادة تشغيل FFmpeg
        ffmpeg -hide_banner -loglevel error \
            -fflags +genpts+flush_packets \
            -avoid_negative_ts make_zero \
            -user_agent "Mozilla/5.0 (compatible; HLS-Server/1.0)" \
            -reconnect 1 \
            -reconnect_at_eof 1 \
            -reconnect_streamed 1 \
            -reconnect_delay_max 5 \
            -timeout 10000000 \
            -rw_timeout 10000000 \
            -analyzeduration 2000000 \
            -probesize 2000000 \
            -thread_queue_size 1024 \
            -i "$SOURCE_URL" \
            $QUALITY_PRESET \
            -c:a aac -b:a 128k -ar 44100 \
            -f hls \
            -hls_time $HLS_TIME \
            -hls_list_size $HLS_LIST_SIZE \
            -hls_flags delete_segments+independent_segments+omit_endlist \
            -hls_allow_cache 0 \
            -hls_segment_filename "$WORK_DIR/hls/segment%03d.ts" \
            -start_number 0 \
            "$WORK_DIR/hls/playlist.m3u8" > "$LOG_DIR/ffmpeg.log" 2>&1 &
        
        FFMPEG_PID=$!
        echo "🔄 FFmpeg restarted (PID: $FFMPEG_PID)"
    fi
    
    # التحقق من Nginx
    if ! kill -0 $NGINX_PID 2>/dev/null; then
        echo "⚠️ Nginx stopped, restarting..."
        nginx -c "$WORK_DIR/nginx.conf" -g "daemon off;" > "$LOG_DIR/nginx.log" 2>&1 &
        NGINX_PID=$!
        echo "🔄 Nginx restarted (PID: $NGINX_PID)"
    fi
done
