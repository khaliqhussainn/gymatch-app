import PageMeta from "../../components/common/PageMeta";
import RepairRequestForm from "./components/RepairRequestForm";
import RepairRequestList from "./components/RepairRequestList";
import { useState } from "react";

export default function RepairRequestPage() {
    const [refreshKey, setRefreshKey] = useState(0);

    const handleSuccess = () => {
        setRefreshKey((prev) => prev + 1);
    };

    return (
        <>
            <PageMeta title="Repair Requests | Property Management" description="Report and track maintenance issues." />
            <div className="p-6 max-w-7xl mx-auto space-y-8">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h1 className="text-3xl font-bold dark:text-white">Maintenance & Repairs</h1>
                        <p className="text-gray-500 dark:text-gray-400">Report an issue and we'll fix it for you.</p>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                    <div className="lg:col-span-1">
                        <RepairRequestForm onSuccess={handleSuccess} />
                    </div>
                    <div className="lg:col-span-2">
                        <RepairRequestList key={refreshKey} />
                    </div>
                </div>
            </div>
        </>
    );
}
