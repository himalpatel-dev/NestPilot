const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

const createPoll = async (req, res, next) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { question, description, end_date, options } = req.body; // options: ["Yes", "No"]

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

        await transaction.commit();
        res.status(201).json(new ApiResponse(201, poll, 'Poll created successfully'));
    } catch (e) {
        await transaction.rollback();
        next(e);
    }
};

const getActivePolls = async (req, res, next) => {
    try {
        const polls = await db.Poll.findAll({
            where: {
                society_id: req.user.society_id,
                is_active: true,
                end_date: { [db.Sequelize.Op.gt]: new Date() }
            },
            include: [
                { model: db.PollOption, as: 'options' },
                {
                    model: db.PollVote,
                    as: 'votes',
                    where: { user_id: req.user.id },
                    required: false // Left join to see if I voted
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
