const Group = require('../models/Group');
const User = require('../models/User');
const crypto = require('crypto');

function generateGroupCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase(); // 6 char code
}

exports.createGroup = async (req, res) => {
  try {
    const { name, description } = req.body;
    const userId = req.userId; // Assume userId is set by auth middleware

    if (!name) {
      return res.status(400).json({ message: 'Group name is required' });
    }

    // Generate unique group code
    let code;
    let existingGroup;
    do {
      code = generateGroupCode();
      existingGroup = await Group.findOne({ code });
    } while (existingGroup);

    // Create group
    const group = new Group({
      name,
      description: description || '',
      code,
      members: [userId],
    });

    await group.save();

    // Update user groupId
    await User.findByIdAndUpdate(userId, { groupId: group._id });

    return res.status(201).json({ message: 'Group created', group });
  } catch (error) {
    console.error('Error in createGroup:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.joinGroup = async (req, res) => {
  try {
    const { code } = req.body;
    const userId = req.userId; // Assume userId is set by auth middleware

    if (!code) {
      return res.status(400).json({ message: 'Group code is required' });
    }

    const group = await Group.findOne({ code });
    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // Check if user is already a member
    if (group.members.includes(userId)) {
      return res.status(400).json({ message: 'User already in group' });
    }

    // Add user to group members
    group.members.push(userId);
    await group.save();

    // Update user groupId
    await User.findByIdAndUpdate(userId, { groupId: group._id });

    return res.status(200).json({ message: 'Joined group', group });
  } catch (error) {
    console.error('Error in joinGroup:', error);
    return res.status(500).json({ message: 'Server error' });
  }
};
