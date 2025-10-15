import axios, { AxiosInstance, AxiosResponse } from 'axios'
import { getApiBaseUrl, config } from '../utils/config'

const API_BASE_URL = getApiBaseUrl()

class ApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: `${API_BASE_URL}/api/v1`,
      timeout: config.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    this.setupInterceptors()
  }

  private setupInterceptors() {
    // 请求拦截器
    this.client.interceptors.request.use(
      (config) => {
        try {
          const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null
          if (token) {
            config.headers.Authorization = `Bearer ${token}`
          }
        } catch (error) {
          console.warn('Failed to get token from localStorage:', error)
        }
        return config
      },
      (error) => {
        return Promise.reject(error)
      }
    )

    // 响应拦截器
    this.client.interceptors.response.use(
      (response: AxiosResponse) => {
        return response
      },
      async (error) => {
        const originalRequest = error.config
        
        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true
          
          try {
            // 尝试刷新token
            const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null
            if (token) {
              const refreshResponse = await axios.post(`${API_BASE_URL}/api/v1/auth/refresh-token`, {}, {
                headers: {
                  'Authorization': `Bearer ${token}`
                }
              })
              
              const { access_token } = refreshResponse.data
              if (typeof window !== 'undefined') {
                localStorage.setItem('token', access_token)
              }
              
              // 重试原始请求
              originalRequest.headers.Authorization = `Bearer ${access_token}`
              return this.client(originalRequest)
            }
          } catch (refreshError) {
            // 刷新失败，清除token并跳转到登录页
            if (typeof window !== 'undefined') {
              localStorage.removeItem('token')
              window.location.href = '/login'
            }
            return Promise.reject(refreshError)
          }
        }
        
        return Promise.reject(error)
      }
    )
  }

  // GET请求
  async get<T>(url: string, params?: any): Promise<T> {
    const response = await this.client.get(url, { params })
    return response.data
  }

  // POST请求
  async post<T>(url: string, data?: any): Promise<T> {
    const response = await this.client.post(url, data)
    return response.data
  }

  // PUT请求
  async put<T>(url: string, data?: any): Promise<T> {
    const response = await this.client.put(url, data)
    return response.data
  }

  // DELETE请求
  async delete<T>(url: string): Promise<T> {
    const response = await this.client.delete(url)
    return response.data
  }

  // PATCH请求
  async patch<T>(url: string, data?: any): Promise<T> {
    const response = await this.client.patch(url, data)
    return response.data
  }
}

export const apiClient = new ApiClient()
export default apiClient
