#!/bin/bash
# === Скрипт деплоя Radio PULSE на сервер ===
# Использование: bash scripts/deploy.sh

SERVER="root@172.86.114.225"
REMOTE_WEB="/var/www/friendlypeople/pulse"
REMOTE_APP="/opt/radio-pulse"

echo "=== Radio PULSE Deploy ==="
echo ""

# 1. Загрузка фронтенда (собранный dist/)
echo "[1/4] Загружаю фронтенд..."
scp -r dist/* "$SERVER:$REMOTE_WEB/"

# 2. Загрузка скрипта Liquidsoap
echo "[2/4] Загружаю конфиг Liquidsoap..."
ssh "$SERVER" "mkdir -p $REMOTE_APP"
scp scripts/radio-prod.liq "$SERVER:$REMOTE_APP/radio.liq"

# 3. Загрузка музыки (если папка music на сервере пуста)
echo "[3/4] Загружаю музыку..."
ssh "$SERVER" "mkdir -p $REMOTE_APP/music"
scp -r public/music/* "$SERVER:$REMOTE_APP/music/"

# 4. Установка и запуск Liquidsoap на сервере
echo "[4/4] Настраиваю сервер..."
ssh "$SERVER" bash -s << 'REMOTE_SCRIPT'
  # Установка ffmpeg и liquidsoap если не установлены
  which liquidsoap > /dev/null 2>&1 || apt-get install -y ffmpeg liquidsoap

  # Создаём папку для HLS-сегментов
  mkdir -p /var/www/friendlypeople/pulse/hls

  # Создаём systemd-сервис для Liquidsoap
  cat > /etc/systemd/system/radio-pulse.service << 'EOF'
[Unit]
Description=Radio PULSE Liquidsoap Streamer
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/radio-pulse
ExecStart=/usr/bin/liquidsoap /opt/radio-pulse/radio.liq
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  # Перезапускаем сервис
  systemctl daemon-reload
  systemctl enable radio-pulse
  systemctl restart radio-pulse

  # Добавляем правила Nginx для HLS (no-cache для .m3u8)
  # Проверяем, есть ли уже наша конфигурация
  if ! grep -q "m3u8" /etc/nginx/sites-available/friendlypeople* 2>/dev/null; then
    echo "⚠️  Нужно добавить в Nginx-конфиг блок для HLS:"
    echo '  location ~* \.m3u8$ {'
    echo '    add_header Cache-Control "no-cache, no-store";'
    echo '    add_header Access-Control-Allow-Origin "*";'
    echo '  }'
    echo '  location ~* \.ts$ {'
    echo '    add_header Cache-Control "max-age=2";'
    echo '    add_header Access-Control-Allow-Origin "*";'
    echo '  }'
  fi

  # Проверяем статус
  echo ""
  echo "=== Статус сервиса ==="
  systemctl status radio-pulse --no-pager -l | head -15
  echo ""
  echo "=== Проверка HLS ==="
  sleep 3
  ls -la /var/www/friendlypeople/pulse/hls/ | head -5

REMOTE_SCRIPT

echo ""
echo "=== Деплой завершён ==="
echo "Сайт: https://friendlypeople.space/pulse/"
