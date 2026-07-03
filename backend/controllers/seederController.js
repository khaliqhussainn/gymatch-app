'use strict';

const pool    = require('../config/connection');
const bcrypt  = require('bcryptjs');
const { pickProfileImage } = require('../services/profileImageSeeder');

/**
 * GET /api/seed-partners?secret=gymatch_migrate_2024_secure_key
 *
 * Idempotent partner seeder — safe to run multiple times.
 * Skips any email that already exists.
 *
 * Protected by MIGRATION_SECRET (same key used for /migration).
 */

// ── Partner data ────────────────────────────────────────────────────────────
const PARTNERS = [
  // ── KARACHI ────────────────────────────────────────────────────────────
  { email:'fatima.malik@example.com',    name:'Fatima Malik',    age:24, gender:'female', fitnessGoals:'Weight loss, Flexibility',                    workoutTypes:'Yoga, Cardio Training',                 availability:'Weekdays 7–9 AM',                          aboutMe:"Yoga enthusiast and runner. Let's motivate each other!",                   gyms:[{id:4,  type:'Yoga',               exp:'Intermediate'}] },
  { email:'usman.ali@example.com',       name:'Usman Ali',       age:29, gender:'male',   fitnessGoals:'Combat skills, Endurance',                    workoutTypes:'MMA, Boxing',                           availability:'Evenings 6–9 PM',                          aboutMe:'Former amateur boxer now into MMA. Need a sparring partner.',              gyms:[{id:5,  type:'MMA',                exp:'Advanced'}] },
  { email:'sara.qureshi@example.com',    name:'Sara Qureshi',    age:22, gender:'female', fitnessGoals:'Functional fitness, Core strength',           workoutTypes:'CrossFit, Functional Fitness',          availability:'Weekdays 6:30–8:30 AM',                    aboutMe:"New to CrossFit but absolutely hooked.",                                   gyms:[{id:3,  type:'CrossFit',           exp:'Beginner'}] },
  { email:'bilal.chaudhry@example.com',  name:'Bilal Chaudhry',  age:31, gender:'male',   fitnessGoals:'Powerlifting, PRs',                           workoutTypes:'Powerlifting, Strength Training',       availability:'Weekdays 7–9 PM',                          aboutMe:"4-year powerlifter chasing a 200 kg squat.",                               gyms:[{id:1,  type:'Powerlifting',       exp:'Advanced'}] },
  { email:'hina.siddiqui@example.com',   name:'Hina Siddiqui',   age:27, gender:'female', fitnessGoals:'Lean body, Cardio endurance',                 workoutTypes:'HIIT, Cardio Training',                 availability:'Mornings 6–8 AM',                          aboutMe:'HIIT addict and nutrition enthusiast.',                                    gyms:[{id:6,  type:'HIIT',               exp:'Intermediate'}] },
  { email:'zain.mirza@example.com',      name:'Zain Mirza',      age:23, gender:'male',   fitnessGoals:'Muscle gain, Athletic performance',           workoutTypes:'Bodybuilding, Strength Training',       availability:'Evenings 5–8 PM, Weekends 9 AM–12 PM',    aboutMe:'Medical student squeezing in gym time wherever possible.',                 gyms:[{id:2,  type:'Bodybuilding',       exp:'Intermediate'}] },
  { email:'nadia.hussain@example.com',   name:'Nadia Hussain',   age:25, gender:'female', fitnessGoals:'Calisthenics skills, Flexibility',            workoutTypes:'Calisthenics, Mobility & Stretching',  availability:'Weekday evenings 6–8 PM',                  aboutMe:'Learning calisthenics from scratch. Find me at the pull-up bar.',          gyms:[{id:15, type:'Calisthenics',       exp:'Beginner'}] },
  { email:'omar.sheikh@example.com',     name:'Omar Sheikh',     age:34, gender:'male',   fitnessGoals:'General fitness, Stress relief',              workoutTypes:'Strength Training, Cardio Training',   availability:'Weekends only 8 AM–12 PM',                 aboutMe:'Busy entrepreneur. Weekends are sacred gym time.',                         gyms:[{id:14, type:'Strength Training',  exp:'Intermediate'}] },
  { email:'mariam.rafiq@example.com',    name:'Mariam Rafiq',    age:21, gender:'female', fitnessGoals:'Weight loss, Toning',                         workoutTypes:'Yoga, Pilates',                         availability:'Mornings 7–9 AM',                          aboutMe:'Yoga & Pilates lover. Just started my fitness journey.',                   gyms:[{id:4,  type:'Yoga',               exp:'Beginner'}] },
  { email:'ahmed.raza@example.com',      name:'Ahmed Raza',      age:26, gender:'male',   fitnessGoals:'Build muscle, Increase strength',             workoutTypes:'Strength Training, Bodybuilding',       availability:'Weekdays 6–8 AM, Weekends 8–10 AM',        aboutMe:'Karachi engineer who lives at the gym.',                                   gyms:[{id:1,  type:'Strength Training',  exp:'Advanced'}] },
  { email:'amna.karachi@example.com',    name:'Amna Karachi',    age:23, gender:'female', fitnessGoals:'Tone up, Build stamina',                      workoutTypes:'HIIT, Functional Fitness',              availability:'Weekdays 7–9 AM',                          aboutMe:'University student passionate about fitness and healthy living.',          gyms:[{id:6,  type:'HIIT',               exp:'Beginner'}] },
  { email:'hassan.clifton@example.com',  name:'Hassan Clifton',  age:28, gender:'male',   fitnessGoals:'CrossFit performance, Endurance',             workoutTypes:'CrossFit, Functional Fitness',          availability:'Daily 6:30–8:30 AM',                       aboutMe:'CrossFit Clifton regular. Always pushing limits.',                         gyms:[{id:15, type:'CrossFit',           exp:'Intermediate'}] },

  // ── CALIFORNIA / VENICE BEACH ───────────────────────────────────────────
  { email:'tyler.beach@example.com',     name:'Tyler Beach',     age:28, gender:'male',   fitnessGoals:'Competition bodybuilding',                    workoutTypes:'Bodybuilding, Strength Training',       availability:'Mon–Fri 5–7 AM',                           aboutMe:"Training for my first NPC show. Based at Gold's Venice.",                  gyms:[{id:7,  type:'Bodybuilding',       exp:'Advanced'}] },
  { email:'jessica.surf@example.com',    name:'Jessica Surf',    age:26, gender:'female', fitnessGoals:'Lean muscle, Beach-body fitness',             workoutTypes:'HIIT, Yoga',                            availability:'Weekdays 6–8 AM, Weekends 9–11 AM',        aboutMe:"Surfer & yoga instructor. Let's hit Muscle Beach!",                        gyms:[{id:8,  type:'HIIT',               exp:'Intermediate'}] },
  { email:'marcus.venice@example.com',   name:'Marcus Venice',   age:32, gender:'male',   fitnessGoals:'CrossFit competition',                        workoutTypes:'CrossFit, Functional Fitness',          availability:'Daily 6–8 AM',                             aboutMe:'L1 CrossFit coach. Training for Regionals.',                               gyms:[{id:17, type:'CrossFit',           exp:'Advanced'}] },
  { email:'ashley.kinney@example.com',   name:'Ashley Kinney',   age:24, gender:'female', fitnessGoals:'Flexibility, Mindfulness, Strength',          workoutTypes:'Yoga, Pilates',                         availability:'Weekday mornings 7–9 AM',                  aboutMe:'Yoga nerd and meditation advocate on Abbot Kinney.',                       gyms:[{id:22, type:'Yoga',               exp:'Intermediate'}] },
  { email:'derek.weights@example.com',   name:'Derek Weights',   age:30, gender:'male',   fitnessGoals:'Strength, Muscle hypertrophy',                workoutTypes:'Strength Training, Powerlifting',       availability:'Evenings 5–8 PM',                          aboutMe:"Venice gym rat since 2016. I live and breathe iron.",                      gyms:[{id:16, type:'Strength Training',  exp:'Advanced'}] },
  { email:'kayla.ufc@example.com',       name:'Kayla UFC',       age:27, gender:'female', fitnessGoals:'MMA skills, Cardio conditioning',             workoutTypes:'MMA, Boxing, Kickboxing',               availability:'Weekdays 4–7 PM',                          aboutMe:'MMA enthusiast training at UFC Gym Venice.',                               gyms:[{id:23, type:'MMA',                exp:'Intermediate'}] },
  { email:'ryan.basecamp@example.com',   name:'Ryan Basecamp',   age:25, gender:'male',   fitnessGoals:'General fitness, HIIT endurance',             workoutTypes:'HIIT, Circuit Training',                availability:'Mon/Wed/Fri 5:30–7 AM',                    aboutMe:'Tech startup founder who uses morning training to stay sharp.',            gyms:[{id:16, type:'HIIT',               exp:'Intermediate'}] },
  { email:'brittany.la@example.com',     name:'Brittany LA',     age:24, gender:'female', fitnessGoals:'Dance fitness, Cardio',                       workoutTypes:'Dance Fitness, Zumba, Cardio Training', availability:'Weekday evenings 5–7 PM',                  aboutMe:'Zumba instructor looking for morning dance fitness buddies.',               gyms:[{id:8,  type:'Dance Fitness',      exp:'Intermediate'}] },
  { email:'carlos.venice@example.com',   name:'Carlos Venice',   age:31, gender:'male',   fitnessGoals:'Powerlifting, Strength',                      workoutTypes:'Powerlifting, Strength Training',       availability:'Weekday mornings 6–8 AM',                  aboutMe:"Powerlifter at Basecamp. Let's chase PRs together.",                       gyms:[{id:16, type:'Powerlifting',       exp:'Advanced'}] },

  // ── BRAZIL / COPACABANA ─────────────────────────────────────────────────
  { email:'gabriel.rio@example.com',     name:'Gabriel Rio',     age:27, gender:'male',   fitnessGoals:'Beach body, Functional strength',             workoutTypes:'Functional Fitness, HIIT',              availability:'Weekdays 6–8 AM',                          aboutMe:'Rio local. Morning workouts before hitting the beach.',                    gyms:[{id:9,  type:'Functional Fitness', exp:'Intermediate'}] },
  { email:'camila.copa@example.com',     name:'Camila Copa',     age:23, gender:'female', fitnessGoals:'Toning, Cardio, Dance fitness',               workoutTypes:'Dance Fitness, Cardio Training, Zumba', availability:'Weekday evenings 6–8 PM',                  aboutMe:'Zumba instructor on Copacabana. Energy +++',                               gyms:[{id:10, type:'Dance Fitness',      exp:'Intermediate'}] },
  { email:'rodrigo.crossfit@example.com',name:'Rodrigo CrossFit',age:30, gender:'male',   fitnessGoals:'CrossFit competition, Endurance',             workoutTypes:'CrossFit, Functional Fitness',          availability:'Daily 6–8 AM',                             aboutMe:"CrossFit Copacabana athlete training for the Open.",                       gyms:[{id:18, type:'CrossFit',           exp:'Advanced'}] },
  { email:'isabela.yoga@example.com',    name:'Isabela Yoga',    age:25, gender:'female', fitnessGoals:'Flexibility, Inner peace, Strength',          workoutTypes:'Yoga, Pilates, Mobility & Stretching',  availability:'Mornings 7–9 AM, Weekends 8–10 AM',        aboutMe:'Yoga teacher on Copacabana beach. Sea breeze included.',                   gyms:[{id:24, type:'Yoga',               exp:'Advanced'}] },
  { email:'lucas.mma@example.com',       name:'Lucas MMA',       age:28, gender:'male',   fitnessGoals:'BJJ, MMA skills',                             workoutTypes:'MMA, Boxing',                           availability:'Evenings 7–10 PM',                         aboutMe:'BJJ blue belt training at Estrada.',                                       gyms:[{id:25, type:'MMA',                exp:'Intermediate'}] },
  { email:'ana.prime@example.com',       name:'Ana Prime',       age:22, gender:'female', fitnessGoals:'Weight loss, Cardio',                         workoutTypes:'Cardio Training, HIIT',                 availability:'Weekdays 6–8 AM',                          aboutMe:'Just started at Academia PR1ME. Very motivated.',                          gyms:[{id:19, type:'Cardio Training',    exp:'Beginner'}] },
  { email:'thiago.smart@example.com',    name:'Thiago Smart',    age:33, gender:'male',   fitnessGoals:'Maintain fitness, Strength',                  workoutTypes:'Strength Training, Bodybuilding',       availability:'Weekday evenings 6–9 PM',                  aboutMe:'Software engineer in Rio. Gym is my decompression zone.',                  gyms:[{id:10, type:'Strength Training',  exp:'Intermediate'}] },
  { email:'julia.brasil@example.com',    name:'Julia Brasil',    age:26, gender:'female', fitnessGoals:'Lean body, Flexibility',                      workoutTypes:'Yoga, Pilates',                         availability:'Weekday mornings 7–9 AM',                  aboutMe:'Pilates and yoga devotee near Copacabana beach.',                          gyms:[{id:24, type:'Yoga',               exp:'Intermediate'}] },
  { email:'pedro.rio@example.com',       name:'Pedro Rio',       age:29, gender:'male',   fitnessGoals:'Bodybuilding, Strength',                      workoutTypes:'Bodybuilding, Strength Training',       availability:'Evenings 6–9 PM',                          aboutMe:'Competitive bodybuilder training in Rio. Consistent and disciplined.',     gyms:[{id:9,  type:'Bodybuilding',       exp:'Advanced'}] },

  // ── WASHINGTON DC ───────────────────────────────────────────────────────
  { email:'jordan.dc@example.com',       name:'Jordan DC',       age:29, gender:'male',   fitnessGoals:'CrossFit performance, Weight loss',           workoutTypes:'CrossFit, HIIT',                        availability:'Weekdays 6–8 AM',                          aboutMe:"Policy analyst who unwinds at CrossFit Capitol.",                          gyms:[{id:13, type:'CrossFit',           exp:'Intermediate'}] },
  { email:'morgan.equinox@example.com',  name:'Morgan Equinox',  age:31, gender:'female', fitnessGoals:'Total body conditioning, Yoga',               workoutTypes:'Yoga, Pilates, Cardio Training',        availability:'Weekdays 5:30–7:30 AM',                    aboutMe:'Equinox Georgetown member. Yoga every morning, weights every afternoon.',  gyms:[{id:12, type:'Yoga',               exp:'Advanced'}] },
  { email:'alex.capitol@example.com',    name:'Alex Capitol',    age:26, gender:'male',   fitnessGoals:'Strength, Powerlifting',                      workoutTypes:'Powerlifting, Strength Training',       availability:'Weekday evenings 6–9 PM',                  aboutMe:'Congressional staffer. Heavy lifts are my stress relief.',                 gyms:[{id:11, type:'Powerlifting',       exp:'Intermediate'}] },
  { email:'taylor.dupont@example.com',   name:'Taylor Dupont',   age:24, gender:'female', fitnessGoals:'CrossFit, Functional fitness',                workoutTypes:'CrossFit, Functional Fitness',          availability:'Daily 6–8 AM',                             aboutMe:"New to DC from Austin. CrossFit Dupont is my second home.",                gyms:[{id:27, type:'CrossFit',           exp:'Intermediate'}] },
  { email:'sam.vida@example.com',        name:'Sam Vida',        age:33, gender:'male',   fitnessGoals:'Swimming, Overall fitness',                   workoutTypes:'Cardio Training, Strength Training',    availability:'Weekdays 5–7 AM',                          aboutMe:'Vida Fitness Capitol Hill VIP. Early bird who loves a pool session.',      gyms:[{id:20, type:'Cardio Training',    exp:'Intermediate'}] },
  { email:'riley.mint@example.com',      name:'Riley Mint',      age:28, gender:'female', fitnessGoals:'Yoga, Mindfulness, Lean body',                workoutTypes:'Yoga, Pilates',                         availability:'Weekday evenings 6–8 PM',                  aboutMe:'Adams Morgan local. Yoga and good vibes.',                                 gyms:[{id:21, type:'Yoga',               exp:'Intermediate'}] },
  { email:'dana.beta@example.com',       name:'Dana Beta',       age:27, gender:'male',   fitnessGoals:'MMA, Self-defense',                           workoutTypes:'MMA, Kickboxing, Boxing',               availability:'Evenings 6–9 PM',                          aboutMe:'Beta Academy MMA student.',                                                gyms:[{id:26, type:'MMA',                exp:'Beginner'}] },
  { email:'casey.golds@example.com',     name:'Casey Golds',     age:35, gender:'male',   fitnessGoals:'Bodybuilding, Muscle gain',                   workoutTypes:'Bodybuilding, Strength Training',       availability:'Weekdays 7–9 AM',                          aboutMe:"Capitol Hill Gold's veteran — 10 years lifting.",                          gyms:[{id:11, type:'Bodybuilding',       exp:'Advanced'}] },
  { email:'priya.dc@example.com',        name:'Priya DC',        age:25, gender:'female', fitnessGoals:'Cardio fitness, Stress management',           workoutTypes:'Yoga, Cardio Training, HIIT',           availability:'Weekday mornings 6–8 AM',                  aboutMe:'Georgetown grad student. Yoga and cardio keep me sane.',                   gyms:[{id:12, type:'Yoga',               exp:'Intermediate'}] },
  { email:'marcus.dc@example.com',       name:'Marcus DC',       age:32, gender:'male',   fitnessGoals:'Athletic performance, Strength',              workoutTypes:'Strength Training, CrossFit',           availability:'Weekday evenings 5–8 PM',                  aboutMe:"Fed worker by day, gym athlete by night. Dupont CrossFit regular.",         gyms:[{id:27, type:'Strength Training',  exp:'Advanced'}] },

  // ── CANADA / TORONTO ────────────────────────────────────────────────────
  { email:'liam.toronto@example.com',    name:'Liam Toronto',    age:27, gender:'male',   fitnessGoals:'CrossFit competition, Endurance',             workoutTypes:'CrossFit, Functional Fitness',          availability:'Daily 6–8 AM',                             aboutMe:"Distillery District CrossFit athlete. Let's push limits.",                 gyms:[{id:29, type:'CrossFit',           exp:'Advanced'}] },
  { email:'emma.goodlife@example.com',   name:'Emma Goodlife',   age:25, gender:'female', fitnessGoals:'Toning, Weight management',                   workoutTypes:'Cardio Training, HIIT',                 availability:'Weekdays 5:30–7:30 AM',                    aboutMe:'GoodLife Bay Street regular. Early morning sweat club.',                   gyms:[{id:28, type:'HIIT',               exp:'Intermediate'}] },
  { email:'noah.equinox.to@example.com', name:'Noah Equinox',    age:30, gender:'male',   fitnessGoals:'Total body, Strength',                        workoutTypes:'Strength Training, Bodybuilding',       availability:'Weekday evenings 5–8 PM',                  aboutMe:"Finance guy by day, gym rat by night. Equinox Yorkville.",                 gyms:[{id:30, type:'Strength Training',  exp:'Advanced'}] },
  { email:'olivia.yoga.to@example.com',  name:'Olivia Yoga',     age:23, gender:'female', fitnessGoals:'Flexibility, Mindfulness',                    workoutTypes:'Yoga, Pilates, Mobility & Stretching',  availability:'Weekday mornings 7–9 AM',                  aboutMe:"Kensington Market yoga devotee. Let's flow together.",                     gyms:[{id:31, type:'Yoga',               exp:'Intermediate'}] },
  { email:'ethan.kombat@example.com',    name:'Ethan Kombat',    age:29, gender:'male',   fitnessGoals:'MMA, Combat skills',                          workoutTypes:'MMA, Boxing, Kickboxing',               availability:'Evenings 6–9 PM',                          aboutMe:'Kombat Arts MMA blue belt.',                                               gyms:[{id:32, type:'MMA',                exp:'Intermediate'}] },
  { email:'sophia.crossfit.ca@example.com',name:'Sophia CrossFit',age:26,gender:'female', fitnessGoals:'Athletic performance, CrossFit',              workoutTypes:'CrossFit, HIIT',                        availability:'Weekdays 6–8 AM',                          aboutMe:'Just got my L1 cert. Coaching at CrossFit Toronto.',                       gyms:[{id:29, type:'CrossFit',           exp:'Advanced'}] },
  { email:'james.goodlife.ca@example.com',name:'James Goodlife', age:34, gender:'male',   fitnessGoals:'Maintain fitness, Strength',                  workoutTypes:'Strength Training, Powerlifting',       availability:'Weekends 8 AM–12 PM',                      aboutMe:"GoodLife Premier member for 5 years. Happy to spot.",                      gyms:[{id:28, type:'Powerlifting',       exp:'Advanced'}] },
  { email:'mia.kensington@example.com',  name:'Mia Kensington',  age:22, gender:'female', fitnessGoals:'Holistic health, Dance fitness',              workoutTypes:'Dance Fitness, Zumba, Yoga',            availability:'Weekday evenings 6–8 PM',                  aboutMe:'Zumba fanatic and Kensington yoga newbie.',                                gyms:[{id:31, type:'Dance Fitness',      exp:'Beginner'}] },
  { email:'zhang.toronto@example.com',   name:'Zhang Toronto',   age:28, gender:'male',   fitnessGoals:'Bodybuilding, Lean muscle',                   workoutTypes:'Bodybuilding, Strength Training',       availability:'Weekday evenings 6–9 PM',                  aboutMe:'Engineering grad at UofT. Gym is how I decompress. ',                      gyms:[{id:30, type:'Bodybuilding',       exp:'Intermediate'}] },
  { email:'isabella.toronto@example.com',name:'Isabella Toronto',age:24, gender:'female', fitnessGoals:'Athletic performance, CrossFit',              workoutTypes:'CrossFit, Functional Fitness, HIIT',    availability:'Daily 6–8 AM',                             aboutMe:'Sport science student. CrossFit Toronto is home.',                         gyms:[{id:29, type:'CrossFit',           exp:'Intermediate'}] },
];

