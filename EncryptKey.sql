--Redirection vers la base de donnée
use SocieteZ;


-- 1. Ajouter un champ "password" à la table Sales.Customers
ALTER TABLE Sales.Customers ADD password VARBINARY(MAX);
SELECT * FROM Sales.Customers;



--Je met le numero 3 avant le numero 2 car la clé doit d'abord exister avant detre utiliser.
-- 3.  Créer une clé symétrique encryptée par mot de passe pour le premier client (custid=1)
CREATE SYMMETRIC KEY SymmetricKey
WITH ALGORITHM = AES_128
ENCRYPTION BY PASSWORD ='MOTDEPASSECRYPTÉ';
GO
-- Ouvrir la clé sémétrique
OPEN SYMMETRIC KEY SymmetricKey
DECRYPTION BY PASSWORD ='MOTDEPASSECRYPTÉ';


--2.	Ajouter un mot de passe pour le premier client (5 POINTS) 
UPDATE Sales.Customers
SET password = ENCRYPTBYKEY(KEY_GUID('SymmetricKey'), 'Pa$$w0rd')
WHERE custid = 1;
-- Fermer la clé symétrique
CLOSE SYMMETRIC KEY SymmetricKey;
-- Sélectionner les données pour vérification
SELECT * FROM Sales.Customers;




-- 4. Ajouter deux champs "phone_encrypted" et "fax_encrypted"
ALTER TABLE Sales.Customers
ADD phone_encrypted VARBINARY(MAX),
    fax_encrypted VARBINARY(MAX);




-- 5. Chiffrer le numéro de téléphone et le numéro de fax en utilisant la clé symétrique
-- Créer la clé symétrique
CREATE SYMMETRIC KEY SymmetricKey2
WITH ALGORITHM = AES_128
ENCRYPTION BY PASSWORD ='CRYPTÉPOURNUMEROETFAX';
-- Ouvrir la clé sémétrique
OPEN SYMMETRIC KEY SymmetricKey2
DECRYPTION BY PASSWORD = 'CRYPTÉPOURNUMEROETFAX';
-- Chiffrer les numéros de téléphone et de fax
UPDATE Sales.Customers
SET phone_encrypted = EncryptByKey(Key_GUID('SymmetricKey2'), CONVERT(VARBINARY(MAX), phone)),
    fax_encrypted = EncryptByKey(Key_GUID('SymmetricKey2'), CONVERT(VARBINARY(MAX), fax));
--fermer la clé sémétrique
CLOSE SYMMETRIC KEY SymmetricKey2;
--affichage des résultats
select * from Sales.Customers




-- 6. Ajouter deux champs "phone_decrypted" et "fax_decrypted"
ALTER TABLE Sales.Customers
ADD phone_decrypted NVARCHAR(24),
    fax_decrypted NVARCHAR(24);



