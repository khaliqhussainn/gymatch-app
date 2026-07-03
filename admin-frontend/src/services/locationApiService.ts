const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://gymatch.syedmisbahali.com';

export interface LocationPreset {
  id: number;
  label: string;
  subtitle: string;
  latitude: number;
  longitude: number;
  status: 'active' | 'inactive';
  created_at: string;
  updated_at: string;
}

export interface LocationPresetInput {
  label: string;
  subtitle: string;
  latitude: number;
  longitude: number;
}

export const locationApiService = {
  async getAllLocations(): Promise<LocationPreset[]> {
    const response = await fetch(`${API_BASE_URL}/api/admin/locations`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch location presets');
    }

    return data.data;
  },

  async createLocation(input: LocationPresetInput): Promise<LocationPreset> {
    const response = await fetch(`${API_BASE_URL}/api/admin/locations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(input),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to create location preset');
    }

    return data.data;
  },

  async updateLocation(id: number, input: LocationPresetInput): Promise<LocationPreset> {
    const response = await fetch(`${API_BASE_URL}/api/admin/locations/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(input),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to update location preset');
    }

    return data.data;
  },

  async updateLocationStatus(id: number, status: 'active' | 'inactive'): Promise<LocationPreset> {
    const response = await fetch(`${API_BASE_URL}/api/admin/locations/${id}/status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ status }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to update location preset status');
    }

    return data.data;
  },

  async deleteLocation(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/api/admin/locations/${id}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to delete location preset');
    }
  },
};
