import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import PageMeta from "../../../components/common/PageMeta";
import Button from "../../../components/ui/button/Button";
import Input from "../../../components/form/input/InputField";

interface Spec {
    _id: string;
    name: string;
}

export default function Specializations() {
    const [specs, setSpecs] = useState<Spec[]>([]);
    const [newName, setNewName] = useState("");
    const [searchTerm, setSearchTerm] = useState('');

    const filteredSpecs = specs.filter(spec =>
        spec.name.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const fetchSpecs = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/specializations`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                setSpecs(data.specializations);
            }
        } catch (error) {
            console.error(error);
        }
    };

    useEffect(() => {
        fetchSpecs();
    }, []);

    const addSpec = async () => {
        if (!newName.trim()) return;
        try {
            const formData = new FormData();
            formData.append('name', newName);

            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/specializations`, {
                method: 'POST',
                headers: {
                    Authorization: `Bearer ${token}`
                },
                body: formData
            });
            const data = await res.json();
            if (data.success) {
                toast.success(data.message || "Specialization added");
                setNewName("");
                fetchSpecs();
            } else {
                toast.error(data.message || "Failed to add specialization");
            }
        } catch (error) {
            toast.error("An error occurred");
            console.error(error);
        }
    }

    const deleteSpec = async (id: string) => {
        if (!confirm("Are you sure?")) return;
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/specializations/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                toast.success(data.message || "Specialization deleted");
                fetchSpecs();
            } else {
                toast.error(data.message || "Failed to delete");
            }
        } catch (error) {
            toast.error("An error occurred");
            console.error(error);
        }
    }

    return (
        <>
            <PageMeta title="Specializations | Admin" description="Manage Specializations" />
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                <h2 className="text-xl font-bold mb-4 dark:text-white">Specializations</h2>

                <div className="flex gap-4 mb-6">
                    <div className="flex-1">
                        <Input placeholder="New Specialization Name" value={newName} onChange={(e) => setNewName(e.target.value)} />
                    </div>
                    <Button onClick={addSpec}>Add</Button>
                </div>

                {/* Search Input */}
                <div className="mb-4">
                    <input
                        type="text"
                        placeholder="Search specializations..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-brand-500 dark:bg-gray-700 dark:text-white"
                    />
                </div>

                <div className="space-y-2">
                    {filteredSpecs.map((spec) => (
                        <div key={spec._id} className="flex justify-between items-center p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-100 dark:border-gray-700">
                            <span className="text-gray-800 dark:text-gray-200">{spec.name}</span>
                            <div className="flex gap-2">
                                <Button size="sm" variant="outline" className="text-red-500 hover:text-red-700 border-red-200 hover:bg-red-50" onClick={() => deleteSpec(spec._id)}>Delete</Button>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </>
    );
}
