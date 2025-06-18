const express = require("express");
const router = express.Router();
const pool = require("../database");

//Read all event
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM events");
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

//Read one event
router.get("/:id", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT e.id, e.title, e.description, e.start_date, e.end_date, e.location, e.location_type, e.max_participants, e.is_private, e.status, json_build_object('id', u.id, 'firstname', u.firstname, 'lastname', u.lastname) AS creator FROM events e JOIN users u ON e.creator_id = u.id WHERE e.id = $1",
      [req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: "Not found" });
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

//Create a event
router.post("/", async (req, res) => {
  const {
    title,
    description,
    start_date,
    end_date,
    location,
    location_type,
    max_participants,
    is_private,
    status,
    creator_id,
    group_id,
  } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO events (title,
    description,
    start_date,
    end_date,
    location,
    location_type,
    max_participants,
    is_private,
    status,
    creator_id,
    group_id)
       VALUES ($1, $2, $3, $4, $5, $6,$7,$8,$9,$10,$11) RETURNING *`,
      [
        title,
        description,
        start_date,
        end_date,
        location,
        location_type,
        max_participants,
        is_private,
        status,
        creator_id,
        group_id,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/:eventId/rsvps", async (req, res) => {
  if (!req.body) {
    return res.status(400).json({ error: "Missing request body" });
  }
  const { status, response_date, notes } = req.body;
  const eventId = parseInt(req.params.eventId, 10);
  const userId = 1;

  if (!status || !response_date || isNaN(eventId)) {
    return res.status(400).json({ error: "Missing or invalid fields" });
  }

  try {
    const result = await pool.query(
      `INSERT INTO EventRSVPs (status, response_date, notes, event_id, user_id)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (event_id, user_id) DO UPDATE
       SET status = EXCLUDED.status,
           response_date = EXCLUDED.response_date,
           notes = EXCLUDED.notes,
           updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [status, response_date, notes, eventId, userId]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
