export interface User {
  id: string;
  username: string;
  email: string;
  is_active: boolean;
  is_superuser: boolean;
  created_at: string;
  updated_at: string;
  roles: Role[];
}

export interface Role {
  id: string;
  name: string;
  description?: string;
  permissions: Record<string, string[]>;
  created_at: string;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface Token {
  access_token: string;
  token_type: string;
}

export interface TokenPayload {
  sub?: string;
}
