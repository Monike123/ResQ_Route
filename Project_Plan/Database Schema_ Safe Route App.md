# Database Schema: Safe Route App

This document outlines the complete Entity-Relationship (ER) description, table structures, field-level details, indexing strategies, and PostGIS usage plan for the Safe Route App. The database is built on PostgreSQL with the PostGIS extension to handle geospatial data efficiently.

## 1. Complete ER Description

The Safe Route App database schema is designed to support user management, journey tracking, safety scoring, emergency response, and feedback mechanisms. Key entities include Users, Emergency Contacts, Journeys, Location Logs, Unsafe Zones, Flags, Reports, Crime Data, and Feedback. Relationships between these entities ensure data integrity and facilitate complex queries.

## 2. Table List and Field-Level Details

Below is a detailed breakdown of each table, including column names, data types, constraints, and descriptions.

### 2.1. `users` Table

Stores user registration and identity verification information.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `VARCHAR(36)`      | `PRIMARY KEY`, `UUID`                     | Unique identifier for the user                  |
| `phone`             | `VARCHAR(20)`      | `NOT NULL`, `UNIQUE`                      | User's primary phone number                     |
| `email`             | `VARCHAR(255)`     | `UNIQUE`                                  | User's email address (optional)                 |
| `password_hash`     | `VARCHAR(255)`     | `NOT NULL`                                | Hashed password using Argon2                    |
| `aadhar_number`     | `VARCHAR(12)`      | `UNIQUE`                                  | Encrypted Aadhaar number (reference only)       |
| `pan_number`        | `VARCHAR(10)`      | `UNIQUE`                                  | Encrypted PAN number (reference only)           |
| `verification_status` | `ENUM("pending", "verified", "failed")` | `NOT NULL`, `DEFAULT 'pending'`           | Status of identity verification                 |
| `verification_type` | `ENUM("aadhar", "pan")` |                                           | Type of ID used for verification                |
| `profile_image_url` | `VARCHAR(255)`     |                                           | URL to user's profile image                     |
| `gender`            | `ENUM("male", "female", "other")` |                                           | User's gender for safety analytics (optional)   |
| `preferred_emergency_language` | `VARCHAR(10)`      | `DEFAULT 'en'`                            | Preferred language for emergency notifications  |
| `is_active`         | `BOOLEAN`          | `NOT NULL`, `DEFAULT TRUE`                | Account active status                           |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of user creation                      |
| `updated_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Last update timestamp                           |

### 2.2. `sessions` Table

Manages user login sessions and JWT tokens.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `VARCHAR(36)`      | `PRIMARY KEY`, `UUID`                     | Unique session ID                               |
| `user_id`           | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (users.id)`      | Foreign key to the `users` table                |
| `jwt_token`         | `TEXT`             | `NOT NULL`                                | JSON Web Token for authentication               |
| `refresh_token`     | `TEXT`             | `NOT NULL`                                | Refresh token for renewing JWT                  |
| `device_info`       | `JSONB`            |                                           | Device details (e.g., model, OS)                |
| `ip_address`        | `VARCHAR(45)`      |                                           | IP address from which the session originated    |
| `expires_at`        | `TIMESTAMP`        | `NOT NULL`                                | Timestamp when the session expires              |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of session creation                   |

### 2.3. `emergency_contacts` Table

