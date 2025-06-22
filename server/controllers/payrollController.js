exports.getAllPayroll = (req, res) => {
  res.json({ message: "Get all payroll records" });
};

exports.getPayrollById = (req, res) => {
  res.json({ message: `Get payroll record with ID ${req.params.id}` });
};

exports.createPayroll = (req, res) => {
  res.json({ message: "Create new payroll record", data: req.body });
};

exports.updatePayroll = (req, res) => {
  res.json({ message: `Update payroll record with ID ${req.params.id}`, data: req.body });
};

exports.deletePayroll = (req, res) => {
  res.json({ message: `Delete payroll record with ID ${req.params.id}` });
};
