const express = require('express');
const router = express.Router();
const leaveController = require('../controllers/leaveController');

router.get('/', leaveController.getAllLeaveRequests);
router.get('/:id', leaveController.getLeaveRequestById);
router.post('/', leaveController.createLeaveRequest);
router.put('/:id', leaveController.updateLeaveRequest);
router.delete('/:id', leaveController.deleteLeaveRequest);

module.exports = router;
