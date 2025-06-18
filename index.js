const express = require("express");
const cors = require("cors");
const resourcesRoutes = require("./routes/ressources");
const eventsRoutes = require("./routes/events");

require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`[${req.method}] ${req.url} - Body:`, req.body);
  next();
});

app.use("/api/v1/ressources", resourcesRoutes);
app.use("/api/v1/events", eventsRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`server ok ${PORT}`);
});
