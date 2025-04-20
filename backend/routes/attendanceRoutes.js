const express = require("express");
const router = express.Router();
const attendance = require("../models/attendanceSchema.js");

// Get all attendance records
router.get("/", async (req, res) => {
  try {
    const allRecords = await attendance.find({});
    res.status(200).json(allRecords);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// Delete all attendance records
router.delete("/", async (req, res) => {
  try {
    const result = await attendance.deleteMany({});
    res.status(200).json({ message: "All attendance records deleted", deletedCount: result.deletedCount });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// ✅ Utility function
function countAttendance(records) {
  let present = 0, absent = 0;
  for (const record of records) {
    if (record.isPresent) present++;
    else absent++;
  }
  return { present, absent, total: present + absent };
}

// 📅 1. Attendance for today
router.get("/:subject/:studentRoll/today", async (req, res) => {
  try {
    const { subject, studentRoll } = req.params;

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const records = await attendance.find({
      subject,
      studentRoll,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    });

    res.json(countAttendance(records));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📅 2. Attendance for last 7 days
router.get("/:subject/:studentRoll/last7days", async (req, res) => {
  try {
    const { subject, studentRoll } = req.params;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 7);
    startDate.setHours(0, 0, 0, 0);

    const endDate = new Date();

    const records = await attendance.find({
      subject,
      studentRoll,
      createdAt: { $gte: startDate, $lte: endDate },
    });

    res.json(countAttendance(records));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📅 3. Attendance for last 30 days
router.get("/:subject/:studentRoll/last30days", async (req, res) => {
  try {
    const { subject, studentRoll } = req.params;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    startDate.setHours(0, 0, 0, 0);

    const endDate = new Date();

    const records = await attendance.find({
      subject,
      studentRoll,
      createdAt: { $gte: startDate, $lte: endDate },
    });

    res.json(countAttendance(records));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📅 4. All-time attendance
router.get("/:subject/:studentRoll/total", async (req, res) => {
  try {
    const { dept, studentRoll, subject } = req.params;

    const records = await attendance.find({ dept, studentRoll, subject });

    res.json(countAttendance(records));
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

//To get all student record for a particular subject for today
router.get("/:dept/:className/:subject/today", async (req, res) => {
  try {
    const { dept, className, subject } = req.params;
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);
    const record = await attendance.find({
      dept,
      className,
      subject,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    });
    res.status(200).json(record);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

/**
 * GET /api/attendance/:dept/:className/:subject/lastclasses
 * Returns the last 7 class sessions (distinct by timestamp) for the given dept/class/subject,
 * each with counts of present and absent students.
 */
router.get("/:dept/:className/:subject/lastclasses", async (req, res) => {
  try {
    const { dept, className, subject } = req.params;

    const result = await attendance.aggregate([
      // 1) Filter to the requested dept, className, and subject
      {
        $match: { dept, className, subject }
      },

      // 2) Project a "sessionKey" including full date+time up to seconds
      {
        $project: {
          sessionKey: {
            $dateToString: {
              format: "%Y-%m-%dT%H:%M:%S",
              date: "$createdAt"
            }
          },
          isPresent: 1
        }
      },

      // 3) Group by sessionKey to tally present/absent per session
      {
        $group: {
          _id: "$sessionKey",
          presentCount: {
            $sum: { $cond: ["$isPresent", 1, 0] }
          },
          absentCount: {
            $sum: { $cond: ["$isPresent", 0, 1] }
          }
        }
      },

      // 4) Sort sessions newest first and limit to 7
      { $sort: { "_id": -1 } },
      { $limit: 7 },

      // 5) Re-sort back to oldest→newest
      { $sort: { "_id": 1 } },

      // 6) Project final fields: sessionTime, studentsPresent, studentsAbsent
      {
        $project: {
          _id: 0,
          sessionTime: "$_id",
          studentsPresent: "$presentCount",
          studentsAbsent: "$absentCount"
        }
      }
    ]);

    return res.status(200).json(result);
  } catch (err) {
    console.error("Error fetching lastclasses:", err);
    return res.status(500).json({ error: err.message });
  }
});

// to get total classes of a subject
router.get("/totalClasses/:dept/:className/:subject", async (req, res) => {
  try {
    const { dept, className, subject } = req.params;
    const totalClasses = await attendance.aggregate([
      { $match: { dept: dept, className: className, subject: subject } },
      {
        $group: {
          _id: {
            dateTime: {
              $dateToString: {
                format: "%Y-%m-%d %H:%M:%S",
                date: "$createdAt",
              },
            },
          },
        },
      },
      {
        $count: "totalClasses",
      },
    ]);
    res.status(200).json({ totalClasses: totalClasses[0]?.totalClasses || 0 });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add multiple day attendances for a student for a subject
router.post("/multiple", async (req, res) => {
  try {
    const {
      studentName,
      studentRoll,
      dept,
      className,
      subject,
      attendanceRecords, // Array of { isPresent: Boolean, createdAt: Date }
    } = req.body;

    if (!Array.isArray(attendanceRecords) || attendanceRecords.length === 0) {
      return res.status(400).json({ error: "attendanceRecords must be a non-empty array" });
    }

    const recordsToInsert = attendanceRecords.map((record) => ({
      studentName,
      studentRoll,
      dept,
      className,
      subject,
      isPresent: record.isPresent,
      createdAt: record.createdAt ? new Date(record.createdAt) : new Date(),
    }));

    const insertedRecords = await attendance.insertMany(recordsToInsert);
    res.status(201).json({ message: "Multiple attendances added", data: insertedRecords });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// to add attendance-working
router.post("/", async (req, res) => {
  try {
    const {
      studentName,
      studentRoll,
      dept,
      className,
      subject,
      isPresent,
      createdAt // grab createdAt from body if it exists
    } = req.body;

    const attendanceData = await attendance.create({
      studentName,
      studentRoll,
      dept,
      className,
      subject,
      isPresent,
      ...(createdAt && { createdAt: new Date(createdAt) }) // only include if provided
    });

    res.status(201).json(attendanceData);
  } catch (err) {
    res.status(500).json({ err: err.message });
  }
});


module.exports = router;
