require('dotenv').config();
const express = require('express');
const app = express();
const port = 5000;

const employeeRoutes = require('./routes/employeeRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const payrollRoutes = require('./routes/payrollRoutes');
const leaveRoutes = require('./routes/leaveRoutes');
const reportRoutes = require('./routes/reportRoutes');

app.use(express.json());

app.use('/api/employees', employeeRoutes);
app.use('/api/attendances', attendanceRoutes);
app.use('/api/payrolls', payrollRoutes);
app.use('/api/leaves', leaveRoutes);
app.use('/api/reports', reportRoutes);

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
});
