const mongoose = require("mongoose");
const studentSchema = new mongoose.Schema({
    name:{
        type:String,
        require:true
    },
    roll:{
        type:Number,
        require:true,
        unique: true
    },
    className:{
        type:String,
        require:true
    },
    dept:{
        type:String,
        require:true
    },
    
    email:{
        type:String,
        require:true
    },
    password:{
        type:String,
        require:true
    },
    is_in_class:{
        type:Boolean,
        require:true,
        default:false
    },
    fcmToken:{
        type:String
    }
})
const student=mongoose.model("Students",studentSchema);
module.exports=student;