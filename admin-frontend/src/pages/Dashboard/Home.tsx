import { useEffect, useState } from "react";
import EcommerceMetrics from "../../components/ecommerce/EcommerceMetrics";
import StatisticsChart from "../../components/ecommerce/StatisticsChart";
import MonthlyTarget from "../../components/ecommerce/MonthlyTarget";
import RecentOrders from "../../components/ecommerce/RecentOrders";
import DemographicCard from "../../components/ecommerce/DemographicCard";
import PageMeta from "../../components/common/PageMeta";

export default function Home() {
  const [stats, setStats] = useState<any>(null);

  useEffect(() => {
    const userData = localStorage.getItem('user');
    if (userData) {
      const parsedUser = JSON.parse(userData);


      if (parsedUser.role === 'admin') {
        const fetchAdminStats = async () => {
          try {
            const token = localStorage.getItem('token');
            const res = await fetch(`${import.meta.env.VITE_API_URL}/dashboard/admin-stats`, {
              headers: { Authorization: `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
              setStats(data.data);
            }
          } catch (error) {
            console.error("Failed to fetch admin stats:", error);
          }
        };
        fetchAdminStats();
      }
    }
  }, []);

  return (
    <>
      <PageMeta
        title="Admin Dashboard | Property Management"
        description="Property Management Admin Dashboard"
      />
      <div className="grid grid-cols-12 gap-4 md:gap-6">
        <div className="col-span-12 space-y-6">
          <EcommerceMetrics stats={stats} />

          <div className="grid grid-cols-12 gap-4 md:gap-6">
            <div className="col-span-12 xl:col-span-7">
              <StatisticsChart />
            </div>
            <div className="col-span-12 xl:col-span-5">
              <MonthlyTarget />
            </div>
          </div>
        </div>

        <div className="col-span-12 xl:col-span-7">
          <RecentOrders />
        </div>

        <div className="col-span-12 xl:col-span-5">
          <DemographicCard />
        </div>
      </div>
    </>
  );
}
