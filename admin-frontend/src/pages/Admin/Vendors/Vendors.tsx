import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import PageMeta from "../../../components/common/PageMeta";
import Button from "../../../components/ui/button/Button";

interface Vendor {
    _id: string;
    first_name: string;
    last_name: string;
    email: string;
    status: boolean;
    claim_address_status: string;
}

export default function Vendors() {
    const [vendors, setVendors] = useState<Vendor[]>([]);
    const [page, setPage] = useState(1);
    const [loading, setLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const itemsPerPage = 10;

    const filteredVendors = vendors.filter(vendor =>
        vendor.first_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        vendor.last_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        vendor.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const pages = Math.ceil(filteredVendors.length / itemsPerPage);
    const paginatedVendors = filteredVendors.slice((page - 1) * itemsPerPage, page * itemsPerPage);

    const fetchVendors = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/vendors`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                setVendors(data.users);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchVendors();
    }, []);

    // Reset to page 1 when search term changes
    useEffect(() => {
        setPage(1);
    }, [searchTerm]);

    const toggleStatus = async (id: string, currentStatus: boolean) => {
        const formData = new FormData();
        formData.append('status', String(!currentStatus));

        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/vendors/${id}`, {
                method: 'PUT',
                headers: {
                    Authorization: `Bearer ${token}`
                },
                body: formData
            });
            const data = await res.json();
            if (data.success) {
                toast.success(data.message || 'Status updated successfully');
                fetchVendors();
            } else {
                toast.error(data.message || 'Failed to update status');
            }
        } catch (error) {
            toast.error('An error occurred. Please try again.');
            console.error(error);
        }
    };

    return (
        <>
            <PageMeta title="Manage Vendors | Admin" description="Approve or Reject Vendors" />
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                <h2 className="text-xl font-bold mb-4 dark:text-white">Vendor Management</h2>

                {/* Search Input */}
                <div className="mb-4">
                    <input
                        type="text"
                        placeholder="Search by name or email..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-brand-500 dark:bg-gray-700 dark:text-white"
                    />
                </div>

                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead>
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Name</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Email</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Status</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200 dark:bg-gray-800 dark:divide-gray-700">
                            {paginatedVendors.map((vendor) => (
                                <tr key={vendor._id}>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-200">{vendor.first_name} {vendor.last_name}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">{vendor.email}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${vendor.status ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                                            {vendor.status ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <Button
                                            size="sm"
                                            variant={vendor.status ? "outline" : "primary"}
                                            onClick={() => toggleStatus(vendor._id, vendor.status)}
                                        >
                                            {vendor.status ? 'Deactivate' : 'Activate'}
                                        </Button>
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
