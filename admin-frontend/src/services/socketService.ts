import { io, Socket } from "socket.io-client";

const SOCKET_URL = import.meta.env.VITE_SOCKET_URL;

class SocketService {
    private socket: Socket | null = null;

    connect(token: string) {
        if (this.socket) return;

        this.socket = io(SOCKET_URL, {
            auth: { token },
            transports: ["websocket"],
        });

        this.socket.on("connect", () => {
            console.log("Socket connected:", this.socket?.id);
        });

        this.socket.on("connect_error", (err) => {
            console.error("Socket connection error:", err.message);
        });
    }

    disconnect() {
        if (this.socket) {
            this.socket.disconnect();
            this.socket = null;
        }
    }

    on(event: string, callback: (...args: any[]) => void) {
        this.socket?.on(event, callback);
    }

    off(event: string, callback: (...args: any[]) => void) {
        this.socket?.off(event, callback);
    }

    emit(event: string, data: any, callback?: (...args: any[]) => void) {
        this.socket?.emit(event, data, callback);
    }
}

export const socketService = new SocketService();
