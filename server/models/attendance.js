'use strict';
const {
  Model
} = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Attendance extends Model {
    static associate(models) {
      Attendance.belongsTo(models.Employee, {
        foreignKey: 'employeeId',
        as: 'employee'
      });
    }
  }

  Attendance.init({
    employeeId: DataTypes.INTEGER,
    date: DataTypes.DATEONLY,
    timeIn: DataTypes.TIME,
    timeOut: DataTypes.TIME,
    break1In: DataTypes.TIME,
    break1Out: DataTypes.TIME,
    lunchIn: DataTypes.TIME,
    lunchOut: DataTypes.TIME,
    break2In: DataTypes.TIME,
    break2Out: DataTypes.TIME,
    break3In: DataTypes.TIME,
    break3Out: DataTypes.TIME,
    status: DataTypes.STRING,
    lateMinutes: DataTypes.INTEGER
  }, {
    sequelize,
    modelName: 'Attendance',
  });

  return Attendance;
};
