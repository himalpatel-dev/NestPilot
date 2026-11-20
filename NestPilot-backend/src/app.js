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
const cors = require('cors');
const allowedOrigins = [
    'http://localhost:51368',
    'http://localhost:3000',
    'https://nestpilot.krimal.in'
];

// Middlewares
app.use(helmet());
app.use(cors({
    origin: function (origin, callback) {
        // Allow requests without an Origin header (Postman, server-to-server)
        if (!origin || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        return callback(new Error('Not allowed by CORS: ' + origin));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
    optionsSuccessStatus: 204
}));
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
        servers: [{ url: 'http://localhost:5005' }],
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
