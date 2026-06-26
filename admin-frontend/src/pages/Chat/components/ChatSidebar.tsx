import { useState, useEffect } from "react";
import { ChatListItem, ChatUser, chatService } from "../../../services/chatService";

interface ChatSidebarProps {
    conversations: ChatListItem[];
    activeConversation: string | null;
    onSelectConversation: (id: string) => void;
    onConversationCreated?: (conv: ChatListItem) => void;
}

export default function ChatSidebar({
    conversations,
    activeConversation,
    onSelectConversation,
    onConversationCreated
}: ChatSidebarProps) {
    const [showUserList, setShowUserList] = useState(false);
    const [users, setUsers] = useState<ChatUser[]>([]);
    const [searchQuery, setSearchQuery] = useState("");
    const [loadingUsers, setLoadingUsers] = useState(false);

    useEffect(() => {
        if (showUserList) {
            const fetchUsers = async () => {
                setLoadingUsers(true);
                const data = await chatService.getChatUsers();
                setUsers(data);
                setLoadingUsers(false);
            };
            fetchUsers();
        }
    }, [showUserList]);

    const handleStartChat = async (userId: string) => {
        const newConv = await chatService.startNewChat(userId);
        if (newConv) {
            if (onConversationCreated) {
                onConversationCreated(newConv);
            }
            onSelectConversation(newConv.conversationId);
            setShowUserList(false);
        }
    };

    const filteredConversations = conversations.filter(c => {
        const fullName = (c.name || `${c.sender?.first_name || ""} ${c.sender?.last_name || ""}`).toLowerCase();
        const lastMsg = (c.message || "").toLowerCase();
        const query = searchQuery.toLowerCase();
        return fullName.includes(query) || lastMsg.includes(query);
    });

    const filteredUsers = users.filter(u => {
        const fullName = `${u.first_name} ${u.last_name}`.toLowerCase();
        return fullName.includes(searchQuery.toLowerCase());
    });

    return (
        <div className="w-80 border-r border-gray-200 dark:border-gray-700 flex flex-col bg-gray-50 dark:bg-gray-900/50">
            <div className="p-6">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-2xl font-bold dark:text-white">
                        {showUserList ? "New Chat" : "Chats"}
                    </h2>
                    <div className="flex items-center gap-2">
                        {showUserList && (
                            <button
                                onClick={() => setShowUserList(false)}
                                className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 transition-all"
                            >
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                                </svg>
                            </button>
                        )}
                        <button
                            onClick={() => setShowUserList(!showUserList)}
                            className={`p-2 rounded-lg shadow-sm border transition-all ${showUserList
                                ? "bg-blue-600 text-white border-blue-600"
                                : "text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 bg-white dark:bg-gray-800 border-gray-100 dark:border-gray-700"
                                }`}
                            title="Start New Chat"
                        >
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                            </svg>
                        </button>
                    </div>
                </div>
                <div className="relative">
                    <input
                        type="text"
                        placeholder={showUserList ? "Search users..." : "Search..."}
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all dark:text-white"
                    />
                    <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                    </div>
                </div>
            </div>

            <div className="flex-1 overflow-y-auto px-2 pb-4 chat-scrollbar">
                {showUserList ? (
                    loadingUsers ? (
                        <div className="text-center py-8 text-gray-500">Loading users...</div>
                    ) : (
                        filteredUsers.map((user) => (
                            <button
                                key={user.id}
                                onClick={() => handleStartChat(user.id)}
                                className="w-full flex items-center gap-4 p-4 rounded-xl transition-all mb-1 hover:bg-gray-100 dark:hover:bg-gray-800/50"
                            >
                                <div className="relative flex-shrink-0">
                                    <img
                                        src={user.image || "/default-avatar.png"}
                                        alt={user.first_name}
                                        className="w-12 h-12 rounded-full object-cover"
                                    />
                                </div>
                                <div className="flex-1 min-w-0 text-left">
                                    <h4 className="font-semibold text-gray-900 dark:text-white truncate">
                                        {user.first_name} {user.last_name}
                                    </h4>
                                    <p className="text-sm text-gray-500 dark:text-gray-400 truncate">
                                        {user.role}
                                    </p>
                                </div>
                            </button>
                        ))
                    )
                ) : (
                    filteredConversations.map((chat) => {
                        const displayName = chat.name || `${chat.sender?.first_name || "Unknown"} ${chat.sender?.last_name || ""}`;
                        const displayImage = chat.image || chat.sender?.image || "/default-avatar.png";
                        const isActive = activeConversation === chat.conversationId;

                        return (
                            <button
                                key={chat.conversationId}
                                onClick={() => onSelectConversation(chat.conversationId)}
                                className={`w-full flex items-center gap-4 p-4 rounded-xl transition-all mb-1 ${isActive
                                    ? "bg-white dark:bg-gray-800 shadow-sm"
                                    : "hover:bg-gray-100 dark:hover:bg-gray-800/50"
                                    }`}
                            >
                                <div className="relative flex-shrink-0">
                                    <img
                                        src={displayImage}
                                        alt={displayName}
                                        className="w-12 h-12 rounded-full object-cover"
                                    />
                                    <span className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-white dark:border-gray-800 rounded-full"></span>
                                </div>
                                <div className="flex-1 min-w-0 text-left">
                                    <div className="flex justify-between items-start mb-0.5">
                                        <h4 className={`font-semibold truncate ${isActive ? "text-blue-600 dark:text-blue-400" : "text-gray-900 dark:text-white"}`}>
                                            {displayName}
                                        </h4>
                                        <span className="text-xs text-gray-400 whitespace-nowrap ml-2">
                                            {new Date(chat.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                        </span>
                                    </div>
                                    <div className="flex justify-between items-center w-full">
                                        <p className="text-sm text-gray-500 dark:text-gray-400 truncate flex-1 mr-2">
                                            {chat.message}
                                        </p>
                                        {chat.unread_count && chat.unread_count > 0 ? (
                                            <span className="flex-shrink-0 min-w-[1.25rem] h-5 px-1.5 flex items-center justify-center bg-blue-600 text-white text-[10px] font-bold rounded-full">
                                                {chat.unread_count > 99 ? "99+" : chat.unread_count}
                                            </span>
                                        ) : null}
                                    </div>
                                </div>
                            </button>
                        );
                    })
                )}
            </div>
        </div>
    );
}
