const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
    // Ambil token dari header Authorization
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            message: 'Token tidak ditemukan. Silakan login.'
        });
    }

    const token = authHeader.split(' ')[1];

    try {
        // Periksa token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Simpan data pengguna ke request
        req.user = decoded;

        next();

    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Token tidak valid atau sudah kedaluwarsa'
        });
    }
};

module.exports = authMiddleware;