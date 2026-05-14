<template>
  <button
    class="pulse-btn"
    :aria-label="isPlaying ? 'Пауза' : 'Воспроизвести'"
    @click="handleToggle"
  >
    <svg viewBox="0 0 40 40" class="pulse-btn__svg" xmlns="http://www.w3.org/2000/svg">
      <!-- Круг с вырезанной иконкой (используем fill-rule="evenodd") -->
      <path 
        fill-rule="evenodd" 
        clip-rule="evenodd" 
        d="M20 0C8.9543 0 0 8.9543 0 20C0 31.0457 8.9543 40 20 40C31.0457 40 40 31.0457 40 20C40 8.9543 31.0457 0 20 0ZM14 10L30 20L14 30V10Z" 
        v-if="!isPlaying"
        fill="var(--pulse-wave-dark)" 
      />
      <path 
        fill-rule="evenodd" 
        clip-rule="evenodd" 
        d="M20 0C8.9543 0 0 8.9543 0 20C0 31.0457 8.9543 40 20 40C31.0457 40 40 31.0457 40 20C40 8.9543 31.0457 0 20 0ZM12 10H17V30H12V10ZM23 10H28V30H23V10Z" 
        v-else
        fill="var(--pulse-wave-dark)" 
      />
    </svg>
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

// URL вашего потока. Пока пусто или локальный адрес для теста.
const streamUrl = 'http://localhost:3000/radio'

let audio = null
let isInitialized = false

function initAudio(willPlay) {
  if (audio) return

  audio = new Audio(streamUrl)
  // В режиме Live stream 'preload' лучше ставить 'none' или 'metadata', 
  // но для "Always On" мы сразу начинаем загрузку.
  audio.preload = 'auto'
  audio.muted = !willPlay
  
  // Обработка ошибок подключения
  audio.addEventListener('error', (e) => {
    console.error('Ошибка потока Radio PULSE:', e)
    // Можно добавить логику авто-переподключения здесь
    isInitialized = false
    audio = null
  })

  audio.play().catch(e => {
    console.warn('Автовоспроизведение заблокировано или поток недоступен:', e)
  })
}

function handleToggle() {
  const willPlay = !props.isPlaying
  emit('toggle')

  if (!isInitialized) {
    isInitialized = true
    initAudio(willPlay)
  } else if (audio) {
    // Просто переключаем звук, поток продолжает идти в фоне
    audio.muted = !willPlay
    
    // На случай, если поток прервался или был на паузе браузером
    if (audio.paused && willPlay) {
      audio.play().catch(p => console.error('Не удалось возобновить поток:', p))
    }
  }
}
</script>
