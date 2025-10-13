import React from 'react';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Header from '../Header';

// Mock the auth hook
jest.mock('../../hooks/useAuth', () => ({
  useAuth: () => ({
    user: { username: 'admin', roles: ['admin'] },
    logout: jest.fn(),
  }),
}));

describe('Header Component', () => {
  test('renders header with logo and navigation', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );

    expect(screen.getByText('IPv6 WireGuard Manager')).toBeInTheDocument();
    expect(screen.getByRole('navigation')).toBeInTheDocument();
  });

  test('displays user information when logged in', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );

    expect(screen.getByText('admin')).toBeInTheDocument();
  });

  test('contains navigation links', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );

    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('WireGuard')).toBeInTheDocument();
    expect(screen.getByText('BGP')).toBeInTheDocument();
    expect(screen.getByText('IPv6 Pools')).toBeInTheDocument();
  });
});