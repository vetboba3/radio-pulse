<template>
  <button
    class="pulse-btn"
    :aria-label="isPlaying ? 'Пауза' : 'Воспроизвести'"
    @click="handleToggle"
  >
    <!-- Play icon -->
    <svg
      v-if="!isPlaying"
      class="pulse-btn__icon"
      viewBox="0 0 32 32"
      xmlns="http://www.w3.org/2000/svg"
    >
      <polygon points="10,6 26,16 10,26" />
    </svg>
    <!-- Pause icon -->
    <svg
      v-else
      class="pulse-btn__icon"
      viewBox="0 0 32 32"
      xmlns="http://www.w3.org/2000/svg"
    >
      <rect x="8" y="6" width="5" height="20" />
      <rect x="19" y="6" width="5" height="20" />
    </svg>
    <!-- Glitch overlay -->
    <span class="pulse-btn__glitch" aria-hidden="true"></span>
  </button>
</template>

<script setup>
const props = defineProps({
  isPlaying: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['toggle'])

const playlist = [
  '/1.mp3',
  '/2.mp3',
  '/3.mp3',
  '/4.mp3',
  '/5.mp3',
  '/6.mp3',
  '/8 марта.mp3',
  '/dram and buss 1.mp3',
  '/drum and buss 2.mp3',
  '/Гимн  (1).mp3',
  '/Гимн .mp3',
  '/Для Ирины.mp3',
  '/Код любви.mp3',
  '/Лошадь и обезьяны.mp3',
  '/Лучший.mp3',
  '/Ната, фо ю.mp3',
  '/Пить или жить_.mp3',
  '/Пить, или жить.mp3',
  '/Прозрение 1.mp3',
  '/Прозрение 2.mp3',
  '/Река 1.mp3',
  '/Река 2.mp3',
  '/Сова .mp3',
  '/Сон.mp3',
  '/Супер Гид .mp3',
  '/белка (1).mp3',
  '/белка.mp3'
]

let audio = null
let currentTrackIndex = 0
let isStarted = false

function playCurrentTrack() {
  if (audio) {
    audio.pause()
  }
  audio = new Audio(playlist[currentTrackIndex])
  // Если мы переключаем трек в фоне (на паузе), он должен оставаться без звука
  audio.muted = !props.isPlaying
  audio.addEventListener('ended', playNextTrack)
  audio.play().catch(e => console.error('Ошибка воспроизведения:', e))
}

function playNextTrack() {
  currentTrackIndex = (currentTrackIndex + 1) % playlist.length
  playCurrentTrack()
}

function handleToggle() {
  const willPlay = !props.isPlaying
  emit('toggle')

  if (!isStarted) {
    // Первый запуск эфира
    isStarted = true
    audio = new Audio(playlist[currentTrackIndex])
    audio.muted = !willPlay
    audio.addEventListener('ended', playNextTrack)
    audio.play().catch(e => console.error('Ошибка воспроизведения:', e))
  } else {
    // Эфир уже идёт, просто выключаем/включаем звук
    if (audio) {
      audio.muted = !willPlay
    }
  }
}
</script>
