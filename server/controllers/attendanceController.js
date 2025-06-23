const { Attendance, Employee } = require('../models'); // ✔️ include Employee model

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
