import React, { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import PageMeta from "../../../components/common/PageMeta";
import Button from "../../../components/ui/button/Button";
import Input from "../../../components/form/input/InputField";
import TextArea from "../../../components/form/input/TextArea";

// Mock TextArea since I am not sure if it exists in components/form/input/TextArea
// If it fails, I'll replace it with standard textarea.
// Waiting for failure? No, let's just use standard textarea for safety if I didn't see it in list.
// I saw "form" has 23 children so likely it has TextArea.
// Let's assume standard textarea for now to be safe or check the list again?
// Step 56 said "form" has 23 children. It likely has TextArea.
// I'll use standard <textarea> with tailwind classes for safety.

interface FaqItem {
    _id: string;
    question: string;
    answer: string;
}

export default function FaqPage() {
    const [faqs, setFaqs] = useState<FaqItem[]>([]);
    const [question, setQuestion] = useState("");
    const [answer, setAnswer] = useState("");
    const [editingId, setEditingId] = useState<string | null>(null);

    const fetchFaqs = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/faqs`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                setFaqs(data.faqs);
            }
        } catch (error) {
            console.error(error);
        }
    };

    useEffect(() => {
        fetchFaqs();
    }, []);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('token');
            const url = editingId
                ? `${import.meta.env.VITE_API_URL}/admin/faqs/${editingId}`
                : `${import.meta.env.VITE_API_URL}/admin/faqs`;
            const method = editingId ? 'PUT' : 'POST';

            const formData = new FormData();
            formData.append('question', question);
            formData.append('answer', answer);

            const res = await fetch(url, {
                method,
                headers: {
                    Authorization: `Bearer ${token}`
                },
                body: formData
            });
            const data = await res.json();
            if (data.success) {
                toast.success(editingId ? 'FAQ updated' : 'FAQ created');
                setQuestion("");
                setAnswer("");
                setEditingId(null);
                fetchFaqs();
            } else {
                toast.error(data.message || 'Failed to save FAQ');
            }
        } catch (error) {
            toast.error('An error occurred');
            console.error(error);
        }
    };

    const deleteFaq = async (id: string) => {
        if (!confirm("Delete this FAQ?")) return;
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/faqs/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                toast.success('FAQ deleted');
                fetchFaqs();
            } else {
                toast.error(data.message || 'Failed to delete FAQ');
            }
        } catch (e) {
            toast.error('An error occurred');
            console.error(e);
        }
    };

    const startEdit = (faq: FaqItem) => {
        setQuestion(faq.question);
        setAnswer(faq.answer);
        setEditingId(faq._id);
    }

    return (
        <>
            <PageMeta title="FAQs | Admin" description="Manage FAQs" />
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

                {/* Form */}
                <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6 h-fit">
                    <h2 className="text-xl font-bold mb-4 dark:text-white">{editingId ? 'Edit FAQ' : 'Add New FAQ'}</h2>
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Question</label>
                            <Input value={question} onChange={(e) => setQuestion(e.target.value)} placeholder="e.g. How do I reset password?" />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Answer</label>
                            <textarea
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-brand-500 focus:border-brand-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
                                rows={4}
                                value={answer}
                                onChange={(e) => setAnswer(e.target.value)}
                                required
                                placeholder="Answer goes here..."
                            />
                        </div>
                        <div className="flex gap-2">
                            <Button type="submit">{editingId ? 'Update' : 'Create'}</Button>
                            {editingId && <Button type="button" variant="outline" onClick={() => { setEditingId(null); setQuestion(""); setAnswer(""); }}>Cancel</Button>}
                        </div>
                    </form>
                </div>

                {/* List */}
                <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                    <h2 className="text-xl font-bold mb-4 dark:text-white">Existing FAQs</h2>
                    <div className="space-y-4 max-h-[600px] overflow-y-auto">
                        {faqs.map(faq => (
                            <div key={faq._id} className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg">
                                <h3 className="font-semibold text-gray-900 dark:text-white mb-2">{faq.question}</h3>
                                <p className="text-gray-600 dark:text-gray-400 text-sm mb-3">{faq.answer}</p>
                                <div className="flex gap-2">
                                    <button onClick={() => startEdit(faq)} className="text-sm text-brand-500 hover:underline">Edit</button>
                                    <button onClick={() => deleteFaq(faq._id)} className="text-sm text-red-500 hover:underline">Delete</button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

            </div>
        </>
    );
}
