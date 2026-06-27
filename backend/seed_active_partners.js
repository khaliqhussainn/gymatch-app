const pool = require('./config/connection');

const locations = {
  california: [7, 8, 16, 17, 22, 23],
  brazil: [9, 10, 18, 19, 24, 25],
  washington: [11, 12, 13, 20, 21, 26, 27],
  toronto: [28, 29, 30, 31],
  karachi: [1, 2, 14]
};

const workoutTypes = ['CrossFit', 'Yoga', 'Strength Training', 'MMA', 'Boxing', 'Cardio', 'HIIT', 'Bodybuilding', 'Pilates', 'Spinning'];
const experienceLevels = ['Beginner', 'Intermediate', 'Advanced'];

async function seedActivePartners() {
  try {
    console.log('Starting to seed active partners...');
    
    // Get available users (excluding guest and null names)
    const [users] = await pool.query(
      'SELECT id, name FROM users WHERE name IS NOT NULL AND name != "Guest User" ORDER BY id LIMIT 20'
    );
    
    if (users.length === 0) {
      console.log('No users found. Please create users first.');
      return;
    }
    
    console.log(`Found ${users.length} users to use as partners`);
    
    let totalInserted = 0;
    
    for (const [locationName, gymIds] of Object.entries(locations)) {
      console.log(`\nSeeding partners for ${locationName}...`);
      
      // Create 15 partners per location
      for (let i = 0; i < 15; i++) {
        // Pick a random user
        const user = users[i % users.length];
        const userId = user.id;
        
        // Pick a random gym from this location
        const gymId = gymIds[i % gymIds.length];
        
        // Pick random workout type and experience level
        const workoutType = workoutTypes[Math.floor(Math.random() * workoutTypes.length)];
        const experienceLevel = experienceLevels[Math.floor(Math.random() * experienceLevels.length)];
        
        // Check if already exists
        const [existing] = await pool.query(
          'SELECT id FROM active_partners WHERE user_id = ? AND gym_id = ?',
          [userId, gymId]
        );
        
        if (existing.length === 0) {
          await pool.query(
            `INSERT INTO active_partners (user_id, gym_id, status, workout_type, experience_level, activated_at)
             VALUES (?, ?, 'Active Now', ?, ?, NOW())`,
            [userId, gymId, workoutType, experienceLevel]
          );
          totalInserted++;
          console.log(`  - Inserted: User ${user.name} at gym ${gymId} (${workoutType})`);
        } else {
          console.log(`  - Skipped: User ${user.name} at gym ${gymId} (already exists)`);
        }
      }
    }
    
    console.log(`\n✅ Successfully seeded ${totalInserted} active partners`);
    
    await pool.end();
  } catch (error) {
    console.error('Error seeding active partners:', error);
    await pool.end();
    process.exit(1);
  }
}

seedActivePartners();
