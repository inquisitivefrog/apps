CREATE TABLE meters (
    id            UUID PRIMARY KEY,
    serial_number VARCHAR(100) NOT NULL,
    location      VARCHAR(255) NOT NULL,
    status        VARCHAR(20)  NOT NULL,
    installed_at  TIMESTAMPTZ  NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX ux_meters_serial_number ON meters (serial_number);
