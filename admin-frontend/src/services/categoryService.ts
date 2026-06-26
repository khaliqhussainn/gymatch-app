// Static data service for Category Management
export interface Category {
  id: string;
  name: string;
  slug: string;
  description: string;
  icon?: string;
  color: string;
  status: 'active' | 'inactive';
  createdAt: string;
}

export interface Tag {
  id: string;
  name: string;
  slug: string;
  category: string;
  status: 'active' | 'inactive';
}

export interface Amenity {
  id: string;
  name: string;
  icon: string;
  category: string;
  status: 'active' | 'inactive';
}

const staticCategories: Category[] = [
  {
    id: '1',
    name: 'Gym',
    slug: 'gym',
    description: 'Traditional fitness centers with cardio and strength equipment',
    icon: 'dumbbell',
    color: '#3B82F6',
    status: 'active',
    createdAt: '2024-01-01',
  },
  {
    id: '2',
    name: 'CrossFit',
    slug: 'crossfit',
    description: 'High-intensity functional training programs',
    icon: 'fire',
    color: '#EF4444',
    status: 'active',
    createdAt: '2024-01-01',
  },
  {
    id: '3',
    name: 'Yoga',
    slug: 'yoga',
    description: 'Yoga and meditation studios for mind-body wellness',
    icon: 'lotus',
    color: '#8B5CF6',
    status: 'active',
    createdAt: '2024-01-01',
  },
  {
    id: '4',
    name: 'MMA',
    slug: 'mma',
    description: 'Mixed martial arts and combat training centers',
    icon: 'fist',
    color: '#F59E0B',
    status: 'active',
    createdAt: '2024-01-01',
  },
  {
    id: '5',
    name: 'Women Only',
    slug: 'women-only',
    description: 'Exclusive fitness centers for women',
    icon: 'female',
    color: '#EC4899',
    status: 'active',
    createdAt: '2024-01-01',
  },
  {
    id: '6',
    name: 'Pilates',
    slug: 'pilates',
    description: 'Pilates studios for core strength and flexibility',
    icon: 'stretch',
    color: '#10B981',
    status: 'active',
    createdAt: '2024-01-01',
  },
];

const staticTags: Tag[] = [
  { id: '1', name: 'Cardio', slug: 'cardio', category: 'Gym', status: 'active' },
  { id: '2', name: 'Strength Training', slug: 'strength-training', category: 'Gym', status: 'active' },
  { id: '3', name: 'Personal Training', slug: 'personal-training', category: 'Gym', status: 'active' },
  { id: '4', name: 'HIIT', slug: 'hiit', category: 'CrossFit', status: 'active' },
  { id: '5', name: 'Group Classes', slug: 'group-classes', category: 'Gym', status: 'active' },
  { id: '6', name: 'CrossFit', slug: 'crossfit', category: 'CrossFit', status: 'active' },
  { id: '7', name: 'Yoga', slug: 'yoga', category: 'Yoga', status: 'active' },
  { id: '8', name: 'Meditation', slug: 'meditation', category: 'Yoga', status: 'active' },
  { id: '9', name: 'Wellness', slug: 'wellness', category: 'Yoga', status: 'active' },
  { id: '10', name: 'MMA', slug: 'mma', category: 'MMA', status: 'active' },
  { id: '11', name: 'BJJ', slug: 'bjj', category: 'MMA', status: 'active' },
  { id: '12', name: 'Muay Thai', slug: 'muay-thai', category: 'MMA', status: 'active' },
  { id: '13', name: 'Boxing', slug: 'boxing', category: 'MMA', status: 'active' },
  { id: '14', name: 'Bodybuilding', slug: 'bodybuilding', category: 'Gym', status: 'active' },
  { id: '15', name: 'Powerlifting', slug: 'powerlifting', category: 'Gym', status: 'active' },
  { id: '16', name: 'Pilates', slug: 'pilates', category: 'Pilates', status: 'active' },
  { id: '17', name: 'Flexibility', slug: 'flexibility', category: 'Yoga', status: 'active' },
  { id: '18', name: 'Weight Loss', slug: 'weight-loss', category: 'Gym', status: 'active' },
];

