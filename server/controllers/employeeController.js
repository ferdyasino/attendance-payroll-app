const { Employee, Attendance, Payroll } = require('../models');


exports.getAllEmployees = async (req, res) => {
  try {
    const employees = await Employee.findAll();
    res.status(200).json(employees);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getEmployeeById = async (req, res) => {
  try {
    const { id } = req.params;

    const employee = await Employee.findByPk(id);

    if (employee) {
      res.status(200).json(employee);
    } else {
      res.status(404).json({ message: 'Employee not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createEmployee = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    const newEmployee = await Employee.create({
      name,
      email,
      password,
      role
    });

    res.status(201).json(newEmployee);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateEmployee = async (req, res) => {
  try {
    const { id } = req.params;

    const [updated] = await Employee.update(req.body,{
      where: { id: id }
    });
    
    if (updated) {
      const updateEmployee = await Employee.findByPk(id);   
      res.status(200).json(updateEmployee);
    } else {
      res.status(404).json({ message: "Employee not found" });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params;

    // Check Attendance
    const attendance = await Attendance.findOne({ where: { employeeId: id } });
    if (attendance) {
      return res.status(400).json({ message: 'Cannot delete: Employee has attendance records.' });
    }

    // Check Payroll
    const payroll = await Payroll.findOne({ where: { employeeId: id } });
    if (payroll) {
      return res.status(400).json({ message: 'Cannot delete: Employee has payroll records.' });
    }

    // If safe, delete
    const deleted = await Employee.destroy({
      where: { id: id }
    });

    if (deleted) {
      res.status(200).json({ message: 'Employee deleted successfully' });
    } else {
      res.status(404).json({ message: 'Employee not found' });
    }

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

