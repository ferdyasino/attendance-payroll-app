'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('Attendances', 'break1In', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'break1Out', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'lunchIn', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'lunchOut', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'break2In', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'break2Out', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'break3In', Sequelize.TIME);
    await queryInterface.addColumn('Attendances', 'break3Out', Sequelize.TIME);
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('Attendances', 'break1In');
    await queryInterface.removeColumn('Attendances', 'break1Out');
    await queryInterface.removeColumn('Attendances', 'lunchIn');
    await queryInterface.removeColumn('Attendances', 'lunchOut');
    await queryInterface.removeColumn('Attendances', 'break2In');
    await queryInterface.removeColumn('Attendances', 'break2Out');
    await queryInterface.removeColumn('Attendances', 'break3In');
    await queryInterface.removeColumn('Attendances', 'break3Out');
  }
};
