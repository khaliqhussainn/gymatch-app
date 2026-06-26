import React, { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import PageMeta from "../components/common/PageMeta";
import UserMetaCard from "../components/UserProfile/UserMetaCard";
import UserInfoCard from "../components/UserProfile/UserInfoCard";
import PageBreadcrumb from "../components/common/PageBreadCrumb";

export default function UserProfiles() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const token = localStorage.getItem('token');
        const res = await fetch(`${import.meta.env.VITE_API_URL}/user/profile`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await res.json();
        if (data.success) {
          setUser(data.data);
        }
      } catch (error) {
        console.error(error);
        toast.error("Failed to fetch profile");
      } finally {
        setLoading(false);
      }
    };
    fetchProfile();
  }, []);

  const handleUpdate = async (updatedData: any) => {
    try {
      const token = localStorage.getItem('token');
      const formData = new FormData();
      Object.keys(updatedData).forEach(key => {
        formData.append(key, updatedData[key]);
      });

      const res = await fetch(`${import.meta.env.VITE_API_URL}/user/profile`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`
        },
        body: formData
      });
      const data = await res.json();
      if (data.success) {
        setUser(data.user);
        localStorage.setItem('user', JSON.stringify(data.user));
        window.dispatchEvent(new Event('profileUpdate'));
        toast.success(data.message || "Profile Updated");
      } else {
        toast.error(data.message || "Update failed");
      }
    } catch (error) {
      console.error(error);
      toast.error("Network error");
    }
  }

  if (loading) return <div className="p-6 text-center">Loading Profile...</div>;
  if (!user) return <div className="p-6 text-center text-red-500">User not found</div>;

  return (
    <>
      <PageMeta
        title="Profile | Property Management"
        description="Manage your profile settings"
      />
      <PageBreadcrumb pageTitle="Profile" />
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] lg:p-6">
        <h3 className="mb-5 text-lg font-semibold text-gray-800 dark:text-white/90 lg:mb-7">
          Profile Settings
        </h3>
        <div className="space-y-6">
          <UserMetaCard user={user} onUpdate={handleUpdate} />
          <UserInfoCard user={user} onUpdate={handleUpdate} />

          {/* {user?.role === 'admin' && (
            <div className="p-5 bg-white border border-gray-200 rounded-2xl dark:border-gray-800 dark:bg-white/[0.03]">
              <h3 className="mb-4 text-lg font-semibold text-gray-800 dark:text-white/90">Notification Test</h3>
              <button
                onClick={async () => {
                  try {
                    const token = localStorage.getItem('token');
                    const res = await fetch(`${import.meta.env.VITE_API_URL}/admin/test-notification`, {
                      method: 'POST',
                      headers: { Authorization: `Bearer ${token}` }
                    });
                    const data = await res.json();
                    if (data.success) toast.success("Notification sent! Check your device.");
                    else toast.error(data.message || "Failed to send");
                  } catch (e) {
                    toast.error("Error sending notification");
                  }
                }}
                className="px-4 py-2 font-medium text-white transition-colors bg-brand-500 rounded-lg hover:bg-brand-600"
              >
                Send Test Notification 🔔
              </button>
            </div>
          )} */}
        </div>
      </div>
    </>
  );
}
