-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it
-- uncomment the following lines to reset the database
DROP TABLE IF EXISTS "cattle";
DROP TABLE IF EXISTS "breeds";
DROP TABLE IF EXISTS "holdings";
DROP TABLE IF EXISTS "movements";
DROP TABLE IF EXISTS "treatments";
DROP TABLE IF EXISTS "treatment_types";
DROP VIEW IF EXISTS "current_animals";
DROP VIEW IF EXISTS "breed_count";
DROP INDEX IF EXISTS "movement_index";

-- Table of cattle in the database

CREATE TABLE "cattle" (
    "id"	INTEGER,
    "eartag"	TEXT NOT NULL UNIQUE CHECK (length(eartag) = 14),
    "breed" INTEGER,
    "dob" TEXT NOT NULL,
    "sex" TEXT NOT NULL CHECK (sex in ('male', 'female')),
    "status" TEXT NOT NULL CHECK (status in ('alive', 'dead')),
    "dam_id" INTEGER,
    "sire_id" INTEGER,
    "current_holding" INTEGER NOT NULL,
    "under_withdrawal_until" TEXT DEFAULT '0000-00-00',
    PRIMARY KEY("id"),
    FOREIGN KEY("dam_id") REFERENCES "cattle"("id"),
    FOREIGN KEY("sire_id") REFERENCES "cattle"("id"),
    FOREIGN KEY("breed") REFERENCES "breeds"("id"),
    FOREIGN KEY("current_holding") REFERENCES "holdings"("id")
    );

-- Table of cattle breeds

CREATE TABLE "breeds" (
    "id"	INTEGER,
    "breed_name"	TEXT NOT NULL,
    PRIMARY KEY("id")
    );

-- Table of holdings that have cattle

CREATE TABLE "holdings" (
    "id"	INTEGER,
    "CPH"	TEXT NOT NULL,
    "owner" TEXT NOT NULL,
    PRIMARY KEY("id")
);

-- Table of cattle movements, births and deaths
CREATE TABLE "movements" (
    "id"	INTEGER,
    "cattle_id" INTEGER NOT NULL,
    "from_holding" INTEGER NOT NULL,
    "to_holding" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    PRIMARY KEY("id"),
    FOREIGN KEY("cattle_id") REFERENCES "cattle"("id"),
    FOREIGN KEY("from_holding") REFERENCES "holdings"("id"),
    FOREIGN KEY("to_holding") REFERENCES "holdings"("id")
    );


-- Table of cattle treatments
CREATE TABLE "treatments" (
    "id"	INTEGER,
    "cattle_id" INTEGER NOT NULL,
    "date" TEXT NOT NULL,
    "treatment_type" INTEGER NOT NULL,
    PRIMARY KEY("id"),
    FOREIGN KEY("cattle_id") REFERENCES "cattle"("id"),
    FOREIGN KEY("treatment_type") REFERENCES "treatment_types"("id")
    );


-- Table of possible cattle treatments
CREATE TABLE "treatment_types" (
    "id"	INTEGER,
    "treatment_name" TEXT NOT NULL,
    "meat_withdrawal_period" INTEGER NOT NULL CHECK (meat_withdrawal_period >= 0),
    PRIMARY KEY("id")
    );


--Views

-- Create a view to show the current alive animals at a holding
CREATE VIEW "current_animals" AS
SELECT "cattle".eartag AS 'Eartag', "cattle".dob as 'Date of Birth', 
"cattle".sex AS 'Sex', "breeds".breed_name AS 'Breed',
"holdings".CPH AS 'Holding'
FROM "cattle"
JOIN "breeds" ON "cattle".breed = "breeds".id,
"holdings" ON "cattle".current_holding = "holdings".id
WHERE  "cattle".status = 'alive'
ORDER BY "cattle".dob DESC, "cattle".eartag ASC;

-- Create view to show the total count of each breed born this year

CREATE VIEW "breed_count" AS
SELECT "breeds".breed_name AS 'Breed', COUNT("cattle".id) AS 'Count'
FROM "cattle"
JOIN "breeds" ON "cattle".breed = "breeds".id
WHERE "cattle".dob >= datetime('now', '-1 year')
GROUP BY "breeds".breed_name
ORDER BY "breeds".breed_name ASC;

-- Triggers

-- Create to update withdrawal date when a treatment is added
-- CHECKED
CREATE TRIGGER "treatment"
AFTER INSERT ON "treatments"
BEGIN
    UPDATE "cattle"
    SET "under_withdrawal_until" = datetime(new.date, '+' || (SELECT "meat_withdrawal_period" FROM "treatment_types" WHERE "id" = new.treatment_type) || ' days')
    WHERE "id" = new.cattle_id AND "under_withdrawal_until" < datetime(new.date, '+' || (SELECT "meat_withdrawal_period" FROM "treatment_types" WHERE "id" = new.treatment_type) || ' days');
END;

-- Create a trigger to enforce the constraint on dam_id
-- CHECKED
    CREATE TRIGGER "check_dam_id"
    BEFORE INSERT ON "cattle"
    FOR EACH ROW
    WHEN (NEW.dam_id IS NOT NULL AND NEW.dam_id  IN (SELECT id FROM cattle WHERE sex = 'male'))
    BEGIN
        SELECT RAISE(ABORT, 'Invalid dam_id: The specified dam must be female.');
    END;

-- Create a trigger to enforce the constraint on sire_id
-- CHECKED
    CREATE TRIGGER "check_sire_id"
    BEFORE INSERT ON "cattle"
    FOR EACH ROW
    WHEN (NEW.sire_id IS NOT NULL AND NEW.sire_id  IN (SELECT id FROM cattle WHERE sex = 'female'))
    BEGIN
        SELECT RAISE(ABORT, 'Invalid sire_id: The specified sire must be male.');
    END;


-- Creates a trigger to change holding of cattle when a movement is added
--CHECKED

CREATE TRIGGER "movement_check" 
BEFORE INSERT ON "movements"
BEGIN

    -- Check if the animal is at the current holding
    SELECT RAISE(ABORT, 'Animal not at original holding')
    FROM "cattle"
    WHERE "id" = new.cattle_id
    AND "current_holding" != new.from_holding;
    
    -- Move animal 
    UPDATE "cattle"
    SET "current_holding" = new.to_holding
    WHERE "id" = new.cattle_id;

END;

-- Create Indexes

-- Index to speed up movement tracings in disease outbreaks

CREATE INDEX "movement_index" ON "movements" ("from_holding");

-- Create index to speed up searching for treatments by animal id

CREATE INDEX treatments_id_index ON treatments(cattle_id);

-- Index to speed up searching for animals previous movements

CREATE INDEX movements_cattle_id ON movements(cattle_id);

-- Index to speed up searching for animals on holding

CREATE INDEX cattle_on_holding ON cattle(status, current_holding, dob DESC, eartag);



