const express = require("express");

const app = express();
const port = process.env.PORT || 8080;

app.get("/", (_req, res) => {
  res.send("Module 15 ECS Fargate assignment app is running");
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});
