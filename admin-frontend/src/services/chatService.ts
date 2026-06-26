const API_URL = import.meta.env.VITE_API_URL;

export interface ChatMessage {
    id: string;
    conversationId: string;
    sender_id: string;
    message: string;
    type: string;
    file_type: string;
    time: string;
    sender: {
        id: string;
        first_name: string;
        last_name: string;
        image: string;
    };
}

export interface ChatListItem {
    conversationId: string;
    message: string;
    lastMessage?: string; // Keep for compatibility if needed elsewhere
    time: string;
    name?: string;
    image?: string;
    role?: string;
    sender?: {
        id: string;
        first_name: string;
        last_name: string;
        image: string;
        role: string;
    };
    unread_count?: number;
}
export interface ChatUser {
    id: string;
    first_name: string;
    last_name: string;
    image: string;
    role: string;
}

class ChatService {

    private getHeaders() {
        const token = localStorage.getItem("token");
        return {
            Authorization: `Bearer ${token}`,
        };
    }

    async getChatList(): Promise<ChatListItem[]> {
        const res = await fetch(`${API_URL}/chat/chat_list`, {
            headers: this.getHeaders(),
        });
        const data = await res.json();
        return data.success && data.data?.data ? data.data.data : [];
    }

    async getChatDetail(conversationId: string): Promise<ChatMessage[]> {
        const formData = new FormData();
        formData.append("chat_list_id", conversationId);

        const res = await fetch(`${API_URL}/chat/chat_detail`, {
            method: "POST",
            headers: {
                ...this.getHeaders(),
            },
            body: formData,
        });
        const data = await res.json();
        return data.success && data.data?.data ? data.data.data : [];
    }

    async sendMessage(formData: FormData): Promise<ChatMessage | null> {
        const res = await fetch(`${API_URL}/chat/send_message`, {
            method: "POST",
            headers: this.getHeaders(),
            body: formData,
        });
        const data = await res.json();
        return data.success ? data.data : null;
    }

    async getChatUsers(): Promise<ChatUser[]> {
        const res = await fetch(`${API_URL}/chat/get_chat_users`, {
            headers: this.getHeaders(),
        });
        const data = await res.json();
        return data.success ? data.users : [];
    }

    async startNewChat(receiverId: string): Promise<ChatListItem | null> {
        const formData = new FormData();
        formData.append("receiver_id", receiverId);

        const res = await fetch(`${API_URL}/chat/create_chat_list`, {
            method: "POST",
            headers: this.getHeaders(),
            body: formData,
        });
        const data = await res.json();
        if (data.success) {
            return {
                conversationId: data.data.conversationId,
                message: data.data.message || data.data.last_message,
                time: data.data.time,
                name: data.data.name,
                image: data.data.image,
                role: data.data.sender?.role,
                sender: data.data.sender,
                unread_count: 0
            };
        }
        return null;
    }
}


export const chatService = new ChatService();
