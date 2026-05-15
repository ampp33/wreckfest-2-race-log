<template>
  <div class="max-w-4xl mx-auto px-6 py-6 pb-24">
    <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark mb-1">
      User <em class="signal">Roles</em>
    </h1>
    <p class="font-body text-[15px] leading-relaxed text-brand-secondary dark:text-brand-secondary-dark mb-6">Manage admin access for registered users.</p>

    <p v-if="loading" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading…</p>

    <p v-else-if="error" class="text-sm text-red-500">{{ error }}</p>

    <div v-else class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark overflow-x-auto">
      <p v-if="!users.length" class="p-4 font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">No users found.</p>
      <table v-else class="min-w-full text-sm">
        <thead>
          <tr class="text-left font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark border-b border-brand-border dark:border-brand-border-dark">
            <th class="px-4 py-2 font-medium">Email</th>
            <th class="px-4 py-2 font-medium">Joined</th>
            <th class="px-4 py-2 font-medium">Role</th>
            <th class="px-4 py-2 font-medium text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-brand-border dark:divide-brand-border-dark">
          <tr
            v-for="user in users"
            :key="user.id"
            class="hover:bg-brand-bg dark:hover:bg-brand-bg-dark/30"
          >
            <td class="px-4 py-2">
              {{ user.email }}
              <span v-if="user.id === currentUserId" class="ml-1 text-xs text-brand-muted dark:text-brand-muted-dark">(you)</span>
            </td>
            <td class="px-4 py-2 text-brand-muted dark:text-brand-muted-dark whitespace-nowrap">
              {{ formatDate(user.created_at) }}
            </td>
            <td class="px-4 py-2">
              <span
                class="px-2 py-0.5 rounded text-xs font-medium"
                :class="user.role === 'admin'
                  ? 'bg-brand-accent/10 text-brand-accent'
                  : 'bg-brand-bg dark:bg-brand-bg-dark text-brand-secondary dark:text-brand-secondary-dark'"
              >
                {{ user.role }}
              </span>
            </td>
            <td class="px-4 py-2 text-right">
              <button
                v-if="user.id !== currentUserId"
                type="button"
                class="text-xs text-brand-accent hover:underline"
                @click="openDialog(user)"
              >
                Change role
              </button>
              <span v-else class="text-xs text-brand-muted dark:text-brand-muted-dark">—</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Role picker dialog -->
    <teleport to="body">
      <div
        v-if="dialog.open"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm"
        @click.self="closeDialog"
      >
        <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark shadow-xl w-72 p-5">
          <h2 class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark mb-1">
            Change <em class="signal">role</em>
          </h2>
          <p class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark mb-4 break-all">{{ dialog.user?.email }}</p>

          <div class="space-y-2 mb-5">
            <label
              v-for="role in availableRoles"
              :key="role.value"
              class="flex items-start gap-3 cursor-pointer"
            >
              <input
                type="radio"
                :value="role.value"
                v-model="dialog.selectedRole"
                class="mt-0.5 accent-brand-accent"
              />
              <span>
                <span class="block text-sm font-medium text-brand-text dark:text-brand-text-dark">{{ role.label }}</span>
                <span class="block font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">{{ role.description }}</span>
              </span>
            </label>
          </div>

          <div class="flex justify-end gap-2">
            <button
              type="button"
              class="px-3 py-1.5 text-sm rounded border border-brand-border dark:border-brand-border-dark hover:bg-brand-bg dark:hover:bg-brand-bg-dark"
              @click="closeDialog"
            >
              Cancel
            </button>
            <button
              type="button"
              class="font-display font-black uppercase tracking-widest bg-brand-accent text-white px-4 py-1.5 rounded-none hover:opacity-85 active:opacity-70 transition-opacity disabled:opacity-50 text-sm"
              :disabled="saving || dialog.selectedRole === dialog.user?.role"
              @click="confirmChange"
            >
              {{ saving ? 'Saving…' : 'OK' }}
            </button>
          </div>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script>
import { authStore } from '../stores/authStore.js'
import { getAllUsers, setUserRole } from '../services/adminService.js'
import { pushToast } from '../stores/toastStore.js'

export default {
  name: 'UserRolesPage',
  data() {
    return {
      loading: true,
      error: null,
      users: [],
      saving: false,
      dialog: {
        open: false,
        user: null,
        selectedRole: null
      },
      availableRoles: [
        { value: 'user',  label: 'User',  description: 'Standard access' },
        { value: 'admin', label: 'Admin', description: 'Access to admin pages' }
      ]
    }
  },
  computed: {
    currentUserId() {
      return authStore.user?.id ?? null
    }
  },
  mounted() {
    this._onKeydown = e => { if (e.key === 'Escape') this.closeDialog() }
    window.addEventListener('keydown', this._onKeydown)
  },
  beforeUnmount() {
    window.removeEventListener('keydown', this._onKeydown)
  },
  async created() {
    try {
      this.users = await getAllUsers()
    } catch (err) {
      this.error = err.message || 'Failed to load users'
    } finally {
      this.loading = false
    }
  },
  methods: {
    formatDate(iso) {
      return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
    },
    openDialog(user) {
      this.dialog = { open: true, user, selectedRole: user.role }
    },
    closeDialog() {
      this.dialog = { open: false, user: null, selectedRole: null }
    },
    async confirmChange() {
      const { user, selectedRole } = this.dialog
      this.saving = true
      try {
        await setUserRole(user.id, selectedRole)
        user.role = selectedRole
        pushToast(`${user.email} is now ${selectedRole}`, 'success')
        this.closeDialog()
      } catch (err) {
        pushToast(err.message || 'Failed to update role', 'error')
      } finally {
        this.saving = false
      }
    }
  }
}
</script>
