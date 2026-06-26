import { useState, useEffect } from "react";
import { Dropdown } from "../ui/dropdown/Dropdown";
import { onMessageListener } from "../../firebase";
import toast from "react-hot-toast";

export default function NotificationDropdown() {
    const [isOpen, setIsOpen] = useState(false);
    const [notifications, setNotifications] = useState<any[]>([]);
    const [unreadCount, setUnreadCount] = useState(0);

    const fetchNotifications = async () => {
        try {
            const token = localStorage.getItem('token');
            if (!token) return;

            const formData = new FormData();
            formData.append('status', 'all');
            formData.append('page', '1');
            formData.append('limit', '20');

            const res = await fetch(`${import.meta.env.VITE_API_URL}/notifications`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
                body: formData
            });
            const data = await res.json();
            if (data.success) {
                setNotifications(data.data);
                const unread = data.data.filter((n: any) => !n.is_read).length;
                setUnreadCount(unread);
            }
        } catch (error) {
            console.error("Failed to fetch notifications:", error);
        }
    };

    useEffect(() => {
        fetchNotifications();

        const setupListener = () => {
            onMessageListener()
                .then((payload: any) => {
                    console.log("Received foreground message: ", payload);
                    const { title, body } = payload.notification || {};
                    if (title) {
                        toast(
                            <div className="flex flex-col">
                                <span className="font-bold">{title}</span>
                                <span className="text-sm">{body}</span>
                            </div>,
                            { icon: '🔔' }
                        );
                        fetchNotifications(); // Refresh list on new message
                    }
                    setupListener();
                })
                .catch((err) => {
                    console.log("onMessageListener failed: ", err);
                    setTimeout(setupListener, 5000);
                });
        };

        setupListener();
    }, []);

    const markAsRead = async (id: string) => {
        try {
            const token = localStorage.getItem('token');
            if (!token) return;

            const formData = new FormData();
            formData.append('id', id);

            await fetch(`${import.meta.env.VITE_API_URL}/notifications/mark-as-read`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
                body: formData
            });
            fetchNotifications();
        } catch (error) {
            console.error("Failed to mark notification as read:", error);
        }
    };

    function toggleDropdown() {
        setIsOpen(!isOpen);
    }

    function closeDropdown() {
        setIsOpen(false);
    }

    return (
        <div className="relative">
            <button
                onClick={toggleDropdown}
                className="relative flex items-center justify-center text-gray-500 transition-colors bg-white border border-gray-200 rounded-full w-11 h-11 hover:text-brand-500 dark:border-gray-800 dark:bg-white/[0.03] dark:text-gray-400 dark:hover:text-brand-500"
            >
                <svg
                    className="fill-current"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    xmlns="http://www.w3.org/2000/svg"
                >
                    <path
                        fillRule="evenodd"
                        clipRule="evenodd"
                        d="M11.9999 3.75C9.72251 3.75 7.7698 5.25057 7.11979 7.31971C6.2627 9.1763 5.40552 10.963 4.54832 12.7497C4.26941 12.8711 4.0956 12.986 3.96644 13.1119C3.65997 13.4105 3.49392 13.8291 3.50293 14.2568C3.51194 14.6845 3.69532 15.0963 4.01358 15.3831C4.33184 15.6699 4.75836 15.8078 5.18617 15.7619C5.61397 15.7161 6.00762 15.49 6.2798 15.1325C7.20239 14.0722 8.12781 13.0147 9.05315 11.9572C9.2738 12.4277 9.53982 12.8596 9.8752 13.2307C10.6358 14.0721 11.3323 14.8986 12.0465 15.7119C12.3529 16.0609 12.7831 16.277 13.242 16.3129C13.7009 16.3488 14.1528 16.2018 14.4984 15.9037C14.8439 15.6056 15.0617 15.1798 15.1039 14.7197C15.1461 14.2596 15.0094 13.8009 14.7237 13.4444C13.8953 12.41 13.0641 11.3784 12.2329 10.3468C12.4332 9.88295 12.6074 9.40795 12.7538 8.92429C12.8906 8.44064 12.9733 7.94276 12.9999 7.43986C13.0163 6.93695 12.9763 6.43907 12.8804 5.95542C12.7845 5.47177 12.6343 5.00676 12.4338 4.56986C12.315 4.30971 12.1692 4.06286 11.9999 3.75ZM6.24993 17.25C6.9116 18.3962 8.12588 19.125 9.44993 19.125H14.5499C15.874 19.125 17.0883 18.3962 17.7499 17.25H6.24993Z"
                        fill=""
                    />
                </svg>
                {unreadCount > 0 && (
                    <span className="absolute top-0 right-0 flex items-center justify-center min-w-4 h-4 p-1 text-[10px] font-bold text-white bg-red-500 rounded-full border-2 border-white dark:border-gray-900">
                        {unreadCount}
                    </span>
                )}
            </button>

            <Dropdown
                isOpen={isOpen}
                onClose={closeDropdown}
                className="absolute right-0 mt-[17px] w-[350px] rounded-2xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark"
            >
                <div className="flex items-center justify-between px-3 py-2 border-b border-gray-200 dark:border-gray-800">
                    <h3 className="font-semibold text-gray-800 text-theme-sm dark:text-white/90">
                        Notifications
                    </h3>
                </div>
                <div className="overflow-y-auto max-h-[300px] flex flex-col">
                    {notifications.length === 0 ? (
                        <div className="p-4 text-center text-sm text-gray-500">No notifications</div>
                    ) : (
                        notifications.map((note) => (
                            <div
                                key={note.id}
                                onClick={() => !note.is_read && markAsRead(note.id)}
                                className={`flex flex-col px-3 py-2 border-b border-gray-100 dark:border-gray-800 last:border-0 hover:bg-gray-50 dark:hover:bg-white/5 cursor-pointer ${!note.is_read ? 'bg-blue-50/50 dark:bg-brand-500/5' : ''}`}
                            >
                                <span className="font-medium text-gray-800 text-sm dark:text-white/90">{note.title}</span>
                                <span className="text-xs text-gray-500">{note.message}</span>
                                <span className="text-[10px] text-gray-400 mt-1">{note.time}</span>
                            </div>
                        ))
                    )}
                </div>
            </Dropdown>
        </div>
    );
}
