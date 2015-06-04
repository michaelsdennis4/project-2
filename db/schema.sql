DROP DATABASE IF EXISTS forum_db;

CREATE DATABASE forum_db;

\c forum_db

CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	fname VARCHAR NOT NULL,
	lname VARCHAR NOT NULL,
	email VARCHAR NOT NULL,
	password VARCHAR NOT NULL,
	signed_up_on DATE NOT NULL,
	gender VARCHAR(1),
	image VARCHAR,
	phone VARCHAR,
	show_location BOOLEAN NOT NULL,
	get_notifications VARCHAR
);
