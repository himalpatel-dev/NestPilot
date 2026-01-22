const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const compression = require("compression");
const path = require("path");
const errorHandler = require("./middlewares/error.middleware");
const routes = require("./routes");
const ApiError = require("./utils/ApiError");

const app = express();

// Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "16kb" }));
app.use(express.urlencoded({ extended: true, limit: "16kb" }));
app.use(compression());
app.use(morgan("dev"));
app.use(express.static("public")); // For static assets if any
app.use("/uploads", express.static(path.join(__dirname, "../uploads"))); // Serve uploads

// Swagger
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'NestPilot Society Management API',
            version: '1.0.0',
        },
        servers: [{ url: 'http://localhost:5000' }],
    },
    apis: ['./src/routes/*.js'],
};
const swaggerDocs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

// Routes
app.use("/api", routes);

// 404 Handler
app.use((req, res, next) => {
    next(new ApiError(404, "Not Found"));
});

// Error Handler
app.use(errorHandler);

module.exports = app;
