--**appel database**
use BANQUE;
select * from Compte
select * from Transfert

--1 ****UTILISER BASE DE DONNÉE BANQUE****	Créer une transaction qui va permettre de transférer une somme 
--d’argent d’un compte à un autre et qui doit s’assurer que les données
--sont cohérentes. La somme transférée doit être déduite du solde du 10001 et ajoutée dans le solde du 10002. 

-- Début de la transaction
BEGIN TRANSACTION;
-- Déclaration des variables pour les comptes source et de destination
DECLARE @source INT = (select idCompte from Compte where idCompte=10001);
DECLARE @destination INT = (select idCompte from Compte where idCompte=10002);
DECLARE @transfert DECIMAL(10, 2) = (select montant from Transfert where idCompte1=10001);
-- Verifaction de la transaction
IF ((SELECT montantCompte FROM Compte WHERE idCompte = @source) >= @transfert)
BEGIN
    -- Si ça marche, on enleve largent du compte principal
    UPDATE Compte
    SET montantCompte = montantCompte - @transfert
    WHERE idCompte = @source;
    -- Ajouter le montant au compte de destination
    UPDATE Compte
    SET montantCompte = montantCompte + @transfert
    WHERE idCompte = @destination;

    -- Insérer un enregistrement dans la table Transfert pour garder une trace du transfert
    INSERT INTO Transfert (idTransfert,idCompte1, idCompte2, montant)
    VALUES (2,@source, @destination, @transfert);
    -- Valider la transaction
    COMMIT;
    PRINT ('Le transfert a été effectué avec succès');
END
ELSE
BEGIN
    -- Annuler la transaction si le compte source n'a pas suffisamment d'argent
    ROLLBACK;
    PRINT ('Le compte source n/a pas suffisamment d/argent pour effectuer le transfert');
END;

select * from Transfert -- preuve transaction faite avec succèes

--2 1.	Créer une transaction qui permet de s'assurer que la capacité d'un 
--dépôt (capacite) n'est pas dépassée lors de l'ajout de nouveaux produits dans l'inventaire (20 points)
--*****UTILISER BASE DE DONNÉE DEPOTS******----
use DEPOTS;
--Debut transaction--
BEGIN TRANSACTION;
DECLARE @Montreal INT= (select capacite from Depot where idlocation=1);
DECLARE @Laval INT= (select capacite from Depot where idlocation=2);
DECLARE @Repentigny INT= (select capacite from Depot where idlocation=3);

-- Vérifiez si la capacité est suffisante
IF ((SELECT SUM(Qte) FROM Inventaire WHERE idlocation = 1) <= @Montreal ) --ON VERIFIE POUR MONTREAL
BEGIN																	  --SI CAPACITE PREND EN CHARGE
	--on rajoute dabord de nouveaux produits!
	INSERT INTO Produit(idproduit, nomproduit, prixunitaire)
    VALUES (5, 'Tables', 100.50);
    -- On peut alors rajouter une nouvelle quantité !
	--on va tester et rajoute une nouvelle quantité pour montréal
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (5, 1, 300);
    COMMIT;
    PRINT 'Transaction réussie. Nouveau stock ajouté.';
END

ELSE																--SI YA ERREUR LA TRANSACTION ANNULER
BEGIN
    ROLLBACK;
    PRINT 'Transaction échouée. Capacité du dépôt dépassée.';
END;

IF((SELECT SUM(Qte) FROM Inventaire WHERE idlocation = 2) <= @Laval)   --ON VERIFIE POUR LAVAL 
BEGIN																   --SI CAPACITE PREND EN CHARGE
	--on rajoute dabord de nouveaux produits!
	INSERT INTO Produit(idproduit, nomproduit, prixunitaire)
    VALUES (6, 'Chaise', 24.5);
    -- On peut alors rajouter une nouvelle quantité !
	--on va tester et rajoute une nouvelle quantité pour Laval
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (6, 2, 150);
    COMMIT;
    PRINT 'Transaction réussie. Nouveau stock ajouté.';
END

ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction échouée. Capacité du dépôt dépassée.';				--SI YA ERREUR LA TRANSACTION ANNULER
END;

IF((SELECT SUM(Qte) FROM Inventaire WHERE idlocation = 3) <= @Repentigny)   --ON VERIFIE POUR REPENTIGNY
BEGIN																		--SI CAPACITE PREND EN CHARGE
	--on rajoute dabord de nouveaux produits!
	INSERT INTO Produit(idproduit, nomproduit, prixunitaire)
    VALUES (7, 'Bureau', 232.12);
    -- On peut alors rajouter une nouvelle quantité !
	--on va tester et rajoute une nouvelle quantité pour REPENTIGNY
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (7, 3, 275);
    COMMIT;
    PRINT 'Transaction réussie. Nouveau stock ajouté.';
