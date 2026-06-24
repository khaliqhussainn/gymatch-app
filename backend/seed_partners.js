/**
 * GYMatch Partner Seeder
 * Seeds realistic users + profiles + active_partners across:
 *   Karachi (gym IDs 1-6, 14-15)
 *   California / Venice Beach (gym IDs 7-8, 16-17, 22-23)
 *   Brazil / Copacabana (gym IDs 9-10, 18-19, 24-25)
 *   Washington DC (gym IDs 11-13, 20-21, 26-27)
 *   Canada / Toronto (gym IDs 28-32)
 *
 * Run: node backend/seed_partners.js
 */

'use strict';

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const dbConfig = require('./config/db');

// ── Partner definitions ────────────────────────────────────────────────────
// Each entry: { email, password, name, age, gender, fitnessGoals,
//               workoutTypes, availability, aboutMe, gyms: [{ id, workoutType, experienceLevel }] }

const PARTNERS = [
  // ── KARACHI ──────────────────────────────────────────────────────────────
  {
    email: 'ahmed.khan@example.com', password: 'Test1234!',
    name: 'Ahmed Khan', age: 26, gender: 'male',
    fitnessGoals: 'Build muscle, Increase strength',
    workoutTypes: 'Strength Training, Bodybuilding',
    availability: 'Weekdays 6–8 AM, Weekends 8–10 AM',
    aboutMe: 'Karachi-based engineer who lives at the gym. Looking for a serious lifting partner.',
    gyms: [{ id: 1, workoutType: 'Strength Training', experienceLevel: 'Advanced' }],
  },
  {
    email: 'fatima.malik@example.com', password: 'Test1234!',
    name: 'Fatima Malik', age: 24, gender: 'female',
    fitnessGoals: 'Weight loss, Flexibility',
    workoutTypes: 'Yoga, Cardio Training',
    availability: 'Weekdays 7–9 AM',
    aboutMe: 'Yoga enthusiast and runner. Let\'s motivate each other every morning!',
    gyms: [{ id: 4, workoutType: 'Yoga', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'usman.ali@example.com', password: 'Test1234!',
    name: 'Usman Ali', age: 29, gender: 'male',
    fitnessGoals: 'Combat skills, Endurance',
    workoutTypes: 'MMA, Boxing',
    availability: 'Evenings 6–9 PM',
    aboutMe: 'Former amateur boxer now into MMA. Need a sparring partner who can keep up.',
    gyms: [{ id: 5, workoutType: 'MMA', experienceLevel: 'Advanced' }],
  },
  {
    email: 'sara.qureshi@example.com', password: 'Test1234!',
    name: 'Sara Qureshi', age: 22, gender: 'female',
    fitnessGoals: 'Functional fitness, Core strength',
    workoutTypes: 'CrossFit, Functional Fitness',
    availability: 'Weekdays 6:30–8:30 AM',
    aboutMe: 'New to CrossFit but absolutely hooked. Looking for a box buddy.',
    gyms: [{ id: 3, workoutType: 'CrossFit', experienceLevel: 'Beginner' }],
  },
  {
    email: 'bilal.chaudhry@example.com', password: 'Test1234!',
    name: 'Bilal Chaudhry', age: 31, gender: 'male',
    fitnessGoals: 'Powerlifting, PRs',
    workoutTypes: 'Powerlifting, Strength Training',
    availability: 'Weekdays 7–9 PM',
    aboutMe: '4-year powerlifter. Currently chasing a 200 kg squat. Let\'s train together.',
    gyms: [{ id: 1, workoutType: 'Powerlifting', experienceLevel: 'Advanced' }],
  },
  {
    email: 'hina.siddiqui@example.com', password: 'Test1234!',
    name: 'Hina Siddiqui', age: 27, gender: 'female',
    fitnessGoals: 'Lean body, Cardio endurance',
    workoutTypes: 'HIIT, Cardio Training',
    availability: 'Mornings 6–8 AM',
    aboutMe: 'HIIT addict and nutrition enthusiast. Searching for a partner who matches my energy.',
    gyms: [{ id: 6, workoutType: 'HIIT', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'zain.mirza@example.com', password: 'Test1234!',
    name: 'Zain Mirza', age: 23, gender: 'male',
    fitnessGoals: 'Muscle gain, Athletic performance',
    workoutTypes: 'Bodybuilding, Strength Training',
    availability: 'Evenings 5–8 PM, Weekends 9 AM–12 PM',
    aboutMe: 'Medical student squeezing in gym time wherever possible. Consistent & motivated.',
    gyms: [{ id: 2, workoutType: 'Bodybuilding', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'nadia.hussain@example.com', password: 'Test1234!',
    name: 'Nadia Hussain', age: 25, gender: 'female',
    fitnessGoals: 'Calisthenics skills, Flexibility',
    workoutTypes: 'Calisthenics, Mobility & Stretching',
    availability: 'Weekday evenings 6–8 PM',
    aboutMe: 'Learning calisthenics from scratch. Love the progress. Find me at the pull-up bar.',
    gyms: [{ id: 15, workoutType: 'Calisthenics', experienceLevel: 'Beginner' }],
  },
  {
    email: 'omar.sheikh@example.com', password: 'Test1234!',
    name: 'Omar Sheikh', age: 34, gender: 'male',
    fitnessGoals: 'General fitness, Stress relief',
    workoutTypes: 'Strength Training, Cardio Training',
    availability: 'Weekends only 8 AM–12 PM',
    aboutMe: 'Busy entrepreneur. Weekends are sacred gym time. Looking for motivated partners.',
    gyms: [{ id: 14, workoutType: 'Strength Training', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'mariam.rafiq@example.com', password: 'Test1234!',
    name: 'Mariam Rafiq', age: 21, gender: 'female',
    fitnessGoals: 'Weight loss, Toning',
    workoutTypes: 'Yoga, Pilates',
    availability: 'Mornings 7–9 AM',
    aboutMe: 'Yoga & Pilates lover. Just started my fitness journey this year. Very welcoming!',
    gyms: [{ id: 4, workoutType: 'Yoga', experienceLevel: 'Beginner' }],
  },

  // ── CALIFORNIA / VENICE BEACH ────────────────────────────────────────────
  {
    email: 'tyler.beach@example.com', password: 'Test1234!',
    name: 'Tyler Beach', age: 28, gender: 'male',
    fitnessGoals: 'Competition bodybuilding',
    workoutTypes: 'Bodybuilding, Strength Training',
    availability: 'Mon–Fri 5–7 AM',
    aboutMe: 'Training for my first NPC show next spring. Based at Gold\'s Venice — the Mecca.',
    gyms: [{ id: 7, workoutType: 'Bodybuilding', experienceLevel: 'Advanced' }],
  },
  {
    email: 'jessica.surf@example.com', password: 'Test1234!',
    name: 'Jessica Surf', age: 26, gender: 'female',
    fitnessGoals: 'Lean muscle, Beach-body fitness',
    workoutTypes: 'HIIT, Yoga',
    availability: 'Weekdays 6–8 AM, Weekends 9–11 AM',
    aboutMe: 'Surfer & yoga instructor. Outdoor fitness is life. Let\'s hit Muscle Beach!',
    gyms: [{ id: 8, workoutType: 'HIIT', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'marcus.venice@example.com', password: 'Test1234!',
    name: 'Marcus Venice', age: 32, gender: 'male',
    fitnessGoals: 'CrossFit competition',
    workoutTypes: 'CrossFit, Functional Fitness',
    availability: 'Daily 6–8 AM',
    aboutMe: 'L1 CrossFit coach. Training for Regionals. Need a partner who can keep the pace.',
    gyms: [{ id: 17, workoutType: 'CrossFit', experienceLevel: 'Advanced' }],
  },
  {
    email: 'ashley.kinney@example.com', password: 'Test1234!',
    name: 'Ashley Kinney', age: 24, gender: 'female',
    fitnessGoals: 'Flexibility, Mindfulness, Strength',
    workoutTypes: 'Yoga, Pilates',
    availability: 'Weekday mornings 7–9 AM',
    aboutMe: 'Yoga nerd and meditation advocate on Abbot Kinney. Warm, supportive energy only.',
    gyms: [{ id: 22, workoutType: 'Yoga', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'derek.weights@example.com', password: 'Test1234!',
    name: 'Derek Weights', age: 30, gender: 'male',
    fitnessGoals: 'Strength, Muscle hypertrophy',
    workoutTypes: 'Strength Training, Powerlifting',
    availability: 'Evenings 5–8 PM',
    aboutMe: 'Venice gym rat since 2016. I live and breathe iron. Spot me and I\'ll spot you.',
    gyms: [{ id: 16, workoutType: 'Strength Training', experienceLevel: 'Advanced' }],
  },
  {
    email: 'kayla.ufc@example.com', password: 'Test1234!',
    name: 'Kayla UFC', age: 27, gender: 'female',
    fitnessGoals: 'MMA skills, Cardio conditioning',
    workoutTypes: 'MMA, Boxing, Kickboxing',
    availability: 'Weekdays 4–7 PM',
    aboutMe: 'MMA enthusiast training at UFC Gym Venice. Looking for a drilling partner.',
    gyms: [{ id: 23, workoutType: 'MMA', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'ryan.basecamp@example.com', password: 'Test1234!',
    name: 'Ryan Basecamp', age: 25, gender: 'male',
    fitnessGoals: 'General fitness, HIIT endurance',
    workoutTypes: 'HIIT, Circuit Training',
    availability: 'Mon/Wed/Fri 5:30–7 AM',
    aboutMe: 'Tech startup founder who uses morning training to stay sharp all day.',
    gyms: [{ id: 16, workoutType: 'HIIT', experienceLevel: 'Intermediate' }],
  },

  // ── BRAZIL / COPACABANA ──────────────────────────────────────────────────
  {
    email: 'gabriel.rio@example.com', password: 'Test1234!',
    name: 'Gabriel Rio', age: 27, gender: 'male',
    fitnessGoals: 'Beach body, Functional strength',
    workoutTypes: 'Functional Fitness, HIIT',
    availability: 'Weekdays 6–8 AM',
    aboutMe: 'Rio local. Morning workouts before hitting the beach. High energy only!',
    gyms: [{ id: 9, workoutType: 'Functional Fitness', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'camila.copa@example.com', password: 'Test1234!',
    name: 'Camila Copa', age: 23, gender: 'female',
    fitnessGoals: 'Toning, Cardio, Dance fitness',
    workoutTypes: 'Dance Fitness, Cardio Training, Zumba',
    availability: 'Weekday evenings 6–8 PM',
    aboutMe: 'Zumba instructor and fitness enthusiast on Copacabana. Energy +++',
    gyms: [{ id: 10, workoutType: 'Dance Fitness', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'rodrigo.crossfit@example.com', password: 'Test1234!',
    name: 'Rodrigo CrossFit', age: 30, gender: 'male',
    fitnessGoals: 'CrossFit competition, Endurance',
    workoutTypes: 'CrossFit, Functional Fitness',
    availability: 'Daily 6–8 AM',
    aboutMe: 'CrossFit Copacabana athlete. Training for the Open. Let\'s push each other.',
    gyms: [{ id: 18, workoutType: 'CrossFit', experienceLevel: 'Advanced' }],
  },
  {
    email: 'isabela.yoga@example.com', password: 'Test1234!',
    name: 'Isabela Yoga', age: 25, gender: 'female',
    fitnessGoals: 'Flexibility, Inner peace, Strength',
    workoutTypes: 'Yoga, Pilates, Mobility & Stretching',
    availability: 'Mornings 7–9 AM, Weekends 8–10 AM',
    aboutMe: 'Yoga teacher on Copacabana beach. Sessions with sea breeze included.',
    gyms: [{ id: 24, workoutType: 'Yoga', experienceLevel: 'Advanced' }],
  },
  {
    email: 'lucas.mma@example.com', password: 'Test1234!',
    name: 'Lucas MMA', age: 28, gender: 'male',
    fitnessGoals: 'BJJ, MMA skills',
    workoutTypes: 'MMA, Boxing',
    availability: 'Evenings 7–10 PM',
    aboutMe: 'BJJ blue belt training at Estrada. Looking for a grappling and boxing partner.',
    gyms: [{ id: 25, workoutType: 'MMA', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'ana.prime@example.com', password: 'Test1234!',
    name: 'Ana Prime', age: 22, gender: 'female',
    fitnessGoals: 'Weight loss, Cardio',
    workoutTypes: 'Cardio Training, HIIT',
    availability: 'Weekdays 6–8 AM',
    aboutMe: 'Just started at Academia PR1ME. Very motivated, looking for a supportive partner.',
    gyms: [{ id: 19, workoutType: 'Cardio Training', experienceLevel: 'Beginner' }],
  },
  {
    email: 'thiago.smart@example.com', password: 'Test1234!',
    name: 'Thiago Smart', age: 33, gender: 'male',
    fitnessGoals: 'Maintain fitness, Strength',
    workoutTypes: 'Strength Training, Bodybuilding',
    availability: 'Weekday evenings 6–9 PM',
    aboutMe: 'Software engineer in Rio. Gym is my decompression zone. Come lift with me.',
    gyms: [{ id: 10, workoutType: 'Strength Training', experienceLevel: 'Intermediate' }],
  },

  // ── WASHINGTON DC ─────────────────────────────────────────────────────────
  {
    email: 'jordan.dc@example.com', password: 'Test1234!',
    name: 'Jordan DC', age: 29, gender: 'male',
    fitnessGoals: 'CrossFit performance, Weight loss',
    workoutTypes: 'CrossFit, HIIT',
    availability: 'Weekdays 6–8 AM',
    aboutMe: 'Policy analyst who unwinds at CrossFit Capitol. Let\'s WOD together!',
    gyms: [{ id: 13, workoutType: 'CrossFit', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'morgan.equinox@example.com', password: 'Test1234!',
    name: 'Morgan Equinox', age: 31, gender: 'female',
    fitnessGoals: 'Total body conditioning, Yoga',
    workoutTypes: 'Yoga, Pilates, Cardio Training',
    availability: 'Weekdays 5:30–7:30 AM',
    aboutMe: 'Equinox Georgetown member. Yoga every morning, weights every afternoon.',
    gyms: [{ id: 12, workoutType: 'Yoga', experienceLevel: 'Advanced' }],
  },
  {
    email: 'alex.capitol@example.com', password: 'Test1234!',
    name: 'Alex Capitol', age: 26, gender: 'male',
    fitnessGoals: 'Strength, Powerlifting',
    workoutTypes: 'Powerlifting, Strength Training',
    availability: 'Weekday evenings 6–9 PM',
    aboutMe: 'Congressional staffer. Heavy lifts are my stress relief. Looking for a spotter.',
    gyms: [{ id: 11, workoutType: 'Powerlifting', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'taylor.dupont@example.com', password: 'Test1234!',
    name: 'Taylor Dupont', age: 24, gender: 'female',
    fitnessGoals: 'CrossFit, Functional fitness',
    workoutTypes: 'CrossFit, Functional Fitness',
    availability: 'Daily 6–8 AM',
    aboutMe: 'New to DC from Austin. CrossFit Dupont is my second home. Come sweat!',
    gyms: [{ id: 27, workoutType: 'CrossFit', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'sam.vida@example.com', password: 'Test1234!',
    name: 'Sam Vida', age: 33, gender: 'male',
    fitnessGoals: 'Swimming, Overall fitness',
    workoutTypes: 'Cardio Training, Strength Training',
    availability: 'Weekdays 5–7 AM',
    aboutMe: 'Vida Fitness Capitol Hill VIP member. Early bird who loves a pool session.',
    gyms: [{ id: 20, workoutType: 'Cardio Training', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'riley.mint@example.com', password: 'Test1234!',
    name: 'Riley Mint', age: 28, gender: 'female',
    fitnessGoals: 'Yoga, Mindfulness, Lean body',
    workoutTypes: 'Yoga, Pilates',
    availability: 'Weekday evenings 6–8 PM',
    aboutMe: 'Adams Morgan local. Yoga and good vibes. Searching for a mindful workout buddy.',
    gyms: [{ id: 21, workoutType: 'Yoga', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'dana.beta@example.com', password: 'Test1234!',
    name: 'Dana Beta', age: 27, gender: 'male',
    fitnessGoals: 'MMA, Self-defense',
    workoutTypes: 'MMA, Kickboxing, Boxing',
    availability: 'Evenings 6–9 PM',
    aboutMe: 'Beta Academy MMA student. Looking for a drilling partner who takes it seriously.',
    gyms: [{ id: 26, workoutType: 'MMA', experienceLevel: 'Beginner' }],
  },
  {
    email: 'casey.golds@example.com', password: 'Test1234!',
    name: 'Casey Golds', age: 35, gender: 'male',
    fitnessGoals: 'Bodybuilding, Muscle gain',
    workoutTypes: 'Bodybuilding, Strength Training',
    availability: 'Weekdays 7–9 AM',
    aboutMe: 'Capitol Hill Gold\'s veteran. 10 years of lifting. Happy to guide beginners too.',
    gyms: [{ id: 11, workoutType: 'Bodybuilding', experienceLevel: 'Advanced' }],
  },

  // ── CANADA / TORONTO ─────────────────────────────────────────────────────
  {
    email: 'liam.toronto@example.com', password: 'Test1234!',
    name: 'Liam Toronto', age: 27, gender: 'male',
    fitnessGoals: 'CrossFit competition, Endurance',
    workoutTypes: 'CrossFit, Functional Fitness',
    availability: 'Daily 6–8 AM',
    aboutMe: 'Distillery District CrossFit athlete. Training hard year-round. Let\'s push limits.',
    gyms: [{ id: 29, workoutType: 'CrossFit', experienceLevel: 'Advanced' }],
  },
  {
    email: 'emma.goodlife@example.com', password: 'Test1234!',
    name: 'Emma Goodlife', age: 25, gender: 'female',
    fitnessGoals: 'Toning, Weight management',
    workoutTypes: 'Cardio Training, HIIT',
    availability: 'Weekdays 5:30–7:30 AM',
    aboutMe: 'GoodLife Bay Street regular. Early morning sweat club. Very welcoming!',
    gyms: [{ id: 28, workoutType: 'HIIT', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'noah.equinox.to@example.com', password: 'Test1234!',
    name: 'Noah Equinox', age: 30, gender: 'male',
    fitnessGoals: 'Total body, Strength',
    workoutTypes: 'Strength Training, Bodybuilding',
    availability: 'Weekday evenings 5–8 PM',
    aboutMe: 'Finance guy by day, gym rat by night. Equinox Yorkville is my temple.',
    gyms: [{ id: 30, workoutType: 'Strength Training', experienceLevel: 'Advanced' }],
  },
  {
    email: 'olivia.yoga.to@example.com', password: 'Test1234!',
    name: 'Olivia Yoga', age: 23, gender: 'female',
    fitnessGoals: 'Flexibility, Mindfulness',
    workoutTypes: 'Yoga, Pilates, Mobility & Stretching',
    availability: 'Weekday mornings 7–9 AM',
    aboutMe: 'Kensington Market yoga devotee. Let\'s flow and grow together.',
    gyms: [{ id: 31, workoutType: 'Yoga', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'ethan.kombat@example.com', password: 'Test1234!',
    name: 'Ethan Kombat', age: 29, gender: 'male',
    fitnessGoals: 'MMA, Combat skills',
    workoutTypes: 'MMA, Boxing, Kickboxing',
    availability: 'Evenings 6–9 PM',
    aboutMe: 'Kombat Arts MMA blue belt. Always looking for serious training partners.',
    gyms: [{ id: 32, workoutType: 'MMA', experienceLevel: 'Intermediate' }],
  },
  {
    email: 'sophia.crossfit.ca@example.com', password: 'Test1234!',
    name: 'Sophia CrossFit', age: 26, gender: 'female',
    fitnessGoals: 'Athletic performance, CrossFit',
    workoutTypes: 'CrossFit, HIIT',
    availability: 'Weekdays 6–8 AM',
    aboutMe: 'Just got my L1 cert. Coaching at CrossFit Toronto and loving every second.',
    gyms: [{ id: 29, workoutType: 'CrossFit', experienceLevel: 'Advanced' }],
  },
  {
    email: 'james.goodlife.ca@example.com', password: 'Test1234!',
    name: 'James Goodlife', age: 34, gender: 'male',
    fitnessGoals: 'Maintain fitness, Strength',
    workoutTypes: 'Strength Training, Powerlifting',
    availability: 'Weekends 8 AM–12 PM',
    aboutMe: 'GoodLife Premier member for 5 years. Friendly spotter — always happy to help.',
    gyms: [{ id: 28, workoutType: 'Powerlifting', experienceLevel: 'Advanced' }],
  },
  {
    email: 'mia.kensington@example.com', password: 'Test1234!',
    name: 'Mia Kensington', age: 22, gender: 'female',
    fitnessGoals: 'Holistic health, Dance fitness',
    workoutTypes: 'Dance Fitness, Zumba, Yoga',
    availability: 'Weekday evenings 6–8 PM',
    aboutMe: 'Zumba fanatic and Kensington yoga newbie. Come dance and stretch with me!',
    gyms: [{ id: 31, workoutType: 'Dance Fitness', experienceLevel: 'Beginner' }],
  },
];

// ── Main seeder ────────────────────────────────────────────────────────────
async function seed() {
  const conn = await mysql.createConnection({
    host:     dbConfig.host,
    user:     dbConfig.user,
    password: dbConfig.password,
    database: dbConfig.database,
    port:     dbConfig.port,
  });

  console.log('✅ Connected to database:', dbConfig.database);

  let created = 0;
  let skipped = 0;

  for (const p of PARTNERS) {
    // Check if user already exists
    const [existing] = await conn.query('SELECT id FROM users WHERE email = ?', [p.email]);
    if (existing.length > 0) {
      console.log(`  ⏩  Skipping existing user: ${p.email}`);
      skipped++;
      continue;
    }

    // Hash password
    const hashed = await bcrypt.hash(p.password, 10);

    // Insert user
    const [userResult] = await conn.query(
      'INSERT INTO users (email, password, name, role) VALUES (?, ?, ?, ?)',
      [p.email, hashed, p.name, 'user']
    );
    const userId = userResult.insertId;

    // Insert profile — handle optional about_me column
    try {
      await conn.query(
        `INSERT INTO profiles
           (user_id, name, age, gender, fitness_goals, workout_types, availability, about_me)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [userId, p.name, p.age, p.gender, p.fitnessGoals, p.workoutTypes, p.availability, p.aboutMe]
      );
    } catch (colErr) {
      if (colErr.code === 'ER_BAD_FIELD_ERROR') {
        await conn.query(
          `INSERT INTO profiles
             (user_id, name, age, gender, fitness_goals, workout_types, availability)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [userId, p.name, p.age, p.gender, p.fitnessGoals, p.workoutTypes, p.availability]
        );
      } else { throw colErr; }
    }

    // Insert active_partners entries
    for (const g of p.gyms) {
      await conn.query(
        `INSERT IGNORE INTO active_partners (user_id, gym_id, status, workout_type, experience_level)
         VALUES (?, ?, 'Active Now', ?, ?)`,
        [userId, g.id, g.workoutType, g.experienceLevel]
      );
    }

    console.log(`  ✔   Created: ${p.name} (${p.email}) → gym(s): ${p.gyms.map(g => g.id).join(', ')}`);
    created++;
  }

  await conn.end();

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`✅  Seeding complete!  Created: ${created}  |  Skipped: ${skipped}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

seed().catch(err => {
  console.error('❌ Seeder failed:', err.message);
  process.exit(1);
});

