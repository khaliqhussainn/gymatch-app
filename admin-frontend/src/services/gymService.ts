// Static data service for Gym Management
export interface Gym {
  id: string;
  name: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  latitude: number;
  longitude: number;
  phone: string;
  email: string;
  website?: string;
  description: string;
  category: string;
  tags: string[];
  amenities: string[];
  images: string[];
  rating: number;
  totalReviews: number;
  isOpen: boolean;
  openingHours: {
    monday: string;
    tuesday: string;
    wednesday: string;
    thursday: string;
    friday: string;
    saturday: string;
    sunday: string;
  };
  priceRange: string;
  featured: boolean;
  status: 'active' | 'inactive' | 'pending';
  createdAt: string;
  viewCount: number;
}

const staticGyms: Gym[] = [
  {
    id: '1',
    name: 'FitZone Gym',
    address: '123 Main Street',
    city: 'Los Angeles',
    state: 'CA',
    zipCode: '90001',
    latitude: 34.0522,
    longitude: -118.2437,
    phone: '+1 (555) 123-4567',
    email: 'contact@fitzone.com',
    website: 'https://fitzone.com',
    description: 'Premium fitness center with state-of-the-art equipment and personal training services.',
    category: 'Gym',
    tags: ['Cardio', 'Strength Training', 'Personal Training'],
    amenities: ['Parking', 'Cardio Equipment', 'Free Weights', 'Personal Training', 'Showers', 'Lockers'],
    images: ['gym1.jpg', 'gym2.jpg'],
    rating: 4.5,
    totalReviews: 128,
    isOpen: true,
    openingHours: {
      monday: '5:00 AM - 11:00 PM',
      tuesday: '5:00 AM - 11:00 PM',
      wednesday: '5:00 AM - 11:00 PM',
      thursday: '5:00 AM - 11:00 PM',
      friday: '5:00 AM - 11:00 PM',
      saturday: '6:00 AM - 10:00 PM',
      sunday: '7:00 AM - 9:00 PM',
    },
    priceRange: '$$',
    featured: true,
    status: 'active',
    createdAt: '2024-01-15',
    viewCount: 1520,
  },
  {
    id: '2',
    name: 'PowerHouse CrossFit',
    address: '456 Fitness Blvd',
    city: 'Los Angeles',
    state: 'CA',
    zipCode: '90002',
    latitude: 34.0522,
    longitude: -118.2537,
    phone: '+1 (555) 234-5678',
    email: 'info@powerhousecrossfit.com',
    description: 'High-intensity CrossFit training with experienced coaches and community atmosphere.',
    category: 'CrossFit',
    tags: ['CrossFit', 'HIIT', 'Group Classes'],
    amenities: ['Parking', 'CrossFit Equipment', 'Showers', 'Lockers', 'Group Classes'],
    images: ['crossfit1.jpg'],
    rating: 4.8,
    totalReviews: 95,
    isOpen: true,
    openingHours: {
      monday: '6:00 AM - 8:00 PM',
      tuesday: '6:00 AM - 8:00 PM',
      wednesday: '6:00 AM - 8:00 PM',
      thursday: '6:00 AM - 8:00 PM',
      friday: '6:00 AM - 8:00 PM',
      saturday: '8:00 AM - 6:00 PM',
      sunday: '9:00 AM - 4:00 PM',
    },
    priceRange: '$$$',
    featured: true,
    status: 'active',
    createdAt: '2024-02-01',
    viewCount: 980,
  },
  {
    id: '3',
    name: 'Zen Yoga Studio',
    address: '789 Wellness Way',
    city: 'Los Angeles',
    state: 'CA',
    zipCode: '90003',
    latitude: 34.0422,
    longitude: -118.2337,
    phone: '+1 (555) 345-6789',
    email: 'hello@zenyoga.com',
    description: 'Peaceful yoga studio offering various yoga styles and meditation classes.',
    category: 'Yoga',
    tags: ['Yoga', 'Meditation', 'Wellness'],
    amenities: ['Parking', 'Yoga Mats', 'Meditation Room', 'Showers'],
    images: ['yoga1.jpg', 'yoga2.jpg'],
    rating: 4.9,
    totalReviews: 156,
    isOpen: true,
    openingHours: {
      monday: '6:00 AM - 9:00 PM',
      tuesday: '6:00 AM - 9:00 PM',
      wednesday: '6:00 AM - 9:00 PM',
      thursday: '6:00 AM - 9:00 PM',
      friday: '6:00 AM - 9:00 PM',
      saturday: '7:00 AM - 8:00 PM',
      sunday: '8:00 AM - 7:00 PM',
    },
    priceRange: '$$',
    featured: false,
    status: 'active',
    createdAt: '2024-01-20',
    viewCount: 750,
  },
  {
    id: '4',
    name: 'Iron Paradise',
    address: '321 Muscle Lane',
    city: 'Los Angeles',
    state: 'CA',
    zipCode: '90004',
    latitude: 34.0622,
    longitude: -118.2637,
    phone: '+1 (555) 456-7890',
    email: 'info@ironparadise.com',
    description: 'Hardcore bodybuilding gym with extensive free weights and resistance equipment.',
    category: 'Gym',
    tags: ['Bodybuilding', 'Powerlifting', 'Strength Training'],
    amenities: ['Parking', 'Free Weights', 'Cable Machines', 'Showers', 'Lockers'],
    images: ['iron1.jpg'],
    rating: 4.3,
    totalReviews: 89,
    isOpen: true,
    openingHours: {
      monday: '5:00 AM - 12:00 AM',
      tuesday: '5:00 AM - 12:00 AM',
      wednesday: '5:00 AM - 12:00 AM',
      thursday: '5:00 AM - 12:00 AM',
      friday: '5:00 AM - 12:00 AM',
      saturday: '6:00 AM - 11:00 PM',
      sunday: '7:00 AM - 10:00 PM',
    },
    priceRange: '$',
    featured: false,
    status: 'active',
    createdAt: '2024-03-10',
    viewCount: 620,
  },
  {
    id: '5',
    name: 'Women Only Fitness',
    address: '555 Empowerment Ave',
    city: 'Los Angeles',
    state: 'CA',
    zipCode: '90005',
    latitude: 34.0322,
    longitude: -118.2737,
    phone: '+1 (555) 567-8901',
    email: 'info@womenonlyfitness.com',
    description: 'Exclusive women-only gym with supportive environment and specialized equipment.',
    category: 'Women Only',
    tags: ['Women Only', 'Cardio', 'Group Classes'],
    amenities: ['Parking', 'Cardio Equipment', 'Strength Training', 'Group Classes', 'Showers', 'Lockers'],
    images: ['women1.jpg'],
    rating: 4.7,
    totalReviews: 112,
    isOpen: true,
    openingHours: {
      monday: '6:00 AM - 10:00 PM',
      tuesday: '6:00 AM - 10:00 PM',
      wednesday: '6:00 AM - 10:00 PM',
      thursday: '6:00 AM - 10:00 PM',
      friday: '6:00 AM - 10:00 PM',
      saturday: '7:00 AM - 9:00 PM',
      sunday: '8:00 AM - 8:00 PM',
    },
    priceRange: '$$',
    featured: true,
    status: 'active',
    createdAt: '2024-02-15',
    viewCount: 890,
  },
  {
    id: '6',
    name: 'Elite MMA Center',
    address: '888 Combat Street',
    city: 'Los Angeles',
    state: 'CA',
    zipCode: '90006',
    latitude: 34.0722,
    longitude: -118.2837,
    phone: '+1 (555) 678-9012',
    email: 'contact@elitemma.com',
    description: 'Mixed martial arts training center with expert instructors in various disciplines.',
    category: 'MMA',
    tags: ['MMA', 'BJJ', 'Muay Thai', 'Boxing'],
    amenities: ['Parking', 'Training Mats', 'Heavy Bags', 'Ring', 'Showers'],
    images: ['mma1.jpg', 'mma2.jpg'],
    rating: 4.6,
    totalReviews: 78,
    isOpen: true,
    openingHours: {
      monday: '7:00 AM - 10:00 PM',
      tuesday: '7:00 AM - 10:00 PM',
      wednesday: '7:00 AM - 10:00 PM',
      thursday: '7:00 AM - 10:00 PM',
      friday: '7:00 AM - 10:00 PM',
      saturday: '8:00 AM - 8:00 PM',
      sunday: '9:00 AM - 6:00 PM',
    },
    priceRange: '$$$',
    featured: false,
    status: 'active',
    createdAt: '2024-03-01',
    viewCount: 540,
  },
];

