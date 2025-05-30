const express = require('express')
const mongoose = require('mongoose')

const Routine = require('../models/sessionSchema')
const Teacher = require('../models/teacherSchema'); 

const router = express.Router()

// Get unique subject names for a particular dept, sem, section
router.get('/uniqueSubjects/:department/:semester/:section', async (req, res) => {
    const { department, semester, section } = req.params;

    if (!department || !semester || !section) {
        return res.status(400).json({ message: "Department, semester, and section are required." });
    }

    try {
        const uniqueSubjects = await Routine.distinct("subject", {
            department,
            semester,
            section
        });

        if (!uniqueSubjects.length) {
            return res.status(404).json({ message: "No subjects found for the specified parameters." });
        }

        res.status(200).json({ subjects: uniqueSubjects });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// Get sessions by department, semester, section and day
router.get('/classRoutine/:department/:semester/:section/:day', async (req, res) => {
    const { department, semester, section, day } = req.params;

    if (!department || !semester || !section || !day) {
        return res.status(400).json({ message: "All query parameters (department, semester, section, day) are required." });
    }

    try {
        const sessions = await Routine.find({
            department,
            semester,
            section,
            day
        });

        if (!sessions.length) {
            return res.status(404).json({ message: "No sessions found for the specified parameters." });
        }

        // Sort sessions based on startTime in hh:mm AM/PM format
        sessions.sort((a, b) => {
            const parseTime = (timeStr) => {
                const [time, modifier] = timeStr.split(" ");
                let [hours, minutes] = time.split(":").map(Number);

                if (modifier === "PM" && hours !== 12) hours += 12;
                if (modifier === "AM" && hours === 12) hours = 0;

                return hours * 60 + minutes;
            };

            return parseTime(a.startTime) - parseTime(b.startTime);
        });

        res.status(200).json({ sessions });

    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});



// Delete all routines (sessions)
router.delete('/', async (req, res) => {
    try {
        const result = await Routine.deleteMany({});
        res.status(200).json({
            message: "All sessions deleted successfully",
            deletedCount: result.deletedCount
        });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// Get all sessions for a particular teacher irrespective of day
router.get('/all/:teacherId', async (req, res) => {
    try {
        const { teacherId } = req.params
        const sessions = await Routine.find({ teacherId })

        if (!sessions.length) {
            return res.status(404).json({ message: "No sessions found for this teacher" })
        }

        res.status(200).json({ sessions })
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message })
    }
})


// Sets routine status by ID and updates lastUpdated automatically
router.patch("/:routineId", async (req, res) => {
    try {
        const { routineId } = req.params;
        const { status } = req.body; // Expecting a single status value to be added

        const updatedRoutine = await Routine.findByIdAndUpdate(
            routineId,
            {
                $push: { status: status },
                lastUpdated: new Date().toISOString().split('T')[0]
            },
            { new: true }
        );

        if (!updatedRoutine) {
            return res.status(404).json({ message: "Routine Not Found." });
        }

        res.json(updatedRoutine);
    } catch (error) {
        return res.status(500).json({ message: "Server Error", error: error.message });
    }
});


// Update a specific session by sessionId
router.patch('/session/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const updateFields = req.body;

        const updatedSession = await Routine.findByIdAndUpdate(
            sessionId,
            {
                ...updateFields,
                lastUpdated: new Date().toISOString().split('T')[0] // update timestamp
            },
            { new: true }
        );

        if (!updatedSession) {
            return res.status(404).json({ message: "Session not found" });
        }

        res.status(200).json({ message: "Session updated successfully", session: updatedSession });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});


// Gets routine for a specific day
router.get('/:teacherId/:day', async (req, res) => {
    try {
        const routine = await Routine.find({ teacherId: req.params.teacherId, day: req.params.day });
        if (!routine.length) {
            return res.status(404).json({ message: "No routine found for this day" });
        }

        const currDate = new Date().toISOString().split('T')[0];
        const updatedRoutine = [];

        for (const session of routine) {
            const updatedDate = session.lastUpdated ? new Date(session.lastUpdated).toISOString().split('T')[0] : null;

            if (updatedDate !== currDate) {
                session.status = [];
                await session.save();
            }

            updatedRoutine.push(session);
        }

        // Sort sessions based on startTime in hh:mm AM/PM format
        updatedRoutine.sort((a, b) => {
            const parseTime = (timeStr) => {
                const [time, modifier] = timeStr.split(" ");
                let [hours, minutes] = time.split(":").map(Number);

                if (modifier === "PM" && hours !== 12) hours += 12;
                if (modifier === "AM" && hours === 12) hours = 0;

                return hours * 60 + minutes; // Total minutes since midnight
            };

            return parseTime(a.startTime) - parseTime(b.startTime);
        });

        return res.status(200).json({ routine: updatedRoutine });
    } catch (error) {
        return res.status(500).json({ message: "Server error", error: error.message });
    }
});




//creates routine for a specific day


router.post('/:teacherId/:day', async (req, res) => {
    const { department, semester, section, subject, startTime, endTime } = req.body;

    if (!department || !semester || !section || !subject || !startTime || !endTime) {
        return res.status(400).json({ message: "All fields are required." });
    }

    try {
        const teacher = await Teacher.findById(req.params.teacherId);
        if (!teacher) {
            return res.status(404).json({ message: "Teacher not found." });
        }

        const className = `${semester}-${section}`; // Combine for matching className

        // Check if class is already assigned
        const alreadyAssigned = teacher.assignedClasses.some(cls =>
            cls.department === department &&
            cls.className === className &&
            cls.subject === subject
        );

        // If not assigned, push to assignedClasses
        if (!alreadyAssigned) {
            teacher.assignedClasses.push({ department, className, subject });
            await teacher.save();
        }

        // Now create the routine
        const newRoutine = new Routine({
            teacherId: req.params.teacherId,
            day: req.params.day,
            department,
            semester,
            section,
            subject,
            startTime,
            endTime,
        });

        await newRoutine.save();

        return res.status(201).json({
            message: "Routine added successfully",
            routine: newRoutine
        });

    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
});






module.exports = router
