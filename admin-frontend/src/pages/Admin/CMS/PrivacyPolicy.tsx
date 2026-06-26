import React, { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import PageMeta from "../../../components/common/PageMeta";
import Button from "../../../components/ui/button/Button";
import ReactQuill from 'react-quill-new';
import 'react-quill-new/dist/quill.snow.css';

export default function PrivacyPolicy() {
    const [content, setContent] = useState("");
    const [id, setId] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);

    const fetchPolicy = async () => {
        try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/privacy-policy`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success && data.policy) {
                setContent(data.policy.content);
                setId(data.policy._id);
            }
        } catch (error) {
            console.error(error);
        }
    };

    useEffect(() => {
        fetchPolicy();
    }, []);

    const handleSave = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('token');
            const url = `${import.meta.env.VITE_API_URL}/admin/privacy-policy` + (id ? `/${id}` : '');
            const method = id ? 'PUT' : 'POST';

            const formData = new FormData();
            formData.append('content', content);

            const res = await fetch(url, {
                method,
                headers: {
                    Authorization: `Bearer ${token}`
                },
                body: formData
            });
            const data = await res.json();
            if (data.success && data.policy) {
                setId(data.policy._id);
                toast.success("Saved successfully!");
            } else {
                toast.error(data.message || "Failed to save");
            }
        } catch (error) {
            toast.error("An error occurred");
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    const modules = {
        toolbar: [
            [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
            ['bold', 'italic', 'underline', 'strike'],
            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
            [{ 'color': [] }, { 'background': [] }],
            ['link', 'image'],
            ['clean']
        ],
    };

    return (
        <>
            <PageMeta title="Privacy Policy | Admin" description="Manage Privacy Policy" />
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
                <div className="flex justify-between items-center mb-4">
                    <h2 className="text-xl font-bold dark:text-white">Privacy Policy</h2>
                    <Button onClick={handleSave} disabled={loading}>{loading ? 'Saving...' : 'Save Changes'}</Button>
                </div>
                <div className="prose max-w-none dark:prose-invert">
                    <style>{`
                        .ql-container {
                            border-bottom-left-radius: 0.5rem;
                            border-bottom-right-radius: 0.5rem;
                            background-color: transparent;
                            font-family: inherit;
                        }
                        .ql-toolbar {
                            border-top-left-radius: 0.5rem;
                            border-top-right-radius: 0.5rem;
                            background-color: #f9fafb;
                            border-color: #d1d5db !important;
                        }
                        .dark .ql-toolbar {
                            background-color: #374151;
                            border-color: #4b5563 !important;
                        }
                        .dark .ql-container {
                            border-color: #4b5563 !important;
                        }
                        .dark .ql-stroke {
                            stroke: #e5e7eb !important;
                        }
                        .dark .ql-fill {
                            fill: #e5e7eb !important;
                        }
                        .dark .ql-picker {
                            color: #e5e7eb !important;
                        }
                        .dark .ql-picker-options {
                            background-color: #1f2937 !important;
                            border-color: #4b5563 !important;
                        }
                        .ql-editor {
                            min-height: 400px;
                            font-size: 0.875rem;
                        }
                        .dark .ql-editor {
                            color: #fff;
                        }
                    `}</style>
                    <ReactQuill
                        theme="snow"
                        value={content}
                        onChange={setContent}
                        modules={modules}
                        placeholder="Write Privacy Policy content here..."
                    />
                </div>
            </div>
        </>
    );
}
