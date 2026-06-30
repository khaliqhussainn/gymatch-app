const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://gymatch.syedmisbahali.com';

export interface DashboardStats {
  totalGyms: number;
  totalUsers: number;
  activeUsers: number;
  mostViewedGyms: Array<{
    name: string;
    viewCount: number;
    city: string;
  }>;
  monthly_trends: {
    month: string;
    gyms: number;
    users: number;
  }[];
}

export const dashboardApiService = {
  async getDashboardStats(): Promise<DashboardStats> {
    const response = await fetch(`${API_BASE_URL}/api/admin/dashboard/stats`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch dashboard stats');
    }

    return data.data;
  },
};
