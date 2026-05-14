<template>
  <div class="pulse-page" :class="{ 'pulse-playing': isPlaying }">
    <PulseBackground />
    <PulseWaveLight />
    <PulseWaveDark />
    <PulseButton :is-playing="isPlaying" @toggle="isPlaying = !isPlaying" />
    <PulseLogo />
    <PulseCommunity />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import PulseBackground from '../components/PulseBackground.vue'
import PulseWaveLight from '../components/PulseWaveLight.vue'
import PulseWaveDark from '../components/PulseWaveDark.vue'
import PulseButton from '../components/PulseButton.vue'
import PulseLogo from '../components/PulseLogo.vue'
import PulseCommunity from '../components/PulseCommunity.vue'

const isPlaying = ref(false)
</script>
