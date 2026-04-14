<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  if (data.session) {
    await auth.initialize()
    router.replace(auth.isTeacher ? { name: 'TeacherDashboard' } : { name: 'Home' })
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
