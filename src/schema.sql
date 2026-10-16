-- Logistics Database Schema for Agent Runtime Demo
-- Database: company_logistics_db
-- User: root (read-write)

-- Schema
CREATE SCHEMA IF NOT EXISTS logistics;

-- Reference types
CREATE TYPE logistics.shipment_status AS ENUM (
  'CREATED','BOOKED','IN_TRANSIT','AT_PORT','CUSTOMS_HOLD','CUSTOMS_CLEARED',
  'OUT_FOR_DELIVERY','DELIVERED','CANCELLED','EXCEPTION'
);

CREATE TYPE logistics.leg_status AS ENUM (
  'PENDING','DEPARTED','ARRIVED','DELAYED','CANCELLED'
);

CREATE TYPE logistics.event_type AS ENUM (
  'CREATED','BOOKED','DEPARTED_PORT','ARRIVED_PORT','DISCHARGED',
  'GATE_IN','GATE_OUT','CUSTOMS_HOLD','CUSTOMS_RELEASE','HANDOFF',
  'OUT_FOR_DELIVERY','DELIVERED','DELAY','ETA_UPDATE','EXCEPTION_NOTE'
);

CREATE TYPE logistics.container_type AS ENUM ('DRY','REEFER','OPEN_TOP','TANK');

-- Parties and locations
CREATE TABLE logistics.customers (
  customer_id      BIGSERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  account_code     TEXT UNIQUE,
  contact_email    TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE logistics.carriers (
  carrier_id       BIGSERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  scac             TEXT UNIQUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE logistics.locations (
  location_id      BIGSERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  unlocode         TEXT UNIQUE,
  country_code     CHAR(2),
  tz               TEXT,
  lat              DOUBLE PRECISION,
  lon              DOUBLE PRECISION
);

CREATE TABLE logistics.vessels (
  vessel_id        BIGSERIAL PRIMARY KEY,
  name             TEXT NOT NULL,
  imo_number       TEXT UNIQUE,
  mmsi             TEXT UNIQUE,
  carrier_id       BIGINT REFERENCES logistics.carriers(carrier_id),
  active           BOOLEAN NOT NULL DEFAULT TRUE
);

-- Shipments and containers
CREATE TABLE logistics.shipments (
  shipment_id      BIGSERIAL PRIMARY KEY,
  customer_id      BIGINT REFERENCES logistics.customers(customer_id) NOT NULL,
  reference_no     TEXT UNIQUE,
  origin_id        BIGINT REFERENCES logistics.locations(location_id) NOT NULL,
  destination_id   BIGINT REFERENCES logistics.locations(location_id) NOT NULL,
  incoterm         TEXT,
  status           logistics.shipment_status NOT NULL DEFAULT 'CREATED',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  eta_final        TIMESTAMPTZ,
  etd_origin       TIMESTAMPTZ,
  current_location_id BIGINT REFERENCES logistics.locations(location_id)
);

CREATE TABLE logistics.containers (
  container_id     BIGSERIAL PRIMARY KEY,
  container_no     TEXT UNIQUE NOT NULL,
  type             logistics.container_type NOT NULL,
  owner_carrier_id BIGINT REFERENCES logistics.carriers(carrier_id),
  reefer_setpoint_c NUMERIC(5,2),
  active           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE logistics.shipment_legs (
  leg_id           BIGSERIAL PRIMARY KEY,
  shipment_id      BIGINT REFERENCES logistics.shipments(shipment_id) ON DELETE CASCADE,
  sequence_no      INT NOT NULL,
  mode             TEXT NOT NULL,
  carrier_id       BIGINT REFERENCES logistics.carriers(carrier_id),
  vessel_id        BIGINT REFERENCES logistics.vessels(vessel_id),
  origin_id        BIGINT REFERENCES logistics.locations(location_id) NOT NULL,
  destination_id   BIGINT REFERENCES logistics.locations(location_id) NOT NULL,
  etd              TIMESTAMPTZ,
  eta              TIMESTAMPTZ,
  ata              TIMESTAMPTZ,
  status           logistics.leg_status NOT NULL DEFAULT 'PENDING',
  UNIQUE (shipment_id, sequence_no)
);

CREATE TABLE logistics.shipment_containers (
  shipment_id      BIGINT REFERENCES logistics.shipments(shipment_id) ON DELETE CASCADE,
  container_id     BIGINT REFERENCES logistics.containers(container_id),
  PRIMARY KEY (shipment_id, container_id)
);

CREATE TABLE logistics.tracking_events (
  event_id         BIGSERIAL PRIMARY KEY,
  occurred_at      TIMESTAMPTZ NOT NULL,
  ingested_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  shipment_id      BIGINT REFERENCES logistics.shipments(shipment_id),
  leg_id           BIGINT REFERENCES logistics.shipment_legs(leg_id),
  container_id     BIGINT REFERENCES logistics.containers(container_id),
  vessel_id        BIGINT REFERENCES logistics.vessels(vessel_id),
  location_id      BIGINT REFERENCES logistics.locations(location_id),
  event            logistics.event_type NOT NULL,
  status_hint      logistics.shipment_status,
  details          JSONB,
  UNIQUE (shipment_id, occurred_at, event)
);

CREATE TABLE logistics.customs_clearance (
  clearance_id     BIGSERIAL PRIMARY KEY,
  shipment_id      BIGINT REFERENCES logistics.shipments(shipment_id) ON DELETE CASCADE,
  port_id          BIGINT REFERENCES logistics.locations(location_id),
  status           TEXT NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes            TEXT
);

CREATE TABLE logistics.exceptions (
  exception_id     BIGSERIAL PRIMARY KEY,
  shipment_id      BIGINT REFERENCES logistics.shipments(shipment_id) ON DELETE CASCADE,
  severity         TEXT NOT NULL,
  category         TEXT NOT NULL,
  opened_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at        TIMESTAMPTZ,
  summary          TEXT,
  details          JSONB
);

-- Indexes
CREATE INDEX idx_shipments_reference ON logistics.shipments (reference_no);
CREATE INDEX idx_shipments_customer_status ON logistics.shipments (customer_id, status);
CREATE INDEX idx_shipments_current_location ON logistics.shipments (current_location_id);

CREATE INDEX idx_shipment_legs_shipment ON logistics.shipment_legs (shipment_id, sequence_no);
CREATE INDEX idx_shipment_legs_destination_eta ON logistics.shipment_legs (destination_id, eta);

CREATE INDEX idx_tracking_events_shipment ON logistics.tracking_events (shipment_id, occurred_at DESC);
CREATE INDEX idx_tracking_events_container ON logistics.tracking_events (container_id, occurred_at DESC);

-- Views
CREATE VIEW logistics.v_shipment_latest_event AS
SELECT DISTINCT ON (te.shipment_id)
  te.shipment_id,
  te.event,
  te.status_hint,
  te.location_id,
  te.occurred_at,
  te.details
FROM logistics.tracking_events te
ORDER BY te.shipment_id, te.occurred_at DESC;

-- Materialized view for ETA risk
CREATE MATERIALIZED VIEW logistics.mv_eta_risk AS
SELECT
  s.shipment_id,
  s.reference_no,
  s.destination_id,
  l.eta,
  s.eta_final,
  CASE
    WHEN l.eta IS NULL THEN 'UNKNOWN'
    WHEN s.eta_final IS NOT NULL AND l.eta > s.eta_final THEN 'AT_RISK'
    ELSE 'ON_TRACK'
  END AS eta_status
FROM logistics.shipments s
LEFT JOIN LATERAL (
  SELECT sl.*
  FROM logistics.shipment_legs sl
  WHERE sl.shipment_id = s.shipment_id
  ORDER BY sl.sequence_no DESC
  LIMIT 1
) l ON TRUE;

CREATE INDEX idx_mv_eta_risk_status ON logistics.mv_eta_risk (eta_status, eta);
