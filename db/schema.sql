-- DROP DATABASE IF EXISTS forum_db;

-- CREATE DATABASE forum_db;

\c forum_db

-- CREATE TABLE users (
-- 	id SERIAL PRIMARY KEY,
-- 	fname VARCHAR NOT NULL,
-- 	lname VARCHAR NOT NULL,
-- 	email VARCHAR NOT NULL,
-- 	password VARCHAR NOT NULL,
-- 	signed_up_on DATE NOT NULL,
-- 	gender VARCHAR(1),
-- 	image VARCHAR,
-- 	phone VARCHAR,
-- 	show_location BOOLEAN NOT NULL,
-- 	get_notifications VARCHAR,
-- 	bio: TEXT
-- );

CREATE TABLE topics (
	id SERIAL PRIMARY KEY,
	subject VARCHAR NOT NULL,
	owner_id INTEGER NOT NULL REFERENCES users(id),
	created_on DATE NOT NULL,
	details TEXT,
	user_location VARCHAR
);



