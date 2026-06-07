const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Create reusable transporter
    this.transporter = nodemailer.createTransport({
      host: process.env.EMAIL_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.EMAIL_PORT || '587'),
      secure: false, // true for 465, false for other ports
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
      },
    });
  }

  async sendPasswordResetEmail(email, resetToken) {
    try {
      // Get domain from environment or use default
      const appDomain = process.env.APP_DOMAIN || 'gymatch.com';
      const webDomain = process.env.WEB_DOMAIN || 'app.gymatch.com';

      // Mobile app deep link (will open directly in app if installed)
      const appDeepLink = `https://${appDomain}/reset-password?token=${resetToken}`;
      // Fallback web URL (if app is not installed or on desktop)
      const webUrl = `https://${webDomain}/reset-password?token=${resetToken}`;

      // For development/testing, also include app scheme
      const devDeepLink = `gymatch://reset?token=${resetToken}`;

      const mailOptions = {
        from: process.env.EMAIL_FROM || '"GYMatch" <noreply@gymatch.com>',
        to: email,
        subject: 'Reset Your GYMatch Password',
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; background-color: #000000; color: #ffffff; padding: 20px; }
              .container { max-width: 600px; margin: 0 auto; background-color: #1A1A1A; border-radius: 10px; padding: 30px; }
              .logo { text-align: center; font-size: 32px; font-weight: 900; color: #CBF135; letter-spacing: 3px; margin-bottom: 20px; }
              .content { color: #ffffff; line-height: 1.6; }
              .button { display: inline-block; background-color: #CBF135; color: #000000; padding: 14px 32px; text-decoration: none; border-radius: 27px; font-weight: 800; margin: 20px 0; }
              .footer { color: #666666; font-size: 12px; text-align: center; margin-top: 30px; }
              .token-box { background-color: #252525; padding: 15px; border-radius: 8px; margin: 20px 0; font-family: monospace; color: #CBF135; word-break: break-all; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="logo">GYMATCH</div>
              <div class="content">
                <h2 style="color: #CBF135;">Reset Your Password</h2>
                <p>We received a request to reset your password. Click the button below to create a new password:</p>
                
                <div style="text-align: center;">
                  <a href="${appDeepLink}" class="button">Reset Password in App</a>
                </div>
                
                <p style="color: #999999; font-size: 14px; margin-top: 20px;">
                 Tap the button above to open directly in the GYMatch app.
                </p>
                                
                <p style="color: #999999; font-size: 13px;">
                  If you didn't request a password reset, you can safely ignore this email.
                </p>
              </div>
              <div class="footer">
                <p>© 2024 GYMatch. All rights reserved.</p>
                <p>This is an automated email, please do not reply.</p>
              </div>
            </div>
          </body>
          </html>
        `,
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Password reset email sent:', info.messageId);
      return true;
    } catch (error) {
      console.error('Error sending password reset email:', error);
      return false;
    }
  }

  // Test email configuration
  async verifyConnection() {
    try {
      await this.transporter.verify();
      console.log('Email service is ready to send emails');
      return true;
    } catch (error) {
      console.error('Email service connection error:', error);
      return false;
    }
  }
}

module.exports = new EmailService();
