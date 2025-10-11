import { apiClient } from './api'

export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  access_token: string
  token_type: string
  user: {
    id: string
    username: string
    email: string
    is_active: boolean
    is_superuser: boolean
    last_login?: string
    created_at: string
    updated_at: string
  }
}

export interface User {
  id: string
  username: string
  email: string
  is_active: boolean
  is_superuser: boolean
  last_login?: string
  created_at: string
  updated_at: string
}

export const authApi = {
  // 用户登录
  login: async (credentials: LoginRequest): Promise<LoginResponse> => {
    return apiClient.post<LoginResponse>('/auth/login', credentials)
  },

  // 用户登出
  logout: async (): Promise<void> => {
    return apiClient.post('/auth/logout')
  },

  // 获取当前用户信息
  getCurrentUser: async (): Promise<User> => {
    return apiClient.get<User>('/auth/test-token')
  },

  // 刷新令牌
  refreshToken: async (): Promise<LoginResponse> => {
    return apiClient.post<LoginResponse>('/auth/refresh')
  },
}
