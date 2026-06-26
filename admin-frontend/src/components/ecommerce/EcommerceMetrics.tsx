import {
  GroupIcon,
  BoxIconLine,
  ChatIcon,
} from "../../icons";

interface EcommerceMetricsProps {
  stats?: {
    users: {
      residents: number;
      property_managers: number;
      vendors: number;
    };
    total_contacts: number;
  };
}

export default function EcommerceMetrics({ stats }: EcommerceMetricsProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4 md:gap-6">
      {/* Residents */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-blue-50 rounded-xl dark:bg-blue-500/10">
          <GroupIcon className="text-blue-600 size-6 dark:text-blue-500" />
        </div>
        <div className="mt-5">
          <span className="text-sm text-gray-500 dark:text-gray-400">Total Residents</span>
          <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
            {stats?.users.residents || 0}
          </h4>
        </div>
      </div>

      {/* Vendors */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-orange-50 rounded-xl dark:bg-orange-500/10">
          <BoxIconLine className="text-orange-600 size-6 dark:orange-500" />
        </div>
        <div className="mt-5">
          <span className="text-sm text-gray-500 dark:text-gray-400">Total Vendors</span>
          <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
            {stats?.users.vendors || 0}
          </h4>
        </div>
      </div>

      {/* Contacts */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-green-50 rounded-xl dark:bg-green-500/10">
          <ChatIcon className="text-green-600 size-6 dark:text-green-500" />
        </div>
        <div className="mt-5">
          <span className="text-sm text-gray-500 dark:text-gray-400">Contact Inquiries</span>
          <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
            {stats?.total_contacts || 0}
          </h4>
        </div>
      </div>

      {/* Property Managers */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-purple-50 rounded-xl dark:bg-purple-500/10">
          <GroupIcon className="text-purple-600 size-6 dark:text-purple-500" />
        </div>
        <div className="mt-5">
          <span className="text-sm text-gray-500 dark:text-gray-400">Property Managers</span>
          <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
            {stats?.users.property_managers || 0}
          </h4>
        </div>
      </div>
    </div>
  );
}
