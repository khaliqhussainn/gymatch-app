const pool = require('../config/connection');

/**
 * GET /api/notifications
 * Get all notifications for authenticated user
 */
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.userId;
    const [rows] = await pool.query(
      `SELECT id, title, body, type, gym_id, is_read, created_at 
       FROM notifications 
       WHERE user_id = ? 
       ORDER BY created_at DESC`,
      [userId]
    );

    const notifications = rows.map(r => ({
      id: r.id,
      title: r.title,
      body: r.body,
      type: r.type,
      gymId: r.gym_id,
      isRead: !!r.is_read,
      createdAt: r.created_at
    }));

    res.json({ notifications, count: notifications.length });
  } catch (error) {
    console.error('[NotificationController.getNotifications]', error);
    res.status(500).json({ error: 'Failed to retrieve notifications.' });
  }
};

/**
 * POST /api/notifications/:id/read
 * Mark notification as read
 */
exports.markRead = async (req, res) => {
  try {
    const userId = req.user.userId;
    const id = parseInt(req.params.id, 10);

    const [result] = await pool.query(
      `UPDATE notifications 
       SET is_read = TRUE 
       WHERE id = ? AND user_id = ?`,
      [id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Notification not found.' });
    }

    res.json({ message: 'Notification marked as read.' });
  } catch (error) {
    console.error('[NotificationController.markRead]', error);
    res.status(500).json({ error: 'Failed to update notification.' });
  }
};

/**
 * POST /api/notifications/read-all
 * Mark all notifications as read
 */
exports.markAllRead = async (req, res) => {
  try {
    const userId = req.user.userId;

    await pool.query(
      `UPDATE notifications 
       SET is_read = TRUE 
       WHERE user_id = ?`,
      [userId]
    );

    res.json({ message: 'All notifications marked as read.' });
  } catch (error) {
    console.error('[NotificationController.markAllRead]', error);
    res.status(500).json({ error: 'Failed to update notifications.' });
  }
};

/**
 * POST /api/notifications/clear
 * Clear all notifications
 */
exports.clearAll = async (req, res) => {
  try {
    const userId = req.user.userId;

    await pool.query(
      `DELETE FROM notifications 
       WHERE user_id = ?`,
      [userId]
    );

    res.json({ message: 'All notifications cleared.' });
  } catch (error) {
    console.error('[NotificationController.clearAll]', error);
    res.status(500).json({ error: 'Failed to clear notifications.' });
  }
};
