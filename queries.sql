-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

--Inserting data into the database examples


INSERT INTO "cattle"("eartag", "breed", "dob", "sex", "status", "dam_id", "sire_id", "current_holding")
VALUES ('UK101603501123', '1', '2018-01-01', 'male', 'dead', '3', '2', '1'),
('UK101603501124', '1', '2018-01-01', 'male', 'alive', '3', '4', '1'),
('UK101603501125', '1', '2018-01-01', 'female','alive', '4', '6', '1'),
('UK101603501126', '1', '2018-01-01', 'female','alive', '7', '8', '1'),
('UK101603501127', '1', '2018-01-01', 'male','alive', '9', '10', '1'),
('UK101603501128', '1', '2018-01-01', 'female','alive', '11', '12', '1'),
('UK101603501129', '1', '2018-01-01', 'female','alive', '11', '14', '1'),
('UK101603501130', '1', '2018-01-01', 'female','alive', '15', '16', '1'),
('UK101603501131', '1', '2018-01-01', 'female','alive', '17', '18', '1'),
('UK101603501132', '1', '2018-01-01', 'female','alive', '19', '20', '1'),
('UK101603501133', '1', '2018-01-01', 'female','alive', '21', '22', '1'),
('UK101603501134', '1', '2018-01-01', 'female','alive', '23', '24', '1'),
('UK101603501135', '1', '2024-01-01', 'male','alive', '25', '26', '1');

-- As cattle are born then new rows can be created with an INSERT statement
-- Otherwise, the status of the cattle can be updated with an UPDATE statement, but current holding and withdrawal
-- dates will be updated by the triggers below

INSERT INTO "breeds"("breed_name")
VALUES ('Angus'),
('Hereford'),
('Simmental'),
('Charolais'),
('Limousin'),
('Shorthorn'),
('Angus Cross');

-- Only the name of the breed is needed to be added the primary key is autoincremented

INSERT INTO "holdings"("CPH", "owner")
VALUES ('123456789', 'John Smith'),
('987654321', 'Jane Doe');

-- Only the CPH and owner is needed to be added the primary key is autoincremented

INSERT INTO "movements"("cattle_id", "from_holding", "to_holding", "date")
VALUES ('1', '1', '2', '2018-01-01'),
('2', '1', '2', '2024-01-01'),
('3', '1', '2', '2024-01-01'),
('4', '1', '2', '2024-01-01');

-- Only the cattle_id, from_holding, to_holding and date is needed to be added the primary key is autoincremented

INSERT INTO "treatment_types"("treatment_name", "meat_withdrawal_period")
VALUES ('antibiotic A', '14'),
('antibiotic B', '21'),
('antibiotic C', '28'),
('vaccine A', '0'),
('wormer A', '21');

-- Only the name of the treatment and the withdrawal period is needed to be added the primary key is autoincremented
-- The withdrawal period is the number of days after the treatment that the animal must not be slaughtered for human consumption

INSERT INTO "treatments"("cattle_id", "treatment_type", "date")
VALUES ('1', '1', '2018-01-01'),
('2', '2', '2018-01-01'),
('3', '3', '2018-01-01'),
('4', '4', '2018-01-01');

-- Only the cattle_id, treatment_type and date is needed to be added the primary key is autoincremented

-- Query to trace all movements from a holding in the event of a disease outbreak


SELECT "holdings"."CPH" AS 'CPH Moved to', "movements"."date" AS 'Date of Movement',
 "cattle"."eartag" AS 'Eartag'
FROM "movements"
JOIN "cattle" ON "cattle"."id" = "movements"."cattle_id",
"holdings" ON "holdings"."id" = "movements"."to_holding"
WHERE "from_holding" = 1;

-- Query to trace all treatments given to a specific animal

SELECT "cattle"."eartag" AS 'Eartag', "treatment_types"."treatment_name" AS 'Treatment',
"treatments"."date" AS 'Date Given'
FROM "treatments"
JOIN "cattle" ON "cattle"."id" = "treatments"."cattle_id",
"treatment_types" ON "treatment_types"."id" = "treatments"."treatment_type"
WHERE "cattle"."eartag" = 'UK101603501123';

-- Query to trace all movements of a specific animal

SELECT "cattle"."eartag" AS 'Eartag', "movements"."date" AS 'Date of Movement',
"holdings"."CPH" AS 'CPH Moved to'
FROM "movements"
JOIN "cattle" ON "cattle"."id" = "movements"."cattle_id",
"holdings" ON "holdings"."id" = "movements"."to_holding"
WHERE "cattle"."eartag" = 'UK101603501123';


-- Query to view all live aniamls on a holding
-- Uses View created in the schema file

SELECT  * from current_animals
WHERE "Holding" = 123456789;

-- Above query not using view

SELECT "cattle".eartag AS 'Eartag', "cattle".dob as 'Date of Birth', 
"cattle".sex AS 'Sex', "breeds".breed_name AS 'Breed', 
"holdings".CPH AS 'CPH'
FROM "cattle"
JOIN "breeds" ON "cattle".breed = "breeds".id,
"holdings" ON "cattle".current_holding = "holdings".id
WHERE  "cattle".status = 'alive'
AND "holdings"."CPH" = 123456789
ORDER BY "cattle".dob DESC, "cattle".eartag ASC;