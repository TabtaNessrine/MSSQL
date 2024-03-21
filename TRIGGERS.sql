--1
CREATE TRIGGER prevent_department_name_update
BEFORE UPDATE ON departement
FOR EACH ROW
BEGIN
    IF NEW.nom <> OLD.nom THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La mise à jour du nom de département est interdite.';
    END IF;
END;

--2
CREATE TRIGGER prevent_department_update
BEFORE UPDATE ON Departement
FOR EACH ROW
BEGIN
    IF NEW.nom <> OLD.nom OR NEW.ville <> OLD.ville THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La mise à jour du nom ou de la ville du département est interdite.';
    END IF;
END;

--3
ALTER TABLE Employe
ADD COLUMN prime FLOAT,
ADD COLUMN total_salaire FLOAT;

CREATE TRIGGER update_employee_bonus_and_total_salary
BEFORE INSERT ON participation
FOR EACH ROW
BEGIN
    SET NEW.prime = NEW.prime + 200;
    SET NEW.total_salaire = NEW.salaire + NEW.prime;
END;

--4
DELIMITER $$
CREATE TRIGGER capitalize_department_city
BEFORE INSERT ON Departement
FOR EACH ROW
BEGIN
    SET NEW.ville = UPPER(NEW.ville);
END;
$$
DELIMITER ;

--5
ALTER TABLE Employe
ADD COLUMN Mois_embauche VARCHAR(7);

CREATE TRIGGER insert_hire_month
BEFORE INSERT ON Employe
FOR EACH ROW
BEGIN
    SET NEW.Mois_embauche = DATE_FORMAT(NEW.date_embauche, '%Y-%m');
END;


--6
CREATE TRIGGER prevent_deletion_of_montreal_employees
BEFORE DELETE ON Employe
FOR EACH ROW
BEGIN
    IF OLD.ville = 'Montreal' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Impossible de supprimer un employé de Montréal.';
    END IF;
END;

--7
DELIMITER $$
CREATE TRIGGER salaryChangeMonitoring
BEFORE UPDATE ON Employe
FOR EACH ROW
BEGIN
    IF NEW.poste = 'Vendeur' AND ((NEW.salaire / OLD.salaire) > 1.20 OR (NEW.salaire / OLD.salaire) < 0.80) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La modification du salaire du vendeur ne peut pas dépasser 20% du salaire d\'origine.';
    END IF;
END;
$$
DELIMITER ;

