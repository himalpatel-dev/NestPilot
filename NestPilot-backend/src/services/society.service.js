const db = require('../models');

const getSocietyDetails = async (societyId) => {
    return db.Society.findByPk(societyId, {
        include: [{
            model: db.Building,
            include: [{ model: db.House }]
        }]
    });
};

const createSociety = async (data) => {
    return db.Society.create(data);
};

const createBuilding = async (data) => {
    return db.Building.create(data);
};

const createHouse = async (data) => {
    return db.House.create(data);
};

const getHouses = async (societyId) => {
    return db.House.findAll({
        where: { society_id: societyId },
        include: [db.Building]
    });
};

module.exports = {
    getSocietyDetails,
    createSociety,
    createBuilding,
    createHouse,
    getHouses
};