export const gymService = {
  getAllGyms: (): Gym[] => {
    return staticGyms;
  },

  getGymById: (id: string): Gym | undefined => {
    return staticGyms.find(gym => gym.id === id);
  },

  getFeaturedGyms: (): Gym[] => {
    return staticGyms.filter(gym => gym.featured);
  },

  getGymsByCategory: (category: string): Gym[] => {
    return staticGyms.filter(gym => gym.category === category);
  },

  addGym: (gym: Omit<Gym, 'id' | 'createdAt' | 'viewCount'>): Gym => {
    const newGym: Gym = {
      ...gym,
      id: (staticGyms.length + 1).toString(),
      createdAt: new Date().toISOString().split('T')[0],
      viewCount: 0,
    };
    staticGyms.push(newGym);
    return newGym;
  },

  updateGym: (id: string, updates: Partial<Gym>): Gym | null => {
    const index = staticGyms.findIndex(gym => gym.id === id);
    if (index !== -1) {
      staticGyms[index] = { ...staticGyms[index], ...updates };
      return staticGyms[index];
    }
    return null;
  },

  deleteGym: (id: string): boolean => {
    const index = staticGyms.findIndex(gym => gym.id === id);
    if (index !== -1) {
      staticGyms.splice(index, 1);
      return true;
    }
    return false;
  },

  getMostViewedGyms: (limit: number = 5): Gym[] => {
    return [...staticGyms].sort((a, b) => b.viewCount - a.viewCount).slice(0, limit);
  },

  getTotalGymsCount: (): number => {
    return staticGyms.length;
  },
};
