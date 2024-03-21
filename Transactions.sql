--**appel database**
use BANQUE;
select * from Compte
select * from Transfert

--1 ****UTILISER BASE DE DONN�E BANQUE****	Cr�er une transaction qui va permettre de transf�rer une somme 
--d�argent d�un compte � un autre et qui doit s�assurer que les donn�es
--sont coh�rentes. La somme transf�r�e doit �tre d�duite du solde du 10001 et ajout�e dans le solde du 10002. 

-- D�but de la transaction
BEGIN TRANSACTION;
-- D�claration des variables pour les comptes source et de destination
DECLARE @source INT = (select idCompte from Compte where idCompte=10001);
DECLARE @destination INT = (select idCompte from Compte where idCompte=10002);
DECLARE @transfert DECIMAL(10, 2) = (select montant from Transfert where idCompte1=10001);
-- Verifaction de la transaction
IF ((SELECT montantCompte FROM Compte WHERE idCompte = @source) >= @transfert)
BEGIN
    -- Si �a marche, on enleve largent du compte principal
    UPDATE Compte
    SET montantCompte = montantCompte - @transfert
    WHERE idCompte = @source;
    -- Ajouter le montant au compte de destination
    UPDATE Compte
    SET montantCompte = montantCompte + @transfert
    WHERE idCompte = @destination;

    -- Ins�rer un enregistrement dans la table Transfert pour garder une trace du transfert
    INSERT INTO Transfert (idTransfert,idCompte1, idCompte2, montant)
    VALUES (2,@source, @destination, @transfert);
    -- Valider la transaction
    COMMIT;
    PRINT ('Le transfert a �t� effectu� avec succ�s');
END
ELSE
BEGIN
    -- Annuler la transaction si le compte source n'a pas suffisamment d'argent
    ROLLBACK;
    PRINT ('Le compte source n/a pas suffisamment d/argent pour effectuer le transfert');
END;

select * from Transfert -- preuve transaction faite avec succ�es

--2 1.	Cr�er une transaction qui permet de s'assurer que la capacit� d'un 
--d�p�t (capacite) n'est pas d�pass�e lors de l'ajout de nouveaux produits dans l'inventaire (20 points)
--*****UTILISER BASE DE DONN�E DEPOTS******----
use DEPOTS;
--Debut transaction--
BEGIN TRANSACTION;
DECLARE @Montreal INT= (select capacite from Depot where idlocation=1);
DECLARE @Laval INT= (select capacite from Depot where idlocation=2);
DECLARE @Repentigny INT= (select capacite from Depot where idlocation=3);

-- V�rifiez si la capacit� est suffisante
IF ((SELECT SUM(Qte) FROM Inventaire WHERE idlocation = 1) <= @Montreal ) --ON VERIFIE POUR MONTREAL
BEGIN																	  --SI CAPACITE PREND EN CHARGE
	--on rajoute dabord de nouveaux produits!
	INSERT INTO Produit(idproduit, nomproduit, prixunitaire)
    VALUES (5, 'Tables', 100.50);
    -- On peut alors rajouter une nouvelle quantit� !
	--on va tester et rajoute une nouvelle quantit� pour montr�al
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (5, 1, 300);
    COMMIT;
    PRINT 'Transaction r�ussie. Nouveau stock ajout�.';
END

ELSE																--SI YA ERREUR LA TRANSACTION ANNULER
BEGIN
    ROLLBACK;
    PRINT 'Transaction �chou�e. Capacit� du d�p�t d�pass�e.';
END;

IF((SELECT SUM(Qte) FROM Inventaire WHERE idlocation = 2) <= @Laval)   --ON VERIFIE POUR LAVAL 
BEGIN																   --SI CAPACITE PREND EN CHARGE
	--on rajoute dabord de nouveaux produits!
	INSERT INTO Produit(idproduit, nomproduit, prixunitaire)
    VALUES (6, 'Chaise', 24.5);
    -- On peut alors rajouter une nouvelle quantit� !
	--on va tester et rajoute une nouvelle quantit� pour Laval
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (6, 2, 150);
    COMMIT;
    PRINT 'Transaction r�ussie. Nouveau stock ajout�.';
END

ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction �chou�e. Capacit� du d�p�t d�pass�e.';				--SI YA ERREUR LA TRANSACTION ANNULER
END;

IF((SELECT SUM(Qte) FROM Inventaire WHERE idlocation = 3) <= @Repentigny)   --ON VERIFIE POUR REPENTIGNY
BEGIN																		--SI CAPACITE PREND EN CHARGE
	--on rajoute dabord de nouveaux produits!
	INSERT INTO Produit(idproduit, nomproduit, prixunitaire)
    VALUES (7, 'Bureau', 232.12);
    -- On peut alors rajouter une nouvelle quantit� !
	--on va tester et rajoute une nouvelle quantit� pour REPENTIGNY
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (7, 3, 275);
    COMMIT;
    PRINT 'Transaction r�ussie. Nouveau stock ajout�.';
