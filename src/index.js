const express = require("express");
const app = express();
const pg = require("pg");

const { Client } = pg;

const client = new Client({
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  host: process.env.POSTGRES_HOST,
  port: process.env.POSTGRES_PORT,
  database: process.env.POSTGRES_DATABASE_NAME,
});
client.connect();

app.get("/product", async (req, res) => {
  const { rows } = await client.query("SELECT * FROM products");
  res.send({ products: rows });
});

app.get("/user", async (req, res) => {
  const { rows } = await client.query("SELECT * FROM users");
  res.send({ users: rows });
});

app.get("/order", async (req, res) => {
  const { rows } = await client.query("SELECT * FROM orders");
  res.send({ orders: rows });
});

app.listen(3000, () => {
  console.log("Server is running on port 3000");
});
