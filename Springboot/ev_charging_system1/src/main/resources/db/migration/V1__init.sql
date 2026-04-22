-- =============================================================================
-- V1__init.sql
-- Initial PostgreSQL 17 schema. Mirrors JPA entities under com.example.ev_charging_system1.entity.
-- Run via Flyway when SPRING_FLYWAY_ENABLED=true (and SPRING_JPA_DDL_AUTO=validate).
--
-- IMPORTANT migration note (BCrypt):
-- After UserService was changed to BCrypt, any pre-existing rows in `users` with
-- plain-text passwords will be auto-upgraded on first successful login (legacy
-- fallback path in UserService.login). Rows that never log in again stay plain.
-- For a clean prod, truncate `users` before enabling Flyway, or hash existing
-- passwords with: UPDATE users SET password = crypt(password, gen_salt('bf'));
-- (requires `pgcrypto` extension; not enabled by default).
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    user_pk     BIGSERIAL PRIMARY KEY,
    login_id    VARCHAR(255) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    name        VARCHAR(255) NOT NULL,
    phone       VARCHAR(255) UNIQUE,
    building    VARCHAR(255),
    unit        VARCHAR(255),
    role        VARCHAR(255) NOT NULL DEFAULT 'USER',
    created_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_pk    BIGSERIAL PRIMARY KEY,
    user_pk       BIGINT REFERENCES users(user_pk) ON DELETE CASCADE,
    plate_number  VARCHAR(255),
    vehicle_type  VARCHAR(255),
    created_at    TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_vehicles_user_pk      ON vehicles(user_pk);
CREATE INDEX IF NOT EXISTS idx_vehicles_plate_number ON vehicles(plate_number);

CREATE TABLE IF NOT EXISTS charging_station (
    station_pk      BIGSERIAL PRIMARY KEY,
    station_number  VARCHAR(255),
    camera_pk       VARCHAR(255),
    building        VARCHAR(255),
    location        VARCHAR(255),
    status          VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS detection_log (
    log_pk           BIGSERIAL PRIMARY KEY,
    plate_number     VARCHAR(20),
    station_pk       BIGINT REFERENCES charging_station(station_pk) ON DELETE SET NULL,
    detection_time   TIMESTAMP,
    result           VARCHAR(20),
    confidence       DOUBLE PRECISION,
    image_url        VARCHAR(255),
    plate_image_url  VARCHAR(255),
    is_ev            BOOLEAN
);
CREATE INDEX IF NOT EXISTS idx_detection_log_station_time ON detection_log(station_pk, detection_time DESC);
CREATE INDEX IF NOT EXISTS idx_detection_log_plate        ON detection_log(plate_number);

CREATE TABLE IF NOT EXISTS charging_queue (
    queue_pk      BIGSERIAL PRIMARY KEY,
    vehicle_pk    BIGINT REFERENCES vehicles(vehicle_pk)        ON DELETE CASCADE,
    station_pk    BIGINT REFERENCES charging_station(station_pk) ON DELETE SET NULL,
    request_time  TIMESTAMP,
    status        VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_queue_status_request ON charging_queue(status, request_time);

CREATE TABLE IF NOT EXISTS charging_history (
    history_pk      BIGSERIAL PRIMARY KEY,
    user_pk         BIGINT REFERENCES users(user_pk) ON DELETE CASCADE,
    station_number  VARCHAR(255),
    start_time      TIMESTAMP,
    end_time        TIMESTAMP,
    status          VARCHAR(255),
    energy_used     DOUBLE PRECISION DEFAULT 0.0,
    cost            INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_history_user_start ON charging_history(user_pk, start_time DESC);

-- Seed the 4 charging stations referenced by Python detectors (stationPk = 1..4).
INSERT INTO charging_station (station_pk, station_number, building, location, status) VALUES
    (1, 'A-01', 'A', 'A동 1번 충전기', 'available'),
    (2, 'A-02', 'A', 'A동 2번 충전기', 'available'),
    (3, 'B-01', 'B', 'B동 1번 충전기', 'available'),
    (4, 'B-02', 'B', 'B동 2번 충전기', 'available')
ON CONFLICT (station_pk) DO NOTHING;

-- Bump the BIGSERIAL sequence past the seeded IDs so new inserts don't collide.
SELECT setval(
    pg_get_serial_sequence('charging_station', 'station_pk'),
    GREATEST((SELECT MAX(station_pk) FROM charging_station), 1)
);
