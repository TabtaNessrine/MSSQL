--Redirection vers la base de donn�e
use SocieteZ;


-- 1. Ajouter un champ "password" � la table Sales.Customers
ALTER TABLE Sales.Customers ADD password VARBINARY(MAX);
SELECT * FROM Sales.Customers;



--Je met le numero 3 avant le numero 2 car la cl� doit d'abord exister avant detre utiliser.
-- 3.  Cr�er une cl� sym�trique encrypt�e par mot de passe pour le premier client (custid=1)
CREATE SYMMETRIC KEY SymmetricKey
WITH ALGORITHM = AES_128
ENCRYPTION BY PASSWORD ='MOTDEPASSECRYPT�';
GO
-- Ouvrir la cl� s�m�trique
OPEN SYMMETRIC KEY SymmetricKey
DECRYPTION BY PASSWORD ='MOTDEPASSECRYPT�';


--2.	Ajouter un mot de passe pour le premier client (5 POINTS) 
UPDATE Sales.Customers
SET password = ENCRYPTBYKEY(KEY_GUID('SymmetricKey'), 'Pa$$w0rd')
WHERE custid = 1;
-- Fermer la cl� sym�trique
CLOSE SYMMETRIC KEY SymmetricKey;
-- S�lectionner les donn�es pour v�rification
SELECT * FROM Sales.Customers;




-- 4. Ajouter deux champs "phone_encrypted" et "fax_encrypted"
ALTER TABLE Sales.Customers
ADD phone_encrypted VARBINARY(MAX),
    fax_encrypted VARBINARY(MAX);




-- 5. Chiffrer le num�ro de t�l�phone et le num�ro de fax en utilisant la cl� sym�trique
-- Cr�er la cl� sym�trique
CREATE SYMMETRIC KEY SymmetricKey2
WITH ALGORITHM = AES_128
ENCRYPTION BY PASSWORD ='CRYPT�POURNUMEROETFAX';
-- Ouvrir la cl� s�m�trique
OPEN SYMMETRIC KEY SymmetricKey2
DECRYPTION BY PASSWORD = 'CRYPT�POURNUMEROETFAX';
-- Chiffrer les num�ros de t�l�phone et de fax
UPDATE Sales.Customers
SET phone_encrypted = EncryptByKey(Key_GUID('SymmetricKey2'), CONVERT(VARBINARY(MAX), phone)),
    fax_encrypted = EncryptByKey(Key_GUID('SymmetricKey2'), CONVERT(VARBINARY(MAX), fax));
--fermer la cl� s�m�trique
CLOSE SYMMETRIC KEY SymmetricKey2;
--affichage des r�sultats
select * from Sales.Customers




-- 6. Ajouter deux champs "phone_decrypted" et "fax_decrypted"
ALTER TABLE Sales.Customers
ADD phone_decrypted NVARCHAR(24),
    fax_decrypted NVARCHAR(24);



