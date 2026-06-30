const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://gymatch.syedmisbahali.com';

export interface FeatureRequest {
  id: number;
  request_type: 'gym' | 'user';
  entity_id: number;
  requester_id: number;
  status: 'pending' | 'approved' | 'rejected';
  reason: string | null;
  created_at: string;
  requester_name: string | null;
  requester_email: string | null;
  entity_name: string | null;
}

export const featureRequestApiService = {
  async getAllFeatureRequests(): Promise<FeatureRequest[]> {
    const response = await fetch(`${API_BASE_URL}/api/admin/feature-requests`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to fetch feature requests');
    }

    return data.data;
  },

  async approveFeatureRequest(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/api/admin/feature-requests/${id}/approve`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to approve feature request');
    }
  },

  async rejectFeatureRequest(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/api/admin/feature-requests/${id}/reject`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Failed to reject feature request');
    }
  },
};
