const express = require('express');
const app = express();
const port = 5000;

const employeeRoutes = require('./routes/employeeRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const payrollRoutes = require('./routes/payrollRoutes');
const leaveRoutes = require('./routes/leaveRoutes');

app.use(express.json());

app.use('/api/employees', employeeRoutes);
app.use('/api/attendances', attendanceRoutes);
app.use('/api/payrolls', payrollRoutes);
app.use('/api/leave', leaveRoutes);

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
