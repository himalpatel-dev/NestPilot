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

const allowedOrigins = [
    'http://localhost:3000',
    'https://nestpilot.krimal.in',
    'http://nestpilot.krimal.in',
    'https://nestpilotapi.krimal.in',
    'http://nestpilotapi.krimal.in',
];

const isOriginAllowed = (origin) => {
    // Allow non-browser requests (mobile apps, Postman, curl, server-to-server)
    if (!origin) return true;

    // Explicit domain match
    if (allowedOrigins.includes(origin)) return true;

    // Allow all localhost and 127.0.0.1 ports (for Flutter Web and local development)
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) return true;

    // Allow local LAN IPs (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
    if (/^https?:\/\/(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+)(:\d+)?$/.test(origin)) return true;

    // Allow krimal.in subdomains
    if (/^https?:\/\/([a-zA-Z0-9-]+\.)*krimal\.in(:\d+)?$/.test(origin)) return true;

    return false;
};

// Middlewares
app.use(helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" }
}));
app.use(cors({
    origin: function (origin, callback) {
        if (isOriginAllowed(origin)) {
            return callback(null, true);
        }
        return callback(null, false);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
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
