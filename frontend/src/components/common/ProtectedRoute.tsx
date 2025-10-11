import React, { useEffect } from 'react'
import { Navigate } from 'react-router-dom'
import { useSelector, useDispatch } from 'react-redux'
import { RootState, AppDispatch } from '@store'
import { getCurrentUser } from '@store/slices/authSlice'

interface ProtectedRouteProps {
  children: React.ReactNode
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const dispatch = useDispatch<AppDispatch>()
  const { isAuthenticated, token, loading } = useSelector((state: RootState) => state.auth)

  useEffect(() => {
    if (token && !isAuthenticated) {
      dispatch(getCurrentUser())
    }
  }, [dispatch, token, isAuthenticated])

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500"></div>
      </div>
    )
  }

  if (!token || !isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  return <>{children}</>
}

export default ProtectedRoute
