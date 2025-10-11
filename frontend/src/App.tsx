import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { Layout } from 'antd'

import LoginPage from '@pages/LoginPage'
import DashboardPage from '@pages/DashboardPage'
import ClientsPage from '@pages/ClientsPage'
import ServersPage from '@pages/ServersPage'
import NetworkPage from '@pages/NetworkPage'
import MonitoringPage from '@pages/MonitoringPage'
import LogsPage from '@pages/LogsPage'
import UsersPage from '@pages/UsersPage'
import SettingsPage from '@pages/SettingsPage'

import AppLayout from '@components/layout/AppLayout'
import ProtectedRoute from '@components/common/ProtectedRoute'

const App: React.FC = () => {
  return (
    <Routes>
      {/* 登录页面 */}
      <Route path="/login" element={<LoginPage />} />
      
      {/* 受保护的路由 */}
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <AppLayout>
              <Routes>
                <Route path="/" element={<Navigate to="/dashboard" replace />} />
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/clients" element={<ClientsPage />} />
                <Route path="/servers" element={<ServersPage />} />
                <Route path="/network" element={<NetworkPage />} />
                <Route path="/monitoring" element={<MonitoringPage />} />
                <Route path="/logs" element={<LogsPage />} />
                <Route path="/users" element={<UsersPage />} />
                <Route path="/settings" element={<SettingsPage />} />
                <Route path="*" element={<Navigate to="/dashboard" replace />} />
              </Routes>
            </AppLayout>
          </ProtectedRoute>
        }
      />
    </Routes>
  )
}

export default App
