# ✅ Attendance & Payroll App — Project Progress Checklist

_Last updated: 2025-06-23_

## 📂 **Project Setup**
- [x] Project folder structure created
- [x] Initialized Git repository (`git init`)
- [x] Connected to remote GitHub repository
- [x] Added `.gitignore`
- [x] Installed dependencies (`express`, `sequelize`, `mysql2`, `dotenv`, `jsonwebtoken`, etc.)
- [x] Sequelize CLI initialized
- [x] Environment variables set in `.env`

## 🔗 **Database & Sequelize**
- [x] Sequelize config integrated with `.env`
- [x] Sequelize models created (`Employee`, `Attendance`, `Payroll`, `LeaveRequest`)
- [x] Associations defined
- [x] Migration files created & executed
- [x] Tables created successfully
- [x] Seed data (optional)
- [ ] Migration rollback tested (to-do)

## 🚀 **Express Server**
- [x] Basic server running (`index.js`)
- [x] Middleware (logger, JSON parser)
- [x] Error handling middleware (to-do)

## 🔧 **Routes & Controllers**
### Employee
- [x] Create Employee
- [x] Get All Employees
- [x] Get Employee by ID
- [x] Update Employee
- [x] Delete Employee (check if has Attendance/Payroll — to improve)

### Attendance
- [x] Create Attendance (check employee exists)
- [x] Get All Attendance
- [x] Get Attendance by ID
- [x] Update Attendance
- [x] Delete Attendance

### Payroll
- [x] Create Payroll (only if attendance exists for the month)
- [x] Get All Payroll
- [x] Get Payroll by ID
- [x] Update Payroll
- [x] Delete Payroll

### LeaveRequest
- [ ] Create LeaveRequest (to-do)
- [ ] Get All LeaveRequests (to-do)

## 🧪 **Testing (Postman)**
- [x] Employee endpoints tested
- [x] Attendance endpoints tested
- [x] Payroll endpoints tested (validation for attendance presence)
- [ ] Leave endpoints (to-do)

## 🔐 **Authentication**
- [ ] JWT Authentication for Employee login (to-do)
- [ ] Protected routes (to-do)

## 📦 **Deployment (optional)**
- [ ] Production environment prepared
- [ ] `.env` for production
- [ ] Database hosted (MySQL server or cloud)
