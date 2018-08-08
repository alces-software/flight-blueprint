import Express from 'express';
import universalLoader from '../universal';

const router = Express.Router();
router.get('/', universalLoader);

module.exports = router;
