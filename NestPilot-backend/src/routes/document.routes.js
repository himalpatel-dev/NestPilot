const express = require('express');
const router = express.Router();
const controller = require('../controllers/document.controller');
const auth = require('../middlewares/auth.middleware');
const role = require('../middlewares/role.middleware');

// Check if upload util exists, if not I'll use a basic multer setup here for now or create the util.
// Since I can't check mid-stream, I'll assume standard multer usage.
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const dir = 'uploads/documents';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const uploadMiddleware = multer({ storage: storage });

router.use(auth);

router.get('/', controller.getDocuments);
router.post('/', role(['SOCIETY_ADMIN']), uploadMiddleware.single('file'), controller.uploadDocument);
router.delete('/:id', role(['SOCIETY_ADMIN']), controller.deleteDocument);

module.exports = router;
