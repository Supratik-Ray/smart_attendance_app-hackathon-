const express = require('express')
const mongoose = require('mongoose')

const Routine = require('../models/sessionSchema')
const Session = require('../models/sessionSchema')

const router = express.Router()

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
router.post('/:teacherId/:day', async (req,res)=>{
    const {department, semester, section, subject, startTime, endTime } = req.body

    if(!department || !semester || !section || !subject || !startTime || !endTime){
        return res.status(400).json({message: "All fields are required."})
    }
    try{
        const newRoutine = new Routine({
            teacherId: req.params.teacherId,
            day: req.params.day,
            department,
            semester,
            section,
            subject,
            startTime,
            endTime,
        })
        await newRoutine.save()
        return res.status(201).json({message: "Routine added successfully", routine:newRoutine})
    }catch(error){
        return res.status(500).json({error: error.message})
    }
})





//delete routine for a specific day
router.delete('/:teacherId/:day', async (req, res)=>{
    try{
        const deleted = await Routine.findOneAndDelete({teacherId: req.params.teacherId, day: req.params.day})
        if(!deleted){
            return res.status(404).json({message: "Routine not found"})
        }
        res.status(200).json({message: "Routine deleted successfully!"})
    }catch(error){
        res.status(500).json({message: "server error",error})
    }
})


module.exports = router
