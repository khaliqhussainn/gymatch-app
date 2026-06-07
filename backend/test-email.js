#!/usr/bin/env node

/**
 * Test Email Service Configuration
 * 
 * Usage: node test-email.js
 * 
 * This will test if your email configuration is working
 * without actually sending an email.
 */

require('dotenv').config();
const emailService = require('./services/emailService');

console.log('\n📧 Testing Email Service Configuration\n');
console.log('═'.repeat(60));

// Check if email variables are configured
const emailConfigured = 
  process.env.EMAIL_USER && 
  process.env.EMAIL_PASSWORD &&
  !process.env.EMAIL_USER.includes('your_') &&
  !process.env.EMAIL_PASSWORD.includes('your_');

if (!emailConfigured) {
  console.log('\n⚠️  Email Not Configured');
  console.log('─'.repeat(60));
  console.log('Email service is not configured in .env file.');
  console.log('\nThis is OK! Password reset will work by showing the token in:');
  console.log('  • API response (visible in network tab)');
  console.log('  • Backend console logs');
  console.log('\nTo enable email sending, configure these in .env:');
  console.log('  • EMAIL_USER');
  console.log('  • EMAIL_PASSWORD');
  console.log('\nSee QUICK_START.md for Gmail setup instructions.\n');
  process.exit(0);
}

console.log('\n✅ Email Variables Set');
console.log('─'.repeat(60));
console.log(`  Host: ${process.env.EMAIL_HOST}`);
console.log(`  Port: ${process.env.EMAIL_PORT}`);
console.log(`  User: ${process.env.EMAIL_USER}`);
console.log(`  From: ${process.env.EMAIL_FROM}`);

console.log('\n🔄 Testing Connection...\n');

emailService.verifyConnection()
  .then(isConnected => {
    if (isConnected) {
      console.log('✅ Email Service Connected Successfully!\n');
      console.log('Password reset emails will be sent automatically.\n');
      console.log('To test, use the Forgot Password flow in the app.\n');
    } else {
      console.log('❌ Email Service Connection Failed\n');
      console.log('Common issues:');
      console.log('  • Wrong email/password');
      console.log('  • Need to use Gmail App Password (not regular password)');
      console.log('  • 2FA not enabled on Gmail account');
      console.log('\nThe app will still work - tokens will show in console.\n');
      console.log('See QUICK_START.md for setup help.\n');
    }
  })
  .catch(error => {
    console.log('❌ Error Testing Email Service\n');
    console.error(error.message);
    console.log('\nThe app will still work - tokens will show in console.\n');
  });
