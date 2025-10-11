import { configureStore } from '@reduxjs/toolkit'
import authSlice from './slices/authSlice'
import wireguardSlice from './slices/wireguardSlice'
import networkSlice from './slices/networkSlice'
import monitoringSlice from './slices/monitoringSlice'

export const store = configureStore({
  reducer: {
    auth: authSlice,
    wireguard: wireguardSlice,
    network: networkSlice,
    monitoring: monitoringSlice,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST', 'persist/REHYDRATE'],
      },
    }),
})

export type RootState = ReturnType<typeof store.getState>
export type AppDispatch = typeof store.dispatch