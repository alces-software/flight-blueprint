import Express from 'express';
import { handleExample } from '../modules/example';

const api = Express.Router();

const process = (fn, req, res) => {
  fn(req.body).then( () => {
    res.json({ success: true });
  }).catch((err) => {
    res.json({ error: err });
  });
};

api.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

api.get('/', (req, res, next) => {
  res.json({});
});

api.post('/example', (req, res, next) => {
  process(handleExample, req, res);
});

export default api;
