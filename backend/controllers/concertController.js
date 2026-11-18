const ConcertModel = require('../models/concertModel');

// ดึงรายการคอนเสิร์ตทั้งหมด
exports.getAllConcerts = async (req, res) => {
  try {
    const { search } = req.query;
    const concerts = await ConcertModel.getAll(search);
    return res.status(200).json(concerts);
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Database Error' });
  }
};

// ดึงรายละเอียดคอนเสิร์ตตาม ID
exports.getConcertById = async (req, res) => {
  try {
    const { id } = req.params;

    // ตรวจสอบว่า ID เป็นตัวเลขหรือไม่
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({
        message: 'Invalid concert ID',
      });
    }

    const result = await ConcertModel.getById(id);
    const concert = Array.isArray(result) ? result[0] : result;

    if (!concert) {
      return res.status(404).json({
        message: 'Concert not found',
      });
    }

    return res.status(200).json(concert);
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Database Error' });
  }
};

// เพิ่มคอนเสิร์ตใหม่ (Admin)
exports.createConcert = async (req, res) => {
  try {
    const { title, artist, category, description, venue, show_datetime, poster_url } = req.body;

    if (!title || !venue || !show_datetime) {
      return res.status(400).json({
        message: 'Title, venue, and show date/time are required.',
      });
    }

    const insertId = await ConcertModel.create({
      title,
      artist,
      category,
      description,
      venue,
      show_datetime,
      poster_url,
    });

    const result = await ConcertModel.getById(insertId);
    const createdConcert = Array.isArray(result) ? result[0] : result;

    return res.status(201).json({
      message: 'Concert created successfully',
      concert: createdConcert,
    });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Database Error' });
  }
};

// แก้ไขข้อมูลคอนเสิร์ต (Admin)
exports.updateConcert = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, artist, category, description, venue, show_datetime, poster_url } = req.body;

    if (!title || !venue || !show_datetime) {
      return res.status(400).json({
        message: 'Title, venue, and show date/time are required.',
      });
    }

    const affectedRows = await ConcertModel.update(id, {
      title,
      artist,
      category,
      description,
      venue,
      show_datetime,
      poster_url,
    });

    if (affectedRows === 0) {
      return res.status(404).json({ message: 'Concert not found' });
    }

    const result = await ConcertModel.getById(id);
    const updatedConcert = Array.isArray(result) ? result[0] : result;

    return res.status(200).json({
      message: 'Concert updated successfully',
      concert: updatedConcert,
    });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Database Error' });
  }
};

// ลบคอนเสิร์ต (Admin)
exports.deleteConcert = async (req, res) => {
  try {
    const { id } = req.params;
    const affectedRows = await ConcertModel.delete(id);

    if (affectedRows === 0) {
      return res.status(404).json({ message: 'Concert not found' });
    }

    return res.status(200).json({ message: 'Concert deleted successfully' });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Database Error' });
  }
};

// อัปโหลดรูปโปสเตอร์คอนเสิร์ต
exports.uploadPoster = (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file uploaded' });
    }
    const posterUrl = `${req.protocol}://${req.get('host')}/uploads/posters/${req.file.filename}`;
    return res.status(200).json({ poster_url: posterUrl });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Failed to upload image' });
  }
};