-- ================================================================
-- Database
-- CREATE database counter_strike;
-- ================================================================

-- +goose Up
-- +goose StatementBegin

-- ================================================================
-- Counter-Strike 2 Complete Database Schema
-- Senior-level PostgreSQL implementation with UUIDs and relationships
-- ================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create dedicated schema
CREATE SCHEMA IF NOT EXISTS cs2;

-- ================================================================
-- 1. WEAPON CATEGORIES (Rifles, Pistols, SMGs, etc.)
-- ================================================================
CREATE TABLE cs2.weapon_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name VARCHAR(50) NOT NULL UNIQUE, -- e.g., Rifle, Pistol, SMG, Sniper, Shotgun, Knife, Gloves
    description TEXT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- ================================================================
-- 2. WEAPONS (AK-47, M4A4, etc.)
-- ================================================================
CREATE TABLE cs2.weapons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id uuid NOT NULL REFERENCES cs2.weapon_categories(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    code VARCHAR(50) NOT NULL UNIQUE, -- short code, e.g. "AK-47", "M4A4"
    display_name VARCHAR(100) NOT NULL, -- readable name
    game_id INTEGER NULL, -- CS2 internal weapon ID
    is_knife BOOLEAN DEFAULT false NOT NULL,
    is_glove BOOLEAN DEFAULT false NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- ================================================================
-- 3. SKIN CONDITIONS (Factory New, Minimal Wear, etc.)
-- ================================================================
CREATE TABLE cs2.skin_conditions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name VARCHAR(50) NOT NULL UNIQUE,
    short_name VARCHAR(10) NOT NULL UNIQUE, -- FN, MW, FT, WW, BS
    min_float numeric(15,14) NOT NULL CHECK (min_float >= 0 AND min_float <= 1),
    max_float numeric(15,14) NOT NULL CHECK (max_float >= 0 AND max_float <= 1),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id),
    CONSTRAINT check_float_range CHECK (min_float < max_float)
);

-- ================================================================
-- 4. SKIN RARITIES (Consumer, Industrial, Mil-Spec, etc.)
-- ================================================================
CREATE TABLE cs2.skin_rarities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name VARCHAR(50) NOT NULL UNIQUE,
    color_hex CHAR(7) NULL, -- e.g. "#4B69FF"
    tier INTEGER NOT NULL UNIQUE, -- 1-7 for sorting
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- ================================================================
-- 5. COLLECTIONS (e.g., Dust 2 Collection, Mirage Collection)
-- ================================================================
CREATE TABLE cs2.skin_collections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL,
    release_date DATE NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- ================================================================
-- 6. SKIN TYPES (Normal, StatTrak, Souvenir)
-- ================================================================
CREATE TABLE cs2.skin_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name VARCHAR(20) NOT NULL UNIQUE, -- Normal, StatTrak, Souvenir
    prefix VARCHAR(20) NULL, -- "StatTrak™", "Souvenir"
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- ================================================================
-- 7. SKIN TEMPLATES (Paint definitions)
-- ================================================================
CREATE TABLE cs2.skin_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    weapon_id uuid NOT NULL REFERENCES cs2.weapons(id) ON DELETE CASCADE ON UPDATE CASCADE,
    collection_id uuid NULL REFERENCES cs2.skin_collections(id) ON DELETE SET NULL ON UPDATE CASCADE,
    rarity_id uuid NOT NULL REFERENCES cs2.skin_rarities(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(200) NOT NULL, -- e.g., "Redline", "Asiimov", "Dragon Lore"
    paint_id INTEGER NOT NULL, -- CS2 internal paint ID
    has_pattern BOOLEAN DEFAULT false NOT NULL, -- Whether this skin uses paint seeds
    pattern_template INTEGER NULL, -- Template ID for pattern-based skins
    min_float numeric(15,14) DEFAULT 0.00000000000000 NOT NULL,
    max_float numeric(15,14) DEFAULT 1.00000000000000 NOT NULL,
    can_be_stattrak BOOLEAN DEFAULT true NOT NULL,
    can_be_souvenir BOOLEAN DEFAULT false NOT NULL,
    description TEXT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id),
    UNIQUE (weapon_id, name, paint_id),
    CONSTRAINT check_template_float_range CHECK (min_float < max_float)
);

-- ================================================================
-- 8. SKIN INSTANCES (Individual skin items)
-- ================================================================
CREATE TABLE cs2.skins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL REFERENCES cs2.skin_templates(id) ON DELETE CASCADE ON UPDATE CASCADE,
    skin_type_id uuid NOT NULL REFERENCES cs2.skin_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    condition_id uuid NOT NULL REFERENCES cs2.skin_conditions(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Core skin attributes
    float_value numeric(15,14) NOT NULL CHECK (float_value >= 0 AND float_value <= 1),
    paint_seed INTEGER NULL, -- Pattern seed (0-1000 for most skins)
    paint_index INTEGER NULL, -- Paint index for some special skins
    
    -- StatTrak counter
    stattrak_kills INTEGER NULL CHECK (stattrak_kills >= 0),
    
    -- Souvenir attributes
    souvenir_event VARCHAR(100) NULL,
    souvenir_team1 VARCHAR(50) NULL,
    souvenir_team2 VARCHAR(50) NULL,
    souvenir_map VARCHAR(50) NULL,
    
    -- Market data
    market_hash_name VARCHAR(300) NULL, -- Steam market hash name
    inspect_link TEXT NULL,
    
    -- Metadata
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    
    PRIMARY KEY (id),
    
    -- Unique constraint to prevent exact duplicates
    UNIQUE (template_id, skin_type_id, float_value, paint_seed, paint_index)
);

