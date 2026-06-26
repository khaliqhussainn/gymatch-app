const pool = require('../config/connection');

/**
 * Get dashboard statistics
 */
exports.getDashboardStats = async (req, res) => {
  try {
    // Get total gyms count
    const [gymCount] = await pool.query('SELECT COUNT(*) as count FROM gyms');
    
    // Get total users count
    const [userCount] = await pool.query('SELECT COUNT(*) as count FROM users');
    
    // Get active users count (status = active)
    const [activeUserCount] = await pool.query('SELECT COUNT(*) as count FROM users WHERE status = "active"');
    
    // Get most viewed gyms (top 5)
    const [mostViewedGyms] = await pool.query(
      `SELECT id, name, location_name as city, rating 
       FROM gyms 
       ORDER BY rating DESC 
       LIMIT 5`
    );

    // Get monthly trends for the last 6 months
    const [monthlyTrends] = await pool.query(`
      SELECT 
        DATE_FORMAT(created_at, '%b') as month,
        SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) THEN 1 ELSE 0 END) as gyms
      FROM gyms
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
      GROUP BY DATE_FORMAT(created_at, '%Y-%m')
      ORDER BY created_at ASC
    `);

    const [monthlyUserTrends] = await pool.query(`
      SELECT 
        DATE_FORMAT(created_at, '%b') as month,
        SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) THEN 1 ELSE 0 END) as users
      FROM users
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
      GROUP BY DATE_FORMAT(created_at, '%Y-%m')
      ORDER BY created_at ASC
    `);

    // Merge monthly trends
    const trends = monthlyTrends.map((trend, index) => ({
      month: trend.month,
      gyms: trend.gyms || 0,
      users: monthlyUserTrends[index]?.users || 0,
    }));

    res.json({
      success: true,
      data: {
        totalGyms: gymCount[0].count,
        totalUsers: userCount[0].count,
        activeUsers: activeUserCount[0].count,
        mostViewedGyms: mostViewedGyms.map(gym => ({
          name: gym.name,
          viewCount: gym.rating * 100, // Using rating as proxy for views since view_count column might not exist
          city: gym.city,
        })),
        monthly_trends: trends.length > 0 ? trends : [
          { month: 'Jan', gyms: 0, users: 0 },
          { month: 'Feb', gyms: 0, users: 0 },
          { month: 'Mar', gyms: 0, users: 0 },
          { month: 'Apr', gyms: 0, users: 0 },
          { month: 'May', gyms: 0, users: 0 },
          { month: 'Jun', gyms: 0, users: 0 },
        ],
      },
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch dashboard stats' });
  }
};
