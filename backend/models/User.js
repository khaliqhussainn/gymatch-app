const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    }
    // Add more fields as per your GYMatch MVP Scope, e.g.,
    // fitnessGoals: [String],
    // preferredWorkoutTypes: [String],
    // availability: [String],
    // preferredGym: {
    //     type: mongoose.Schema.Types.ObjectId,
    //     ref: 'gym'
    // },
    // location: {
    //     type: { type: String, default: 'Point' },
    //     coordinates: [Number] // [longitude, latitude]
    // }
});

module.exports = mongoose.model('User', UserSchema);
