const db = require('../models');

const getStates = async () => {
    return db.State.findAll({
        where: { is_active: true },
        attributes: ['id', 'name', 'code'],
        order: [['name', 'ASC']],
    });
};

const getDistricts = async (stateId) => {
    const where = { is_active: true };
    if (stateId) where.state_id = stateId;
    return db.District.findAll({
        where,
        attributes: ['id', 'state_id', 'name'],
        order: [['name', 'ASC']],
    });
};

module.exports = {
    getStates,
    getDistricts,
};
