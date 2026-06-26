const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000';

export interface User {
  id: number;
  email: string;
  role: string;
  status: string;
  created_at: string;
  name?: string;
  age?: number;
  gender?: string;
  fitness_goals?: string;
  workout_types?: string;
  availability?: string;
  about_me?: string;
  profile_image?: string;
}

export const userApiService = {
  async getAllUsers(): Promise<User[]> {
    const response = await fetch(`${API_BASE_URL}/api/admin/users`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch users');
    }

    return data.data;
  },

  async getUserProfile(id: number): Promise<User> {
    const response = await fetch(`${API_BASE_URL}/api/admin/users/${id}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch user profile');
    }

    return data.data;
  },

  async updateUserStatus(id: number, status: 'active' | 'suspended'): Promise<User> {
    const response = await fetch(`${API_BASE_URL}/api/admin/users/${id}/status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to update user status');
    }

    return data.data;
  },
};
