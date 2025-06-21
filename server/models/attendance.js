'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Attendance extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  Attendance.init({
    employeeId: DataTypes.INTEGER,
    date: DataTypes.DATE,
    timeIn: DataTypes.TIME,
    timeOut: DataTypes.TIME,
    late: DataTypes.BOOLEAN,
    undertime: DataTypes.BOOLEAN
  }, {
    sequelize,
    modelName: 'Attendance',
  });
  return Attendance;
};