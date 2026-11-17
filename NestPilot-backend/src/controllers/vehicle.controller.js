const { Op } = require('sequelize');
const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { getMembersLookup } = require('./admin.controller');

/**
 * A vehicle belongs to a person (user_id), never to a flat. "Household"
 * vehicles are derived: everyone with an active mapping to the same flat(s).
 * That way a resident who moves flats takes their vehicles along, and the
 * next family in the old flat never inherits them.
 *
 * A vehicle only counts while its owner is still an active member of the
 * vehicle's society — see liveOwnerInclude. Someone who is blocked, rejected
 * or moved to another society drops out of every list automatically, with
 * no clean-up needed in each of those code paths, and comes back if they
 * are reinstated.
 */

const isMember = (req) => req.user?.Role?.code === 'MEMBER';

const flatLabelOf = (house) => house
    ? (house.wing ? `${house.wing}-${house.house_no}` : house.house_no)
    : null;

// The flat a user's sticker / listing is labelled with: their primary
// active flat, else any active one.
const pickHouse = (mappings = []) =>
    (mappings.find(m => m.is_primary) || mappings[0])?.House || null;

const activeFlatsInclude = () => ({
    model: db.UserHouseMapping,
    required: false,
    where: { is_active: true },
    attributes: ['is_primary'],
    include: [{ model: db.House, attributes: ['house_no', 'wing'] }]
});

// Built per call: Sequelize mutates include options in place.
const liveOwnerInclude = (societyId) => ({
    model: db.User,
    as: 'owner',
    attributes: ['id', 'full_name', 'mobile'],
    where: { status: 'active', society_id: societyId },
    required: true,
    include: [activeFlatsInclude()]
});

// Flattens the owner to { id, full_name, mobile, flat_number } for the app.
const serializeVehicle = (vehicle) => {
    const json = vehicle.toJSON();
    if (json.owner) {
        json.owner = {
            id: json.owner.id,
            full_name: json.owner.full_name,
            mobile: json.owner.mobile,
            flat_number: flatLabelOf(pickHouse(json.owner.UserHouseMappings))
        };
    }
    return json;
};

/** Everyone currently living in any of [userId]'s flats, themself included. */
const householdUserIds = async (userId) => {
    const own = await db.UserHouseMapping.findAll({
        where: { user_id: userId, is_active: true },
        attributes: ['house_id']
    });
    const houseIds = own.map(m => m.house_id);
    if (!houseIds.length) return [userId];

    const all = await db.UserHouseMapping.findAll({
        where: { house_id: houseIds, is_active: true },
        attributes: ['user_id']
    });
    return [...new Set([userId, ...all.map(m => m.user_id)])];
};

/**
 * Who a new vehicle is registered to. Residents (MEMBER) register only for
 * themselves; a manager may name any active user of the society — inside
 * their assigned buildings when they are building-scoped.
 */
const resolveOwnerId = async (req, rawOwnerId) => {
    if (rawOwnerId === undefined || rawOwnerId === null || rawOwnerId === '') {
        return req.user.id;
    }
    const ownerId = Number(rawOwnerId);
    if (ownerId === req.user.id) return ownerId;
    if (isMember(req)) {
        throw new ApiError(403, 'You can only register vehicles for yourself');
    }
    if (!Number.isInteger(ownerId) || ownerId <= 0) {
        throw new ApiError(400, 'Select a valid owner');
    }

    const owner = await db.User.findOne({
        where: { id: ownerId, society_id: req.user.society_id, status: 'active' },
        attributes: ['id']
    });
    if (!owner) throw new ApiError(404, 'Owner not found in this society');

    if (req.userScope && !req.userScope.unscoped) {
        const inScope = await db.UserHouseMapping.count({
            where: { user_id: ownerId, is_active: true },
            include: [{
                model: db.House,
                attributes: [],
                required: true,
                where: { building_id: { [Op.in]: req.userScope.building_ids } }
            }]
        });
        if (!inScope) throw new ApiError(403, 'That resident is outside your assigned buildings');
    }
    return ownerId;
};

/**
 * Makes sure [number] is free to use in the society. Only an active vehicle
 * whose owner still lives here blocks it; one left behind by someone who
 * moved out or was blocked is retired so the number can be registered again
 * (e.g. the car was sold to a neighbour).
 */
const claimVehicleNumber = async (number, societyId, { exceptId, transaction } = {}) => {
    const clashes = await db.Vehicle.findAll({
        where: {
            vehicle_number: number,
            society_id: societyId,
            is_active: true,
            ...(exceptId ? { id: { [Op.ne]: exceptId } } : {})
        },
        include: [{ model: db.User, as: 'owner', attributes: ['status', 'society_id'] }],
        transaction
    });
    const live = clashes.find(v => v.owner?.status === 'active' && v.owner.society_id === societyId);
    if (live) throw new ApiError(400, 'Vehicle already registered in this society');

    for (const stale of clashes) {
        await stale.update({ is_active: false }, { transaction });
    }
};

