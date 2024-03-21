use PremiereProducts;
--1--
INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP, BALANCE, CREDIT_LIMIT, REP_NUM)
VALUES (999, 'Nessrine Tabta', '3800 Sherbrooke', 'Montreal', 'QC', 'H1X', 1000, 10000, 65);

select * from CUSTOMER;

--2--
create or alter procedure nomLimite 
	@I_CUSTOMER_NUM CHAR(3) 
as 
BEGIN 

declare @I_CUSTOMER_NAME CHAR(35); 
declare @I_CREDIT_LIMIT DECIMAL(8,2); 

select @I_CUSTOMER_NAME=CUSTOMER_NAME  ,@I_CREDIT_LIMIT=CREDIT_LIMIT  
from CUSTOMER where CUSTOMER_NUM=@I_CUSTOMER_NUM 
--attribution de valeur a @I_CUSTOMER_NAME et @I_CREDIT_LIMIT NE FAIT AUCUN AFFICHAGE IL INDIQUE JUSTE L'INTERIEUR D'UNE VARIABLE 
	if @@ROWCOUNT=0 
		print ('Erreur, projet non trouvé') 
	Else  
		Begin
		print('Nom du client : ' + @I_CUSTOMER_NAME + 'Limite de Crédit : ' + CAST(@I_CREDIT_LIMIT AS NVARCHAR(20)));
		--CELUI CI SERT D'AFFICHAGE PUISQU'IL S'AGIT D'UNE SELECTION ET NON D'ATTRIBUTION 
	end 
END 

DECLARE @CUSTOMER_NUM CHAR(3) = '408'; 
EXEC nomLimite @I_CUSTOMER_NUM = @CUSTOMER_NUM 

--3--
CREATE OR ALTER PROCEDURE AfficherCommande(@I_ORDER_NUM CHAR(5))
AS
BEGIN
    DECLARE @I_ORDER_DATE DATE;
    DECLARE @I_CUSTOMER_NUM CHAR(3);
    DECLARE @I_CUSTOMER_NAME CHAR(35);

    SELECT
        @I_ORDER_DATE = O.ORDER_DATE,
        @I_CUSTOMER_NUM = C.CUSTOMER_NUM,
        @I_CUSTOMER_NAME = C.CUSTOMER_NAME
    FROM ORDERS O
    INNER JOIN CUSTOMER C ON O.CUSTOMER_NUM = C.CUSTOMER_NUM
    WHERE O.ORDER_NUM = @I_ORDER_NUM;

    IF @@ROWCOUNT = 0
        PRINT('Erreur, commande non trouvée') 
    ELSE
        BEGIN
            PRINT('Numéro de commande : ' + @I_ORDER_NUM);
            PRINT('Date de commande : ' + CONVERT(NVARCHAR, @I_ORDER_DATE, 103)); -- Formatage de la date
            PRINT('Numéro de client : ' + @I_CUSTOMER_NUM);
            PRINT('Nom du client : ' + @I_CUSTOMER_NAME);
        END
END;

DECLARE @ORDER_NUM CHAR(5) = '21608';
EXEC AfficherCommande @I_ORDER_NUM = @ORDER_NUM

--4--
INSERT INTO ORDERS (ORDER_NUM, ORDER_DATE, CUSTOMER_NUM)
VALUES (21630, '2023-09-24', 999);

--5--
CREATE OR ALTER PROCEDURE modifierDate
    @I_ORDER_NUM CHAR(5),
    @I_NEW_ORDER_DATE DATE OUTPUT
AS
BEGIN
    DECLARE @I_ORDER_DATE DATE;
    -- Obtenir la date actuelle de la commande
    SELECT @I_ORDER_DATE = ORDER_DATE
    FROM ORDERS
    WHERE ORDER_NUM = @I_ORDER_NUM;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT('Erreur, commande non trouvée');
    END
    ELSE
    BEGIN
        -- Mettre à jour la date de la commande
        UPDATE ORDERS
        SET ORDER_DATE = @I_NEW_ORDER_DATE
        WHERE ORDER_NUM = @I_ORDER_NUM;

        PRINT('Date de commande mise à jour avec succès.');
		PRINT('Numéro de commande : ' + @I_ORDER_NUM);
        PRINT('Ancienne date de commande : ' + CONVERT(NVARCHAR, @I_ORDER_DATE, 103));
        PRINT('Nouvelle date de commande : ' + CONVERT(NVARCHAR, @I_NEW_ORDER_DATE, 103));
    END
END;

DECLARE @ORDER_NUM CHAR(5) = '21608';
DECLARE @ORDER_DATE date= '2023-09-25';
EXEC modifierDate @I_ORDER_NUM = @ORDER_NUM,@I_NEW_ORDER_DATE=@ORDER_DATE

--6--
CREATE OR ALTER PROCEDURE SupprimerCommande
    @I_ORDER_NUM CHAR(5)
AS
BEGIN
    DELETE FROM ORDER_LINE
    WHERE ORDER_NUM = @I_ORDER_NUM;
	DELETE FROM ORDERS
    WHERE ORDER_NUM = @I_ORDER_NUM;

    PRINT ('La commande ci-dessus a été supprimée : ' + @I_ORDER_NUM);
END;

declare @ORDER_NUM CHAR(5)='21617';
EXEC SupprimerCommande @I_ORDER_NUM=@ORDER_NUM;

--7--

CREATE OR ALTER PROCEDURE RecupererPiece
    @I_CLASS CHAR(2)
AS
BEGIN
    select PART_NUM,part.DESCRIPTION,WAREHOUSE,PRICE from PART
	where CLASS=@I_CLASS
END;

declare @CLASS CHAR(2)='HW';
EXEC RecupererPiece @I_CLASS=@CLASS

--8--
CREATE OR ALTER PROCEDURE modifierPrixPiece	
    @I_PART_NUM CHAR(4),
	@I_NEW_PRICE DECIMAL(6,2)
AS
BEGIN
	UPDATE PART
    SET PRICE = @I_NEW_PRICE
    WHERE PART_NUM = @I_PART_NUM;
	
	select * from PART where PART_NUM=@I_PART_NUM
END;

declare @PART_NUM CHAR(4)='AT94';
declare @New_Price DECIMAL(6,2)=(26.95);

EXEC modifierPrixPiece @I_PART_NUM=@PART_NUM, @I_NEW_PRICE=@New_Price;

--9 (fonction)--
CREATE OR ALTER FUNCTION AffichagePiece(@I_CLASS CHAR(2))

RETURNS TABLE
AS

RETURN
(SELECT PART_NUM,PART.DESCRIPTION,WAREHOUSE,PRICE FROM PART WHERE CLASS = @I_CLASS);

SELECT *
FROM dbo.AffichagePiece('SG');

--10 fonction b--
CREATE OR ALTER FUNCTION AffichageCommande(@I_COMMANDE CHAR(5))

RETURNS TABLE
AS

RETURN
(SELECT ORDER_NUM,ORDER_DATE,PRICE from ORDERS,PART WHERE ORDER_NUM = @I_COMMANDE);

select * FROM dbo.AffichageCommande('21619');
