// routes/hello.js
const express = require("express");
const router = express.Router();

// A hello route
router.get("/", (_req, res) => {
  res.send("Hello! 2024-04-12!");
});

module.exports = router;