const addVehicle = async (req, res, next) => {
    try {
        const { vehicle_number, type, brand, model, owner_user_id } = req.body;
        const number = String(vehicle_number || '').trim();
        if (!number) throw new ApiError(400, 'Vehicle number is required');

        const societyId = req.user.society_id;
        const ownerId = await resolveOwnerId(req, owner_user_id);

        const vehicle = await db.sequelize.transaction(async (transaction) => {
            await claimVehicleNumber(number, societyId, { transaction });

            const created = await db.Vehicle.create({
                user_id: ownerId,
                society_id: societyId,
                vehicle_number: number,
                type,
                brand,
                model
            }, { transaction });

            // Generated here (not accepted from the client) so it can include
            // the vehicle's own id — otherwise every vehicle a resident
            // registers would carry an identical sticker. The flat carries
            // its wing ("A-2", not "2") so a guard can tell A-2 from B-2.
            const mappings = await db.UserHouseMapping.findAll({
                where: { user_id: ownerId, is_active: true },
                attributes: ['is_primary'],
                include: [{ model: db.House, attributes: ['house_no', 'wing'] }],
                transaction
            });
            const flatLabel = flatLabelOf(pickHouse(mappings)) || 'NA';
            created.sticker_number = `${flatLabel}-${societyId}-${ownerId}-${created.id}`;
            await created.save({ transaction });
            return created;
        });

        res.status(201).json(new ApiResponse(201, vehicle, 'Vehicle added successfully'));
    } catch (e) { next(e); }
};

// Household vehicles of the caller (kept for API compatibility; the app's
// list uses getAllVehicles, which returns the same set for residents).
const getMyVehicles = async (req, res, next) => {
    try {
        const vehicles = await db.Vehicle.findAll({
            where: {
                user_id: await householdUserIds(req.user.id),
                society_id: req.user.society_id,
                is_active: true
            },
            include: [liveOwnerInclude(req.user.society_id)],
            order: [['id', 'ASC']]
        });
        res.status(200).json(new ApiResponse(200, vehicles.map(serializeVehicle)));
    } catch (e) { next(e); }
};

// MEMBERs may only touch a vehicle belonging to their own household;
// everyone else (secretary/admin, per hasPermission('VEHICLES','manage'))
// can act on any vehicle in the society, mirroring what getAllVehicles
// already shows them.
const findVehicleInScope = async (req, extraWhere = {}) => {
    const where = { id: req.params.id, society_id: req.user.society_id, ...extraWhere };
    if (isMember(req)) where.user_id = await householdUserIds(req.user.id);
    return db.Vehicle.findOne({ where });
};

const updateVehicle = async (req, res, next) => {
    try {
        const vehicle = await findVehicleInScope(req, { is_active: true });
        if (!vehicle) throw new ApiError(404, 'Vehicle not found');

        // sticker_number is system-generated (see addVehicle) and not editable.
        const { vehicle_number, type, brand, model } = req.body;

        if (vehicle_number !== undefined) {
            const number = String(vehicle_number || '').trim();
            if (!number) throw new ApiError(400, 'Vehicle number is required');
            if (number !== vehicle.vehicle_number) {
                await claimVehicleNumber(number, req.user.society_id, { exceptId: vehicle.id });
                vehicle.vehicle_number = number;
            }
        }
        if (type !== undefined) vehicle.type = type;
        if (brand !== undefined) vehicle.brand = brand;
        if (model !== undefined) vehicle.model = model;

        await vehicle.save();
        res.status(200).json(new ApiResponse(200, vehicle, 'Vehicle updated successfully'));
    } catch (e) { next(e); }
};

const deleteVehicle = async (req, res, next) => {
    try {
        const vehicle = await findVehicleInScope(req);
        if (!vehicle) throw new ApiError(404, 'Vehicle not found');

        vehicle.is_active = false;
        await vehicle.save();

        res.status(200).json(new ApiResponse(200, null, 'Vehicle removed'));
    } catch (e) { next(e); }
};

// Residents see their household's vehicles; every other role sees the whole
// society (guards check vehicles at the gate, secretaries manage them).
const getAllVehicles = async (req, res, next) => {
    try {
        const where = { society_id: req.user.society_id, is_active: true };
        if (isMember(req)) where.user_id = await householdUserIds(req.user.id);

        const vehicles = await db.Vehicle.findAll({
            where,
            include: [liveOwnerInclude(req.user.society_id)],
            order: [['id', 'ASC']]
        });
        res.status(200).json(new ApiResponse(200, vehicles.map(serializeVehicle)));
    } catch (e) { next(e); }
};

// Owner picker for a manager registering a vehicle on a resident's behalf.
// Residents also hold VEHICLES manage, so they are refused here explicitly —
// otherwise they could list their neighbours' names and mobile numbers.
const getOwnerOptions = async (req, res, next) => {
    if (isMember(req)) return next(new ApiError(403, 'Forbidden'));
    return getMembersLookup(req, res, next);
};

module.exports = {
    addVehicle,
    getMyVehicles,
    updateVehicle,
    deleteVehicle,
    getAllVehicles,
    getOwnerOptions
};
