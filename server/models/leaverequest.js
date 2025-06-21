'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class LeaveRequest extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  LeaveRequest.init({
    employeeId: DataTypes.INTEGER,
    dateFrom: DataTypes.DATE,
    dateTo: DataTypes.DATE,
    reason: DataTypes.TEXT,
    status: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'LeaveRequest',
  });
  return LeaveRequest;
};