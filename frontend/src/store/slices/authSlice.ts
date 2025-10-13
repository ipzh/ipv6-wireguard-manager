import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { User, LoginCredentials, AuthResponse } from '../../types/auth'
import { apiClient } from '../../services/api'

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  loading: boolean
  error: string | null
}

const initialState: AuthState = {
  user: null,
  token: typeof window !== 'undefined' ? localStorage.getItem('token') : null,
  isAuthenticated: false,
  loading: false,
  error: null,
}

// 异步操作
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: LoginCredentials, { rejectWithValue }) => {
    try {
      // 调用后端认证API
      const response = await apiClient.post('/auth/login', {
        username: credentials.username,
        password: credentials.password
      })
      
      const { access_token, user } = response
      
      // 存储token到localStorage
      if (typeof window !== 'undefined') {
        localStorage.setItem('token', access_token)
      }
      
      return { access_token, user }
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '登录失败')
    }
  }
)

export const getCurrentUser = createAsyncThunk(
  'auth/getCurrentUser',
  async (_, { rejectWithValue }) => {
    try {
      // 调用后端API获取当前用户信息
      const response = await apiClient.get('/auth/test-token')
      return response
    } catch (error: any) {
      // 如果token无效，清除本地存储
      if (typeof window !== 'undefined') {
        localStorage.removeItem('token')
      }
      return rejectWithValue(error.response?.data?.detail || '获取用户信息失败')
    }
  }
)

export const refreshToken = createAsyncThunk(
  'auth/refreshToken',
  async (_, { rejectWithValue }) => {
    try {
      // 调用后端API刷新token
      const response = await apiClient.post('/auth/refresh-token')
      const { access_token } = response
      
      // 更新本地存储的token
      if (typeof window !== 'undefined') {
        localStorage.setItem('token', access_token)
      }
      
      return { access_token }
    } catch (error: any) {
      // 如果刷新失败，清除本地token
      if (typeof window !== 'undefined') {
        localStorage.removeItem('token')
      }
      return rejectWithValue(error.response?.data?.detail || 'Token刷新失败')
    }
  }
)

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      // 清除本地存储的token
      if (typeof window !== 'undefined') {
        localStorage.removeItem('token')
      }
      // 注意：这里可以添加调用后端登出API的逻辑
      // await apiClient.post('/auth/logout')
      return null
    } catch (error: any) {
      // 即使后端登出失败，也要清除本地token
      if (typeof window !== 'undefined') {
        localStorage.removeItem('token')
      }
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
        if (typeof window !== 'undefined') {
          localStorage.removeItem('token')
        }
      })
      // 刷新token
      .addCase(refreshToken.fulfilled, (state, action) => {
        state.token = action.payload.access_token
        state.isAuthenticated = true
        state.error = null
      })
      .addCase(refreshToken.rejected, (state, action) => {
        state.user = null
        state.token = null
        state.isAuthenticated = false
        state.error = action.payload as string
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