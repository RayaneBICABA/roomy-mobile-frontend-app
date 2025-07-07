const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const {
  createTask,
  assignTask,
  markTaskDone,
  listGroupTasks,
  updateTask,
  deleteTask,
} = require('../controllers/taskController');

router.post('/create', authMiddleware, createTask);
router.post('/assign', authMiddleware, assignTask);
router.post('/mark-done', authMiddleware, markTaskDone);
router.get('/list', authMiddleware, listGroupTasks);
router.put('/:id', authMiddleware, updateTask);
router.delete('/:id', authMiddleware, deleteTask);

module.exports = router;
