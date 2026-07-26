<template>
  <div class="min-h-screen bg-bg-dark">
    <!-- Header -->
    <header class="neo-header">
      <button @click="router.push('/teacher')" class="text-white/30 text-sm font-title hover:text-white/50 transition-colors mb-1">
        ← ダッシュボードへ
      </button>
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-title font-bold text-white">{{ currentClass?.class_name ?? 'クラス詳細' }}</h1>
        <div class="flex items-center gap-4">
          <button
            v-if="store.students.length > 0"
            @click="exportCSV"
            class="btn-ghost !text-xs border border-white/10 !rounded-xl"
          >CSV出力</button>
          <div v-if="currentClass" class="text-right">
            <p class="text-[10px] text-white/25 font-title">クラスコード</p>
            <span class="font-mono text-xl font-bold tracking-[0.2em] text-neo-gradient">
              {{ currentClass.class_code }}
            </span>
          </div>
        </div>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-5 py-6 space-y-5">

      <!-- Class stats -->
      <section v-if="store.students.length > 0" class="neo-card">
        <h2 class="neo-section-title">クラス統計</h2>
        <div class="grid grid-cols-4 gap-3 text-center">
          <div>
            <p class="text-2xl font-bold font-title text-neo-gradient">{{ store.students.length }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">生徒数</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-yellow">{{ classAvgMastery }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">平均★</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-green">{{ classActiveRate }}%</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">直近7日活動率</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-orange">{{ classAvgStreak }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">平均連続日数</p>
          </div>
        </div>
        <div v-if="weakPatterns.length > 0" class="mt-4 pt-3 border-t border-white/[0.06]">
          <p class="text-[11px] text-white/25 mb-2 font-title">弱点パターン TOP3</p>
          <div class="flex gap-2">
            <span
              v-for="wp in weakPatterns"
              :key="wp"
              class="neo-badge pink"
            >{{ wp }}</span>
          </div>
        </div>
      </section>

      <!-- Assign content -->
      <section class="neo-card">
        <div class="flex items-center justify-between mb-3">
          <h2 class="neo-section-title !mb-0">課題を出す</h2>
          <button
            v-if="!showAssignForm"
            @click="openAssignForm"
            class="btn-neo !py-1.5 !px-4 !text-xs !rounded-xl"
          >+ 新しい課題</button>
        </div>

        <!-- Step 1: Game selection (card grid) -->
        <div v-if="showAssignForm && !assignGameId">
          <div class="flex items-center justify-between mb-3">
            <label class="text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider">ゲームを選ぶ</label>
            <button @click="showAssignForm = false" class="text-white/30 text-xs font-title hover:text-white/50">✕ 閉じる</button>
          </div>

          <!-- Category filter -->
          <div class="flex gap-1.5 mb-3 overflow-x-auto pb-1 -mx-1 px-1">
            <button
              @click="assignCategoryFilter = ''"
              class="shrink-0 px-3 py-1 rounded-full text-[11px] font-title font-semibold transition-all"
              :class="assignCategoryFilter === '' ? 'bg-white/15 text-white' : 'text-white/30 hover:text-white/50'"
            >すべて</button>
            <button
              v-for="(label, cat) in gameStore.categoryLabels"
              :key="cat"
              @click="assignCategoryFilter = cat"
              class="shrink-0 px-3 py-1 rounded-full text-[11px] font-title font-semibold transition-all"
              :class="assignCategoryFilter === cat ? categoryBadgeClass(cat) : 'text-white/30 hover:text-white/50'"
            >{{ label }}</button>
          </div>

          <!-- Game cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 max-h-[60vh] overflow-y-auto pr-1">
            <div
              v-for="g in filteredGamesForAssign"
              :key="g.id"
              class="bg-white/[0.03] rounded-2xl border border-white/[0.06] overflow-hidden hover:border-brand-primary/30 transition-all cursor-pointer group"
              @click="selectGameForAssign(g.id)"
            >
              <!-- Thumbnail -->
              <div class="aspect-video w-full overflow-hidden" :class="!g.thumbnail ? categoryBgClass(g.category) : ''">
                <img
                  v-if="g.thumbnail"
                  :src="g.thumbnail"
                  :alt="g.title_ja"
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <div v-else class="w-full h-full flex items-center justify-center">
                  <GameIcon :game-id="g.id" :category="g.category" size="lg" />
                </div>
              </div>
              <!-- Info -->
              <div class="px-3 py-2.5">
                <div class="flex items-start justify-between gap-2">
                  <div class="flex-1 min-w-0">
                    <p class="text-white font-title font-bold text-sm truncate">{{ g.title_ja }}</p>
                    <p class="text-white/25 text-xs font-title mt-0.5 line-clamp-2">{{ g.description_ja || '' }}</p>
                  </div>
                  <span class="shrink-0 text-[9px] font-title font-bold px-2 py-0.5 rounded-full mt-0.5" :class="categoryBadgeClass(g.category)">
                    {{ gameStore.categoryLabels[g.category] || g.category }}
                  </span>
                </div>
                <div class="flex gap-2 mt-2.5">
                  <button
                    class="flex-1 py-1.5 text-[11px] font-title font-bold text-white bg-brand-primary/20 rounded-xl hover:bg-brand-primary/30 transition-colors"
                    @click.stop="selectGameForAssign(g.id)"
                  >この課題を出す</button>
                  <button
                    class="px-3 py-1.5 text-[11px] font-title text-white/40 border border-white/10 rounded-xl hover:text-white/60 hover:border-white/20 transition-colors"
                    @click.stop="previewGame(g.url)"
                  >お試し</button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Step 2: Details (after game selected) -->
        <div v-if="showAssignForm && assignGameId" class="space-y-3">
          <!-- Selected game summary -->
          <div class="flex items-center gap-3 bg-white/[0.03] rounded-xl px-3 py-2.5 border border-brand-primary/20">
            <GameIcon :game-id="assignGameId" :category="selectedAssignGame?.category ?? 'mixed'" size="sm" />
            <div class="flex-1 min-w-0">
              <p class="text-white font-title font-bold text-sm truncate">{{ selectedAssignGame?.title_ja }}</p>
              <p class="text-white/25 text-xs font-title truncate">{{ selectedAssignGame?.description_ja }}</p>
            </div>
            <button @click="assignGameId = ''" class="text-brand-secondary text-xs font-title font-medium hover:underline shrink-0">変更</button>
          </div>
          <!-- Target: all or individual -->
          <div>
            <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">配信先</label>
            <div class="flex gap-2 mb-2">
              <button
                @click="assignTargetMode = 'all'"
                class="flex-1 py-2 rounded-xl text-xs font-title font-semibold transition-all"
                :class="assignTargetMode === 'all' ? 'bg-brand-primary/20 text-white border border-brand-primary/30' : 'bg-white/[0.03] text-white/40 border border-white/[0.06]'"
              >クラス全員</button>
              <button
                @click="assignTargetMode = 'individual'"
                class="flex-1 py-2 rounded-xl text-xs font-title font-semibold transition-all"
                :class="assignTargetMode === 'individual' ? 'bg-brand-primary/20 text-white border border-brand-primary/30' : 'bg-white/[0.03] text-white/40 border border-white/[0.06]'"
              >個別に選ぶ</button>
            </div>
            <div v-if="assignTargetMode === 'individual' && store.students.length > 0" class="max-h-40 overflow-y-auto space-y-1 bg-white/[0.02] rounded-xl p-2 border border-white/[0.06]">
              <label
                v-for="s in store.students"
                :key="s.student_id"
                class="flex items-center gap-2 px-2 py-1.5 rounded-lg cursor-pointer hover:bg-white/[0.04] transition-colors"
              >
                <input type="checkbox" :value="s.student_id" v-model="assignTargetStudents" class="accent-brand-primary w-4 h-4" />
                <span class="text-white text-sm font-title">{{ s.display_name }}</span>
              </label>
            </div>
            <p v-if="assignTargetMode === 'individual' && store.students.length === 0" class="text-white/20 text-xs font-title">生徒がまだいません</p>
          </div>
          <div>
            <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">指示メモ（任意）</label>
            <input v-model="assignInstructions" type="text" placeholder="例：Grade 3を選んで10問やろう" class="neo-input" />
          </div>
          <div>
            <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">期限（任意）</label>
            <input v-model="assignDueDate" type="datetime-local" class="neo-input" />
          </div>
          <div class="flex gap-2 pt-1">
            <button @click="showAssignForm = false; assignGameId = ''" class="btn-ghost flex-1 py-2.5 border border-white/10 rounded-2xl text-sm">キャンセル</button>
            <button
              @click="handleAssignGame"
              :disabled="!assignGameId || assigning || (assignTargetMode === 'individual' && assignTargetStudents.length === 0)"
              class="btn-neo flex-1"
            >{{ assigning ? '配信中...' : assignTargetMode === 'individual' ? `${assignTargetStudents.length}人に配信` : '全員に配信' }}</button>
          </div>
        </div>

        <!-- Active assignments list -->
        <div v-if="activeAssignments.length > 0 && !showAssignForm" class="space-y-2">
          <div
            v-for="a in activeAssignments"
            :key="a.id"
            class="flex items-center justify-between bg-white/[0.03] rounded-xl px-4 py-3 border border-white/[0.06]"
          >
            <div class="flex-1 min-w-0">
              <p class="text-white font-title font-semibold text-sm truncate">{{ a.game_title_ja || a.game_id }}</p>
              <p v-if="a.instructions" class="text-white/25 text-xs truncate mt-0.5">{{ a.instructions }}</p>
              <div class="flex items-center gap-2 mt-0.5">
                <span v-if="a.target_student_ids" class="text-[10px] font-title text-brand-secondary">{{ a.target_student_ids.length }}人</span>
                <span v-else class="text-[10px] font-title text-white/20">全員</span>
                <p v-if="a.due_date" class="text-white/15 text-[10px] font-title">期限: {{ formatDate(a.due_date) }}</p>
              </div>
            </div>
            <button
              @click="handleDeleteAssignment(a.id)"
              class="text-white/20 hover:text-neon-pink text-xs ml-3 shrink-0 transition-colors"
              title="削除"
            >✕</button>
          </div>
        </div>
        <p v-else-if="!showAssignForm" class="text-white/20 text-sm font-title">まだ課題がありません</p>
      </section>

      <!-- Add student -->
      <section class="neo-card">
        <h2 class="neo-section-title">生徒を追加</h2>
        <div class="flex gap-2">
          <input
            v-model="newStudentName"
            type="text"
            placeholder="生徒の名前"
            class="neo-input flex-1"
            @keyup.enter="handleCreateStudent"
          />
          <button
            @click="handleCreateStudent"
            :disabled="!newStudentName.trim() || creatingStudent"
            class="btn-neo !py-2.5 !px-5 !text-sm !rounded-xl shrink-0"
          >
            {{ creatingStudent ? '作成中...' : '追加' }}
          </button>
        </div>
        <p v-if="createStudentError" class="text-neon-pink text-xs mt-2">{{ createStudentError }}</p>

        <!-- Created students with PINs -->
        <div v-if="createdStudents.length > 0" class="mt-4 space-y-2">
          <p class="text-[11px] text-white/30 font-title font-semibold">作成済み生徒（PINを共有してください）</p>
          <div
            v-for="cs in createdStudents"
            :key="cs.user_id"
            class="flex items-center justify-between bg-white/[0.03] rounded-xl px-4 py-3 border border-white/[0.06]"
          >
            <div>
              <p class="text-white font-title font-semibold text-sm">{{ cs.display_name }}</p>
              <p class="text-white/30 text-xs mt-0.5">クラスコード: <span class="font-mono text-white/50">{{ cs.class_code }}</span></p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-white/25 font-title">PIN</p>
              <p class="font-mono text-2xl font-bold tracking-[0.3em] text-neo-gradient">{{ cs.pin }}</p>
            </div>
          </div>
          <button
            @click="printStudentCards"
            class="btn-ghost !text-xs border border-white/10 !rounded-xl w-full mt-2"
          >PIN一覧を印刷用に表示</button>
        </div>

        <!-- Existing PINs -->
        <div v-if="existingPins.length > 0" class="mt-4">
          <button
            @click="showExistingPins = !showExistingPins"
            class="text-[11px] text-brand-secondary font-title font-medium hover:underline"
          >
            {{ showExistingPins ? 'PIN一覧を閉じる' : `既存の生徒PIN一覧を表示（${existingPins.length}名）` }}
          </button>
          <div v-if="showExistingPins" class="mt-2 space-y-1">
            <div
              v-for="ep in existingPins"
              :key="ep.user_id"
              class="flex items-center justify-between bg-white/[0.02] rounded-lg px-3 py-2"
            >
              <span class="text-white/60 text-sm font-title">{{ (ep.users as any)?.display_name ?? '---' }}</span>
              <span class="font-mono text-sm font-bold tracking-[0.2em] text-white/80">{{ ep.pin }}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Pending members -->
      <section v-if="store.pendingMembers.length > 0">
        <h2 class="text-sm font-title font-semibold text-neon-orange mb-3">
          参加申請中 {{ store.pendingMembers.length }}名
        </h2>
        <div class="neo-card !p-0 divide-y divide-white/[0.05]">
          <div
            v-for="m in store.pendingMembers"
            :key="m.id"
            class="flex items-center justify-between px-5 py-3"
          >
            <div>
              <p class="font-title font-medium text-white text-sm">{{ m.users?.display_name }}</p>
              <p class="text-xs text-white/25">{{ m.users?.email }}</p>
            </div>
            <div class="flex gap-2">
              <button @click="handleApprove(m.id)" class="btn-neo !py-1.5 !px-3 !text-xs !rounded-xl">承認</button>
              <button @click="handleRemove(m.id)" class="btn-ghost !text-xs border border-white/10 !rounded-xl">削除</button>
            </div>
          </div>
        </div>
      </section>

      <!-- Pending badges -->
      <section v-if="store.pendingBadges.length > 0">
        <h2 class="text-sm font-title font-semibold text-neon-purple mb-3">
          チャートバッジ承認待ち {{ store.pendingBadges.length }}件
        </h2>
        <div class="neo-card !p-0 divide-y divide-white/[0.05]">
          <div
            v-for="b in store.pendingBadges"
            :key="b.id"
            class="flex items-center justify-between px-5 py-4"
          >
            <div>
              <p class="font-title font-medium text-white text-sm">
                {{ b.users?.display_name }}
                <span class="ml-2 text-neo-gradient font-bold">{{ areaLabel(b.area) }}</span>
              </p>
              <p class="text-xs text-white/25">
                申請：{{ formatDate(b.applied_at) }}
                <span v-if="b.mastery_avg_at_apply"> | 平均★{{ Number(b.mastery_avg_at_apply).toFixed(1) }}</span>
              </p>
            </div>
            <div class="flex gap-2">
              <button @click="handleApproveBadge(b.id)" class="btn-neo !py-1.5 !px-3 !text-xs !rounded-xl">承認</button>
              <button @click="openRejectModal(b.id)" class="btn-ghost !text-xs border border-white/10 !rounded-xl">却下</button>
            </div>
          </div>
        </div>
      </section>

      <!-- Assignment completion -->
      <section v-if="assignmentStats.length > 0" class="neo-card">
        <h2 class="neo-section-title">宿題の提出状況</h2>
        <div class="space-y-3">
          <div v-for="a in assignmentStats" :key="a.assignment_id" class="bg-white/[0.02] rounded-xl px-4 py-3">
            <div class="flex items-center justify-between mb-2">
              <div>
                <p class="text-white font-title font-semibold text-sm">{{ a.game_title }}</p>
                <p v-if="a.assignment_title" class="text-white/25 text-xs">{{ a.assignment_title }}</p>
              </div>
              <div class="text-right">
                <p class="text-neo-gradient font-title font-bold text-lg">{{ a.completed_count }}/{{ a.total_count }}</p>
                <p class="text-white/20 text-[10px] font-title">提出率 {{ Math.round(a.completed_count / a.total_count * 100) }}%</p>
              </div>
            </div>
            <div class="w-full h-2 bg-white/[0.06] rounded-full overflow-hidden">
              <div class="h-full bg-neo-gradient rounded-full transition-all duration-500"
                :style="{ width: `${a.completed_count / a.total_count * 100}%` }" />
            </div>
            <p v-if="a.due_date" class="text-white/15 text-[10px] font-title mt-1">
              期限: {{ formatDate(a.due_date) }}
            </p>
          </div>
        </div>
      </section>

      <!-- Game performance by category -->
      <section v-if="categoryStats.length > 0" class="neo-card">
        <h2 class="neo-section-title">カテゴリ別パフォーマンス</h2>
        <div class="grid grid-cols-2 gap-3">
          <div v-for="cs in categoryStats" :key="cs.category" class="bg-white/[0.02] rounded-xl px-4 py-3 text-center">
            <p class="text-white/40 text-[11px] font-title mb-1">{{ gameStore.categoryLabels[cs.category] || cs.category }}</p>
            <p class="font-title font-bold text-xl" :class="strengthColor(cs.strength_level)">
              {{ cs.avg_accuracy }}%
            </p>
            <p class="text-white/20 text-[10px] font-title mt-0.5">{{ cs.play_count }}回プレイ</p>
            <span class="inline-block mt-1 text-[9px] font-title font-semibold px-2 py-0.5 rounded-full"
              :class="strengthBadge(cs.strength_level)">
              {{ strengthLabel(cs.strength_level) }}
            </span>
          </div>
        </div>
      </section>

      <!-- Top game stats -->
      <section v-if="gameStats.length > 0" class="neo-card">
        <h2 class="neo-section-title">ゲーム別成績（クラス平均）</h2>
        <div class="space-y-1">
          <div v-for="gs in gameStats" :key="gs.game_id"
            class="flex items-center justify-between px-3 py-2.5 rounded-xl hover:bg-white/[0.02] transition-colors">
            <div class="flex-1">
              <p class="text-white font-title text-sm font-medium">{{ gs.game_title }}</p>
              <p class="text-white/20 text-[10px] font-title">{{ gs.total_plays }}回プレイ | {{ gs.player_count }}人参加</p>
            </div>
            <div class="text-right">
              <p class="text-neo-gradient font-title font-bold">{{ gs.avg_accuracy }}%</p>
              <p class="text-white/20 text-[10px] font-title">平均正答率</p>
            </div>
          </div>
        </div>
      </section>

      <!-- Students list -->
      <section>
        <h2 class="text-sm font-title font-semibold text-white/60 mb-3">
          生徒一覧（{{ store.students.length }}名）
        </h2>

        <div v-if="store.loading" class="flex justify-center py-10">
          <div class="w-7 h-7 border-2 border-brand-primary border-t-transparent rounded-full animate-spin" />
        </div>

        <div v-else-if="store.students.length === 0" class="text-center py-12 text-white/25 text-sm font-title">
          承認済みの生徒がいません。
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="s in store.students"
            :key="s.student_id"
            class="neo-card cursor-pointer hover:shadow-neo-md active:scale-[0.99] transition-all duration-200"
            @click="router.push({ name: 'TeacherStudent', params: { classId, studentId: s.student_id } })"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <p class="font-title font-semibold text-white">{{ s.display_name }}</p>
                  <span
                    v-if="s.anxious_days_last_3 >= 2"
                    class="neo-badge pink !text-[10px]"
                  >要フォロー</span>
                </div>
                <div class="flex flex-wrap gap-3 mt-2 text-sm text-white/40">
                  <span>Lv. <strong class="text-neo-gradient">{{ s.mowi_level }}</strong></span>
                  <span>🔥 <strong class="text-neon-orange">{{ s.streak_days }}</strong> 日</span>
                  <span v-if="s.avg_mastery_level">★ <strong class="text-neon-yellow">{{ Number(s.avg_mastery_level).toFixed(1) }}</strong></span>
                  <span v-if="s.patterns_mastered">習得 <strong class="text-neon-cyan">{{ s.patterns_mastered }}</strong></span>
                  <span v-if="s.approved_badges">バッジ <strong class="text-neon-purple">{{ s.approved_badges }}</strong></span>
                </div>
              </div>
              <div class="ml-4 text-right">
                <p class="text-[10px] text-white/20 font-title">今朝</p>
                <span class="text-lg">{{ moodEmoji(s.latest_morning_mood) }}</span>
              </div>
            </div>
            <!-- Roblox -->
            <div v-if="store.robloxStats[s.student_id]" class="mt-3 bg-neon-purple/5 rounded-xl px-4 py-2 border border-neon-purple/10">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-[11px] font-title font-semibold text-neon-purple">Roblox</span>
                <span
                  v-if="store.robloxStats[s.student_id].linked"
                  class="neo-badge green !text-[9px] !py-0"
                >連携済み</span>
                <span v-else class="neo-badge !text-[9px] !py-0">未連携</span>
              </div>
              <template v-if="store.robloxStats[s.student_id].linked">
                <div class="flex flex-wrap gap-3 text-xs text-white/40">
                  <span v-if="store.robloxStats[s.student_id].roblox_display_name">{{ store.robloxStats[s.student_id].roblox_display_name }}</span>
                  <span v-if="store.robloxStats[s.student_id].town">🪙 <strong>{{ store.robloxStats[s.student_id].town.word_coins }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].town">🏠 <strong>{{ store.robloxStats[s.student_id].town.total_buildings_built }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].town">📋 <strong>{{ store.robloxStats[s.student_id].town.total_missions_completed }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].total_sessions > 0">🕹️ <strong>{{ store.robloxStats[s.student_id].total_sessions }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].latest_session">コンボ <strong>{{ store.robloxStats[s.student_id].latest_session.max_combo }}</strong></span>
                </div>
              </template>
            </div>
            <p v-if="s.last_practice_at" class="text-[11px] text-white/15 mt-2 font-title">
              最終練習：{{ formatDate(s.last_practice_at) }}
            </p>
            <p v-else class="text-[11px] text-white/15 mt-2 font-title">まだ練習なし</p>
          </div>
        </div>
      </section>
    </main>

    <!-- Reject modal -->
    <div
      v-if="rejectModal.open"
      class="neo-overlay"
      @click.self="rejectModal.open = false"
    >
      <div class="neo-modal !max-w-sm">
        <h2 class="text-base font-title font-bold text-white mb-3">却下理由（任意）</h2>
        <textarea
          v-model="rejectModal.reason"
          rows="3"
          placeholder="例：エリア1のパターンをもう少し練習してから申請してください。"
          class="neo-input resize-none"
        />
        <div class="flex gap-3 mt-4">
          <button @click="rejectModal.open = false" class="btn-ghost flex-1 py-2.5 border border-white/10 rounded-2xl">キャンセル</button>
          <button @click="handleRejectBadge" class="flex-1 py-2.5 text-sm font-title font-bold text-white bg-wrong rounded-2xl active:scale-95 transition-transform">却下する</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useTeacherStore } from '@/stores/teacher'
import { useGameStore } from '@/stores/game'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import GameIcon from '@/components/game/GameIcon.vue'

const route  = useRoute()
const router = useRouter()
const store  = useTeacherStore()
const gameStore = useGameStore()
const auth = useAuthStore()

const classId      = route.params.classId as string
const currentClass = ref<any>(null)

const rejectModal = ref({ open: false, badgeId: '', reason: '' })

// Student creation
const newStudentName = ref('')
const creatingStudent = ref(false)
const createStudentError = ref('')
const createdStudents = ref<Array<{ user_id: string; pin: string; class_code: string; display_name: string }>>([])
const existingPins = ref<any[]>([])
const showExistingPins = ref(false)

async function handleCreateStudent() {
  if (!newStudentName.value.trim()) return
  creatingStudent.value = true
  createStudentError.value = ''
  const result = await store.createStudentAccount(classId, newStudentName.value.trim())
  creatingStudent.value = false
  if (!result) {
    createStudentError.value = store.error ?? 'Failed to create student'
    return
  }
  createdStudents.value.push(result)
  newStudentName.value = ''
  // Refresh student list
  await store.fetchClassStudents(classId)
}

function printStudentCards() {
  const allStudents = [...createdStudents.value]
  // Add existing PINs if loaded
  if (existingPins.value.length > 0) {
    for (const ep of existingPins.value) {
      if (!allStudents.find(s => s.user_id === ep.user_id)) {
        allStudents.push({
          user_id: ep.user_id,
          pin: ep.pin,
          class_code: currentClass.value?.class_code ?? '',
          display_name: (ep.users as any)?.display_name ?? '',
        })
      }
    }
  }
  const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>MoWISE Student PINs</title>
<style>body{font-family:sans-serif;padding:20px}
.card{border:2px solid #333;border-radius:12px;padding:16px 24px;margin:8px;display:inline-block;width:280px;text-align:center}
.name{font-size:18px;font-weight:bold;margin-bottom:8px}
.label{font-size:11px;color:#888;margin-bottom:2px}
.code{font-family:monospace;font-size:16px;letter-spacing:0.15em}
.pin{font-family:monospace;font-size:32px;font-weight:bold;letter-spacing:0.3em;color:#6C5CE7}
.url{font-size:10px;color:#aaa;margin-top:8px}
@media print{body{padding:0}.card{break-inside:avoid}}</style></head><body>
<h2>MoWISE - ${currentClass.value?.class_name ?? 'Class'} ログイン情報</h2>
${allStudents.map(s => `<div class="card">
<div class="name">${s.display_name}</div>
<div class="label">クラスコード</div>
<div class="code">${s.class_code}</div>
<div class="label" style="margin-top:12px">PIN</div>
<div class="pin">${s.pin}</div>
<div class="url">mowise.vercel.app</div>
</div>`).join('\n')}
</body></html>`
  const w = window.open('', '_blank')
  if (w) { w.document.write(html); w.document.close(); w.print() }
}

// Assignment creation
const showAssignForm = ref(false)
const assignGameId = ref('')
const assignInstructions = ref('')
const assignDueDate = ref('')
const assigning = ref(false)
const activeAssignments = ref<any[]>([])
const assignCategoryFilter = ref('')
const assignTargetMode = ref<'all' | 'individual'>('all')
const assignTargetStudents = ref<string[]>([])

const selectedAssignGame = computed(() => assignGameId.value ? gameStore.getGameById(assignGameId.value) : null)

const filteredGamesForAssign = computed(() => {
  const all = gameStore.catalog
  if (!assignCategoryFilter.value) return all
  return all.filter(g => g.category === assignCategoryFilter.value)
})

function selectGameForAssign(gameId: string) {
  assignGameId.value = gameId
}

function previewGame(url: string) {
  window.open(url, '_blank')
}

function categoryBadgeClass(cat: string): string {
  const map: Record<string, string> = {
    grammar: 'bg-neon-cyan/15 text-neon-cyan',
    phonics: 'bg-blue-500/15 text-blue-400',
    eiken: 'bg-neon-orange/15 text-neon-orange',
    writing: 'bg-neon-purple/15 text-neon-purple',
    listening: 'bg-neon-green/15 text-neon-green',
    mixed: 'bg-white/10 text-white/50',
  }
  return map[cat] ?? 'bg-white/10 text-white/50'
}

function categoryBgClass(cat: string): string {
  const map: Record<string, string> = {
    grammar: 'bg-gradient-to-br from-cyan-900/40 to-cyan-800/20',
    phonics: 'bg-gradient-to-br from-blue-900/40 to-blue-800/20',
    eiken: 'bg-gradient-to-br from-orange-900/40 to-orange-800/20',
    writing: 'bg-gradient-to-br from-purple-900/40 to-purple-800/20',
    listening: 'bg-gradient-to-br from-green-900/40 to-green-800/20',
    mixed: 'bg-gradient-to-br from-gray-800/40 to-gray-700/20',
  }
  return map[cat] ?? 'bg-white/[0.04]'
}

function openAssignForm() {
  assignGameId.value = ''
  assignInstructions.value = ''
  assignDueDate.value = ''
  assignCategoryFilter.value = ''
  assignTargetMode.value = 'all'
  assignTargetStudents.value = []
  assigning.value = false
  showAssignForm.value = true
  if (gameStore.catalog.length === 0) gameStore.fetchCatalog()
}

async function handleAssignGame() {
  if (!assignGameId.value || !auth.userId) return
  assigning.value = true
  try {
    const game = gameStore.getGameById(assignGameId.value)
    const { error } = await supabase
      .from('assignments')
      .insert({
        class_id: classId,
        teacher_id: auth.userId,
        game_id: assignGameId.value,
        title: game?.title_ja ?? null,
        instructions: assignInstructions.value || null,
        due_date: assignDueDate.value || null,
        target_student_ids: assignTargetMode.value === 'individual' ? assignTargetStudents.value : null,
      })
    if (error) { console.error('[assign]', error); return }
    showAssignForm.value = false
    assignGameId.value = ''
    await fetchActiveAssignments()
  } catch (e) {
    console.error('[assign]', e)
  } finally {
    assigning.value = false
  }
}

async function fetchActiveAssignments() {
  const { data } = await supabase
    .from('assignments')
    .select('*, game_catalog!game_id(title_ja)')
    .eq('class_id', classId)
    .eq('status', 'active')
    .order('created_at', { ascending: false })
  activeAssignments.value = (data ?? []).map((a: any) => ({
    ...a,
    game_title_ja: a.game_catalog?.title_ja,
    target_student_ids: a.target_student_ids,
  }))
}

async function handleDeleteAssignment(assignmentId: string) {
  if (!confirm('この課題を削除しますか？')) return
  await supabase
    .from('assignments')
    .update({ status: 'archived' })
    .eq('id', assignmentId)
  await fetchActiveAssignments()
}

function exportCSV() {
  const header = '名前,Lv,連続日数,平均★,完全習得数,バッジ数,今朝の気分,最終練習日'
  const rows = store.students.map((s: any) => [
    s.display_name,
    s.mowi_level,
    s.streak_days,
    Number(s.avg_mastery_level ?? 0).toFixed(1),
    s.patterns_mastered ?? 0,
    s.approved_badges ?? 0,
    s.latest_morning_mood ?? '',
    s.last_practice_at ? new Date(s.last_practice_at).toLocaleDateString('ja-JP') : '',
  ].join(','))
  const bom = '\uFEFF'
  const csv = bom + [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${currentClass.value?.class_name ?? 'class'}_progress_${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}


const classAvgMastery = computed(() => {
  const vals = store.students.map((s: any) => Number(s.avg_mastery_level ?? 0))
  if (vals.length === 0) return '0.0'
  return (vals.reduce((a: number, b: number) => a + b, 0) / vals.length).toFixed(1)
})

const classAvgStreak = computed(() => {
  const vals = store.students.map((s: any) => Number(s.streak_days ?? 0))
  if (vals.length === 0) return 0
  return Math.round(vals.reduce((a: number, b: number) => a + b, 0) / vals.length)
})

const classActiveRate = computed(() => {
  if (store.students.length === 0) return 0
  const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000
  const active = store.students.filter((s: any) =>
    s.last_practice_at && new Date(s.last_practice_at).getTime() > sevenDaysAgo
  ).length
  return Math.round((active / store.students.length) * 100)
})

const weakPatterns = ref<string[]>([])
const assignmentStats = ref<any[]>([])
const categoryStats = ref<any[]>([])
const gameStats = ref<any[]>([])

onMounted(async () => {
  const { data } = await supabase
    .from('classes')
    .select('*')
    .eq('id', classId)
    .single()
  currentClass.value = data

  await Promise.all([
    store.fetchClassStudents(classId),
    store.fetchPendingMembers(classId),
    store.fetchPendingBadges(classId),
  ])

  await store.fetchRobloxStats(classId)
  existingPins.value = await store.fetchClassPins(classId)
  await Promise.all([
    fetchWeakPatterns(),
    fetchAssignmentStats(),
    fetchCategoryStats(),
    fetchGameStats(),
    fetchActiveAssignments(),
    gameStore.fetchCatalog(),
  ])
})

async function fetchWeakPatterns() {
  const studentIds = store.students.map((s: any) => s.student_id)
  if (studentIds.length === 0) return
  const { data } = await supabase
    .from('pattern_progress')
    .select('pattern_no, mastery_level')
    .in('user_id', studentIds)
  if (!data || data.length === 0) return
  const totals: Record<string, { sum: number; count: number }> = {}
  for (const row of data as any[]) {
    if (!totals[row.pattern_no]) totals[row.pattern_no] = { sum: 0, count: 0 }
    totals[row.pattern_no].sum += row.mastery_level
    totals[row.pattern_no].count++
  }
  weakPatterns.value = Object.entries(totals)
    .map(([pno, v]) => ({ pno, avg: v.sum / v.count }))
    .sort((a, b) => a.avg - b.avg)
    .slice(0, 3)
    .map(x => x.pno)
}

async function fetchAssignmentStats() {
  const { data } = await supabase
    .from('assignment_completion')
    .select('assignment_id, game_title, assignment_title, due_date, student_id, is_completed')
    .eq('class_id', classId)
  if (!data || data.length === 0) return
  // Group by assignment
  const grouped: Record<string, any> = {}
  for (const row of data as any[]) {
    if (!grouped[row.assignment_id]) {
      grouped[row.assignment_id] = {
        assignment_id: row.assignment_id,
        game_title: row.game_title,
        assignment_title: row.assignment_title,
        due_date: row.due_date,
        total_count: 0,
        completed_count: 0,
      }
    }
    grouped[row.assignment_id].total_count++
    if (row.is_completed) grouped[row.assignment_id].completed_count++
  }
  assignmentStats.value = Object.values(grouped)
}

async function fetchCategoryStats() {
  const { data } = await supabase
    .from('student_category_weakness')
    .select('*')
    .eq('class_id', classId)
  if (!data || data.length === 0) return
  // Average across students per category
  const cats: Record<string, { total_acc: number; total_plays: number; count: number; strength: string }> = {}
  for (const row of data as any[]) {
    if (!cats[row.category]) cats[row.category] = { total_acc: 0, total_plays: 0, count: 0, strength: 'ok' }
    cats[row.category].total_acc += Number(row.avg_accuracy) * Number(row.play_count)
    cats[row.category].total_plays += Number(row.play_count)
    cats[row.category].count++
  }
  categoryStats.value = Object.entries(cats).map(([category, v]) => ({
    category,
    avg_accuracy: v.total_plays > 0 ? Math.round(v.total_acc / v.total_plays) : 0,
    play_count: v.total_plays,
    strength_level: v.total_plays > 0
      ? (v.total_acc / v.total_plays < 50 ? 'weak' : v.total_acc / v.total_plays < 70 ? 'needs_work' : v.total_acc / v.total_plays < 85 ? 'ok' : 'strong')
      : 'ok',
  }))
}

async function fetchGameStats() {
  const { data } = await supabase
    .from('student_game_stats')
    .select('*')
    .eq('class_id', classId)
  if (!data || data.length === 0) return
  // Group by game
  const games: Record<string, { game_title: string; total_plays: number; total_acc: number; total_weighted: number; players: Set<string> }> = {}
  for (const row of data as any[]) {
    if (!games[row.game_id]) games[row.game_id] = { game_title: row.game_title, total_plays: 0, total_acc: 0, total_weighted: 0, players: new Set() }
    games[row.game_id].total_plays += Number(row.play_count)
    games[row.game_id].total_weighted += Number(row.avg_accuracy ?? 0) * Number(row.play_count)
    games[row.game_id].players.add(row.user_id)
  }
  gameStats.value = Object.entries(games)
    .map(([game_id, v]) => ({
      game_id,
      game_title: v.game_title,
      total_plays: v.total_plays,
      avg_accuracy: v.total_plays > 0 ? Math.round(v.total_weighted / v.total_plays) : 0,
      player_count: v.players.size,
    }))
    .sort((a, b) => b.total_plays - a.total_plays)
}

function strengthColor(level: string): string {
  const map: Record<string, string> = { strong: 'text-neon-green', ok: 'text-neon-cyan', needs_work: 'text-neon-orange', weak: 'text-neon-pink' }
  return map[level] ?? 'text-white'
}

function strengthBadge(level: string): string {
  const map: Record<string, string> = {
    strong: 'bg-neon-green/15 text-neon-green',
    ok: 'bg-neon-cyan/15 text-neon-cyan',
    needs_work: 'bg-neon-orange/15 text-neon-orange',
    weak: 'bg-neon-pink/15 text-neon-pink',
  }
  return map[level] ?? ''
}

function strengthLabel(level: string): string {
  const map: Record<string, string> = { strong: '得意', ok: '普通', needs_work: '要練習', weak: '苦手' }
  return map[level] ?? level
}

async function handleApprove(memberId: string) {
  await store.approveMember(memberId)
  await store.fetchClassStudents(classId)
}

async function handleRemove(memberId: string) {
  if (!confirm('この生徒をクラスから削除しますか？')) return
  await store.removeMember(memberId)
}

async function handleApproveBadge(badgeId: string) {
  await store.approveBadge(badgeId)
}

function openRejectModal(badgeId: string) {
  rejectModal.value = { open: true, badgeId, reason: '' }
}

async function handleRejectBadge() {
  await store.rejectBadge(rejectModal.value.badgeId, rejectModal.value.reason)
  rejectModal.value.open = false
}

function moodEmoji(mood: string | null): string {
  const map: Record<string, string> = {
    morning_great: '✨', morning_doable: '🙂', morning_normal: '😐',
    morning_heavy: '😮‍💨', morning_nope: '😵',
  }
  return mood ? (map[mood] ?? '─') : '─'
}

function areaLabel(area: string): string {
  const map: Record<string, string> = {
    area1: 'エリア1 Hello Badge', area2: 'エリア2 Daily Badge',
    area3: 'エリア3 Travel Badge', area4: 'エリア4 Business Badge',
    area5: 'エリア5 World Badge',
  }
  return map[area] ?? area
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('ja-JP', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}
</script>
