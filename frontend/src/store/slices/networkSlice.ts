import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { NetworkInterface, FirewallRule } from '../../types/network'
import api from '../../services/api'

interface NetworkState {
  interfaces: NetworkInterface[]
  firewallRules: FirewallRule[]
  loading: boolean
  error: string | null
}

const initialState: NetworkState = {
  interfaces: [],
  firewallRules: [],
  loading: false,
  error: null,
}

// 异步操作
export const fetchInterfaces = createAsyncThunk(
  'network/fetchInterfaces',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get<NetworkInterface[]>('/network/interfaces')
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取网络接口失败')
    }
  }
)

export const fetchFirewallRules = createAsyncThunk(
  'network/fetchFirewallRules',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get<FirewallRule[]>('/network/firewall-rules')
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取防火墙规则失败')
    }
  }
)

const networkSlice = createSlice({
  name: 'network',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null
    },
  },
  extraReducers: (builder) => {
    builder
      // 获取网络接口
      .addCase(fetchInterfaces.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchInterfaces.fulfilled, (state, action) => {
        state.loading = false
        state.interfaces = action.payload
      })
      .addCase(fetchInterfaces.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
      // 获取防火墙规则
      .addCase(fetchFirewallRules.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchFirewallRules.fulfilled, (state, action) => {
        state.loading = false
        state.firewallRules = action.payload
      })
      .addCase(fetchFirewallRules.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
  },
})

export const { clearError } = networkSlice.actions
export default networkSlice.reducer
