import { useEffect, useState } from "react";
import { repairService, RepairRequest } from "../../../services/repairService";

export default function RepairRequestList() {
    const [requests, setRequests] = useState<RepairRequest[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchRequests = async () => {
        setLoading(true);
        const data = await repairService.getTenantRepairRequests();
        setRequests(data);
        setLoading(false);
    };

    useEffect(() => {
        fetchRequests();
    }, []);

    const getStatusColor = (status: string) => {
        switch (status) {
            case "pending": return "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400";
            case "approved": return "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400";
            case "completed": return "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400";
            case "rejected": return "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400";
            default: return "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400";
        }
    };

    const getPriorityColor = (priority: string) => {
        switch (priority) {
            case "critical": return "text-red-600 dark:text-red-400 font-bold";
            case "urgent": return "text-orange-600 dark:text-orange-400 font-bold";
            case "normal": return "text-blue-600 dark:text-blue-400 font-medium";
            case "low": return "text-gray-500 dark:text-gray-400 font-medium";
            default: return "text-gray-500 font-medium";
        }
    };

    if (loading) return <div className="text-center py-10 dark:text-gray-400">Loading requests...</div>;

    return (
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-100 dark:border-gray-700 overflow-hidden">
            <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center">
                <h2 className="text-xl font-bold dark:text-white">My Repair Requests</h2>
                <button
                    onClick={fetchRequests}
                    className="p-2 text-gray-500 hover:text-blue-600 transition-colors"
                    title="Refresh List"
                >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                </button>
            </div>
            <div className="overflow-x-auto">
                <table className="w-full text-left">
                    <thead className="bg-gray-50 dark:bg-gray-700/50 text-gray-500 dark:text-gray-400 text-xs uppercase font-semibold">
                        <tr>
                            <th className="px-6 py-4">Request</th>
                            <th className="px-6 py-4">Type</th>
                            <th className="px-6 py-4">Priority (AI)</th>
                            <th className="px-6 py-4">Status</th>
                            <th className="px-6 py-4">Created At</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                        {(!requests || requests.length === 0) ? (
                            <tr>
                                <td colSpan={5} className="px-6 py-10 text-center text-gray-500 dark:text-gray-400">
                                    No repair requests found.
                                </td>
                            </tr>
                        ) : (
                            requests.map((req) => (
                                <tr key={req._id} className="hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors">
                                    <td className="px-6 py-4">
                                        <div className="font-semibold text-gray-900 dark:text-white">{req.request_name}</div>
                                        <div className="text-xs text-gray-500 truncate max-w-[200px]">{req.description}</div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className="capitalize text-sm dark:text-gray-300">{req.request_type}</span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`capitalize text-xs px-2 py-1 rounded-full bg-gray-100 dark:bg-gray-800 ${getPriorityColor(req.request_priority)}`}>
                                            {req.request_priority}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(req.status)}`}>
                                            {req.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                                        {new Date(req.createdAt).toLocaleDateString()}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
