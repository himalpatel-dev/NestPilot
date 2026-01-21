const db = require('../models');
const ApiError = require('../utils/ApiError');
const { generateToken } = require('../utils/token');

const login = async (mobile) => {
    const user = await db.User.findOne({
        where: { mobile },
        include: [
            { model: db.Role },
            { model: db.Society }
        ]
    });

    if (!user) {
        throw new ApiError(404, 'User not found. Please register.');
    }

    if (user.status === 'blocked' || user.status === 'rejected') {
        throw new ApiError(403, 'Account is blocked or rejected.');
    }

    const token = generateToken({ userId: user.id, roleCode: user.Role.code, societyId: user.society_id });

    return { user, token };
};

const register = async (data) => {
    const { fullName, mobile, societyId, buildingId, houseId, relationType, email } = data;

    // Check if user exists
    const existingUser = await db.User.findOne({ where: { mobile } });
    if (existingUser) {
        throw new ApiError(400, 'User with this mobile number already exists.');
    }

    const transaction = await db.sequelize.transaction();
    try {
        // 1. Find Member Role
        const memberRole = await db.Role.findOne({ where: { code: 'MEMBER' } });
        if (!memberRole) throw new ApiError(500, 'Member role not found');

        // 2. Create User
        const user = await db.User.create({
            full_name: fullName,
            mobile,
            email,
            society_id: societyId,
            role_id: memberRole.id,
            status: 'pending'
        }, { transaction });

        // 3. Create Mapping
        await db.UserHouseMapping.create({
            user_id: user.id,
            house_id: houseId,
            relation_type: relationType,
            is_active: true
        }, { transaction });

        await transaction.commit();
        return user;
    } catch (error) {
        await transaction.rollback();
        throw error;
    }
};

const getMe = async (userId) => {
    return db.User.findByPk(userId, {
        include: [
            { model: db.Role },
            { model: db.Society },
            {
                model: db.House,
                through: { attributes: ['relation_type'] },
                include: [{ model: db.Building }]
            }
        ]
    });
};

module.exports = {
    login,
    register,
    getMe
};
