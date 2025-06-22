exports.getAllLeaveRequests = (req, res) => {
  res.json({ message: "Get all leave requests" });
};

exports.getLeaveRequestById = (req, res) => {
  res.json({ message: `Get leave request with ID ${req.params.id}` });
};

exports.createLeaveRequest = (req, res) => {
  res.json({ message: "Create new leave request", data: req.body });
};

exports.updateLeaveRequest = (req, res) => {
  res.json({ message: `Update leave request with ID ${req.params.id}`, data: req.body });
};

exports.deleteLeaveRequest = (req, res) => {
  res.json({ message: `Delete leave request with ID ${req.params.id}` });
};