Stores emergency contact details for each user.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `VARCHAR(36)`      | `PRIMARY KEY`, `UUID`                     | Unique identifier for the emergency contact     |
| `user_id`           | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (users.id)`      | Foreign key to the `users` table                |
| `name`              | `VARCHAR(255)`     | `NOT NULL`                                | Name of the emergency contact                   |
| `phone`             | `VARCHAR(20)`      | `NOT NULL`                                | Phone number of the emergency contact           |
| `priority`          | `INTEGER`          | `NOT NULL`, `CHECK (priority BETWEEN 1 AND 3)` | Priority level (1=highest, 3=lowest)            |
| `verified`          | `BOOLEAN`          | `NOT NULL`, `DEFAULT FALSE`               | Indicates if the contact has been verified      |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of contact creation                   |

### 2.4. `journeys` Table

Records details of each user journey.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `VARCHAR(36)`      | `PRIMARY KEY`, `UUID`                     | Unique identifier for the journey               |
| `user_id`           | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (users.id)`      | Foreign key to the `users` table                |
| `origin`            | `GEOMETRY(POINT, 4326)` | `NOT NULL`                                | Starting point of the journey (latitude, longitude) |
| `destination`       | `GEOMETRY(POINT, 4326)` | `NOT NULL`                                | Ending point of the journey (latitude, longitude)   |
| `selected_route_id` | `VARCHAR(36)`      | `FOREIGN KEY (routes.id)`                 | Foreign key to the `routes` table (selected route) |
| `start_time`        | `TIMESTAMP`        | `NOT NULL`                                | Timestamp when the journey started              |
| `end_time`          | `TIMESTAMP`        |                                           | Timestamp when the journey ended                |
| `status`            | `ENUM("initiated", "active", "warning", "emergency", "completed", "cancelled")` | `NOT NULL`, `DEFAULT 'initiated'`         | Current status of the journey                   |
| `share_location`    | `BOOLEAN`          | `NOT NULL`, `DEFAULT FALSE`               | Indicates if live location sharing is enabled   |
| `tracking_link_token` | `VARCHAR(255)`     | `UNIQUE`                                  | Token for public live tracking link             |
| `safety_score_at_start` | `FLOAT`            |                                           | Safety score of the selected route at journey start |
| `final_safety_score` | `FLOAT`            |                                           | Final safety score of the actual path taken     |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of journey creation                   |
| `updated_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Last update timestamp                           |

### 2.5. `journey_points` Table

Logs granular GPS points during an active journey.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `BIGSERIAL`        | `PRIMARY KEY`                             | Unique identifier for the journey point         |
| `journey_id`        | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (journeys.id)`   | Foreign key to the `journeys` table             |
| `location`          | `GEOMETRY(POINT, 4326)` | `NOT NULL`                                | GPS coordinates of the point                    |
| `timestamp`         | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp when the point was recorded           |
| `speed`             | `FLOAT`            |                                           | Speed at the recorded point (meters/second)     |
| `accuracy`          | `FLOAT`            |                                           | GPS accuracy at the recorded point              |

### 2.6. `routes` Table

Stores calculated route details and their safety scores.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `VARCHAR(36)`      | `PRIMARY KEY`, `UUID`                     | Unique identifier for the route                 |
| `journey_id`        | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (journeys.id)`   | Foreign key to the `journeys` table             |
| `path`              | `GEOMETRY(LINESTRING, 4326)` | `NOT NULL`                                | Geospatial representation of the route          |
| `waypoints`         | `JSONB`            | `NOT NULL`                                | List of `{lat, lng}` coordinates for the route  |
| `distance`          | `FLOAT`            | `NOT NULL`                                | Distance of the route in kilometers             |
| `duration`          | `INTEGER`          | `NOT NULL`                                | Estimated duration of the route in minutes      |
| `safety_score`      | `FLOAT`            | `NOT NULL`                                | Calculated safety score (0-100)                 |
| `crime_count`       | `INTEGER`          | `DEFAULT 0`                               | Number of crime incidents along the route       |
| `commercial_points` | `INTEGER`          | `DEFAULT 0`                               | Number of commercial points along the route     |
| `user_flags`        | `INTEGER`          | `DEFAULT 0`                               | Number of user-flagged unsafe zones along route |
| `street_lights`     | `INTEGER`          | `DEFAULT 0`                               | Estimated number of street lights               |
| `crime_severity_breakdown` | `JSONB`            |                                           | Breakdown of crime severity (low, medium, high) |
| `gemini_analysis`   | `JSONB`            |                                           | Full AI analysis response from Gemini           |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of route calculation                  |

### 2.7. `unsafe_zones` Table

Stores information about user-flagged or system-identified unsafe areas.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `BIGSERIAL`        | `PRIMARY KEY`                             | Unique identifier for the unsafe zone           |
| `location`          | `GEOMETRY(POINT, 4326)` | `NOT NULL`                                | Geospatial location of the unsafe zone          |
| `flagged_by_user_id` | `VARCHAR(36)`      | `FOREIGN KEY (users.id)`                  | User who initially flagged the zone (if applicable) |
| `flag_reason`       | `VARCHAR(500)`     |                                           | Description of why the area is unsafe           |
| `flag_type`         | `ENUM("broken_light", "suspicious_activity", "crime_report", "general")` | `DEFAULT 'general'`                       | Categorization of the unsafe zone               |
| `report_count`      | `INTEGER`          | `NOT NULL`, `DEFAULT 1`                   | Number of times this zone has been reported     |
| `severity`          | `ENUM("low", "medium", "high")` | `NOT NULL`, `DEFAULT 'medium'`            | Perceived severity of the unsafe zone           |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of the initial report                 |
| `verified`          | `BOOLEAN`          | `NOT NULL`, `DEFAULT FALSE`               | Admin verification status                       |
| `decay_coefficient` | `FLOAT`            | `NOT NULL`, `DEFAULT 0.01`                | Rate at which severity decays over time         |

### 2.8. `flags` Table

Detailed records of individual user flags within an unsafe zone.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `BIGSERIAL`        | `PRIMARY KEY`                             | Unique identifier for the flag                  |
| `user_id`           | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (users.id)`      | User who submitted the flag                     |
| `unsafe_zone_id`    | `BIGINT`           | `NOT NULL`, `FOREIGN KEY (unsafe_zones.id)` | Foreign key to the `unsafe_zones` table         |
| `location`          | `GEOMETRY(POINT, 4326)` | `NOT NULL`                                | Exact location of the flag                      |
| `reason`            | `VARCHAR(500)`     | `NOT NULL`                                | User's description of the flag                  |
| `photo_url`         | `VARCHAR(255)`     |                                           | URL to an optional photo attachment             |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of flag submission                    |

