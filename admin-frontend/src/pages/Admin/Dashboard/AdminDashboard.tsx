import { useEffect, useState } from 'react';
import PageMeta from "../../../components/common/PageMeta";
import {
    GroupIcon,
    BoxIconLine,
    TaskIcon,
    CalenderIcon
} from "../../../icons";
import Chart from "react-apexcharts";
import { ApexOptions } from "apexcharts";
import { dashboardApiService, DashboardStats } from "../../../services/dashboardApiService";
import toast from "react-hot-toast";

export default function AdminDashboard() {
    const [stats, setStats] = useState<DashboardStats | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const data = await dashboardApiService.getDashboardStats();
                setStats(data);
            } catch (error) {
                console.error("Failed to fetch admin stats:", error);
                toast.error('Failed to load dashboard stats');
            } finally {
                setLoading(false);
            }
        };
        fetchStats();
    }, []);

    const chartOptions: ApexOptions = {
        chart: {
            fontFamily: "Outfit, sans-serif",
            type: "area",
            height: 350,
            toolbar: { show: false },
            zoom: { enabled: false },
        },
        colors: ["#465FFF", "#9CB9FF", "#FDBA74"],
        dataLabels: { enabled: false },
        stroke: { curve: "smooth", width: 3 },
        fill: {
            type: "gradient",
            gradient: {
                shadeIntensity: 1,
                opacityFrom: 0.45,
                opacityTo: 0.05,
                stops: [0, 100],
            },
        },
        grid: {
            borderColor: "#E5E7EB",
            strokeDashArray: 3,
            xaxis: { lines: { show: false } },
            yaxis: { lines: { show: true } },
        },
        xaxis: {
            categories: stats?.monthly_trends.map((t: any) => t.month) || [],
            axisBorder: { show: false },
            axisTicks: { show: false },
        },
        yaxis: {
            labels: {
                style: { colors: "#6B7280" },
            },
        },
        legend: {
            position: "top",
            horizontalAlign: "right",
        },
    };

    const chartSeries = [
        {
            name: "Gyms",
            data: stats?.monthly_trends.map((t: any) => t.gyms) || [],
        },
        {
            name: "Users",
            data: stats?.monthly_trends.map((t: any) => t.users) || [],
        },
    ];

    return (
        <>
            <PageMeta
                title="Admin Dashboard | GYMatch"
                description="Admin Dashboard Overview"
            />
            <div className={`p-1 space-y-6 ${loading ? 'opacity-50' : ''}`}>
                <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-800 dark:text-white">GYMatch Admin Dashboard</h1>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Welcome back! Here's what's happening with GYMatch today.</p>
                    </div>
                    <div className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
                        <CalenderIcon className="size-5 text-gray-500" />
                        <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                            {new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                        </span>
                    </div>
                </div>

                {/* Metrics Grid */}
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4 lg:gap-6">
                    {/* Total Gyms */}
                    <div className="bg-white dark:bg-gray-800/50 p-6 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 transition-all hover:shadow-md">
                        <div className="flex items-center justify-between">
                            <div className="w-12 h-12 bg-blue-50 dark:bg-blue-900/20 rounded-xl flex items-center justify-center">
                                <BoxIconLine className="text-blue-600 size-6" />
                            </div>
                            <span className="text-xs font-medium text-green-600 bg-green-50 dark:bg-green-900/20 px-2 py-1 rounded-full">+12%</span>
                        </div>
                        <div className="mt-4">
                            <h3 className="text-2xl font-bold text-gray-800 dark:text-white">{stats?.totalGyms || 0}</h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400">Total Gyms</p>
                        </div>
                    </div>

                    {/* Total Users */}
                    <div className="bg-white dark:bg-gray-800/50 p-6 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 transition-all hover:shadow-md">
                        <div className="flex items-center justify-between">
                            <div className="w-12 h-12 bg-orange-50 dark:bg-orange-900/20 rounded-xl flex items-center justify-center">
                                <GroupIcon className="text-orange-600 size-6" />
                            </div>
                            <span className="text-xs font-medium text-green-600 bg-green-50 dark:bg-green-900/20 px-2 py-1 rounded-full">+8%</span>
                        </div>
                        <div className="mt-4">
                            <h3 className="text-2xl font-bold text-gray-800 dark:text-white">{stats?.totalUsers || 0}</h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400">Total Users</p>
                        </div>
                    </div>

                    {/* Active Users */}
                    <div className="bg-white dark:bg-gray-800/50 p-6 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 transition-all hover:shadow-md">
                        <div className="flex items-center justify-between">
                            <div className="w-12 h-12 bg-green-50 dark:bg-green-900/20 rounded-xl flex items-center justify-center">
                                <GroupIcon className="text-green-600 size-6" />
                            </div>
                            <span className="text-xs font-medium text-green-600 bg-green-50 dark:bg-green-900/20 px-2 py-1 rounded-full">Active</span>
                        </div>
                        <div className="mt-4">
                            <h3 className="text-2xl font-bold text-gray-800 dark:text-white">{stats?.activeUsers || 0}</h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400">Active Users</p>
                        </div>
                    </div>

                    {/* Most Viewed Gyms */}
                    <div className="bg-white dark:bg-gray-800/50 p-6 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 transition-all hover:shadow-md">
                        <div className="flex items-center justify-between">
                            <div className="w-12 h-12 bg-purple-50 dark:bg-purple-900/20 rounded-xl flex items-center justify-center">
                                <TaskIcon className="text-purple-600 size-6" />
                            </div>
                            <span className="text-xs font-medium text-blue-600 bg-blue-50 dark:bg-blue-900/20 px-2 py-1 rounded-full">Top 5</span>
                        </div>
                        <div className="mt-4">
                            <h3 className="text-2xl font-bold text-gray-800 dark:text-white">{stats?.mostViewedGyms?.[0]?.viewCount || 0}</h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400">Top Gym Views</p>
                        </div>
                    </div>
                </div>

                {/* Charts and Activity */}
                <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
                    <div className="lg:col-span-8 bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700">
                        <div className="mb-4">
                            <h3 className="text-lg font-bold text-gray-800 dark:text-white">Platform Growth</h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400">Monthly trends for gyms and users</p>
                        </div>
                        <div className="h-[350px]">
                            {stats && (
                                <Chart options={chartOptions} series={chartSeries} type="area" height="100%" />
                            )}
                        </div>
                    </div>

                    <div className="lg:col-span-4 space-y-6">
                        <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700">
                            <h3 className="text-lg font-bold text-gray-800 dark:text-white mb-4">Quick Actions</h3>
                            <div className="space-y-3">
                                <a href="/gyms" className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors group">
                                    <div className="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center group-hover:bg-blue-600 transition-colors">
                                        <BoxIconLine className="size-5 text-blue-600 group-hover:text-white transition-colors" />
                                    </div>
                                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Manage Gyms</span>
                                </a>
                                <a href="/users" className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-green-50 dark:hover:bg-green-900/20 transition-colors group">
                                    <div className="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center group-hover:bg-green-600 transition-colors">
                                        <GroupIcon className="size-5 text-green-600 group-hover:text-white transition-colors" />
                                    </div>
                                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Manage Users</span>
                                </a>
                                <a href="/categories/gyms" className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-colors group">
                                    <div className="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center group-hover:bg-purple-600 transition-colors">
                                        <TaskIcon className="size-5 text-purple-600 group-hover:text-white transition-colors" />
                                    </div>
                                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Gym Categories</span>
                                </a>
                                <a href="/categories/tags" className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-orange-50 dark:hover:bg-orange-900/20 transition-colors group">
                                    <div className="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center group-hover:bg-orange-600 transition-colors">
                                        <TaskIcon className="size-5 text-orange-600 group-hover:text-white transition-colors" />
                                    </div>
                                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Manage Tags</span>
                                </a>
                                <a href="/categories/amenities" className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors group">
                                    <div className="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center group-hover:bg-red-600 transition-colors">
                                        <TaskIcon className="size-5 text-red-600 group-hover:text-white transition-colors" />
                                    </div>
                                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Manage Amenities</span>
                                </a>
                            </div>
                        </div>

                        {/* <div className="bg-gradient-to-br from-blue-600 to-indigo-700 p-6 rounded-2xl shadow-lg relative overflow-hidden">
                            <div className="relative z-10">
                                <h3 className="text-lg font-bold text-white mb-2">Platform Status</h3>
                                <p className="text-blue-100 text-sm mb-4">Everything is running smoothly. 0 major issues reported in the last 24 hours.</p>
                                <button className="px-4 py-2 bg-white text-blue-600 rounded-lg text-sm font-bold shadow-sm hover:bg-blue-50 transition-colors">
                                    Check System Health
                                </button>
                            </div>
                            <div className="absolute top-[-20px] right-[-20px] w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
                            <div className="absolute bottom-[-20px] left-[-20px] w-24 h-24 bg-white/10 rounded-full blur-xl"></div>
                        </div> */}
                    </div>
                </div>
            </div>
        </>
    );
}