-- ================================================================
-- 9. STICKERS
-- ================================================================
CREATE TABLE cs2.stickers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name VARCHAR(200) NOT NULL,
    sticker_id INTEGER NOT NULL UNIQUE, -- CS2 internal sticker ID
    rarity_id uuid NULL REFERENCES cs2.skin_rarities(id) ON DELETE SET NULL,
    collection VARCHAR(100) NULL,
    description TEXT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id)
);

-- ================================================================
-- 10. SKIN STICKERS (Applied stickers on skins)
-- ================================================================
CREATE TABLE cs2.skin_stickers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    skin_id uuid NOT NULL REFERENCES cs2.skins(id) ON DELETE CASCADE ON UPDATE CASCADE,
    sticker_id uuid NOT NULL REFERENCES cs2.stickers(id) ON DELETE CASCADE ON UPDATE CASCADE,
    slot INTEGER NOT NULL CHECK (slot >= 0 AND slot <= 4), -- Sticker position (0-4)
    wear DECIMAL(4,3) DEFAULT 0.000 NOT NULL CHECK (wear >= 0 AND wear <= 1), -- Sticker wear
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id),
    UNIQUE (skin_id, slot) -- Only one sticker per slot
);

-- ================================================================
-- 11. NAMETAGS
-- ================================================================
CREATE TABLE cs2.skin_nametags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    skin_id uuid NOT NULL REFERENCES cs2.skins(id) ON DELETE CASCADE ON UPDATE CASCADE,
    custom_name VARCHAR(20) NOT NULL, -- CS2 limit is 20 characters
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz,
    PRIMARY KEY (id),
    UNIQUE (skin_id) -- One nametag per skin
);

-- ================================================================
-- 12. PERFORMANCE INDEXES
-- ================================================================

-- Core relationship indexes
CREATE INDEX idx_weapons_category ON cs2.weapons(category_id);
CREATE INDEX idx_skin_templates_weapon ON cs2.skin_templates(weapon_id);
CREATE INDEX idx_skin_templates_collection ON cs2.skin_templates(collection_id);
CREATE INDEX idx_skin_templates_rarity ON cs2.skin_templates(rarity_id);
CREATE INDEX idx_skins_template ON cs2.skins(template_id);
CREATE INDEX idx_skins_skin_type ON cs2.skins(skin_type_id);
CREATE INDEX idx_skins_condition ON cs2.skins(condition_id);

-- Query optimization indexes
CREATE INDEX idx_skins_float_value ON cs2.skins(float_value);
CREATE INDEX idx_skins_paint_seed ON cs2.skins(paint_seed) WHERE paint_seed IS NOT NULL;
CREATE INDEX idx_skins_stattrak_kills ON cs2.skins(stattrak_kills) WHERE stattrak_kills IS NOT NULL;
CREATE INDEX idx_skin_templates_paint_id ON cs2.skin_templates(paint_id);
CREATE INDEX idx_skin_templates_has_pattern ON cs2.skin_templates(has_pattern) WHERE has_pattern = true;

-- Search indexes
CREATE INDEX idx_skin_conditions_name ON cs2.skin_conditions(name);
CREATE INDEX idx_skin_rarities_name ON cs2.skin_rarities(name);
CREATE INDEX idx_weapons_code ON cs2.weapons(code);
CREATE INDEX idx_weapons_display_name ON cs2.weapons(display_name);
CREATE INDEX idx_skin_templates_name ON cs2.skin_templates(name);
CREATE INDEX idx_skins_market_hash ON cs2.skins(market_hash_name) WHERE market_hash_name IS NOT NULL;

-- Composite indexes for complex queries
CREATE INDEX idx_skins_template_float ON cs2.skins(template_id, float_value);
CREATE INDEX idx_skins_template_seed ON cs2.skins(template_id, paint_seed) WHERE paint_seed IS NOT NULL;
CREATE INDEX idx_skin_stickers_skin_slot ON cs2.skin_stickers(skin_id, slot);

-- ================================================================
-- 13. INITIAL DATA - SKIN CONDITIONS
-- ================================================================
INSERT INTO cs2.skin_conditions (name, short_name, min_float, max_float) VALUES
('Factory New', 'FN', 0.00000000000000, 0.07000000000000),
('Minimal Wear', 'MW', 0.07000000000001, 0.15000000000000),
('Field-Tested', 'FT', 0.15000000000001, 0.38000000000000),
('Well-Worn', 'WW', 0.38000000000001, 0.45000000000000),
('Battle-Scarred', 'BS', 0.45000000000001, 1.00000000000000)
ON CONFLICT (name) DO NOTHING;