END

ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction �chou�e. Capacit� du d�p�t d�pass�e.';			--ON ANNULE SI TRANSACTION ECHOUER
END;

--apres transaction
select * from Produit
select * from Inventaire

--2 2.	Cr�er une transaction qui permet de d�placer une quantit� d�un produit de Montreal � celui de Laval. --
--avant la transaction
select * from Inventaire ;
--debut transaction
BEGIN TRANSACTION;

DECLARE @idproduit INT= 5 ; --id produit qu'on prend est 5 donc TABLE
DECLARE @transfere INT=100; --jveux d�placer 100 de quantit� de Montr�al vers laval

-- V�rifiez si la quantit� � transf�rer est disponible dans Montreal
IF (@transfere <= (SELECT Qte FROM Inventaire WHERE idproduit = @idproduit AND idlocation = 1))
BEGIN
    -- D�cr�mentez la quantit� dans Montreal
    UPDATE Inventaire
    SET Qte = Qte - @transfere
    WHERE idproduit = @idproduit AND idlocation = 1;

    -- Incr�mentez la quantit� � Laval
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (@idproduit, 2, @transfere);

    COMMIT;
    PRINT 'Transaction r�ussie. Transfert de stock effectu�.';
END
ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction �chou�e. Quantit� insuffisante � Montreal.';
END;
--affichage (on remarque que laval a un produit 5 d�sormais)
select * from Inventaire

--2 3.	Cr�er une transaction qui lorsqu�un client commande une quantit� 
--d�un article, cette derni�re doit �tre soustraite de la quantit� stock�e dans le d�p�t. --

--avant transaction
select * from commande
select * from Inventaire
select * from Depot

--on demarre la transaction
BEGIN TRANSACTION;
DECLARE @nouvelleCommande INT= 1; --on cr�e la premiere commande
DECLARE @produitId INT=5; --on prend bureau comme produit
DECLARE @nouvelleQuantite INT=100; --la quantit� a rajout� sera de 100 elle sera ensuite enlever du depot
IF (@nouvelleQuantite <= (SELECT sum(Qte) FROM Inventaire WHERE idlocation = 1)) --on regarde si la quantite peut rentrer dans le depot
BEGIN
    -- Soustrayez la quantit� command�e du stock DANS INVENTAIRE
    UPDATE Inventaire
    SET Qte = Qte - @nouvelleQuantite
    WHERE idproduit = @produitId ;
	update Depot --vue que je netais pas sur, jenleve la quantit� du depot aussi
	SET capacite= capacite-@nouvelleQuantite
	WHERE idlocation=1
	--on enregistre la commande
	insert into Commande(idcommande,datecommande,idlocation)
	values (@nouvelleCommande,'2023-11-11',1)
    COMMIT;
    PRINT 'Transaction r�ussie. Quantit� soustraite du stock.';
END
ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction �chou�e. Quantit� insuffisante en stock.';
END;
--apres transaction
select * from commande
select * from Inventaire
select * from Depot

--2 4.	Cr�er une transaction qui permet d�ajouter la quantit� du produit annul� par un client. 
--Ce produit sera supprim� de la table d�tails commande.--

--avant transaction
select * from Detail_commande;
select * from Inventaire

--debut transaction 
BEGIN TRANSACTION;
DECLARE @idCommande INT = 1;
DECLARE @idProduits INT = 5;
DECLARE @quantiteAnnuler INT = 5;
BEGIN TRY --JE MET DANS UN TRY AU CAS OU IL Y A UNE ERREUR
    -- Ajoutez la quantit� annul�e au stock
    UPDATE Inventaire
    SET Qte = Qte + @quantiteAnnuler
    WHERE idproduit = @idProduits
        AND idlocation = (SELECT idlocation FROM Commande WHERE idcommande = @idCommande);

    -- Supprimez le produit de la table de d�tails de commande
    DELETE FROM Detail_commande
    WHERE idcommande = @idCommande AND idproduit = @idProduits;

    COMMIT;
    PRINT 'Transaction r�ussie. Quantit� annul�e ajout�e au stock et produit supprim� de la commande.'
END TRY
BEGIN CATCH --EN GROS SIL Y A UNE ERREUR QUELQUONQUE SA AFFICHE LERREUR ET REFUSE LA TRANSCATION
    ROLLBACK;
    PRINT 'Erreur lors de la transaction : ' + ERROR_MESSAGE();
END CATCH;

--apres transaction
select * from Detail_commande;
select * from Inventaire
