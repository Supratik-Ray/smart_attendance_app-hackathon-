const mongoose = require('mongoose')

const teacherSchema = mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
    },
    password: {
        type: String,
        required: true
    },
    assignedClasses:[
        {
            department: {
                type: String,
                required: true
            },
            className: {
                type: String,
                required: true
            },
            subject: {
                type: String,
                required: true
            }
        }
    ]
})

const Teacher = mongoose.model("Teacher", teacherSchema)

module.exports = Teacher
