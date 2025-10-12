import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { User, LoginCredentials, AuthResponse } from '../../types/auth'
import api from '../../services/api'

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  loading: boolean
  error: string | null
}

const initialState: AuthState = {
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: false,
  loading: false,
  error: null,
}

// 简单的本地认证配置
const DEFAULT_USERNAME = 'admin'
const DEFAULT_PASSWORD = 'admin123'

// 异步操作
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: LoginCredentials, { rejectWithValue }) => {
    try {
      // 简单的本地认证验证
      if (credentials.username === DEFAULT_USERNAME && credentials.password === DEFAULT_PASSWORD) {
        const token = btoa(credentials.username + ':' + Date.now())
        const user = {
          id: 1,
          username: credentials.username,
          email: 'admin@ipv6wg.local',
          role: 'admin',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
        
        localStorage.setItem('token', token)
        return { access_token: token, user }
      } else {
        return rejectWithValue('用户名或密码错误')
      }
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '登录失败')
    }
  }
)

export const getCurrentUser = createAsyncThunk(
  'auth/getCurrentUser',
  async (_, { rejectWithValue }) => {
    try {
      // 简单的本地用户信息
      const token = localStorage.getItem('token')
      if (token) {
        const user = {
          id: 1,
          username: DEFAULT_USERNAME,
          email: 'admin@ipv6wg.local',
          role: 'admin',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
        return user
      } else {
        return rejectWithValue('未找到认证令牌')
      }
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取用户信息失败')
    }
  }
)

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      // 简单的本地登出
      localStorage.removeItem('token')
      return null
    } catch (error: any) {
      localStorage.removeItem('token')
      return rejectWithValue('登出失败')
    }
  }
)

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null
    },
    setToken: (state, action: PayloadAction<string>) => {
      state.token = action.payload
      state.isAuthenticated = true
    },
  },
  extraReducers: (builder) => {
    builder
      // 登录
      .addCase(login.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false
        state.token = action.payload.access_token
        state.user = action.payload.user
        state.isAuthenticated = true
        state.error = null
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
        state.isAuthenticated = false
      })
      // 获取当前用户
      .addCase(getCurrentUser.pending, (state) => {
        state.loading = true
      })
      .addCase(getCurrentUser.fulfilled, (state, action) => {
        state.loading = false
        state.user = action.payload
        state.isAuthenticated = true
      })
      .addCase(getCurrentUser.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
        state.isAuthenticated = false
        state.token = null
        localStorage.removeItem('token')
      })
      // 登出
      .addCase(logout.fulfilled, (state) => {
        state.user = null
        state.token = null
        state.isAuthenticated = false
        state.error = null
      })
  },
})

export const { clearError, setToken } = authSlice.actions
export default authSlice.reducer