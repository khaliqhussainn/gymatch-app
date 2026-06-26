const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

export interface AdminUser {
  id: string;
  email: string;
  role: string;
}

export interface LoginResponse {
  token: string;
  user: AdminUser;
}

export interface VerifyResponse {
  valid: boolean;
  user: AdminUser;
}

export interface AuthError {
  error: string;
}

export const adminAuthService = {
  async login(email: string, password: string): Promise<LoginResponse> {
    const response = await fetch(`${API_BASE_URL}/api/admin/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Login failed');
    }

    // Store token in localStorage
    localStorage.setItem('adminToken', data.token);
    localStorage.setItem('adminUser', JSON.stringify(data.user));

    return data;
  },

  async verifyToken(token: string): Promise<VerifyResponse> {
    const response = await fetch(`${API_BASE_URL}/api/admin/auth/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ token }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Token verification failed');
    }

    return data;
  },

  logout(): void {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
  },

  getToken(): string | null {
    return localStorage.getItem('adminToken');
  },

  getUser(): AdminUser | null {
    const userStr = localStorage.getItem('adminUser');
    return userStr ? JSON.parse(userStr) : null;
  },

  isAuthenticated(): boolean {
    const token = this.getToken();
    const user = this.getUser();
    return !!(token && user && user.role === 'admin');
  },
};
