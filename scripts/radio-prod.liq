#!/usr/bin/liquidsoap

# === Radio PULSE — Production Config ===
# Запускается на сервере как systemd-сервис
settings.init.allow_root := true


# Путь к папке с музыкой на сервере
music_dir = "/opt/radio-pulse/music"
# HLS-сегменты пишутся прямо в папку, которую раздаёт Nginx
hls_dir = "/var/www/friendlypeople/pulse/hls"

# Создаем источник (плейлист) с рандомизацией
radio = playlist(mode="randomize", reload_mode="watch", music_dir)

# Добавляем кроссфейд для плавного перехода между треками
radio = crossfade(duration=3.0, radio)

# Делаем источник безотказным (infallible)
radio = mksafe(radio)

# Вывод в HLS
output.file.hls(
  playlist="stream.m3u8",
  segment_duration=2.0,
  segments=10,
  segments_overhead=5,
  hls_dir,
  [("stream", %ffmpeg(format="mpegts", %audio(codec="aac", b="128k")))],
  radio
)
