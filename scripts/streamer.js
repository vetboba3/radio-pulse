import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { PassThrough } from 'stream';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const MUSIC_DIR = path.join(__dirname, '../public/music');
const PORT = 3000;

// Общий поток, в который мы "вещаем"
const broadcaster = new PassThrough();
const clients = new Set();

// Функция для получения списка файлов
function getPlaylist() {
  return fs.readdirSync(MUSIC_DIR)
    .filter(file => file.endsWith('.mp3'))
    .map(file => path.join(MUSIC_DIR, file))
    .sort(() => Math.random() - 0.5); // Перемешиваем
}

// Главный цикл вещания
async function startBroadcasting() {
  while (true) {
    const playlist = getPlaylist();
    if (playlist.length === 0) {
      console.error('Папка music пуста!');
      await new Promise(resolve => setTimeout(resolve, 5000));
      continue;
    }

    for (const track of playlist) {
      console.log(`Играет: ${path.basename(track)}`);
      await new Promise((resolve) => {
        const stream = fs.createReadStream(track);
        stream.pipe(broadcaster, { end: false });
        stream.on('end', resolve);
        stream.on('error', (err) => {
          console.error(`Ошибка при чтении ${track}:`, err);
          resolve();
        });
      });
    }
  }
}

// Настройка HTTP сервера
const server = http.createServer((req, res) => {
  if (req.url === '/radio') {
    console.log('Новое подключение слушателя');
    
    res.writeHead(200, {
      'Content-Type': 'audio/mpeg',
      'Transfer-Encoding': 'chunked',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    // Привязываем клиента к общему потоку
    const clientStream = new PassThrough();
    broadcaster.pipe(clientStream);
    clientStream.pipe(res);

    clients.add(res);

    req.on('close', () => {
      console.log('Слушатель отключился');
      broadcaster.unpipe(clientStream);
      clients.delete(res);
    });
  } else {
    res.writeHead(404);
    res.end();
  }
});

server.listen(PORT, () => {
  console.log(`\n=== Radio PULSE Streamer ===`);
  console.log(`Поток доступен по адресу: http://localhost:${PORT}/radio`);
  console.log(`Сканирую папку: ${MUSIC_DIR}`);
  console.log(`============================\n`);
  startBroadcasting();
});