// ── Controller ──────────────────────────────────────────────────────────────
exports.runSeeder = async (req, res) => {
  // Secret guard — same key as MIGRATION_SECRET
  const provided = (req.query.secret || '').toString().trim();
  const expected = (process.env.MIGRATION_SECRET || '').toString().trim();

  if (!expected) {
    return res.status(500).json({ error: 'MIGRATION_SECRET not set on server.' });
  }
  if (provided !== expected) {
    return res.status(401).json({ error: 'Invalid secret. Access denied.' });
  }

  const results  = [];
  const skipped  = [];
  const errors   = [];
  const log      = (msg) => { console.log(msg); results.push(msg); };

  try {
    // Check if about_me column exists once
    let hasAboutMe = true;
    try { await pool.query('SELECT about_me FROM profiles LIMIT 1'); }
    catch (_) { hasAboutMe = false; }

    let femaleIdx = 0;
    let maleIdx = 0;

    for (const p of PARTNERS) {
      try {
        // Skip if email already exists
        const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [p.email]);
        if (existing.length > 0) {
          skipped.push(p.email);
          continue;
        }

        // Hash password
        const hashed = await bcrypt.hash('Test1234!', 10);

        // Insert user
        const [userResult] = await pool.query(
          'INSERT INTO users (email, password, name, role) VALUES (?, ?, ?, ?)',
          [p.email, hashed, p.name, 'user']
        );
        const userId = userResult.insertId;

        const profileImage = pickProfileImage(
          p.gender,
          p.gender === 'female' ? femaleIdx++ : maleIdx++
        );

        // Insert profile
        if (hasAboutMe) {
          await pool.query(
            `INSERT INTO profiles (user_id, name, age, gender, fitness_goals, workout_types, availability, about_me, profile_image)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [userId, p.name, p.age, p.gender, p.fitnessGoals, p.workoutTypes, p.availability, p.aboutMe, profileImage]
          );
        } else {
          await pool.query(
            `INSERT INTO profiles (user_id, name, age, gender, fitness_goals, workout_types, availability, profile_image)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [userId, p.name, p.age, p.gender, p.fitnessGoals, p.workoutTypes, p.availability, profileImage]
          );
        }

        // Insert active_partner records
        for (const g of p.gyms) {
          await pool.query(
            `INSERT IGNORE INTO active_partners (user_id, gym_id, status, workout_type, experience_level)
             VALUES (?, ?, 'Active Now', ?, ?)`,
            [userId, g.id, g.type, g.exp]
          );
        }

        log(`✔ ${p.name} (${p.email}) → gym(s): ${p.gyms.map(g => g.id).join(', ')}`);
      } catch (rowErr) {
        const msg = `✘ ${p.email}: ${rowErr.message}`;
        console.error(msg);
        errors.push(msg);
      }
    }

    return res.json({
      ok: true,
      created: results.length,
      skipped: skipped.length,
      errors: errors.length,
      details: results,
      skippedEmails: skipped,
      errorDetails: errors,
    });
  } catch (err) {
    console.error('[seederController]', err);
    return res.status(500).json({ ok: false, error: err.message });
  }
};

