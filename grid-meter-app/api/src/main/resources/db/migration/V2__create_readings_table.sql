CREATE TABLE readings (
    id                UUID PRIMARY KEY,
    meter_id          UUID NOT NULL REFERENCES meters (id),
    reading_timestamp TIMESTAMPTZ    NOT NULL,
    received_at       TIMESTAMPTZ    NOT NULL,
    value             NUMERIC(12, 3) NOT NULL,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX ix_readings_meter_id_reading_timestamp ON readings (meter_id, reading_timestamp);
