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

const updateHouse = async (id, data) => {
    const house = await db.House.findByPk(id);
    if (!house) return null;
    return house.update(data);
};

const getHouses = async (societyId) => {
    return db.House.findAll({
        where: { society_id: societyId },
        include: [db.Building]
    });
};

const getAllSocieties = async () => {
    return db.Society.findAll();
};

const updateSociety = async (id, data) => {
    const society = await db.Society.findByPk(id);
    if (!society) return null;
    return society.update(data);
};

const updateBuilding = async (id, data) => {
    const building = await db.Building.findByPk(id);
    if (!building) return null;
    return building.update(data);
};

const getBuildingById = async (id) => {
    return db.Building.findByPk(id);
};

const getBuildingsBySocietyId = async (societyId) => {
    return db.Building.findAll({
        where: { society_id: societyId }
    });
};

const getFlatsByBuildingId = async (buildingId) => {
    return db.House.findAll({
        where: { building_id: buildingId }
    });
};

const getFlatsBySocietyId = async (societyId) => {
    return db.House.findAll({
        where: { society_id: societyId },
        include: [db.Building]
    });
};

const getHouseOccupancyStats = async (societyId) => {
    const [totalHouses, occupiedHouses, ownerCount, tenantCount] = await Promise.all([
        db.House.count({
            where: { society_id: societyId, is_active: true }
        }),
        db.House.count({
            where: { society_id: societyId, is_active: true },
            include: [{
                model: db.UserHouseMapping,
                where: { is_active: true },
                required: true
            }],
            distinct: true
        }),
        db.UserHouseMapping.count({
            where: { is_active: true, relation_type: 'OWNER' },
            include: [{
                model: db.House,
                where: { society_id: societyId, is_active: true },
                required: true
            }]
        }),
        db.UserHouseMapping.count({
            where: { is_active: true, relation_type: 'TENANT' },
            include: [{
                model: db.House,
                where: { society_id: societyId, is_active: true },
                required: true
            }]
        }),
    ]);

    return {
        total_houses: totalHouses,
        occupied_houses: occupiedHouses,
        vacant_houses: totalHouses - occupiedHouses,
        owner_count: ownerCount,
        tenant_count: tenantCount,
    };
};

module.exports = {
    getSocietyDetails,
    createSociety,
    createBuilding,
    createHouse,
    updateHouse,
    getHouses,
    getAllSocieties,
    updateSociety,
    updateBuilding,
    getBuildingById,
    getBuildingsBySocietyId,
    getFlatsByBuildingId,
    getFlatsBySocietyId,
    getHouseOccupancyStats
};

