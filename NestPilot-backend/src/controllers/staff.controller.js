const db = require('../models');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { Op } = require('sequelize');

const addStaff = async (req, res, next) => {
    try {
        const data = { ...req.body, society_id: req.user.society_id };
        const staff = await db.ServiceStaff.create(data);
        res.status(201).json(new ApiResponse(201, staff, 'Staff added successfully'));
    } catch (e) { next(e); }
};

const getAllStaff = async (req, res, next) => {
    try {
        const staff = await db.ServiceStaff.findAll({
            where: { society_id: req.user.society_id, is_active: true }
        });
        res.status(200).json(new ApiResponse(200, staff));
    } catch (e) { next(e); }
};

const logAttendance = async (req, res, next) => {
    try {
        const { staff_id, type } = req.body; // type: 'IN' or 'OUT'

        const staff = await db.ServiceStaff.findByPk(staff_id);
        if (!staff) throw new ApiError(404, 'Staff not found');

        const today = new Date().toISOString().split('T')[0];

        let attendance = await db.StaffAttendance.findOne({
            where: { staff_id, date: today }
        });

        if (type === 'IN') {
            if (!attendance) {
                attendance = await db.StaffAttendance.create({
                    staff_id,
                    date: today,
                    in_time: new Date()
                });
            }
        } else if (type === 'OUT') {
            if (attendance) {
                attendance.out_time = new Date();
                await attendance.save();
            } else {
                // Edge case: Out without In (maybe missed scan)
                attendance = await db.StaffAttendance.create({
                    staff_id,
                    date: today,
                    out_time: new Date(),
                    is_present: true // Assume present if leaving
                });
            }
        }

        res.status(200).json(new ApiResponse(200, attendance, `Staff marked ${type}`));
    } catch (e) { next(e); }
};

const getStaffAttendance = async (req, res, next) => {
    try {
        const { staff_id } = req.params;
        const attendance = await db.StaffAttendance.findAll({
            where: { staff_id },
            order: [['date', 'DESC']],
            limit: 30 // Last 30 days
        });
        res.status(200).json(new ApiResponse(200, attendance));
    } catch (e) { next(e); }
};

module.exports = {
    addStaff,
    getAllStaff,
    logAttendance,
    getStaffAttendance
};
