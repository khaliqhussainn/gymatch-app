const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://gymatch.syedmisbahali.com';

export interface Gym {
  id: number;
  name: string;
  sub_name: string;
  location_name: string;
  near_location: string;
  latitude: number;
  longitude: number;
  rating: number;
  is_open: boolean;
  open_hours: string;
  contact_phone: string;
  category: string;
  is_featured: boolean;
  created_at: string;
  owner_name?: string;
  owner_email?: string;
  images?: { image_url: string; sort_order: number }[];
  amenities?: string[];
  membership_plans?: {
    id: number;
    name: string;
    price: number;
    billing_period: string;
    features: string;
    is_premium: boolean;
  }[];
}

export const gymApiService = {
  async getAllGyms(): Promise<Gym[]> {
    const response = await fetch(`${API_BASE_URL}/api/admin/gyms`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch gyms');
    }

    return data.data;
  },

  async getGymDetails(id: number): Promise<Gym> {
    const response = await fetch(`${API_BASE_URL}/api/admin/gyms/${id}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch gym details');
    }

    return data.data;
  },
};
