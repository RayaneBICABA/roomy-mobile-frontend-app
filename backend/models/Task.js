const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  groupId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Group',
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  assignedTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  dueDate: {
    type: Date,
  },
  status: {
    type: String,
    enum: ['pending', 'done'],
    default: 'pending',
  },
  recurring: {
    type: String,
    enum: ['none', 'daily', 'weekly'],
    default: 'none',
  },
}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);
