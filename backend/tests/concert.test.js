const request = require('supertest');
const app = require('../app');

describe('Concert API', () => {
  it('should return all concerts', async () => {
    const res = await request(app).get('/api/concerts');
    expect(res.statusCode).toEqual(200);
    expect(Array.isArray(res.body)).toBeTruthy();
  });

  it('should return concert by id', async () => {
    const res = await request(app).get('/api/concerts/1');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('concert_id');
  });

  it('should return 404 for invalid id', async () => {
    const res = await request(app).get('/api/concerts/999999');
    expect(res.statusCode).toEqual(404);
  });
});