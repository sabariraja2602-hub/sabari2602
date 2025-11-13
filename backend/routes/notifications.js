const express = require('express');
const router = express.Router();
const Notification = require("../models/notifications");

// 🔹 Get ALL notifications for a specific employee with optional month & category filter
router.get('/employee/:empId', async (req, res) => {
  try {
    const { empId } = req.params;
    const { month, category } = req.query;

    const query = {
      $or: [
        { empId },
        { empId: null },
        { empId: "" }
      ]
    };

    if (month) {
      query.month = { $regex: new RegExp(`^${month}$`, 'i') };
    }

    if (category) {
      query.category = { $regex: new RegExp(`^${category}$`, 'i') };
    }

    const notifications = await Notification.find(query).sort({ createdAt: -1 });

    if (!notifications.length) {
      return res.status(404).json({ message: "No notifications found for this employee" });
    }

    res.json(notifications);
  } catch (err) {
    console.error("Error fetching notifications:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// 2️⃣ Performance → Admin view
router.get('/performance/admin/:month', async (req, res) => {
  const { month } = req.params;
  try {
    const notifications = await Notification.find({
      category: "performance",
      month: { $regex: new RegExp(`^${month}$`, 'i') }
    });

    if (!notifications.length) {
      return res.status(404).json({ message: 'No performance notifications for admin' });
    }

    res.json(notifications);
  } catch (err) {
    console.error('Error fetching performance notifications for admin:', err);
    res.status(500).json({ message: 'Server error' });
  }
});


// 3️⃣ Performance → Employee view
router.get('/performance/employee/:month/:empId', async (req, res) => {
  const { month, empId } = req.params;
  try {
    const notifications = await Notification.find({
      category: "performance",
      month: { $regex: new RegExp(`^${month}$`, 'i') },
      $or: [
        { empId },
        { empId: null },
        { empId: "" }
      ],
    });

    if (!notifications.length) {
      return res.status(404).json({ message: "No performance notifications for this employee" });
    }

    res.json(notifications);
  } catch (err) {
    console.error("Error fetching performance for employee:", err);
    res.status(500).json({ message: 'Server error' });
  }
});


// 4️⃣ Holidays → Admin view
router.get('/holiday/admin/:month', async (req, res) => {
  const { month } = req.params;
  try {
    const notifications = await Notification.find({
      category: "holiday",
      month: { $regex: new RegExp(`^${month}$`, 'i') }
    });

    if (!notifications.length) {
      return res.status(404).json({ message: "No holiday notifications found" });
    }

    res.json(notifications);
  } catch (err) {
    console.error("Error fetching holiday notifications:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// 5️⃣ Holidays → Employee view  ✅ NEW
router.get('/holiday/employee/:empId', async (req, res) => {
  try {
    const { empId } = req.params;
    const { month } = req.query;

    const query = {
      category: "holiday",
      $or: [
        { empId },
        { empId: null },
        { empId: "" }
      ]
    };

    if (month) {
      query.month = { $regex: new RegExp(`^${month}$`, 'i') };
    }

    const notifications = await Notification.find(query).sort({ createdAt: -1 });

    if (!notifications.length) {
      return res.status(404).json({ message: "No holiday notifications for this employee" });
    }

    res.json(notifications);
  } catch (err) {
    console.error("Error fetching holiday for employee:", err);
    res.status(500).json({ message: "Server error" });
  }
});


// ✅ Add a new notification
router.post('/', async (req, res) => {
  try {
    const { month, category, message, empId, senderName, senderId, flag } = req.body;

    if (!message || !empId || !category) {
      return res.status(400).json({ message: "Required fields are missing" });
    }

    const newNotification = new Notification({
      month,
      category,
      message,
      empId,
      senderName: senderName || "",
      senderId: senderId || "",
      flag: flag || ""
    });

    await newNotification.save();
    res.status(201).json({ message: 'Notification added successfully' });
  } catch (err) {
    console.error('Error adding notification:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
