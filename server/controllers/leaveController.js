const { LeaveRequest, Employee } = require('../models');

exports.createLeaveRequest = async (req, res) => {
  try {
    const { employeeId, startDate, endDate, reason, status } = req.body;

    // Check if Employee exists
    const employee = await Employee.findByPk(employeeId);
    if (!employee) {
      return res.status(400).json({ error: 'Employee not found' });
    }

    const leave = await LeaveRequest.create({ employeeId, startDate, endDate, reason, status });
    res.status(201).json(leave);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllLeaveRequests = async (req, res) => {
  try {
    const leaves = await LeaveRequest.findAll();
    res.status(200).json(leaves);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getLeaveRequestById = async (req, res) => {
  try {
    const { id } = req.params;
    const leave = await LeaveRequest.findByPk(id);
    if (!leave) return res.status(404).json({ message: 'Leave request not found' });
    res.status(200).json(leave);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateLeaveRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const [updated] = await LeaveRequest.update(req.body, { where: { id } });
    if (updated) {
      const updatedLeave = await LeaveRequest.findByPk(id);
      res.status(200).json(updatedLeave);
    } else {
      res.status(404).json({ message: 'Leave request not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteLeaveRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await LeaveRequest.destroy({ where: { id } });
    if (deleted) {
      res.status(200).json({ message: 'Leave request deleted successfully' });
    } else {
      res.status(404).json({ message: 'Leave request not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