END

ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction échouée. Capacité du dépôt dépassée.';			--ON ANNULE SI TRANSACTION ECHOUER
END;

--apres transaction
select * from Produit
select * from Inventaire

--2 2.	Créer une transaction qui permet de déplacer une quantité d’un produit de Montreal à celui de Laval. --
--avant la transaction
select * from Inventaire ;
--debut transaction
BEGIN TRANSACTION;

DECLARE @idproduit INT= 5 ; --id produit qu'on prend est 5 donc TABLE
DECLARE @transfere INT=100; --jveux déplacer 100 de quantité de Montréal vers laval

-- Vérifiez si la quantité à transférer est disponible dans Montreal
IF (@transfere <= (SELECT Qte FROM Inventaire WHERE idproduit = @idproduit AND idlocation = 1))
BEGIN
    -- Décrémentez la quantité dans Montreal
    UPDATE Inventaire
    SET Qte = Qte - @transfere
    WHERE idproduit = @idproduit AND idlocation = 1;

    -- Incrémentez la quantité à Laval
    INSERT INTO Inventaire (idproduit, idlocation, Qte)
    VALUES (@idproduit, 2, @transfere);

    COMMIT;
    PRINT 'Transaction réussie. Transfert de stock effectué.';
END
ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction échouée. Quantité insuffisante à Montreal.';
END;
--affichage (on remarque que laval a un produit 5 désormais)
select * from Inventaire

--2 3.	Créer une transaction qui lorsqu’un client commande une quantité 
--d’un article, cette dernière doit être soustraite de la quantité stockée dans le dépôt. --

--avant transaction
select * from commande
select * from Inventaire
select * from Depot

--on demarre la transaction
BEGIN TRANSACTION;
DECLARE @nouvelleCommande INT= 1; --on crée la premiere commande
DECLARE @produitId INT=5; --on prend bureau comme produit
DECLARE @nouvelleQuantite INT=100; --la quantité a rajouté sera de 100 elle sera ensuite enlever du depot
IF (@nouvelleQuantite <= (SELECT sum(Qte) FROM Inventaire WHERE idlocation = 1)) --on regarde si la quantite peut rentrer dans le depot
BEGIN
    -- Soustrayez la quantité commandée du stock DANS INVENTAIRE
    UPDATE Inventaire
    SET Qte = Qte - @nouvelleQuantite
    WHERE idproduit = @produitId ;
	update Depot --vue que je netais pas sur, jenleve la quantité du depot aussi
	SET capacite= capacite-@nouvelleQuantite
	WHERE idlocation=1
	--on enregistre la commande
	insert into Commande(idcommande,datecommande,idlocation)
	values (@nouvelleCommande,'2023-11-11',1)
    COMMIT;
    PRINT 'Transaction réussie. Quantité soustraite du stock.';
END
ELSE
BEGIN
    ROLLBACK;
    PRINT 'Transaction échouée. Quantité insuffisante en stock.';
END;
--apres transaction
select * from commande
select * from Inventaire
select * from Depot

--2 4.	Créer une transaction qui permet d’ajouter la quantité du produit annulé par un client. 
--Ce produit sera supprimé de la table détails commande.--

--avant transaction
select * from Detail_commande;
select * from Inventaire

--debut transaction 
BEGIN TRANSACTION;
DECLARE @idCommande INT = 1;
DECLARE @idProduits INT = 5;
DECLARE @quantiteAnnuler INT = 5;
BEGIN TRY --JE MET DANS UN TRY AU CAS OU IL Y A UNE ERREUR
    -- Ajoutez la quantité annulée au stock
    UPDATE Inventaire
    SET Qte = Qte + @quantiteAnnuler
    WHERE idproduit = @idProduits
        AND idlocation = (SELECT idlocation FROM Commande WHERE idcommande = @idCommande);

    -- Supprimez le produit de la table de détails de commande
    DELETE FROM Detail_commande
    WHERE idcommande = @idCommande AND idproduit = @idProduits;

    COMMIT;
    PRINT 'Transaction réussie. Quantité annulée ajoutée au stock et produit supprimé de la commande.'
END TRY
BEGIN CATCH --EN GROS SIL Y A UNE ERREUR QUELQUONQUE SA AFFICHE LERREUR ET REFUSE LA TRANSCATION
    ROLLBACK;
    PRINT 'Erreur lors de la transaction : ' + ERROR_MESSAGE();
END CATCH;

--apres transaction
select * from Detail_commande;
select * from Inventaire
