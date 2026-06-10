const db = require('../models');
const { Op } = require('sequelize');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const auditService = require('../services/audit.service');

/**
 * Visible poll ids for the caller: ones with no PollBuilding target
 * (society-wide) OR ones targeted at a building they own/live in.
 * Returns null when unscoped (no filter).
 */
const visiblePollIds = async (societyId, userScope) => {
    if (!userScope || userScope.unscoped) return null;
    const all = await db.Poll.findAll({
        attributes: ['id'],
        where: { society_id: societyId },
        include: [{ model: db.PollBuilding, required: false, attributes: ['building_id'] }]
    });
    const ids = [];
    for (const p of all) {
        const targets = p.PollBuildings || [];
        if (!targets.length) { ids.push(p.id); continue; }
        if (userScope.building_ids.length &&
            targets.some(t => userScope.building_ids.includes(t.building_id))) {
            ids.push(p.id);
        }
    }
    return ids;
};

const createPoll = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { question, description, end_date, options } = req.body; // options: ["Yes", "No"]

        if (req.userScope && !req.userScope.unscoped && !req.userScope.building_ids.length) {
            throw new ApiError(403, 'No assigned buildings — cannot create poll');
        }

        const poll = await db.Poll.create({
            society_id: req.user.society_id,
            created_by: req.user.id,
            question,
            description,
            end_date
        }, { transaction });

        if (options && options.length > 0) {
            const pollOptions = options.map(opt => ({
                poll_id: poll.id,
                option_text: opt
            }));
            await db.PollOption.bulkCreate(pollOptions, { transaction });
        }

        let targetBuildingIds = [];
        if (req.userScope && !req.userScope.unscoped) {
            targetBuildingIds = req.userScope.building_ids;
            await db.PollBuilding.bulkCreate(
                targetBuildingIds.map(bid => ({ poll_id: poll.id, building_id: bid })),
                { transaction }
            );
        }

        const userQuery = {
            attributes: ['id'],
            where: { society_id: req.user.society_id, status: 'active' },
            transaction
        };
        if (targetBuildingIds.length) {
            userQuery.include = [{
                model: db.UserHouseMapping,
                required: true,
                include: [{
                    model: db.House,
                    attributes: [],
                    where: { building_id: { [Op.in]: targetBuildingIds } },
                    required: true
                }]
            }];
        }
        const users = await db.User.findAll(userQuery);

        const currentUserId = req.user.id;
        let usersToNotify = users.map(u => u.id).filter(id => id !== currentUserId);
        usersToNotify = [...new Set(usersToNotify)];

        if (usersToNotify.length > 0) {
            const notifications = usersToNotify.map(userId => ({
                user_id: userId,
                society_id: req.user.society_id,
                type: 'POLL',
                title: 'New Poll Created',
                message: question,
                reference_id: poll.id,
                is_read: false
            }));
            await db.Notification.bulkCreate(notifications, { transaction });

            // Emit Socket Events (Non-transactional)
            try {
                const io = require('../utils/socket').getIo();
                usersToNotify.forEach(userId => {
                    io.to(`user_${userId}`).emit('new_notification', {
                        title: 'New Poll Created',
                        message: question,
                        type: 'POLL'
                    });
                });
            } catch (socketError) {
                console.error("Socket emit failed (non-critical):", socketError);
            }
        }
        // --- Notification Logic End ---

        await transaction.commit();

        try {
            await auditService.logAction(
                req.user.id,
                req.user.society_id,
                'CREATED',
                'POLL',
                String(poll.id),
                { new_value: { title: poll.question }, ip_address: req.ip }
            );
        } catch (_) {}

        res.status(201).json(new ApiResponse(201, poll, 'Poll created successfully'));
    } catch (e) {
        await transaction.rollback();
        next(e);
    }
};

const getActivePolls = async (req, res, next) => {
    try {
        const where = {
            society_id: req.user.society_id,
            is_active: true,
            end_date: { [Op.gt]: new Date() }
        };

        const visibleIds = await visiblePollIds(req.user.society_id, req.userScope);
        if (visibleIds !== null) {
            if (!visibleIds.length) return res.status(200).json(new ApiResponse(200, []));
            where.id = { [Op.in]: visibleIds };
        }

        const polls = await db.Poll.findAll({
            where,
            include: [
                { model: db.PollOption, as: 'options' },
                {
                    model: db.PollVote,
                    as: 'votes',
                    where: { user_id: req.user.id },
                    required: false
                }
            ],
            order: [['created_at', 'DESC']]
        });
        res.status(200).json(new ApiResponse(200, polls));
    } catch (e) { next(e); }
};

const votePoll = async (req, res, next) => {
    try {
        const { poll_id, option_id } = req.body;

        const poll = await db.Poll.findByPk(poll_id);
        if (!poll) throw new ApiError(404, 'Poll not found');
        if (new Date() > poll.end_date) throw new ApiError(400, 'Poll has ended');

        const visibleIds = await visiblePollIds(poll.society_id, req.userScope);
        if (visibleIds !== null && !visibleIds.includes(poll.id)) {
            throw new ApiError(403, 'Poll outside your assigned buildings');
        }

        const existingVote = await db.PollVote.findOne({
            where: { poll_id, user_id: req.user.id }
        });
        if (existingVote) throw new ApiError(400, 'You have already voted');

        const vote = await db.PollVote.create({
            poll_id,
            option_id,
            user_id: req.user.id
        });

        res.status(201).json(new ApiResponse(201, vote, 'Vote recorded'));
    } catch (e) { next(e); }
};

const getPollResults = async (req, res, next) => {
    try {
        const { id } = req.params;
        const poll = await db.Poll.findByPk(id, {
            include: [{ model: db.PollOption, as: 'options' }]
        });

        if (!poll) throw new ApiError(404, 'Poll not found');

        const visibleIds = await visiblePollIds(poll.society_id, req.userScope);
        if (visibleIds !== null && !visibleIds.includes(poll.id)) {
            throw new ApiError(404, 'Poll not found');
        }

        // Aggregate votes
        const results = await Promise.all(poll.options.map(async (opt) => {
            const count = await db.PollVote.count({ where: { option_id: opt.id } });
            return {
                option: opt.option_text,
                count
            };
        }));

        // Count total active members since we are in a society scope usually by implicit auth. But wait, `poll` has a society_id.
        // We should count users in that society.
        const totalMembers = await db.User.count({
            where: { society_id: poll.society_id, status: 'active' }
        });

        res.status(200).json(new ApiResponse(200, {
            question: poll.question,
            results,
            totalMembers
        }));
    } catch (e) { next(e); }
};

module.exports = {
    createPoll,
    getActivePolls,
    votePoll,
    getPollResults
};
