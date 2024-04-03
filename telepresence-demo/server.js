const express = require("express");
const app = express();
const helloRoute = require("./routes/hello");

app.get("/", (_req, res) => {
  res.send("<h1>Hello, Express.js Server!</h1>");
});

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

app.use("/hello", helloRoute);
