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
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'
import Hls from 'hls.js'

const props = defineProps({
  isPlaying: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['toggle'])

// Путь к HLS-плейлисту
const streamUrl = '/pulse/hls/stream.m3u8'

let audio = null
let hls = null
const isBuffering = ref(false)

function initAudio() {
  if (!audio) {
    audio = new Audio()
    // Воспроизведение всегда работает в фоне, звук контролируем через muted
    audio.muted = !props.isPlaying
  }

  if (Hls.isSupported()) {
    hls = new Hls({
      // Настройки для низких задержек (Live)
      liveSyncDurationCount: 3,
      liveMaxLatencyDurationCount: 10,
    })
    
    hls.loadSource(streamUrl)
    hls.attachMedia(audio)

    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      audio.play().catch(e => console.warn('Autoplay blocked:', e))
    })

    hls.on(Hls.Events.ERROR, (event, data) => {
      if (data.fatal) {
        switch (data.type) {
          case Hls.ErrorTypes.NETWORK_ERROR:
            console.error('Network error, trying to recover...', data)
            hls.startLoad()
            break
          case Hls.ErrorTypes.MEDIA_ERROR:
            console.error('Media error, recovering...', data)
            hls.recoverMediaError()
            break
          default:
            hls.destroy()
            break
        }
      }
    })
  } else if (audio.canPlayType('application/vnd.apple.mpegurl')) {
    // Fallback для Safari (iOS/macOS), который нативно поддерживает HLS
    audio.src = streamUrl
    audio.addEventListener('loadedmetadata', () => {
      audio.play().catch(e => console.warn('Autoplay blocked:', e))
    })
  }
}

watch(() => props.isPlaying, (newVal) => {
  if (audio) {
    audio.muted = !newVal
    if (newVal && audio.paused) {
      const playPromise = audio.play()
      if (playPromise !== undefined) {
        playPromise.catch(e => console.warn('Play blocked:', e))
      }
    }
  }
})

function handleToggle() {
  const willPlay = !props.isPlaying
  if (!audio) {
    initAudio()
  }
  
  emit('toggle')
  
  if (audio && willPlay) {
    audio.muted = false
    const playPromise = audio.play()
    if (playPromise !== undefined) {
      playPromise.catch(e => console.warn('Play blocked:', e))
    }
  }
}

onBeforeUnmount(() => {
  if (hls) {
    hls.destroy()
  }
})
</script>
