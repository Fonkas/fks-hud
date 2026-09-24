-- fks-hud: /hudsettings settings of each player (per account / license)
-- The script creates this table automatically on start; only import this
-- if your database user is not allowed to create tables.
CREATE TABLE IF NOT EXISTS `fks_hud_settings` (
    `license`    VARCHAR(64) NOT NULL,
    `layout`     LONGTEXT    NOT NULL,
    `updated_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`license`)
);
