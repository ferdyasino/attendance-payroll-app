const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');

router.post('/', attendanceController.createAttendance);
router.get('/', attendanceController.getAllAttendance);
router.get('/:id', attendanceController.getAttendanceById);
router.put('/:id', attendanceController.updateAttendance);
router.delete('/:id', attendanceController.deleteAttendance);

router.post('/clock-in', attendanceController.clockIn);
router.post('/clock-out', attendanceController.clockOut);
router.post('/break1-in', attendanceController.break1In);
router.post('/break1-out', attendanceController.break1Out);
router.post('/lunch-in', attendanceController.lunchIn);
router.post('/lunch-out', attendanceController.lunchOut);
router.post('/break2-in', attendanceController.break2In);
router.post('/break2-out', attendanceController.break2Out);
router.post('/break3-in', attendanceController.break3In);
router.post('/break3-out', attendanceController.break3Out);

module.exports = router;
