const ApiError = require("../utils/ApiError");

const errorHandler = (err, req, res, next) => {
    let error = err;

    // Handle Sequelize validation errors
    if (error.name === 'SequelizeValidationError' || error.name === 'SequelizeUniqueConstraintError') {
        const statusCode = 400;
        const message = 'Validation Error';
        const errors = error.errors.map(e => e.message);
        error = new ApiError(statusCode, message, errors, error.stack);
    }

    if (!(error instanceof ApiError)) {
        const statusCode = error.statusCode || 500;
        const message = error.message || "Internal Server Error";
        error = new ApiError(statusCode, message, error?.errors || [], error.stack);
    }

    const response = {
        success: false,
        statusCode: error.statusCode,
        message: error.message,
        errors: error.errors, // Include errors in response
        ...(process.env.NODE_ENV === "development" ? { stack: error.stack } : {}),
    };

    res.status(error.statusCode).json(response);
};

module.exports = errorHandler;
