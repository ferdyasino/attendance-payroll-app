const { Payroll, Employee, Attendance } = require('../models');
const { Op } = require('sequelize');
const moment = require('moment');

exports.  createPayroll = async (req, res) => {
  try {
    const { employeeId, basicSalary, deductions, overtimePay, netPay, month } = req.body;

    const employee = await Employee.findByPk(employeeId);
    if (!employee) {
      return res.status(400).json({ error: 'Employee not found' });
    }

    // Compute valid date range for the month
    const startDate = moment(month, 'YYYY-MM').startOf('month').format('YYYY-MM-DD');
    const endDate = moment(month, 'YYYY-MM').endOf('month').format('YYYY-MM-DD');

    const attendance = await Attendance.findOne({
      where: {
        employeeId,
        date: {
          [Op.between]: [startDate, endDate]  // ✅ Correct usage
        }
      }
    });

    if (!attendance) {
      return res.status(400).json({ error: 'Cannot generate payroll: No attendance records found for this employee in the given month.' });
    }

    const payroll = await Payroll.create({ employeeId, basicSalary, deductions, overtimePay, netPay, month });
    res.status(201).json(payroll);

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



exports.getAllPayrolls = async (req, res) => {
  try {
    const payrolls = await Payroll.findAll();
    res.status(200).json(payrolls);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getPayrollById = async (req, res) => {
  try {
    const { id } = req.params;
    const payroll = await Payroll.findByPk(id);
    if (!payroll) return res.status(404).json({ message: 'Payroll not found' });
    res.status(200).json(payroll);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updatePayroll = async (req, res) => {
  try {
    const { id } = req.params;
    const [updated] = await Payroll.update(req.body, { where: { id } });
    if (updated) {
      const updatedPayroll = await Payroll.findByPk(id);
      res.status(200).json(updatedPayroll);
    } else {
      res.status(404).json({ message: 'Payroll not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deletePayroll = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Payroll.destroy({ where: { id } });
    if (deleted) {
      res.status(200).json({ message: 'Payroll deleted successfully' });
    } else {
      res.status(404).json({ message: 'Payroll not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
