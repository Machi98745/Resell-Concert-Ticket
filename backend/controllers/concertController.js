const concerts = require('../data/concerts.json');

exports.getAllConcerts = (req, res) => {
  try {
    const { search } = req.query;
    if (search && search.trim() !== '') {
      const keyword = search.trim().toLowerCase();
      const filtered = concerts.filter(
        (c) =>
          c.name.toLowerCase().includes(keyword) ||
          c.venue.toLowerCase().includes(keyword)
      );
      return res.status(200).json(filtered);
    }
    res.status(200).json(concerts);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

exports.getConcertById = (req, res) => {
  try {
    const { id } = req.params;
    const concert = concerts.find((c) => c.id === id);

    if (!concert) {
      return res.status(404).json({ message: 'Concert not found' });
    }

    res.status(200).json(concert);
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};