-- Выполните этот скрипт в Supabase SQL Editor

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS location_lat double precision,
ADD COLUMN IF NOT EXISTS location_lng double precision;
