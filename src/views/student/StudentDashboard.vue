<template>
  <StudentDashboardLayout>
    <div class="dashboard-container">
      <!-- ローディング表示 -->
      <div v-if="loading" class="flex justify-center items-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>

      <!-- ウェルカムセクション -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gradient mb-2">ようこそ、{{ userStore.name }}さん！</h1>
        <p class="text-text-secondary">今日も、ここから。</p>
      </div>

      <!-- 統計カード -->
      <div class="stats-cards grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <Card :key="'assignments'" :class="`animate-fadeIn delay-100`" :show-header="false">
          <div class="flex items-center">
            <div class="stat-icon w-12 h-12 rounded-full flex items-center justify-center mr-4 shadow-neon bg-accent-blue bg-opacity-20">
              <i class="fas fa-tasks text-accent-blue"></i>
            </div>
            <div>
              <p class="text-app-text-secondary text-sm">進行中の課題</p>
              <div class="flex items-end">
                <p class="text-2xl font-bold">{{ pendingAssignments }}</p>
              </div>
            </div>
          </div>
        </Card>

        <Card :key="'progress'" :class="`animate-fadeIn delay-200`" :show-header="false">
          <div class="flex items-center">
            <div class="stat-icon w-12 h-12 rounded-full flex items-center justify-center mr-4 shadow-neon bg-primary bg-opacity-20">
              <i class="fas fa-chart-line text-primary"></i>
            </div>
            <div>
              <p class="text-app-text-secondary text-sm">進捗率</p>
              <div class="flex items-end">
                <p class="text-2xl font-bold">{{ progress }}%</p>
              </div>
            </div>
          </div>
        </Card>

        <Card :key="'streak'" :class="`animate-fadeIn delay-300`" :show-header="false">
          <div class="flex items-center">
            <div class="stat-icon w-12 h-12 rounded-full flex items-center justify-center mr-4 shadow-neon bg-accent-purple bg-opacity-20">
              <i class="fas fa-fire text-accent-purple"></i>
            </div>
            <div>
              <p class="text-app-text-secondary text-sm">連続学習日数</p>
              <div class="flex items-end">
                <p class="text-2xl font-bold">{{ streak }}日</p>
              </div>
            </div>
          </div>
        </Card>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- 最近のアクティビティ -->
        <div class="lg:col-span-2">
          <Card class="mb-6">
            <template #header>
              <h2 class="text-xl font-bold">最近のアクティビティ</h2>
            </template>
            <div class="divide-y divide-gray-200">
              <div v-for="(activity, index) in recentActivities" :key="index" class="py-4 flex items-start">
                <div :class="['activity-icon w-8 h-8 rounded-full flex items-center justify-center mr-3', activityIconClass(activity.type)]">
                  <i :class="['text-white text-sm', activityIcon(activity.type)]"></i>
                </div>
                <div class="flex-1">
                  <p class="text-sm font-medium text-gray-900">{{ activity.message }}</p>
                  <p class="text-xs text-gray-500">{{ activity.time }}</p>
                </div>
              </div>
            </div>
          </Card>
        </div>

        <!-- クイックアクション -->
        <div>
          <Card class="mb-6">
            <template #header>
              <h2 class="text-xl font-bold">クイックアクション</h2>
            </template>
            <div class="space-y-3">
              <button @click="navigateTo('/student/activities')" class="w-full flex items-center p-3 bg-gradient-to-r from-blue-50 to-indigo-50 hover:from-blue-100 hover:to-indigo-100 rounded-lg transition-all">
                <i class="fas fa-tasks mr-3 text-blue-500"></i>
                <span class="text-gray-700">アクティビティ</span>
              </button>
              <button @click="navigateTo('/student/progress')" class="w-full flex items-center p-3 bg-gradient-to-r from-pink-50 to-red-50 hover:from-pink-100 hover:to-red-100 rounded-lg transition-all">
                <i class="fas fa-chart-line mr-3 text-pink-500"></i>
                <span class="text-gray-700">進捗状況</span>
              </button>
              <button @click="navigateTo('/student/feedback')" class="w-full flex items-center p-3 bg-gradient-to-r from-green-50 to-teal-50 hover:from-green-100 hover:to-teal-100 rounded-lg transition-all">
                <i class="fas fa-comments mr-3 text-green-500"></i>
                <span class="text-gray-700">フィードバック</span>
              </button>
            </div>
          </Card>

          <!-- 今後の予定 -->
          <Card>
            <template #header>
              <h2 class="text-xl font-bold">今後の予定</h2>
            </template>
            <div class="divide-y divide-gray-200">
              <div v-for="(task, index) in upcomingTasks" :key="index" class="py-4">
                <div class="flex justify-between items-start">
                  <div>
                    <p class="text-sm font-medium text-gray-900">{{ task.title }}</p>
                    <p class="text-xs text-gray-500">{{ task.time }}</p>
                  </div>
                  <button class="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-xs">
                    詳細
                  </button>
                </div>
              </div>
              <div v-if="upcomingTasks.length === 0" class="py-4 text-center text-gray-500">
                予定はありません
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  </StudentDashboardLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from '@vue/runtime-core';
import { useRouter } from 'vue-router';
import { useUserStore } from '@/stores/user';
import Card from '@/components/common/Card.vue';
import StudentDashboardLayout from '@/components/layouts/StudentDashboardLayout.vue';

