import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit'
import { SystemMetrics, AuditLog, OperationLog } from '../../types/monitoring'
import api from '../../services/api'

interface MonitoringState {
  metrics: SystemMetrics | null
  auditLogs: AuditLog[]
  operationLogs: OperationLog[]
  loading: boolean
  error: string | null
}

const initialState: MonitoringState = {
  metrics: null,
  auditLogs: [],
  operationLogs: [],
  loading: false,
  error: null,
}

// 异步操作
export const fetchMetrics = createAsyncThunk(
  'monitoring/fetchMetrics',
  async (_, { rejectWithValue }) => {
    try {
      const response = await api.get<SystemMetrics>('/monitoring/metrics')
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取系统指标失败')
    }
  }
)

export const fetchAuditLogs = createAsyncThunk(
  'monitoring/fetchAuditLogs',
  async (params: any = {}, { rejectWithValue }) => {
    try {
      const response = await api.get<AuditLog[]>('/monitoring/audit-logs', { params })
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取审计日志失败')
    }
  }
)

export const fetchOperationLogs = createAsyncThunk(
  'monitoring/fetchOperationLogs',
  async (params: any = {}, { rejectWithValue }) => {
    try {
      const response = await api.get<OperationLog[]>('/monitoring/operation-logs', { params })
      return response.data
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.detail || '获取操作日志失败')
    }
  }
)

const monitoringSlice = createSlice({
  name: 'monitoring',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null
    },
    updateMetrics: (state, action: PayloadAction<SystemMetrics>) => {
      state.metrics = action.payload
    },
  },
  extraReducers: (builder) => {
    builder
      // 获取系统指标
      .addCase(fetchMetrics.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchMetrics.fulfilled, (state, action) => {
        state.loading = false
        state.metrics = action.payload
      })
      .addCase(fetchMetrics.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
      // 获取审计日志
      .addCase(fetchAuditLogs.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchAuditLogs.fulfilled, (state, action) => {
        state.loading = false
        state.auditLogs = action.payload
      })
      .addCase(fetchAuditLogs.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
      // 获取操作日志
      .addCase(fetchOperationLogs.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchOperationLogs.fulfilled, (state, action) => {
        state.loading = false
        state.operationLogs = action.payload
      })
      .addCase(fetchOperationLogs.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload as string
      })
  },
})

export const { clearError, updateMetrics } = monitoringSlice.actions
export default monitoringSlice.reducer
