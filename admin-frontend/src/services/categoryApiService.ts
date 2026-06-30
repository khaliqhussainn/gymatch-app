const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://gymatch.syedmisbahali.com';

export interface Category {
  id: number;
  name: string;
  status: 'active' | 'inactive';
  created_at: string;
  updated_at: string;
}

export const categoryApiService = {
  async getAllCategories(): Promise<Category[]> {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch categories');
    }

    return data.data;
  },

  async createCategory(name: string): Promise<Category> {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ name }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to create category');
    }

    return data.data;
  },

  async updateCategory(id: number, name: string): Promise<Category> {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ name }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to update category');
    }

    return data.data;
  },

  async updateCategoryStatus(id: number, status: 'active' | 'inactive'): Promise<Category> {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories/${id}/status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to update category status');
    }

    return data.data;
  },

  async deleteCategory(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/api/admin/categories/${id}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to delete category');
    }
  },
};
