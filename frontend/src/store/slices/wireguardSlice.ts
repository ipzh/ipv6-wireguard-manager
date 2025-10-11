import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { WireGuardServer, WireGuardClient } from '../../types/wireguard'
import api from '../../services/api'

interface WireGuardState {
  servers: WireGuardServer[]
  clients: WireGuardClient[]
  loading: boolean
  error: string | null
}

const initialState: WireGuardState = {
  servers: [],
  clients: [],
  loading: false,
  error: null,
}

// 异步操作
export const fetchServers = createAsyncThunk(
  'wireguard/fetchServers',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get<WireGuardServer[]>('/wireguard/servers')
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取服务器列表失败')
    }
  }
)

export const createServer = createAsyncThunk(
  'wireguard/createServer',
  async (serverData: any, { rejectWithValue }) => {
    try {
      const response = await api.post<WireGuardServer>('/wireguard/servers', serverData)
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '创建服务器失败')
    }
  }
)

export const fetchClients = createAsyncThunk(
  'wireguard/fetchClients',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get<WireGuardClient[]>('/wireguard/clients')
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取客户端列表失败')
    }
  }
)

export const createClient = createAsyncThunk(
  'wireguard/createClient',
  async (clientData: any, { rejectWithValue }) => {
    try {
      const response = await api.post<WireGuardClient>('/wireguard/clients', clientData)
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '创建客户端失败')
    }
  }
)

const wireguardSlice = createSlice({
  name: 'wireguard',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null
    },
  },
  extraReducers: (builder) => {
    builder
      // 获取服务器列表
      .addCase(fetchServers.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchServers.fulfilled, (state, action) => {
        state.loading = false
        state.servers = action.payload
      })
      .addCase(fetchServers.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
      // 创建服务器
      .addCase(createServer.fulfilled, (state, action) => {
        state.servers.push(action.payload)
      })
      // 获取客户端列表
      .addCase(fetchClients.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchClients.fulfilled, (state, action) => {
        state.loading = false
        state.clients = action.payload
      })
      .addCase(fetchClients.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
      // 创建客户端
      .addCase(createClient.fulfilled, (state, action) => {
        state.clients.push(action.payload)
      })
  },
})

export const { clearError } = wireguardSlice.actions
export default wireguardSlice.reducer
