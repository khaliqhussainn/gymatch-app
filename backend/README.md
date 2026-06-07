# GYMatch Backend

Node.js/Express backend for the GYMatch mobile application.

## Features

- ✅ User authentication (email/password)
- ✅ Google OAuth integration
- ✅ JWT token-based authorization
- ✅ Password reset via email
- ✅ Gym discovery and search
- ✅ Active workout partner matching
- ✅ Saved/favorite gyms
- ✅ User profiles

## Prerequisites

- Node.js 16+ 
- MySQL 5.7+ (XAMPP recommended for Windows)
- npm or yarn

## Quick Start

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Setup database**:
   ```bash
   # Start MySQL (XAMPP)
   # Then run:
   mysql -u root < setup.sql
   
   # Or run the migration:
   mysql -u root < migration_fix_password.sql
   ```

4. **Start development server**:
   ```bash
   npm run dev
   ```

   The server will start on http://localhost:5000

## Configuration

### Required Environment Variables

```env
# Server
PORT=5000
NODE_ENV=development
JWT_SECRET=your_jwt_secret_here

# Database
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=gymatch_db
```

### Optional: Google OAuth

See `../SETUP_GUIDE.md` for detailed instructions.

```env
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret
```

### Optional: Email Service

For password reset emails. See `../SETUP_GUIDE.md` for setup.

```env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
EMAIL_FROM=GYMatch <noreply@gymatch.com>
```

## Testing Email Service

Test if your email configuration is working:

```bash
node test-email.js your-email@example.com
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with email/password
- `POST /api/auth/google` - Login with Google
- `POST /api/auth/guest` - Get guest token
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password with token

### Gyms
- `GET /api/gyms` - Get nearby gyms
- `GET /api/gyms/:id` - Get gym details
- `POST /api/gyms/:id/favorite` - Toggle favorite gym
- `GET /api/gyms/favorites` - Get saved gyms
- `GET /api/gyms/:id/active-partners` - Get active workout partners
- `POST /api/gyms/:id/partner-toggle` - Toggle active status

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users/matches` - Get matched partners

## Project Structure

```
backend/
├── config/
│   ├── db.js           # Database configuration
│   └── connection.js   # MySQL connection pool
├── controllers/
│   ├── authController.js
│   ├── userController.js
│   └── gymController.js
├── middleware/
│   └── authMiddleware.js
├── models/
│   ├── User.js
│   └── Gym.js
├── routes/
│   ├── authRoutes.js
│   ├── userRoutes.js
│   └── gymRoutes.js
├── services/
│   └── emailService.js
├── server.js
├── setup.sql
└── package.json
```

## Development

### Running Tests

```bash
npm test
```

### Linting

```bash
npm run lint
```

### Database Migrations

When schema changes are needed:

1. Create a new migration file: `migration_description.sql`
2. Run it: `mysql -u root < migration_description.sql`
3. Document it in this README

## Troubleshooting

### MySQL Connection Issues

**Error: `ECONNREFUSED ::1:3306`**
- Make sure MySQL is running (start XAMPP)
- Check DB_HOST, DB_USER, DB_PASSWORD in .env
- Verify database `gymatch_db` exists

### Google OAuth Issues

**Error: "Invalid client ID"**
- Check GOOGLE_CLIENT_ID in .env
- Verify it matches your Google Cloud Console

### Email Not Sending

**Error: "Invalid login"**
- For Gmail, use an App Password (not regular password)
- Enable 2-Factor Authentication first
- Run: `node test-email.js your@email.com` to test

### Module Not Found

```bash
npm install
```

### Port Already in Use

Change PORT in .env or stop the other process:

```bash
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

## Production Deployment

1. Set `NODE_ENV=production`
2. Use strong JWT_SECRET (64+ characters)
3. Configure SSL/HTTPS
4. Use environment variables (never commit .env)
5. Set up proper CORS origins
6. Enable rate limiting
7. Set up monitoring and logging

## Support

- See `../SETUP_GUIDE.md` for configuration help
- See `../FIXES_SUMMARY.md` for recent changes
- Check server logs: `npm run dev`

## License

MIT