-- 7. D�chiffrer les num�ros de t�l�phone et le num�ro de fax
--ouvrir cl� s�m�trique (la cl� a deja �t� cr�er a l'exercice 5)
OPEN SYMMETRIC KEY SymmetricKey2
DECRYPTION BY PASSWORD ='CRYPT�POURNUMEROETFAX';
--d�chiffrer les numeros tell et fax
UPDATE Sales.Customers
SET phone_decrypted = CONVERT(NVARCHAR(24), DecryptByKey(phone_encrypted)),
    fax_decrypted = CONVERT(NVARCHAR(24), DecryptByKey(fax_encrypted));
--fermer la cl� sm�trique
CLOSE SYMMETRIC KEY SymmetricKey2;
--affichage des r�sultats
select * from Sales.Customers



--8.	Refaire les m�mes �tapes en utilisant ENCRYPTBYPASSPHRASE (20 POINTS) 
--Ajouter un mot de passe pour le premier client
UPDATE Sales.Customers
SET password = ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', 'Pa$$w0rd')
WHERE custid = 1;
-- Cr�er une cl� sym�trique encrypt�e par mot de passe pour le premier client (custid=1)
CREATE SYMMETRIC KEY SymmetricKey3
WITH ALGORITHM = AES_128
ENCRYPTION BY PASSWORD ='MOTDEPASSECRYPT�';
GO
--  Ajouter deux champs "phone_encrypted" et "fax_encrypted"
ALTER TABLE Sales.Customers
ADD phone_encrypted VARBINARY(MAX),
    fax_encrypted VARBINARY(MAX);
-- Chiffrer le num�ro de t�l�phone et le num�ro de fax en utilisant la cl� sym�trique
UPDATE Sales.Customers
SET phone_encrypted = ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', phone),
    fax_encrypted = ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', fax);
-- Ajouter deux champs "phone_decrypted" et "fax_decrypted"
ALTER TABLE Sales.Customers
ADD phone_decrypted NVARCHAR(24),
    fax_decrypted NVARCHAR(24);
-- D�chiffrer les num�ros de t�l�phone et le num�ro de fax
UPDATE Sales.Customers
SET phone_decrypted = CONVERT(NVARCHAR(24), DECRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', phone_encrypted)),
    fax_decrypted = CONVERT(NVARCHAR(24), DECRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', fax_encrypted));

--Afficher les modifications
select * from Sales.Customers



--9.	Cr�er une proc�dure nomm�e chiffrer qui: o	 Prend comme INPUT: la m�thode de chiffrement (Par cl� sym�trique ou par  ENCRYPTBYPASSPHRASE), un mot de passe et une chaine de caract�res non chiffr�e   
--o	Donne comme OUTPUT: une chaine de caract�res chiffr�e   (15 POINTS) 
CREATE OR ALTER PROCEDURE chiffrer
    @methodeChiffrement NVARCHAR(50),  -- "Cl�Symetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteNonChiffre NVARCHAR(MAX),
    @resultatChiffre NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @methodeChiffrement = 'Cl�Symetrique'
    BEGIN
        -- Chiffrement par cl� sym�trique
        DECLARE @cleSymetrique VARBINARY(8000);
        OPEN SYMMETRIC KEY SymmetricKey3
        DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPT�';
        SET @cleSymetrique = EncryptByKey(KEY_GUID('SymmetricKey3'), @texteNonChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeChiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- Chiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', @texteNonChiffre));
    END
    ELSE
    BEGIN
        -- M�thode de chiffrement non support�e
        SET @resultatChiffre = NULL;
        RETURN;
    END
END;

--TEST DE CHIFFREMENT 
DECLARE @resultat NVARCHAR(MAX);
EXEC chiffrer 'Cl�Symetrique', 'MOTDEPASSE', 'Chocolat au lait', @resultat OUTPUT;
-- Utilisez @resultat pour acc�der � la cha�ne chiffr�e
PRINT @resultat;



--10.	Cr�er une proc�dure dechiffrer qui: 
--o	 Prend comme INPUT: la m�thode de chiffrement (Par cl� sym�trique ou par  ENCRYPTBYPASSPHRASE), un mot de passe et une chaine de caract�res  chiffr�e   
--o	Donne comme output : une chaine de caract�res non chiffr�e (15 POINTS) 
CREATE OR ALTER PROCEDURE dechiffrer
    @methodeDechiffrement NVARCHAR(50),  -- "Cl�Symetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteChiffre NVARCHAR(MAX),
    @resultatDechiffre NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @methodeDechiffrement = 'Cl�Symetrique'
    BEGIN
        -- D�chiffrement par cl� sym�trique
        DECLARE @cleSymetrique VARBINARY(MAX);
        OPEN SYMMETRIC KEY SymmetricKey3 DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPT�';
        SET @cleSymetrique = DecryptByKey(@texteChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeDechiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- D�chiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@motDePasse, @texteChiffre));
    END
    ELSE
    BEGIN
        -- M�thode de d�chiffrement non support�e
        SET @resultatDechiffre = NULL;
        RETURN;
    END
END;

--TEST DU DECHIFFREMENT
--je chiffre patate au four
DECLARE @motChiffre NVARCHAR(MAX);
EXEC chiffrer 'Cl�Symetrique', 'MOTDEPASSE', 'Patate au four', @motChiffre OUTPUT;
--je dechiffre patate au four
DECLARE @resultat2 NVARCHAR(MAX);
EXEC dechiffrer 'Cl�Symetrique', 'MOTDEPASSE', @motChiffre, @resultat2 OUTPUT;
-- j'affiche le mot d�chiffr�.
PRINT @resultat2;



--11.	Chiffrer ces deux proc�dures AVEC ENCRYPTION (15 POINTS) 
-- 1. Chiffrer la proc�dure chiffrer
CREATE OR ALTER PROCEDURE chiffrer
    @methodeChiffrement NVARCHAR(50),  -- "Cl�Symetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteNonChiffre NVARCHAR(MAX),
    @resultatChiffre NVARCHAR(MAX) OUTPUT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    IF @methodeChiffrement = 'Cl�Symetrique'
    BEGIN
        -- Chiffrement par cl� sym�trique
        DECLARE @cleSymetrique VARBINARY(8000);
        OPEN SYMMETRIC KEY SymmetricKey3
        DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPT�';
        SET @cleSymetrique = EncryptByKey(KEY_GUID('SymmetricKey3'), @texteNonChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeChiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- Chiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatChiffre = CONVERT(NVARCHAR(MAX), ENCRYPTBYPASSPHRASE('MOTDEPASSECRYPT�', @texteNonChiffre));
    END
    ELSE
    BEGIN
        -- M�thode de chiffrement non support�e
        SET @resultatChiffre = NULL;
        RETURN;
    END
END;

--TEST DE CHIFFREMENT DE Mousse blanche
DECLARE @resultat NVARCHAR(MAX);
EXEC chiffrer 'Cl�Symetrique', 'MOTDEPASSE', 'Mousse blanche', @resultat OUTPUT;
-- Utilisez @resultat pour acc�der � la cha�ne chiffr�e
PRINT @resultat;


-- 2. Chiffrer la proc�dure dechiffrer
CREATE OR ALTER PROCEDURE dechiffrer
    @methodeDechiffrement NVARCHAR(50),  -- "Cl�Symetrique" ou "EncryptByPassPhrase"
    @motDePasse NVARCHAR(100),
    @texteChiffre NVARCHAR(MAX),
    @resultatDechiffre NVARCHAR(MAX) OUTPUT
WITH ENCRYPTION --on chiffre la proc�dure avec WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    IF @methodeDechiffrement = 'Cl�Symetrique'
    BEGIN
        -- D�chiffrement par cl� sym�trique
        DECLARE @cleSymetrique VARBINARY(MAX);
        OPEN SYMMETRIC KEY SymmetricKey3 DECRYPTION BY PASSWORD = 'MOTDEPASSECRYPT�';
        SET @cleSymetrique = DecryptByKey(@texteChiffre);
        CLOSE SYMMETRIC KEY SymmetricKey3;
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), @cleSymetrique);
    END
    ELSE IF @methodeDechiffrement = 'EncryptByPassPhrase'
    BEGIN
        -- D�chiffrement par ENCRYPTBYPASSPHRASE
        SET @resultatDechiffre = CONVERT(NVARCHAR(MAX), DECRYPTBYPASSPHRASE(@motDePasse, @texteChiffre));
    END
    ELSE
    BEGIN
        -- M�thode de d�chiffrement non support�e
        SET @resultatDechiffre = NULL;
        RETURN;
    END
END;

--TEST DU DECHIFFREMENT
--je chiffre Tomates et oignons
DECLARE @motChiffre NVARCHAR(MAX);
EXEC chiffrer 'Cl�Symetrique', 'MOTDEPASSE', 'Tomates et oignons', @motChiffre OUTPUT;
--je dechiffre patate au four
DECLARE @resultat2 NVARCHAR(MAX);
EXEC dechiffrer 'Cl�Symetrique', 'MOTDEPASSE', @motChiffre, @resultat2 OUTPUT;
-- j'affiche le mot d�chiffr�.
PRINT @resultat2;