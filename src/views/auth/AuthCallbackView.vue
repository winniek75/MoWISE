<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  if (data.session) {
    router.replace({ name: 'Home' })
  } else {
    router.replace({ name: 'Onboarding1' })
  }
})
</script>

<template>
  <div class="min-h-screen bg-bg-dark flex items-center justify-center">
    <div class="w-16 h-16 mowi-orb animate-mowi-pulse" />
  </div>
</template>
