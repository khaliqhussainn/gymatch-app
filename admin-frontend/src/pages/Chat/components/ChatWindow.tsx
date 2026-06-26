import React, { useState, useRef, useEffect } from "react";
import { ChatMessage, ChatListItem } from "../../../services/chatService";

interface ChatWindowProps {
    conversation?: ChatListItem;
    messages: ChatMessage[];
    onSendMessage: (text: string, file?: File) => void;
    userId: string;
}

export default function ChatWindow({ conversation, messages, onSendMessage, userId }: ChatWindowProps) {

    const [inputText, setInputText] = useState("");
    const scrollRef = useRef<HTMLDivElement>(null);
    const displayName = conversation?.name || `${conversation?.sender?.first_name || "Chat"} ${conversation?.sender?.last_name || ""}`;
    const displayImage = conversation?.image || conversation?.sender?.image || "/default-avatar.png";

    const messagesEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        // Use a small timeout to ensure DOM has updated and images are taking up space
        const timeoutId = setTimeout(() => {
            messagesEndRef.current?.scrollIntoView({ behavior: "auto", block: "end" });
        }, 100);
        return () => clearTimeout(timeoutId);
    }, [messages]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (inputText.trim()) {
            onSendMessage(inputText);
            setInputText("");
        }
    };

    return (
        <div className="flex-1 flex flex-col min-w-0 min-h-0 bg-white dark:bg-gray-900">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <img
                            src={displayImage}
                            alt={displayName}
                            className="w-10 h-10 rounded-full object-cover"
                        />
                        <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-green-500 border-2 border-white dark:border-gray-900 rounded-full"></span>
                    </div>
                    <div>
                        <h3 className="font-semibold text-gray-900 dark:text-white leading-tight">
                            {displayName}
                        </h3>
                        <span className="text-xs text-green-500">Online</span>
                    </div>
                </div>
                <div className="flex items-center gap-4">
                    <button className="text-gray-400 hover:text-blue-500 transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                    </button>
                    <button className="text-gray-400 hover:text-blue-500 transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                        </svg>
                    </button>
                    <button className="text-gray-400 hover:text-blue-500 transition-colors">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                        </svg>
                    </button>
                </div>
            </div>

            {/* Messages */}
            <div
                ref={scrollRef}
                className="flex-1 overflow-y-auto p-6 space-y-6 chat-scrollbar bg-gray-50/30 dark:bg-gray-900/10 min-h-0"
            >
                {messages.map((msg, index) => {
                    const isMe = msg.sender_id === userId;
                    return (

                        <div key={msg.id || index} className={`flex ${isMe ? "justify-end" : "justify-start"} items-start gap-3`}>
                            {!isMe && (
                                <img
                                    src={msg.sender.image || "/default-avatar.png"}
                                    alt={msg.sender.first_name}
                                    className="w-8 h-8 rounded-full object-cover mt-1"
                                />
                            )}
                            <div className={`max-w-[70%] ${isMe ? "order-1" : "order-2"}`}>
                                {!isMe && (
                                    <div className="flex items-center gap-2 mb-1">
                                        <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                                            {msg.sender.first_name}, {new Date(msg.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                        </span>
                                    </div>
                                )}
                                <div className={`p-4 rounded-2xl shadow-sm ${isMe
                                    ? "bg-blue-600 text-white rounded-tr-none"
                                    : "bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-tl-none border border-gray-100 dark:border-gray-700"
                                    }`}>
                                    {msg.type === "text" ? (
                                        <p className="text-sm leading-relaxed">{msg.message}</p>
                                    ) : msg.file_type.startsWith("image/") ? (
                                        <img src={msg.message} alt="attachment" className="rounded-lg max-w-[300px] max-h-[400px] w-auto h-auto object-cover cursor-pointer hover:opacity-90 transition-opacity" />
                                    ) : msg.file_type.startsWith("video/") ? (
                                        <video src={msg.message} controls className="rounded-lg max-w-[300px] max-h-[400px] w-auto h-auto" />
                                    ) : (
                                        <a href={msg.message} target="_blank" rel="noreferrer" className="underline italic">Attachment</a>
                                    )}
                                </div>
                                {isMe && (
                                    <div className="text-[10px] text-gray-400 mt-1 text-right">
                                        {new Date(msg.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                    </div>
                                )}
                            </div>
                        </div>
                    );
                })}
                <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className="p-4 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700">
                <form onSubmit={handleSubmit} className="flex items-center gap-2 bg-gray-50 dark:bg-gray-800 rounded-2xl p-2 px-4 border border-gray-200 dark:border-gray-700 focus-within:ring-2 focus-within:ring-blue-500 transition-all">
                    <button type="button" className="text-gray-400 hover:text-blue-500 p-1">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </button>
                    <input
                        type="text"
                        value={inputText}
                        onChange={(e) => setInputText(e.target.value)}
                        placeholder="Type a message..."
                        className="flex-1 bg-transparent border-none focus:ring-0 outline-none py-2 text-sm text-gray-900 dark:text-white"
                    />
                    <div className="flex items-center gap-1 border-l border-gray-200 dark:border-gray-700 ml-2 pl-2">
                        <button type="button" className="text-gray-400 hover:text-blue-500 p-2">
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                            </svg>
                        </button>
                        <button type="button" className="text-gray-400 hover:text-blue-500 p-2">
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                            </svg>
                        </button>
                        <button
                            type="submit"
                            className="bg-blue-600 hover:bg-blue-700 text-white p-2 rounded-xl shadow-md transition-all active:scale-95 ml-1"
                        >
                            <svg className="w-5 h-5 rotate-45" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                            </svg>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