const staticAmenities: Amenity[] = [
  { id: '1', name: 'Parking', icon: 'parking', category: 'General', status: 'active' },
  { id: '2', name: 'Cardio Equipment', icon: 'cardio', category: 'Equipment', status: 'active' },
  { id: '3', name: 'Free Weights', icon: 'weights', category: 'Equipment', status: 'active' },
  { id: '4', name: 'Personal Training', icon: 'trainer', category: 'Services', status: 'active' },
  { id: '5', name: 'Showers', icon: 'shower', category: 'Facilities', status: 'active' },
  { id: '6', name: 'Lockers', icon: 'locker', category: 'Facilities', status: 'active' },
  { id: '7', name: 'Group Classes', icon: 'group', category: 'Services', status: 'active' },
  { id: '8', name: 'Sauna', icon: 'sauna', category: 'Facilities', status: 'active' },
  { id: '9', name: 'Pool', icon: 'pool', category: 'Facilities', status: 'active' },
  { id: '10', name: 'Cable Machines', icon: 'cable', category: 'Equipment', status: 'active' },
  { id: '11', name: 'Training Mats', icon: 'mat', category: 'Equipment', status: 'active' },
  { id: '12', name: 'Heavy Bags', icon: 'bag', category: 'Equipment', status: 'active' },
  { id: '13', name: 'Ring', icon: 'ring', category: 'Equipment', status: 'active' },
  { id: '14', name: 'Yoga Mats', icon: 'yoga-mat', category: 'Equipment', status: 'active' },
  { id: '15', name: 'Meditation Room', icon: 'meditation', category: 'Facilities', status: 'active' },
  { id: '16', name: 'CrossFit Equipment', icon: 'crossfit', category: 'Equipment', status: 'active' },
  { id: '17', name: 'Tennis Court', icon: 'tennis', category: 'Facilities', status: 'active' },
  { id: '18', name: 'Basketball Court', icon: 'basketball', category: 'Facilities', status: 'active' },
  { id: '19', name: 'Nutrition Counseling', icon: 'nutrition', category: 'Services', status: 'active' },
  { id: '20', name: 'Massage Therapy', icon: 'massage', category: 'Services', status: 'active' },
];

export const categoryService = {
  // Categories
  getAllCategories: (): Category[] => {
    return staticCategories;
  },

  getCategoryById: (id: string): Category | undefined => {
    return staticCategories.find(cat => cat.id === id);
  },

  addCategory: (category: Omit<Category, 'id' | 'createdAt'>): Category => {
    const newCategory: Category = {
      ...category,
      id: (staticCategories.length + 1).toString(),
      createdAt: new Date().toISOString().split('T')[0],
    };
    staticCategories.push(newCategory);
    return newCategory;
  },

  updateCategory: (id: string, updates: Partial<Category>): Category | null => {
    const index = staticCategories.findIndex(cat => cat.id === id);
    if (index !== -1) {
      staticCategories[index] = { ...staticCategories[index], ...updates };
      return staticCategories[index];
    }
    return null;
  },

  deleteCategory: (id: string): boolean => {
    const index = staticCategories.findIndex(cat => cat.id === id);
    if (index !== -1) {
      staticCategories.splice(index, 1);
      return true;
    }
    return false;
  },

  // Tags
  getAllTags: (): Tag[] => {
    return staticTags;
  },

  getTagsByCategory: (category: string): Tag[] => {
    return staticTags.filter(tag => tag.category === category);
  },

  addTag: (tag: Omit<Tag, 'id'>): Tag => {
    const newTag: Tag = {
      ...tag,
      id: (staticTags.length + 1).toString(),
    };
    staticTags.push(newTag);
    return newTag;
  },

  updateTag: (id: string, updates: Partial<Tag>): Tag | null => {
    const index = staticTags.findIndex(tag => tag.id === id);
    if (index !== -1) {
      staticTags[index] = { ...staticTags[index], ...updates };
      return staticTags[index];
    }
    return null;
  },

  deleteTag: (id: string): boolean => {
    const index = staticTags.findIndex(tag => tag.id === id);
    if (index !== -1) {
      staticTags.splice(index, 1);
      return true;
    }
    return false;
  },

  // Amenities
  getAllAmenities: (): Amenity[] => {
    return staticAmenities;
  },

  getAmenitiesByCategory: (category: string): Amenity[] => {
    return staticAmenities.filter(amenity => amenity.category === category);
  },

  addAmenity: (amenity: Omit<Amenity, 'id'>): Amenity => {
    const newAmenity: Amenity = {
      ...amenity,
      id: (staticAmenities.length + 1).toString(),
    };
    staticAmenities.push(newAmenity);
    return newAmenity;
  },

  updateAmenity: (id: string, updates: Partial<Amenity>): Amenity | null => {
    const index = staticAmenities.findIndex(amenity => amenity.id === id);
    if (index !== -1) {
      staticAmenities[index] = { ...staticAmenities[index], ...updates };
      return staticAmenities[index];
    }
    return null;
  },

  deleteAmenity: (id: string): boolean => {
    const index = staticAmenities.findIndex(amenity => amenity.id === id);
    if (index !== -1) {
      staticAmenities.splice(index, 1);
      return true;
    }
    return false;
  },
};
