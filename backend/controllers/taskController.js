const Task = require('../models/Task');
const User = require('../models/User');
const Group = require('../models/Group');

exports.createTask = async (req, res) => {
  try {
    const { title, dueDate, recurring } = req.body;
    const userId = req.userId;

    if (!title) {
      return res.status(400).json({ message: 'Task title is required' });
    }

    const user = await User.findById(userId);
    if (!user || !user.groupId) {
      return res.status(400).json({ message: 'User must belong to a group to create tasks' });
    }

    const task = new Task({
      groupId: user.groupId,
      title,
      dueDate: dueDate ? new Date(dueDate) : undefined,
      recurring: recurring || 'none',
      status: 'pending',
    });

    await task.save();

    return res.status(201).json({ message: 'Task created', task });
  } catch (error) {
    console.error('Error in createTask:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.assignTask = async (req, res) => {
  try {
    const { taskId, assignedTo } = req.body;
    const userId = req.userId;

    if (!taskId || !assignedTo) {
      return res.status(400).json({ message: 'Task ID and assignedTo user ID are required' });
    }

    const user = await User.findById(userId);
    if (!user || !user.groupId) {
      return res.status(400).json({ message: 'User must belong to a group to assign tasks' });
    }

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (task.groupId.toString() !== user.groupId.toString()) {
      return res.status(403).json({ message: 'Task does not belong to your group' });
    }

    const assignee = await User.findById(assignedTo);
    if (!assignee || assignee.groupId.toString() !== user.groupId.toString()) {
      return res.status(400).json({ message: 'Assignee must be a member of your group' });
    }

    task.assignedTo = assignedTo;
    await task.save();

    return res.status(200).json({ message: 'Task assigned', task });
  } catch (error) {
    console.error('Error in assignTask:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.markTaskDone = async (req, res) => {
  try {
    const { taskId } = req.body;
    const userId = req.userId;

    if (!taskId) {
      return res.status(400).json({ message: 'Task ID is required' });
    }

    const user = await User.findById(userId);
    if (!user || !user.groupId) {
      return res.status(400).json({ message: 'User must belong to a group to update tasks' });
    }

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (task.groupId.toString() !== user.groupId.toString()) {
      return res.status(403).json({ message: 'Task does not belong to your group' });
    }

    task.status = 'done';
    await task.save();

    return res.status(200).json({ message: 'Task marked as done', task });
  } catch (error) {
    console.error('Error in markTaskDone:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.listGroupTasks = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user || !user.groupId) {
      return res.status(400).json({ message: 'User must belong to a group to list tasks' });
    }

    const tasks = await Task.find({ groupId: user.groupId }).populate('assignedTo', 'name email');

    return res.status(200).json({ tasks });
  } catch (error) {
    console.error('Error in listGroupTasks:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const updates = req.body;

    const user = await User.findById(userId);
    if (!user || !user.groupId) {
      return res.status(400).json({ message: 'User must belong to a group to update tasks' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (task.groupId.toString() !== user.groupId.toString()) {
      return res.status(403).json({ message: 'Task does not belong to your group' });
    }

    Object.assign(task, updates);
    await task.save();

    return res.status(200).json({ message: 'Task updated', task });
  } catch (error) {
    console.error('Error in updateTask:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const user = await User.findById(userId);
    if (!user || !user.groupId) {
      return res.status(400).json({ message: 'User must belong to a group to delete tasks' });
    }

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (task.groupId.toString() !== user.groupId.toString()) {
      return res.status(403).json({ message: 'Task does not belong to your group' });
    }

    await task.deleteOne();
    return res.status(200).json({ message: 'Task deleted' });
  } catch (error) {
    console.error('Error in deleteTask:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};
