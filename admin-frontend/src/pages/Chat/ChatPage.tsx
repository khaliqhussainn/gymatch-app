import { useEffect, useState, useRef } from "react";

import PageMeta from "../../components/common/PageMeta";
import ChatSidebar from "./components/ChatSidebar";
import ChatWindow from "./components/ChatWindow";
import { chatService, ChatListItem, ChatMessage } from "../../services/chatService";
import { socketService } from "../../services/socketService";

export default function ChatPage() {
    const [conversations, setConversations] = useState<ChatListItem[]>([]);
    const [activeConversation, setActiveConversation] = useState<string | null>(null);
    const [messages, setMessages] = useState<ChatMessage[]>([]);
    const [loading, setLoading] = useState(true);
    const userStr = localStorage.getItem("user");
    const user = userStr ? JSON.parse(userStr) : null;
    const userId = user?.id || user?._id || "";
    const activeConvRef = useRef<string | null>(null);

    useEffect(() => {
        activeConvRef.current = activeConversation;
    }, [activeConversation]);


    useEffect(() => {
        const token = localStorage.getItem("token");
        if (token) {
            socketService.connect(token);
        }

        const handleNewMessage = (msg: ChatMessage) => {
            console.log("Message received via socket:", msg);
            setMessages((prev) => {
                // Use ref to avoid stale closure
                if (msg.conversationId === activeConvRef.current) {
                    // Avoid duplicates
                    if (prev.find(m => m.id === msg.id)) return prev;
                    return [...prev, msg];
                }
                return prev;
            });

            setConversations((prev) =>
                prev.map((c) =>
                    c.conversationId === msg.conversationId
                        ? {
                            ...c,
                            message: msg.message,
                            time: msg.time,
                            unread_count: msg.conversationId === activeConvRef.current ? 0 : (c.unread_count || 0) + 1
                        }
                        : c
                )
            );
        };

        socketService.on("message", handleNewMessage);
        return () => {
            socketService.off("message", handleNewMessage);
        };
    }, []); // Only register once


    // Separate effect for initial load and socket cleanup
    useEffect(() => {
        const fetchConversations = async () => {
            setLoading(true);
            const data = await chatService.getChatList();
            setConversations(data);
            if (data.length > 0 && !activeConversation) {
                setActiveConversation(data[0].conversationId);
            }
            setLoading(false);
        };

        fetchConversations();

        return () => {
            // Only disconnect when the entire component unmounts
            socketService.disconnect();
        };
    }, []);


    useEffect(() => {
        if (activeConversation) {
            const fetchMessages = async () => {
                const data = await chatService.getChatDetail(activeConversation);
                setMessages(data);
                // Clear unread count locally when viewing the chat
                setConversations(prev => prev.map(c =>
                    c.conversationId === activeConversation
                        ? { ...c, unread_count: 0 }
                        : c
                ));
                socketService.emit("join", { conversationId: activeConversation });
            };
            fetchMessages();
        }
    }, [activeConversation]);

    const handleSendMessage = async (text: string, file?: File) => {
        if (!activeConversation) return;

        const formData = new FormData();
        formData.append("chat_list_id", activeConversation); // Backend expects chat_list_id
        if (text) formData.append("message", text); // Backend expects message for text
        if (file) formData.append("message", file); // Backend expects message for file

        const newMsg = await chatService.sendMessage(formData);
        if (newMsg) {
            console.log("Message sent successfully:", newMsg);
            setMessages(prev => {
                if (prev.find(m => m.id === newMsg.id)) return prev;
                return [...prev, newMsg];
            });
            setConversations(prev => prev.map(c =>
                c.conversationId === activeConversation
                    ? { ...c, message: newMsg.message, time: newMsg.time }
                    : c
            ));
        }
    };

    const handleConversationCreated = (newConv: ChatListItem) => {
        setConversations(prev => {
            if (prev.find(c => c.conversationId === newConv.conversationId)) return prev;
            return [newConv, ...prev];
        });
    };


    return (
        <>
            <PageMeta title="Chats | Property Management" description="Real-time chat for property management" />
            <div className="flex h-[calc(100vh-180px)] overflow-hidden bg-white dark:bg-gray-800 rounded-xl shadow-md border border-gray-200 dark:border-gray-700">
                <ChatSidebar
                    conversations={conversations}
                    activeConversation={activeConversation}
                    onSelectConversation={setActiveConversation}
                    onConversationCreated={handleConversationCreated}
                />

                <div className="flex-1 flex flex-col min-w-0 min-h-0">
                    {loading ? (
                        <div className="flex-1 flex items-center justify-center">Loading...</div>
                    ) : activeConversation ? (
                        <ChatWindow
                            conversation={conversations.find(c => c.conversationId === activeConversation)}
                            messages={messages}
                            onSendMessage={handleSendMessage}
                            userId={userId}
                        />
                    ) : (

                        <div className="flex-1 flex items-center justify-center text-gray-500">
                            Select a conversation to start chatting
                        </div>
                    )}
                </div>
            </div>
        </>
    );
}