-- 7. Déchiffrer les numéros de téléphone et le numéro de fax
--ouvrir clé sémétrique (la clé a deja été créer a l'exercice 5)
OPEN SYMMETRIC KEY SymmetricKey2
DECRYPTION BY PASSWORD ='CRYPTÉPOURNUMEROETFAX';
--déchiffrer les numeros tell et fax
UPDATE Sales.Customers
SET phone_decrypted = CONVERT(NVARCHAR(24), DecryptByKey(phone_encrypted)),
    fax_decrypted = CONVERT(NVARCHAR(24), DecryptByKey(fax_encrypted));
--fermer la clé smétrique
CLOSE SYMMETRIC KEY SymmetricKey2;
--affichage des résultats
select * from Sales.Customers



--8.	Refaire les mêmes étapes en utilisant ENCRYPTBYPASSPHRASE (20 POINTS) 
--Ajouter un mot de passe pour le premier client
UPDATE Sales.Customers
SET password = ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', 'Pa$$w0rd')
WHERE custid = 1;
-- Créer une clé symétrique encryptée par mot de passe pour le premier client (custid=1)
CREATE SYMMETRIC KEY SymmetricKey3
WITH ALGORITHM = AES_128
ENCRYPTION BY PASSWORD ='MOTDEPASSECRYPTÉ';
GO
--  Ajouter deux champs "phone_encrypted" et "fax_encrypted"
ALTER TABLE Sales.Customers
ADD phone_encrypted VARBINARY(MAX),
    fax_encrypted VARBINARY(MAX);
-- Chiffrer le numéro de téléphone et le numéro de fax en utilisant la clé symétrique
UPDATE Sales.Customers
SET phone_encrypted = ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', phone),
    fax_encrypted = ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', fax);
-- Ajouter deux champs "phone_decrypted" et "fax_decrypted"
ALTER TABLE Sales.Customers
ADD phone_decrypted NVARCHAR(24),
    fax_decrypted NVARCHAR(24);
-- Déchiffrer les numéros de téléphone et le numéro de fax
UPDATE Sales.Customers
SET phone_decrypted = CONVERT(NVARCHAR(24), DECRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', phone_encrypted)),
    fax_decrypted = CONVERT(NVARCHAR(24), DECRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', fax_encrypted));

--Afficher les modifications
select * from Sales.Customers



--9.	Créer une procédure nommée chiffrer qui: o	 Prend comme INPUT: la méthode de chiffrement (Par clé symétrique ou par  ENCRYPTBYPASSPHRASE), un mot de passe et une chaine de caractères non chiffrée   
--o	Donne comme OUTPUT: une chaine de caractères chiffrée   (15 POINTS) 
CREATE OR ALTER PROCEDURE chiffrer
    @methodeChiffrement NVARCHAR(50),  -- "CléSymetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteNonChiffre NVARCHAR(MAX),
    @resultatChiffre NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @methodeChiffrement = 'CléSymetrique'
    BEGIN
        -- Chiffrement par clé symétrique
        DECLARE @cleSymetrique VARBINARY(8000);
        OPEN SYMMETRIC KEY SymmetricKey3
        DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPTÉ';
        SET @cleSymetrique = EncryptByKey(KEY_GUID('SymmetricKey3'), @texteNonChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeChiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- Chiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', @texteNonChiffre));
    END
    ELSE
    BEGIN
        -- Méthode de chiffrement non supportée
        SET @resultatChiffre = NULL;
        RETURN;
    END
END;

--TEST DE CHIFFREMENT 
DECLARE @resultat NVARCHAR(MAX);
EXEC chiffrer 'CléSymetrique', 'MOTDEPASSE', 'Chocolat au lait', @resultat OUTPUT;
-- Utilisez @resultat pour accéder à la chaîne chiffrée
PRINT @resultat;



--10.	Créer une procédure dechiffrer qui: 
--o	 Prend comme INPUT: la méthode de chiffrement (Par clé symétrique ou par  ENCRYPTBYPASSPHRASE), un mot de passe et une chaine de caractères  chiffrée   
--o	Donne comme output : une chaine de caractères non chiffrée (15 POINTS) 
CREATE OR ALTER PROCEDURE dechiffrer
    @methodeDechiffrement NVARCHAR(50),  -- "CléSymetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteChiffre NVARCHAR(MAX),
    @resultatDechiffre NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @methodeDechiffrement = 'CléSymetrique'
    BEGIN
        -- Déchiffrement par clé symétrique
        DECLARE @cleSymetrique VARBINARY(MAX);
        OPEN SYMMETRIC KEY SymmetricKey3 DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPTÉ';
        SET @cleSymetrique = DecryptByKey(@texteChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeDechiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- Déchiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@motDePasse, @texteChiffre));
    END
    ELSE
    BEGIN
        -- Méthode de déchiffrement non supportée
        SET @resultatDechiffre = NULL;
        RETURN;
    END
END;

--TEST DU DECHIFFREMENT
--je chiffre patate au four
DECLARE @motChiffre NVARCHAR(MAX);
EXEC chiffrer 'CléSymetrique', 'MOTDEPASSE', 'Patate au four', @motChiffre OUTPUT;
--je dechiffre patate au four
DECLARE @resultat2 NVARCHAR(MAX);
EXEC dechiffrer 'CléSymetrique', 'MOTDEPASSE', @motChiffre, @resultat2 OUTPUT;
-- j'affiche le mot déchiffré.
PRINT @resultat2;



--11.	Chiffrer ces deux procédures AVEC ENCRYPTION (15 POINTS) 
-- 1. Chiffrer la procédure chiffrer
CREATE OR ALTER PROCEDURE chiffrer
    @methodeChiffrement NVARCHAR(50),  -- "CléSymetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteNonChiffre NVARCHAR(MAX),
    @resultatChiffre NVARCHAR(MAX) OUTPUT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    IF @methodeChiffrement = 'CléSymetrique'
    BEGIN
        -- Chiffrement par clé symétrique
        DECLARE @cleSymetrique VARBINARY(8000);
        OPEN SYMMETRIC KEY SymmetricKey3
        DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPTÉ';
        SET @cleSymetrique = EncryptByKey(KEY_GUID('SymmetricKey3'), @texteNonChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeChiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- Chiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPTÉ', @texteNonChiffre));
    END
    ELSE
    BEGIN
        -- Méthode de chiffrement non supportée
        SET @resultatChiffre = NULL;
        RETURN;
    END
END;

--TEST DE CHIFFREMENT DE Mousse blanche
DECLARE @resultat NVARCHAR(MAX);
EXEC chiffrer 'CléSymetrique', 'MOTDEPASSE', 'Mousse blanche', @resultat OUTPUT;
-- Utilisez @resultat pour accéder à la chaîne chiffrée
PRINT @resultat;


-- 2. Chiffrer la procédure dechiffrer
CREATE OR ALTER PROCEDURE dechiffrer
    @methodeDechiffrement NVARCHAR(50),  -- "CléSymetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteChiffre NVARCHAR(MAX),
    @resultatDechiffre NVARCHAR(MAX) OUTPUT
WITH ENCRYPTION --on chiffre la procédure avec WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    IF @methodeDechiffrement = 'CléSymetrique'
    BEGIN
        -- Déchiffrement par clé symétrique
        DECLARE @cleSymetrique VARBINARY(MAX);
        OPEN SYMMETRIC KEY SymmetricKey3 DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPTÉ';
        SET @cleSymetrique = DecryptByKey(@texteChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeDechiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- Déchiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@motDePasse, @texteChiffre));
    END
    ELSE
    BEGIN
        -- Méthode de déchiffrement non supportée
        SET @resultatDechiffre = NULL;
        RETURN;
    END
END;

--TEST DU DECHIFFREMENT
--je chiffre Tomates et oignons
DECLARE @motChiffre NVARCHAR(MAX);
EXEC chiffrer 'CléSymetrique', 'MOTDEPASSE', 'Tomates et oignons', @motChiffre OUTPUT;
--je dechiffre patate au four
DECLARE @resultat2 NVARCHAR(MAX);
EXEC dechiffrer 'CléSymetrique', 'MOTDEPASSE', @motChiffre, @resultat2 OUTPUT;
-- j'affiche le mot déchiffré.
PRINT @resultat2;