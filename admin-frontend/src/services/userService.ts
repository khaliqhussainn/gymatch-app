// Static data service for User Management
export interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  avatar?: string;
  role: 'guest' | 'registered' | 'admin';
  status: 'active' | 'suspended' | 'pending';
  createdAt: string;
  lastActive: string;
  profile: {
    age?: number;
    gender?: 'male' | 'female' | 'other';
    fitnessGoals: string[];
    workoutPreferences: string[];
    experienceLevel: 'beginner' | 'intermediate' | 'advanced';
    preferredGyms: string[];
  };
  location?: {
    city: string;
    state: string;
    country: string;
  };
  stats: {
    totalConnections: number;
    totalWorkouts: number;
    totalInvitationsSent: number;
    totalInvitationsReceived: number;
  };
}

const staticUsers: User[] = [
  {
    id: '1',
    name: 'John Smith',
    email: 'john.smith@email.com',
    phone: '+1 (555) 111-2222',
    avatar: 'user1.jpg',
    role: 'registered',
    status: 'active',
    createdAt: '2024-01-10',
    lastActive: '2024-06-25',
    profile: {
      age: 28,
      gender: 'male',
      fitnessGoals: ['Weight Loss', 'Muscle Gain'],
      workoutPreferences: ['Cardio', 'Strength Training'],
      experienceLevel: 'intermediate',
      preferredGyms: ['1', '4'],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 12,
      totalWorkouts: 45,
      totalInvitationsSent: 8,
      totalInvitationsReceived: 15,
    },
  },
  {
    id: '2',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@email.com',
    phone: '+1 (555) 222-3333',
    avatar: 'user2.jpg',
    role: 'registered',
    status: 'active',
    createdAt: '2024-01-15',
    lastActive: '2024-06-24',
    profile: {
      age: 25,
      gender: 'female',
      fitnessGoals: ['Flexibility', 'Stress Relief'],
      workoutPreferences: ['Yoga', 'Meditation'],
      experienceLevel: 'beginner',
      preferredGyms: ['3'],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 8,
      totalWorkouts: 32,
      totalInvitationsSent: 5,
      totalInvitationsReceived: 10,
    },
  },
  {
    id: '3',
    name: 'Mike Davis',
    email: 'mike.davis@email.com',
    phone: '+1 (555) 333-4444',
    avatar: 'user3.jpg',
    role: 'registered',
    status: 'active',
    createdAt: '2024-02-01',
    lastActive: '2024-06-25',
    profile: {
      age: 32,
      gender: 'male',
      fitnessGoals: ['Strength', 'Competition Prep'],
      workoutPreferences: ['CrossFit', 'Powerlifting'],
      experienceLevel: 'advanced',
      preferredGyms: ['2', '4'],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 20,
      totalWorkouts: 78,
      totalInvitationsSent: 15,
      totalInvitationsReceived: 22,
    },
  },
  {
    id: '4',
    name: 'Emily Brown',
    email: 'emily.brown@email.com',
    phone: '+1 (555) 444-5555',
    avatar: 'user4.jpg',
    role: 'registered',
    status: 'active',
    createdAt: '2024-02-10',
    lastActive: '2024-06-23',
    profile: {
      age: 29,
      gender: 'female',
      fitnessGoals: ['Weight Loss', 'Toning'],
      workoutPreferences: ['Cardio', 'Group Classes'],
      experienceLevel: 'intermediate',
      preferredGyms: ['5'],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 15,
      totalWorkouts: 56,
      totalInvitationsSent: 12,
      totalInvitationsReceived: 18,
    },
  },
  {
    id: '5',
    name: 'Alex Wilson',
    email: 'alex.wilson@email.com',
    phone: '+1 (555) 555-6666',
    avatar: 'user5.jpg',
    role: 'registered',
    status: 'suspended',
    createdAt: '2024-03-01',
    lastActive: '2024-06-10',
    profile: {
      age: 35,
      gender: 'male',
      fitnessGoals: ['Self Defense', 'Fitness'],
      workoutPreferences: ['MMA', 'BJJ'],
      experienceLevel: 'intermediate',
      preferredGyms: ['6'],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 5,
      totalWorkouts: 18,
      totalInvitationsSent: 3,
      totalInvitationsReceived: 7,
    },
  },
  {
    id: '6',
    name: 'Guest User',
    email: 'guest@email.com',
    phone: '+1 (555) 666-7777',
    role: 'guest',
    status: 'active',
    createdAt: '2024-06-20',
    lastActive: '2024-06-25',
    profile: {
      age: undefined,
      gender: undefined,
      fitnessGoals: [],
      workoutPreferences: [],
      experienceLevel: 'beginner',
      preferredGyms: [],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 0,
      totalWorkouts: 0,
      totalInvitationsSent: 0,
      totalInvitationsReceived: 0,
    },
  },
  {
    id: '7',
    name: 'Admin User',
    email: 'admin@gymatch.com',
    phone: '+1 (555) 777-8888',
    avatar: 'admin.jpg',
    role: 'admin',
    status: 'active',
    createdAt: '2024-01-01',
    lastActive: '2024-06-25',
    profile: {
      age: 40,
      gender: 'male',
      fitnessGoals: ['General Fitness'],
      workoutPreferences: ['All'],
      experienceLevel: 'advanced',
      preferredGyms: [],
    },
    location: {
      city: 'Los Angeles',
      state: 'CA',
      country: 'USA',
    },
    stats: {
      totalConnections: 0,
      totalWorkouts: 0,
      totalInvitationsSent: 0,
      totalInvitationsReceived: 0,
    },
  },
];

export const userService = {
  getAllUsers: (): User[] => {
    return staticUsers;
  },

  getUserById: (id: string): User | undefined => {
    return staticUsers.find(user => user.id === id);
  },

  getUsersByRole: (role: User['role']): User[] => {
    return staticUsers.filter(user => user.role === role);
  },

  getUsersByStatus: (status: User['status']): User[] => {
    return staticUsers.filter(user => user.status === status);
  },

  getActiveUsers: (): User[] => {
    return staticUsers.filter(user => user.status === 'active');
  },

  suspendUser: (id: string): User | null => {
    const index = staticUsers.findIndex(user => user.id === id);
    if (index !== -1) {
      staticUsers[index].status = 'suspended';
      return staticUsers[index];
    }
    return null;
  },

  activateUser: (id: string): User | null => {
    const index = staticUsers.findIndex(user => user.id === id);
    if (index !== -1) {
      staticUsers[index].status = 'active';
      return staticUsers[index];
    }
    return null;
  },

  updateUser: (id: string, updates: Partial<User>): User | null => {
    const index = staticUsers.findIndex(user => user.id === id);
    if (index !== -1) {
      staticUsers[index] = { ...staticUsers[index], ...updates };
      return staticUsers[index];
    }
    return null;
  },

  deleteUser: (id: string): boolean => {
    const index = staticUsers.findIndex(user => user.id === id);
    if (index !== -1) {
      staticUsers.splice(index, 1);
      return true;
    }
    return false;
  },

  getTotalUsersCount: (): number => {
    return staticUsers.length;
  },

  getActiveUsersCount: (): number => {
    return staticUsers.filter(user => user.status === 'active').length;
  },

  getRegisteredUsersCount: (): number => {
    return staticUsers.filter(user => user.role === 'registered').length;
  },
};
