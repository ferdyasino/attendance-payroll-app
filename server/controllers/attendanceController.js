const { Attendance, Employee } = require('../models'); // ✔️ include Employee model
const   moment = require('moment');

exports.clockIn = async (req, res) => {
  try {
    const { employeeId } = req.body;
    const today = moment().format('YYYY-MM-DD');
    const now = moment();

    const clockInStart = moment(today + ' 07:30', 'YYYY-MM-DD HH:mm');
    const clockInEnd = moment(today + ' 09:00', 'YYYY-MM-DD HH:mm');
    const scheduledTime = moment(today + ' 08:00', 'YYYY-MM-DD HH:mm');

    // Deny if too early or too late
    // if (!now.isBetween(clockInStart, clockInEnd)) {
    //   return res.status(403).json({ message: 'Clock In allowed only between 07:30 and 09:00.' });
    // }

    const existing = await Attendance.findOne({ where: { employeeId, date: today } });
    if (existing) {
      return res.status(400).json({ message: 'Already clocked in today.' });
    }

    const lateMinutes = Math.max(now.diff(scheduledTime, 'minutes'), 0);

    const attendance = await Attendance.create({
      employeeId,
      date: today,
      timeIn: now.format('HH:mm:ss'),
      status: 'Present',
      lateMinutes
    });

    res.status(200).json({ message: 'Clocked in successfully', attendance });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error during clock-in' });
  }
};


exports.clockOut = async (req, res) => {
  try {
    const { employeeId } = req.body;
    const today = moment().format('YYYY-MM-DD');
    const now = moment();

    const clockOutStart = moment(today + ' 16:30', 'YYYY-MM-DD HH:mm');
    const clockOutEnd = moment(today + ' 18:30', 'YYYY-MM-DD HH:mm');

    // Deny if too early or too late
    // if (!now.isBetween(clockOutStart, clockOutEnd)) {
    //   return res.status(403).json({ message: 'Clock Out allowed only between 16:30 and 18:30.' });
    // }

    const attendance = await Attendance.findOne({ where: { employeeId, date: today } });
    if (!attendance) {
      return res.status(404).json({ message: 'No attendance record found for today.' });
    }

    if (attendance.timeOut) {
      return res.status(400).json({ message: 'Already clocked out.' });
    }

    attendance.timeOut = now.format('HH:mm:ss');
    await attendance.save();

    res.status(200).json({ message: 'Clocked out successfully', attendance });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error during clock-out' });
  }
};

exports.break1In = async (req, res) => {
  await updateAttendanceField(req, res, 'break1In');
};

exports.break1Out = async (req, res) => {
  await updateAttendanceField(req, res, 'break1Out');
};

exports.lunchIn = async (req, res) => {
  await updateAttendanceField(req, res, 'lunchIn');
};

exports.lunchOut = async (req, res) => {
  await updateAttendanceField(req, res, 'lunchOut');
};

exports.break2In = async (req, res) => {
  await updateAttendanceField(req, res, 'break2In');
};

exports.break2Out = async (req, res) => {
  await updateAttendanceField(req, res, 'break2Out');
};

exports.break3In = async (req, res) => {
  await updateAttendanceField(req, res, 'break3In');
};

exports.break3Out = async (req, res) => {
  await updateAttendanceField(req, res, 'break3Out');
};

// Common helper
async function updateAttendanceField(req, res, field) {
  try {
    const { employeeId } = req.body;
    const today = moment().format('YYYY-MM-DD');

    const attendance = await Attendance.findOne({
      where: { employeeId, date: today }
    });

    if (!attendance) {
      return res.status(404).json({ message: 'No attendance record for today.' });
    }

    attendance[field] = moment().format('HH:mm:ss');
    await attendance.save();

    res.json({ message: `${field} recorded`, time: attendance[field] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: `Failed to record ${field}.`, error: error.message });
  }
}


exports.createAttendance = async (req, res) => {
  try {
    const { employeeId, date, timeIn, timeOut, status, lateMinutes } = req.body;

    // ✔️ Check if Employee exists
    const employee = await Employee.findByPk(employeeId);
    if (!employee) {
      return res.status(400).json({ error: 'Employee not found' });
    }

    // ✔️ Create Attendance if valid employee
    const attendance = await Attendance.create({ employeeId, date, timeIn, timeOut, status, lateMinutes });
    res.status(201).json(attendance);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllAttendance = async (req, res) => {
  try {
    const attendance = await Attendance.findAll();
    res.status(200).json(attendance);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAttendanceById = async (req, res) => {
  try {
    const { id } = req.params;
    const attendance = await Attendance.findByPk(id);
    if (!attendance) return res.status(404).json({ message: 'Attendance not found' });
    res.status(200).json(attendance);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateAttendance = async (req, res) => {
  try {
    const { id } = req.params;
    const [updated] = await Attendance.update(req.body, { where: { id } });
    if (updated) {
      const updatedAttendance = await Attendance.findByPk(id);
      res.status(200).json(updatedAttendance);
    } else {
      res.status(404).json({ message: 'Attendance not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteAttendance = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Attendance.destroy({ where: { id } });
    if (deleted) {
      res.status(200).json({ message: 'Attendance deleted successfully' });
    } else {
      res.status(404).json({ message: 'Attendance not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
