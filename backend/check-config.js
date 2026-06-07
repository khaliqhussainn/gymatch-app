#!/usr/bin/env node

/**
 * Configuration Checker for GYMatch Backend
 * Run this to verify your environment variables are set correctly
 * 
 * Usage: node check-config.js
 */

require('dotenv').config();

const checks = {
  database: {
    name: 'Database Configuration',
    vars: ['DB_HOST', 'DB_USER', 'DB_NAME'],
    optional: ['DB_PASSWORD']
  },
  auth: {
    name: 'Authentication',
    vars: ['JWT_SECRET'],
    optional: []
  },
  google: {
    name: 'Google OAuth',
    vars: ['GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET'],
    optional: [],
    warning: 'Required for Google Sign-In to work'
  },
  email: {
    name: 'Email Service',
    vars: ['EMAIL_HOST', 'EMAIL_PORT', 'EMAIL_USER', 'EMAIL_PASSWORD', 'EMAIL_FROM'],
    optional: [],
    warning: 'Optional: Password reset emails will show token in console if not configured'
  }
};

console.log('\n🔍 GYMatch Backend Configuration Check\n');
console.log('═'.repeat(60));

let allRequired = true;
let hasWarnings = false;

Object.entries(checks).forEach(([key, config]) => {
  console.log(`\n📦 ${config.name}`);
  console.log('─'.repeat(60));
  
  let sectionComplete = true;
  
  config.vars.forEach(varName => {
    const value = process.env[varName];
    const isSet = value && value.trim() !== '' && !value.includes('your_') && !value.includes('_here');
    
    if (isSet) {
      console.log(`  ✅ ${varName}: Set`);
    } else {
      console.log(`  ❌ ${varName}: NOT SET or using placeholder`);
      sectionComplete = false;
      allRequired = false;
    }
  });
  
  if (config.optional && config.optional.length > 0) {
    config.optional.forEach(varName => {
      const value = process.env[varName];
      const isSet = value && value.trim() !== '';
      
      if (isSet) {
        console.log(`  ✅ ${varName}: Set (optional)`);
      } else {
        console.log(`  ⚠️  ${varName}: Not set (optional)`);
      }
    });
  }
  
  if (!sectionComplete && config.warning) {
    console.log(`  ⚠️  ${config.warning}`);
    hasWarnings = true;
  }
});

console.log('\n' + '═'.repeat(60));

// Summary
if (allRequired && !hasWarnings) {
  console.log('\n✅ All required configuration is set!\n');
  console.log('You can start the server with: npm run dev\n');
} else if (allRequired) {
  console.log('\n✅ Required configuration is set\n');
  console.log('⚠️  Optional features may not work (see warnings above)\n');
  console.log('You can start the server with: npm run dev\n');
} else {
  console.log('\n❌ Missing required configuration!\n');
  console.log('Please update your .env file with the required values.\n');
  console.log('See FIXES_SUMMARY.md or GOOGLE_OAUTH_SETUP.md for help.\n');
}

// Additional checks
console.log('📝 Additional Information:');
console.log('─'.repeat(60));
console.log(`  Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`  Port: ${process.env.PORT || '5000'}`);
console.log(`  Database: ${process.env.DB_NAME || 'gymatch_db'}`);
console.log('');

// Test database connection
if (process.env.DB_HOST && process.env.DB_USER && process.env.DB_NAME) {
  console.log('💡 Tip: To test database connection, run: npm run dev');
}

console.log('');
