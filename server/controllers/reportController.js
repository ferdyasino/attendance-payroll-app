const { Attendance, Employee } = require('../models');
const { Op } = require('sequelize');
const moment = require('moment');

exports.generateMonthlyReport = async (req, res) => {
  try {
    const { employeeId, month } = req.query;

    if (!employeeId || !month) {
      return res.status(400).json({ error: "employeeId and month are required in query parameters" });
    }

    const startDate = `${month}-01`;
    const endDate = moment(startDate).endOf('month').format('YYYY-MM-DD');

    // ✅ Check if employee exists
    const employee = await Employee.findByPk(employeeId);
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    // ✅ Get Attendance Records for month
    const records = await Attendance.findAll({
      where: {
        employeeId,
        date: {
          [Op.between]: [startDate, endDate]
        }
      }
    });

    if (!records.length) {
      return res.status(404).json({ error: 'No attendance records found for this employee in the given month.' });
    }

    // ✅ Calculate Report Data
    const totalDays = records.length;
    const totalLateMinutes = records.reduce((sum, record) => sum + record.lateMinutes, 0);
    const totalAbsent = records.filter(r => r.status.toLowerCase() === 'absent').length;

    res.status(200).json({
      employeeId,
      employeeName: employee.name,
      month,
      totalDaysPresent: totalDays - totalAbsent,
      totalAbsent,
      totalLateMinutes
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