-- ================================================================
-- 14. INITIAL DATA - SKIN RARITIES
-- ================================================================
INSERT INTO cs2.skin_rarities (name, color_hex, tier) VALUES
('Consumer Grade', '#B0C3D9', 1),
('Industrial Grade', '#5E98D9', 2),
('Mil-Spec', '#4B69FF', 3),
('Restricted', '#8847FF', 4),
('Classified', '#D32CE6', 5),
('Covert', '#EB4B4B', 6),
('Contraband', '#FFD700', 7)
ON CONFLICT (name) DO NOTHING;

-- ================================================================
-- 15. INITIAL DATA - SKIN TYPES
-- ================================================================
INSERT INTO cs2.skin_types (name, prefix) VALUES
('Normal', NULL),
('StatTrak', 'StatTrak™'),
('Souvenir', 'Souvenir')
ON CONFLICT (name) DO NOTHING;

-- ================================================================
-- 16. INITIAL DATA - WEAPON CATEGORIES
-- ================================================================
INSERT INTO cs2.weapon_categories (name, description) VALUES
('Rifle', 'Assault rifles and automatic weapons'),
('Pistol', 'Sidearm weapons'),
('SMG', 'Submachine guns'),
('Sniper Rifle', 'Long-range precision weapons'),
('Shotgun', 'Close-range scatter weapons'),
('Machine Gun', 'Heavy automatic weapons'),
('Knife', 'Melee weapons'),
('Gloves', 'Hand equipment')
ON CONFLICT (name) DO NOTHING;

-- ================================================================
-- 17. COMMENTS AND DOCUMENTATION
-- ================================================================

COMMENT ON SCHEMA cs2 IS 'Counter-Strike 2 skin and weapon database schema';
COMMENT ON TABLE cs2.weapon_categories IS 'Categories of weapons (Rifle, Pistol, etc.)';
COMMENT ON TABLE cs2.weapons IS 'Individual weapon definitions';
COMMENT ON TABLE cs2.skin_conditions IS 'Wear conditions based on float ranges';
COMMENT ON TABLE cs2.skin_rarities IS 'Rarity tiers with colors';
COMMENT ON TABLE cs2.skin_collections IS 'Skin collections and cases';
COMMENT ON TABLE cs2.skin_types IS 'Skin variants (Normal, StatTrak, Souvenir)';
COMMENT ON TABLE cs2.skin_templates IS 'Skin designs and paint definitions';
COMMENT ON TABLE cs2.skins IS 'Individual skin instances with specific attributes';
COMMENT ON TABLE cs2.stickers IS 'Available stickers';
COMMENT ON TABLE cs2.skin_stickers IS 'Applied stickers on skin instances';
COMMENT ON TABLE cs2.skin_nametags IS 'Custom names applied to skins';

COMMENT ON COLUMN cs2.skin_templates.paint_id IS 'CS2 internal paint ID';
COMMENT ON COLUMN cs2.skin_templates.pattern_template IS 'Template ID for pattern generation';
COMMENT ON COLUMN cs2.skins.paint_seed IS 'Pattern seed (0-1000) for pattern-based skins';
COMMENT ON COLUMN cs2.skins.paint_index IS 'Paint index for special skin variations';
COMMENT ON COLUMN cs2.skins.float_value IS 'Wear float value (0.0 = perfect, 1.0 = maximum wear)';
COMMENT ON COLUMN cs2.skins.stattrak_kills IS 'Kill counter for StatTrak weapons';

-- ================================================================
-- END OF SCHEMA
-- ================================================================

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

-- ================================================================
-- Counter-Strike 2 Database Schema Rollback
-- Drop all tables, indexes, and schema in reverse dependency order
-- ================================================================

-- Drop dependent tables first (tables with foreign keys)
DROP TABLE IF EXISTS cs2.skin_nametags CASCADE;
DROP TABLE IF EXISTS cs2.skin_stickers CASCADE;
DROP TABLE IF EXISTS cs2.stickers CASCADE;
DROP TABLE IF EXISTS cs2.skins CASCADE;
DROP TABLE IF EXISTS cs2.skin_templates CASCADE;
DROP TABLE IF EXISTS cs2.skin_types CASCADE;
DROP TABLE IF EXISTS cs2.skin_collections CASCADE;
DROP TABLE IF EXISTS cs2.skin_rarities CASCADE;
DROP TABLE IF EXISTS cs2.skin_conditions CASCADE;
DROP TABLE IF EXISTS cs2.weapons CASCADE;
DROP TABLE IF EXISTS cs2.weapon_categories CASCADE;

-- Drop the schema
DROP SCHEMA IF EXISTS cs2 CASCADE;

-- +goose StatementEnd