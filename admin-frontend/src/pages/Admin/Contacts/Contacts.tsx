import { useEffect, useState } from 'react';
import PageMeta from "../../../components/common/PageMeta";
import Button from "../../../components/ui/button/Button";

interface User {
    first_name: string;
    last_name: string;
    email: string;
}

interface Contact {
    _id: string;
    title: string;
    description: string;
    user: User;
    createdAt: string;
}

export default function Contacts() {
    const [contacts, setContacts] = useState<Contact[]>([]);
    const [page, setPage] = useState(1);
    const [loading, setLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const itemsPerPage = 10;

    const filteredContacts = contacts.filter(contact =>
        contact.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        contact.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (contact.user && contact.user.first_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
        (contact.user && contact.user.last_name.toLowerCase().includes(searchTerm.toLowerCase())) ||
        (contact.user && contact.user.email.toLowerCase().includes(searchTerm.toLowerCase()))
    );

    const pages = Math.ceil(filteredContacts.length / itemsPerPage);
    const paginatedContacts = filteredContacts.slice((page - 1) * itemsPerPage, page * itemsPerPage);

    const fetchContacts = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/contacts`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                setContacts(data.contacts);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchContacts();
    }, []);

    // Reset to page 1 when search term changes
    useEffect(() => {
        setPage(1);
    }, [searchTerm]);

    return (
        <>
            <PageMeta title="Contact Requests | Admin" description="View user contact requests and inquiries" />
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-bold mb-4 dark:text-white">Contact Requests</h2>
                    {/* Search Input */}
                    <div className="mb-4 w-1/2">
                        <input
                            type="text"
                            placeholder="Search by title, description, name or email..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-brand-500 dark:bg-gray-700 dark:text-white"
                        />
                    </div>
                </div>


                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead>
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">User</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Title</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Description</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Date</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200 dark:bg-gray-800 dark:divide-gray-700">
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-6 py-4 text-center text-sm text-gray-500 dark:text-gray-400">Loading...</td>
                                </tr>
                            ) : paginatedContacts.length === 0 ? (
                                <tr>
                                    <td colSpan={4} className="px-6 py-4 text-center text-sm text-gray-500 dark:text-gray-400">No contact requests found.</td>
                                </tr>
                            ) : paginatedContacts.map((contact) => (
                                <tr key={contact._id}>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="text-sm font-medium text-gray-900 dark:text-gray-200">
                                            {contact.user?.first_name} {contact.user?.last_name}
                                        </div>
                                        <div className="text-sm text-gray-500 dark:text-gray-400">
                                            {contact.user?.email}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-900 dark:text-gray-200">{contact.title}</td>
                                    <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                                        <div className="max-w-xs overflow-hidden text-ellipsis">
                                            {contact.description}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                        {new Date(contact.createdAt).toLocaleDateString()}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                {/* Pagination */}
                <div className="flex justify-between items-center mt-4">
                    <Button disabled={page === 1} onClick={() => setPage(p => Math.max(1, p - 1))} size="sm" variant="outline">Previous</Button>
                    <span className="text-sm text-gray-600 dark:text-gray-400">Page {page} of {pages || 1}</span>
                    <Button disabled={page >= pages} onClick={() => setPage(p => Math.min(pages, p + 1))} size="sm" variant="outline">Next</Button>
                </div>
            </div>
        </>
    );
}
