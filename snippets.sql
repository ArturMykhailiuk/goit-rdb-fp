-- 1.Створення схема та призначення її як дефолтної
CREATE SCHEMA pandemic;
USE pandemic;

-- 2.Нормалізація даних
-- Створення таблиці для зберігання унікальних значень Entity та Code
CREATE TABLE entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL,
    UNIQUE(entity, code)
);

-- Створення нормалізованої таблиці для зберігання даних про захворювання
CREATE TABLE infectious_cases_normalized (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT,
    year INT,
    number_yaws DOUBLE, 
    polio_cases DOUBLE, 
    cases_guinea_worm DOUBLE, 
    number_rabies DOUBLE, 
    number_malaria DOUBLE, 
    number_hiv DOUBLE, 
    number_tuberculosis DOUBLE, 
    number_smallpox DOUBLE, 
    number_cholera_cases DOUBLE,
    FOREIGN KEY (entity_id) REFERENCES entities(id)
);

-- Заповнення таблиці entities унікальними значеннями Entity та Code
INSERT INTO entities (entity, code)
SELECT DISTINCT entity, code FROM infectious_cases;

-- Заповнення нормалізованої таблиці infectious_cases_normalized
INSERT INTO infectious_cases_normalized (entity_id, year, number_yaws, polio_cases, cases_guinea_worm, number_rabies, 
                                         number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases)
SELECT 	e.id, 
		ic.year,
        CASE WHEN ic.number_yaws = '' THEN NULL ELSE CAST(ic.number_yaws AS DOUBLE) END, 
		CASE WHEN ic.polio_cases = '' THEN NULL ELSE CAST(ic.polio_cases AS DOUBLE) END, 
		CASE WHEN ic.cases_guinea_worm = '' THEN NULL ELSE CAST(ic.cases_guinea_worm AS DOUBLE) END, 
   		CASE WHEN ic.number_rabies = '' THEN NULL ELSE CAST(ic.number_rabies AS DOUBLE) END,
		CASE WHEN ic.number_malaria = '' THEN NULL ELSE CAST(ic.number_malaria AS DOUBLE) END, 
		CASE WHEN ic.number_hiv = '' THEN NULL ELSE CAST(ic.number_hiv AS DOUBLE) END, 
		CASE WHEN ic.number_tuberculosis = '' THEN NULL ELSE CAST(ic.number_tuberculosis AS DOUBLE) END, 
		CASE WHEN ic.number_smallpox = '' THEN NULL ELSE CAST(ic.number_smallpox AS DOUBLE) END, 
		CASE WHEN ic.number_cholera_cases = '' THEN NULL ELSE CAST(ic.number_cholera_cases AS DOUBLE) END
FROM infectious_cases ic
JOIN entities e ON ic.entity = e.entity AND ic.code = e.code;

-- 3.Підрахунок середнього, мінімального, максимального значення та суми для атрибута number_rabies
SELECT 
    e.entity, 
    e.code, 
    AVG(ic.number_rabies) AS avg_rabies, 
    MIN(ic.number_rabies) AS min_rabies, 
    MAX(ic.number_rabies) AS max_rabies, 
    SUM(ic.number_rabies) AS sum_rabies
FROM 
    infectious_cases_normalized ic
JOIN 
    entities e ON ic.entity_id = e.id
WHERE 
    ic.number_rabies IS NOT NULL
GROUP BY 
    e.entity, e.code
ORDER BY 
    avg_rabies DESC
LIMIT 10;

-- 4.Побудова колонки різниці в роках
SELECT 
    year,
    CONCAT(year, '-01-01') AS first_january,
    CURDATE() AS 'current_date',
    TIMESTAMPDIFF(YEAR, CONCAT(year, '-01-01'), CURDATE()) AS year_difference
FROM 
    infectious_cases_normalized;
    
-- 5. Побудова власної функції
-- Створення функції для обчислення різниці в роках
DELIMITER //

CREATE FUNCTION year_difference(year INT) RETURNS INT
NO SQL
BEGIN
    DECLARE first_january DATE;
    DECLARE cur_date DATE;
    DECLARE difference INT;
    
    SET first_january = CONCAT(year, '-01-01');
    SET cur_date = CURDATE();
    SET difference = TIMESTAMPDIFF(YEAR, first_january, cur_date);
    
    RETURN difference;
END //

DELIMITER ;

-- Використання функції
SELECT 
    year,
	CONCAT(year, '-01-01') AS first_january,
    CURDATE() AS 'current_date',
    year_difference(year) AS year_difference
FROM 
    infectious_cases_normalized;
    
-- 6.Альтернативна функція для підрахунку кількості захворювань за певний період
-- Створення функції для підрахунку кількості захворювань за певний період
DELIMITER //

CREATE FUNCTION calculate_cases_per_period(cases_per_year DOUBLE, period INT) RETURNS DECIMAL(10, 2)
NO SQL
BEGIN
    DECLARE cases_per_period DECIMAL(10, 2);
    
    IF cases_per_year IS NULL OR period <= 0 THEN
        RETURN NULL;
    ELSE
        SET cases_per_period = cases_per_year / period;
    END IF;
    
    RETURN cases_per_period;
END //

DELIMITER ;

-- Використання функції
SELECT 
	e.entity AS entity,
    year,
    number_rabies,
    calculate_cases_per_period(number_rabies, 12) AS cases_per_month,
    calculate_cases_per_period(number_rabies, 4) AS cases_per_quarter,
    calculate_cases_per_period(number_rabies, 2) AS cases_per_semester
FROM 
    infectious_cases_normalized ic
INNER JOIN entities e ON e.id = ic.entity_id
WHERE 
    number_rabies IS NOT NULL;
    
