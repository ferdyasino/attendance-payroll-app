const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

router.get('/monthly', reportController.generateMonthlyReport);

module.exports = router;