### 2.9. `reports` Table

Stores generated Safe Route Reports (SRR).

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `VARCHAR(36)`      | `PRIMARY KEY`, `UUID`                     | Unique identifier for the report                |
| `journey_id`        | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (journeys.id)`   | Foreign key to the `journeys` table             |
| `user_id`           | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (users.id)`      | User who generated the report                   |
| `report_url`        | `VARCHAR(255)`     | `NOT NULL`                                | URL to the generated PDF report (e.g., S3)      |
| `digital_hash`      | `VARCHAR(64)`      | `NOT NULL`                                | SHA-256 hash for tamper prevention              |
| `generated_at`      | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of report generation                  |
| `share_link_token`  | `VARCHAR(255)`     | `UNIQUE`                                  | Token for shareable report link                 |
| `share_link_expires_at` | `TIMESTAMP`        |                                           | Expiration timestamp for the shareable link     |

### 2.10. `feedback` Table

Records user feedback on journeys and routes.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `BIGSERIAL`        | `PRIMARY KEY`                             | Unique identifier for the feedback              |
| `journey_id`        | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (journeys.id)`   | Foreign key to the `journeys` table             |
| `user_id`           | `VARCHAR(36)`      | `NOT NULL`, `FOREIGN KEY (users.id)`      | User who provided the feedback                  |
| `rating`            | `INTEGER`          | `NOT NULL`, `CHECK (rating BETWEEN 1 AND 5)` | Star rating (1-5) for the journey/route         |
| `comment`           | `TEXT`             |                                           | User's textual feedback                         |
| `unsafe_zone_disputed` | `BOOLEAN`          | `DEFAULT FALSE`                           | Indicates if user disputed an unsafe zone       |
| `created_at`        | `TIMESTAMP`        | `NOT NULL`, `DEFAULT CURRENT_TIMESTAMP`   | Timestamp of feedback submission                |

### 2.11. `crime_data` Table

Stores imported and AI-aggregated crime data.

| Column Name         | Data Type          | Constraints                               | Description                                     |
| :------------------ | :----------------- | :---------------------------------------- | :---------------------------------------------- |
| `id`                | `BIGSERIAL`        | `PRIMARY KEY`                             | Unique identifier for the crime record          |
| `location`          | `GEOMETRY(POINT, 4326)` | `NOT NULL`                                | Geospatial location of the crime                |
| `crime_type`        | `VARCHAR(255)`     | `NOT NULL`                                | Type of crime (e.g., 
