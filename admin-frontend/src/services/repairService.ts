const API_URL = import.meta.env.VITE_API_URL;

export interface RepairRequest {
    _id: string;
    request_name: string;
    first_name: string;
    last_name: string;
    email: string;
    contact_number: string;
    address: string;
    request_type: string;
    description: string;
    request_priority: 'low' | 'normal' | 'urgent' | 'critical';
    status: 'pending' | 'approved' | 'rejected' | 'completed';
    cat_or_dog_on_site: string;
    media: Array<{
        url: string;
        type: 'image' | 'video';
    }>;
    createdAt: string;
}

class RepairService {
    private getHeaders() {
        const token = localStorage.getItem("token");
        return {
            Authorization: `Bearer ${token}`,
        };
    }

    async createRepairRequest(formData: FormData): Promise<any> {
        const res = await fetch(`${API_URL}/repair-requests/tenant/create`, {
            method: "POST",
            headers: this.getHeaders(),
            body: formData,
        });
        return await res.json();
    }

    async getTenantRepairRequests(): Promise<RepairRequest[]> {
        const res = await fetch(`${API_URL}/repair-requests/tenant/all`, {
            headers: this.getHeaders(),
        });
        const data = await res.json();
        return data.success && data.data?.requests ? data.data.requests : [];
    }
}

export const repairService = new RepairService();
