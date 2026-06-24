const pool = require('../config/connection');

/**
 * POST /api/chats/invite (requires auth)
 * Body: gymId, partnerId, matchType
 */
exports.invitePartner = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { gymId, partnerId, matchType } = req.body;

    if (!gymId || !partnerId) {
      return res.status(400).json({ error: 'gymId and partnerId are required.' });
    }

    if (userId === parseInt(partnerId, 10)) {
      return res.status(400).json({ error: 'You cannot match with yourself.' });
    }

    // Check if an active thread already exists
    const [existing] = await pool.query(
      `SELECT id FROM chat_threads 
       WHERE gym_id = ? 
         AND ((user_1 = ? AND user_2 = ?) OR (user_1 = ? AND user_2 = ?))
         AND expires_at > NOW()`,
      [gymId, userId, partnerId, partnerId, userId]
    );

    if (existing.length > 0) {
      return res.json({ threadId: existing[0].id, msg: 'Active chat thread already exists.' });
    }

    // Create a new thread with a 24-hour expiration
    const type = matchType || 'CROSSFIT';
    const [result] = await pool.query(
      `INSERT INTO chat_threads (gym_id, user_1, user_2, match_type, expires_at)
       VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))`,
      [gymId, userId, partnerId, type]
    );

    const threadId = result.insertId;

    // Send a system message or a prompt greeting
    await pool.query(
      `INSERT INTO chat_messages (thread_id, sender_id, message_text)
       VALUES (?, ?, ?)`,
      [threadId, userId, `Hey! I matched with you at this gym for ${type}. Down to work out?`]
    );

    try {
      // Get sender name
      const [senderProfile] = await pool.query('SELECT name FROM profiles WHERE user_id = ?', [userId]);
      const senderName = (senderProfile[0] && senderProfile[0].name) || 'A training partner';

      // Get gym name
      const [gymInfo] = await pool.query('SELECT name FROM gyms WHERE id = ?', [gymId]);
      const gymName = (gymInfo[0] && gymInfo[0].name) || 'Gold\'s Gym';

      // Create notification
      await pool.query(
        `INSERT INTO notifications (user_id, title, body, type, gym_id)
         VALUES (?, ?, ?, ?, ?)`,
        [
          partnerId,
          'New Match Found',
          `${senderName} is looking for a ${type.toLowerCase()} partner at ${gymName} right now.`,
          'chats',
          gymId
        ]
      );
    } catch (notifErr) {
      console.error('[ChatController.invitePartner.notification]', notifErr);
    }

    res.status(201).json({ threadId, msg: 'Matched! Chat thread initiated.' });
  } catch (error) {
    console.error('[ChatController.invitePartner]', error);
    res.status(500).json({ error: 'Failed to match with partner.' });
  }
};

/**
 * GET /api/chats/threads (requires auth)
 */
exports.getThreads = async (req, res) => {
  try {
    const userId = req.user.userId;

    const query = `
      SELECT 
        ct.id AS thread_id,
        ct.gym_id,
        ct.match_type,
        ct.created_at,
        ct.expires_at,
        g.name AS gym_name,
        other_u.id AS partner_id,
        other_u.email AS partner_email,
        other_p.name AS partner_name,
        lm.message_text AS latest_message,
        lm.created_at AS latest_message_time
      FROM chat_threads ct
      JOIN gyms g ON ct.gym_id = g.id
      JOIN users other_u ON (other_u.id = ct.user_1 AND ct.user_2 = ?) OR (other_u.id = ct.user_2 AND ct.user_1 = ?)
      LEFT JOIN profiles other_p ON other_u.id = other_p.user_id
      LEFT JOIN (
        SELECT m1.*
        FROM chat_messages m1
        LEFT JOIN chat_messages m2 ON m1.thread_id = m2.thread_id AND m1.id < m2.id
        WHERE m2.id IS NULL
      ) lm ON ct.id = lm.thread_id
      WHERE (ct.user_1 = ? OR ct.user_2 = ?)
        AND ct.expires_at > NOW()
      ORDER BY COALESCE(lm.created_at, ct.created_at) DESC
    `;

    const [rows] = await pool.query(query, [userId, userId, userId, userId]);
    
    const threads = rows.map(r => {
      // Calculate remaining hours
      const expiresAt = new Date(r.expires_at);
      const now = new Date();
      const diffMs = expiresAt - now;
      const diffHours = Math.max(0, Math.floor(diffMs / (1000 * 60 * 60)));
      const diffMins = Math.max(0, Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60)));

      let timeLabel = `${diffHours}h left`;
      if (diffHours === 0) {
        timeLabel = `${diffMins}m left`;
      }

      return {
        id: r.thread_id,
        gymId: r.gym_id,
        gymName: r.gym_name,
        matchType: r.match_type,
        partnerId: r.partner_id,
        partnerName: r.partner_name || r.partner_email.split('@')[0],
        latestMessage: r.latest_message || 'No messages yet.',
        latestMessageTime: r.latest_message_time || r.created_at,
        timeLabel: timeLabel,
        expiresAt: r.expires_at
      };
    });

    res.json({ threads, count: threads.length });
  } catch (error) {
    console.error('[ChatController.getThreads]', error);
    res.status(500).json({ error: 'Failed to retrieve chat threads.' });
  }
};

/**
 * GET /api/chats/threads/:threadId/messages (requires auth)
 */