const router = useRouter();
const userStore = useUserStore();

// 状態
const loading = ref(false);

// 統計データ
const pendingAssignments = ref(3);
const progress = ref(75);
const streak = ref(5);

// 最近のアクティビティ
const recentActivities = ref([
  {
    type: 'assignment',
    message: '数学の課題を提出しました',
    time: '2時間前'
  },
  {
    type: 'feedback',
    message: '先生からのフィードバックが届きました',
    time: '昨日'
  },
  {
    type: 'progress',
    message: '英語の進捗が更新されました',
    time: '3日前'
  }
]);

// 今後の予定
const upcomingTasks = ref([
  {
    title: '数学の課題提出期限',
    time: '明日 23:59'
  },
  {
    title: '英語のレッスン',
    time: '明後日 15:00'
  }
]);

// メソッド
const navigateTo = (path: string) => {
  router.push(path);
};

const activityIconClass = (type: string) => {
  const classes: Record<string, string> = {
    'assignment': 'bg-blue-500',
    'feedback': 'bg-green-500',
    'progress': 'bg-purple-500',
    'default': 'bg-gray-500'
  };
  return classes[type] || classes['default'];
};

const activityIcon = (type: string) => {
  const icons: Record<string, string> = {
    'assignment': 'fas fa-tasks',
    'feedback': 'fas fa-comments',
    'progress': 'fas fa-chart-line',
    'default': 'fas fa-bell'
  };
  return icons[type] || icons['default'];
};

onMounted(async () => {
  loading.value = true;
  
  try {
    // 実際のアプリケーションではAPIからデータを取得
    await new Promise(resolve => setTimeout(resolve, 500)); // ローディングシミュレーション
    
    // ユーザーがログインしていない場合はログインページにリダイレクト
    if (!userStore.isLoggedIn) {
      router.push('/login');
      return;
    }
    
    // 生徒でない場合は生徒モードに切り替える
    if (!userStore.isStudent) {
      userStore.switchToStudentMode();
    }
  } catch (error) {
    console.error('Dashboard loading error:', error);
  } finally {
    loading.value = false;
  }
});
</script>

<style scoped>
.dashboard-container {
  @apply max-w-7xl mx-auto px-4 sm:px-6 lg:px-8;
}

.shadow-neon {
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.05);
}

.animate-gradient {
  background-size: 200% 200%;
}
</style> 