exports.getMessages = async (req, res) => {
  try {
    const userId = req.user.userId;
    const threadId = parseInt(req.params.threadId, 10);

    // Validate that the user is part of the thread
    const [threadCheck] = await pool.query(
      'SELECT 1 FROM chat_threads WHERE id = ? AND (user_1 = ? OR user_2 = ?)',
      [threadId, userId, userId]
    );

    if (threadCheck.length === 0) {
      return res.status(403).json({ error: 'You are not authorized to view this chat.' });
    }

    const [rows] = await pool.query(
      `SELECT cm.id, cm.thread_id, cm.sender_id, cm.message_text, cm.created_at
       FROM chat_messages cm
       WHERE cm.thread_id = ?
       ORDER BY cm.created_at ASC`,
      [threadId]
    );

    const messages = rows.map(r => ({
      id: r.id,
      threadId: r.thread_id,
      senderId: r.sender_id,
      message: r.message_text,
      createdAt: r.created_at,
      isMe: r.sender_id === userId
    }));

    res.json({ messages });
  } catch (error) {
    console.error('[ChatController.getMessages]', error);
    res.status(500).json({ error: 'Failed to fetch messages.' });
  }
};

/**
 * POST /api/chats/threads/:threadId/messages (requires auth)
 * Body: messageText
 */
exports.sendMessage = async (req, res) => {
  try {
    const userId = req.user.userId;
    const threadId = parseInt(req.params.threadId, 10);
    const { messageText } = req.body;

    if (!messageText || !messageText.trim()) {
      return res.status(400).json({ error: 'Message text cannot be empty.' });
    }

    // Validate that the user is part of the thread
    const [threadCheck] = await pool.query(
      'SELECT expires_at, user_1, user_2, gym_id FROM chat_threads WHERE id = ? AND (user_1 = ? OR user_2 = ?)',
      [threadId, userId, userId]
    );

    if (threadCheck.length === 0) {
      return res.status(403).json({ error: 'You are not authorized to send messages in this chat.' });
    }

    const expiresAt = new Date(threadCheck[0].expires_at);
    if (expiresAt < new Date()) {
      return res.status(400).json({ error: 'This chat thread has expired.' });
    }

    const [result] = await pool.query(
      `INSERT INTO chat_messages (thread_id, sender_id, message_text)
       VALUES (?, ?, ?)`,
      [threadId, userId, messageText.trim()]
    );

    try {
      const thread = threadCheck[0];
      const recipientId = userId === thread.user_1 ? thread.user_2 : thread.user_1;
      const gymId = thread.gym_id;

      // Get sender name
      const [senderProfile] = await pool.query('SELECT name FROM profiles WHERE user_id = ?', [userId]);
      const senderName = (senderProfile[0] && senderProfile[0].name) || 'Partner';

      // Create notification
      await pool.query(
        `INSERT INTO notifications (user_id, title, body, type, gym_id)
         VALUES (?, ?, ?, ?, ?)`,
        [
          recipientId,
          'New Message',
          `New message from ${senderName}: "${messageText.trim().substring(0, 40)}${messageText.trim().length > 40 ? '...' : ''}"`,
          'chats',
          gymId
        ]
      );
    } catch (notifErr) {
      console.error('[ChatController.sendMessage.notification]', notifErr);
    }

    res.status(201).json({
      id: result.insertId,
      threadId,
      senderId: userId,
      message: messageText.trim(),
      createdAt: new Date(),
      isMe: true
    });
  } catch (error) {
    console.error('[ChatController.sendMessage]', error);
    res.status(500).json({ error: 'Failed to send message.' });
  }
};

/**
 * GET /api/chats/thread-with/:partnerId (requires auth)
 * Returns the active thread with a specific partner, if one exists.
 */
exports.getThreadWithPartner = async (req, res) => {
  try {
    const userId = req.user.userId;
    const partnerId = parseInt(req.params.partnerId, 10);

    if (isNaN(partnerId)) {
      return res.status(400).json({ error: 'Invalid partner id.' });
    }

    const [rows] = await pool.query(
      `SELECT id FROM chat_threads
       WHERE ((user_1 = ? AND user_2 = ?) OR (user_1 = ? AND user_2 = ?))
         AND expires_at > NOW()
       LIMIT 1`,
      [userId, partnerId, partnerId, userId]
    );

    if (rows.length > 0) {
      return res.json({ matched: true, threadId: rows[0].id });
    }

    res.json({ matched: false, threadId: null });
  } catch (error) {
    console.error('[ChatController.getThreadWithPartner]', error);
    res.status(500).json({ error: 'Failed to check match status.' });
  }
};

/**
 * DELETE /api/chats/threads/:threadId (requires auth)
 * Unmatch — only the requesting user's side is removed.
 * Both messages and the thread row are deleted.
 */
exports.deleteThread = async (req, res) => {
  try {
    const userId = req.user.userId;
    const threadId = parseInt(req.params.threadId, 10);

    // Verify the user owns this thread
    const [threadCheck] = await pool.query(
      'SELECT id, user_1, user_2 FROM chat_threads WHERE id = ? AND (user_1 = ? OR user_2 = ?)',
      [threadId, userId, userId]
    );

    if (threadCheck.length === 0) {
      return res.status(403).json({ error: 'Thread not found or you are not part of it.' });
    }

    // Delete messages first (FK constraint), then the thread
    await pool.query('DELETE FROM chat_messages WHERE thread_id = ?', [threadId]);
    await pool.query('DELETE FROM chat_threads WHERE id = ?', [threadId]);

    res.json({ success: true, message: 'Match removed successfully.' });
  } catch (error) {
    console.error('[ChatController.deleteThread]', error);
    res.status(500).json({ error: 'Failed to remove match.' });
  }
};
