-- MySQL dump 10.13  Distrib 8.0.20, for Win64 (x86_64)
--
-- Host: 192.168.231.3    Database: hyu1309-act-theta3
-- ------------------------------------------------------
-- Server version	5.7.20-ndb-7.5.8-cluster-gpl

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `hyu1309-act-theta3`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hyu1309-act-theta3` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `hyu1309-act-theta3`;

--
-- Table structure for table `st01_vissage_boitier`
--

DROP TABLE IF EXISTS `st01_vissage_boitier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st01_vissage_boitier` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Vissage` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_6` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_6` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_6` float NOT NULL DEFAULT '-9999.99',
  `Galia_Joint_Boitier` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT '',
  `Galia_Distrib_Ass` varchar(10) DEFAULT '',
  `Galia_Corp_Soud` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1309 : Vissage boitier';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st02_vissage_boitier_manuel`
--

DROP TABLE IF EXISTS `st02_vissage_boitier_manuel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st02_vissage_boitier_manuel` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) COLLATE latin1_bin NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) COLLATE latin1_bin NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) COLLATE latin1_bin NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Vis_2` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Num_Prog_Vis_5` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Galia_Vis` varchar(10) COLLATE latin1_bin DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='HYU1309 : Vissage manuel et graissage boitier';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st03_etancheite`
--

DROP TABLE IF EXISTS `st03_etancheite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st03_etancheite` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Posage_Plateau` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Etancheite` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Controle` int(10) unsigned NOT NULL DEFAULT '0',
  `Pression_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_1` float NOT NULL DEFAULT '0',
  `Pression_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_2` float NOT NULL DEFAULT '0',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Joint_Culasse` varchar(10) DEFAULT '',
  `Galia_Capteur_Temp` varchar(10) DEFAULT '',
  `Galia_Agrafe_Capteur` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Assemblage, étanchéité et orientation came';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st04_vissage_actionneur`
--

DROP TABLE IF EXISTS `st04_vissage_actionneur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st04_vissage_actionneur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Vissage` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Galia_Actionneur` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1309 : Vissage actionneur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st05_calibration`
--

DROP TABLE IF EXISTS `st05_calibration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st05_calibration` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Posage_Plateau` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Calibr` int(10) unsigned NOT NULL DEFAULT '0',
  `H_Initial_LS1_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS2_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS3_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS1_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS2_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS3_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS1_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS2_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS3_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS1_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS2_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS3_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Soupape_1` varchar(10) DEFAULT '',
  `Galia_Soupape_2` varchar(10) DEFAULT '',
  `Galia_Soupape_3` varchar(10) DEFAULT '',
  `Galia_Ressort_1_2` varchar(10) DEFAULT '',
  `Galia_Ressort_3` varchar(10) DEFAULT '',
  `Galia_Ressort_4` varchar(10) DEFAULT '',
  `Galia_Thermostat` varchar(10) DEFAULT '',
  `Galia_Platine_1` varchar(10) DEFAULT '',
  `Galia_Platine_2` varchar(10) DEFAULT '',
  `Galia_Conditionnement` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1309 : Calibration actionneur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st06_vissage_collecteur`
--

DROP TABLE IF EXISTS `st06_vissage_collecteur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st06_vissage_collecteur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Vis_1` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Num_Prog_Vis_2` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Num_Prog_Vis_3` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Galia_Coll_Ass` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1309 : Vissage collecteur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st08_soudure_rot_kcc`
--

DROP TABLE IF EXISTS `st08_soudure_rot_kcc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st08_soudure_rot_kcc` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Galia_Axe_Came` varchar(16) DEFAULT '',
  `Galia_Ressort` varchar(16) DEFAULT '',
  `Galia_Came` varchar(16) DEFAULT '',
  `Galia_Aimant` varchar(16) DEFAULT '',
  `Galia_Chapeau` varchar(16) DEFAULT '',
  `Galia_Palier` varchar(16) DEFAULT '',
  `Galia_Joint_Dyn` varchar(16) DEFAULT '',
  `Galia_Rondelle` varchar(16) DEFAULT '',
  `Galia_Distributeur` varchar(16) DEFAULT '',
  `Galia_Rotule` varchar(16) DEFAULT '',
  `Galia_Joint_Rot` varchar(16) DEFAULT '',
  `Galia_Grifaxe_TGDI` varchar(45) DEFAULT '',
  `Galia_Distrib_Ass` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Soudure rotation KCC sur  soudeuse Sonimat';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st11_soudure_rot_pipette_radia`
--

DROP TABLE IF EXISTS `st11_soudure_rot_pipette_radia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st11_soudure_rot_pipette_radia` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Type_Machine` varchar(10) NOT NULL DEFAULT '',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Intensite` float NOT NULL DEFAULT '-9999.99',
  `Fusion` float NOT NULL DEFAULT '-9999.99',
  `Galia_Corp_Nu` varchar(16) DEFAULT '',
  `Galia_Pip_Radia` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure pipette radiateur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st12_soudure_rot_pipette_oil`
--

DROP TABLE IF EXISTS `st12_soudure_rot_pipette_oil`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st12_soudure_rot_pipette_oil` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Type_Machine` varchar(10) NOT NULL DEFAULT '',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Intensite` float NOT NULL DEFAULT '-9999.99',
  `Fusion` float NOT NULL DEFAULT '-9999.99',
  `Galia_Pip_OIL` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure pipette oil';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st13_soudure_rot_pipette_heater`
--

DROP TABLE IF EXISTS `st13_soudure_rot_pipette_heater`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st13_soudure_rot_pipette_heater` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Type_Machine` varchar(10) NOT NULL DEFAULT '',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Intensite` float NOT NULL DEFAULT '-9999.99',
  `Fusion` float NOT NULL DEFAULT '-9999.99',
  `Galia_Pip_Heater` varchar(16) DEFAULT '',
  `Galia_Corp_Ass` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure pipette heater';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st20_soudure_us_insert_collecteur`
--

DROP TABLE IF EXISTS `st20_soudure_us_insert_collecteur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st20_soudure_us_insert_collecteur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Vitesse` float NOT NULL DEFAULT '-9999.99'
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure us, insert M6';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st21_soudure_rot_collecteur`
--

DROP TABLE IF EXISTS `st21_soudure_rot_collecteur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st21_soudure_rot_collecteur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99'
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Soudure rotation de la pipette collecteur sur soudeuse Sonimat';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st22_etancheite_collecteur`
--

DROP TABLE IF EXISTS `st22_etancheite_collecteur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st22_etancheite_collecteur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Etancheite` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Controle` int(10) unsigned NOT NULL DEFAULT '0',
  `Pression_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_1` int(10) unsigned NOT NULL DEFAULT '0',
  `Pression_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_2` int(10) unsigned NOT NULL DEFAULT '0',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Coll_Nu` varchar(10) DEFAULT '',
  `Galia_Insert` varchar(10) DEFAULT '',
  `Galia_Spigot_Heater` varchar(10) DEFAULT '',
  `Galia_Coll_Ass` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Etanchéite collecteur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `hyu1278-act-newu`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hyu1278-act-newu` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `hyu1278-act-newu`;

--
-- Table structure for table `st01_vissage_boitier`
--

DROP TABLE IF EXISTS `st01_vissage_boitier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st01_vissage_boitier` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Vissage` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Galia_Joint_Boitier` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT '',
  `Galia_Distrib_Ass` varchar(10) DEFAULT '',
  `Galia_Corp_Soud` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1278 : Vissage boitier';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st02_vissage_boitier_manuel`
--

DROP TABLE IF EXISTS `st02_vissage_boitier_manuel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st02_vissage_boitier_manuel` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) COLLATE latin1_bin NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) COLLATE latin1_bin NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) COLLATE latin1_bin NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Vis_3` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Galia_Vis` varchar(10) COLLATE latin1_bin DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COLLATE=latin1_bin COMMENT='HYU1278 : Vissage manuel et graissage boitier';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st03_etancheite`
--

DROP TABLE IF EXISTS `st03_etancheite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st03_etancheite` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Posage_Plateau` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Etancheite` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Controle` int(10) unsigned NOT NULL DEFAULT '0',
  `Pression_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_1` float NOT NULL DEFAULT '0',
  `Pression_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_2` float NOT NULL DEFAULT '0',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Joint_Culasse` varchar(10) DEFAULT '',
  `Galia_Capteur_Temp` varchar(10) DEFAULT '',
  `Galia_Agrafe_Capteur` varchar(10) DEFAULT '',
  `Galia_Pions` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1278 : Assemblage, étanchéité et orientation came';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st04_vissage_actionneur`
--

DROP TABLE IF EXISTS `st04_vissage_actionneur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st04_vissage_actionneur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Vissage` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Galia_Actionneur` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1278 : Vissage actionneur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st05_calibration`
--

DROP TABLE IF EXISTS `st05_calibration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st05_calibration` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Posage_Plateau` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Calibr` int(10) unsigned NOT NULL DEFAULT '0',
  `H_Initial_LS1_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS2_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS3_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS1_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS2_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS3_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS1_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS2_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS3_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS1_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS2_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS3_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Soupape_1_2` varchar(10) DEFAULT '',
  `Galia_Soupape_3` varchar(10) DEFAULT '',
  `Galia_Ressort_1_2` varchar(10) DEFAULT '',
  `Galia_Ressort_3` varchar(10) DEFAULT '',
  `Galia_Ressort_4` varchar(10) DEFAULT '',
  `Galia_Thermostat` varchar(10) DEFAULT '',
  `Galia_Grifaxe_Platine` varchar(10) DEFAULT '',
  `Galia_Platine_1` varchar(10) DEFAULT '',
  `Galia_Platine_2` varchar(10) DEFAULT '',
  `Galia_Conditionnement` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1278 : Calibration actionneur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st08_soudure_rot_kcc`
--

DROP TABLE IF EXISTS `st08_soudure_rot_kcc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st08_soudure_rot_kcc` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Galia_Axe_Came` varchar(16) DEFAULT '',
  `Galia_Ressort` varchar(16) DEFAULT '',
  `Galia_Came` varchar(16) DEFAULT '',
  `Galia_Aimant` varchar(16) DEFAULT '',
  `Galia_Chapeau` varchar(16) DEFAULT '',
  `Galia_Palier` varchar(16) DEFAULT '',
  `Galia_Joint_Dyn` varchar(16) DEFAULT '',
  `Galia_Rondelle` varchar(16) DEFAULT '',
  `Galia_Distributeur` varchar(16) DEFAULT '',
  `Galia_Rotule` varchar(16) DEFAULT '',
  `Galia_Joint_Rot` varchar(16) DEFAULT '',
  `Galia_Distrib_Ass` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Soudure rotation KCC sur  soudeuse Sonimat';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `hyu1278-act-newu_efi`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hyu1278-act-newu_efi` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `hyu1278-act-newu_efi`;

--
-- Table structure for table `Result`
--

DROP TABLE IF EXISTS `Result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Result` (
  `ID_Result` int(11) NOT NULL AUTO_INCREMENT,
  `Numero_piece` varchar(100) DEFAULT NULL,
  `Numero_poste` double DEFAULT NULL,
  `Date` datetime DEFAULT NULL,
  `conforme` varchar(100) DEFAULT NULL,
  `i_aller` double DEFAULT NULL,
  `i_retour` double DEFAULT NULL,
  `ls1ini` double DEFAULT NULL,
  `ls2ini` double DEFAULT NULL,
  `ls3ini` double DEFAULT NULL,
  `Point_A` double DEFAULT NULL,
  `Point_B` double DEFAULT NULL,
  `Point_C` double DEFAULT NULL,
  `Point_D` double DEFAULT NULL,
  `ls1palier` double DEFAULT NULL,
  `LS2palier` double DEFAULT NULL,
  `LS3palier` double DEFAULT NULL,
  `Vminhigh` double DEFAULT NULL,
  `Vmaxlow` double DEFAULT NULL,
  `frequence` double DEFAULT NULL,
  `angle` double DEFAULT NULL,
  `PWM_BB` double DEFAULT NULL,
  `PWM_BH` double DEFAULT NULL,
  `Livraison` double DEFAULT NULL,
  `Num_Actionneur` varchar(12) DEFAULT NULL,
   KEY (`ID_Result`)
) ENGINE=ndbcluster AUTO_INCREMENT=568552 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Setup`
--

DROP TABLE IF EXISTS `Setup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Setup` (
  `ID` double NOT NULL DEFAULT '1',
  `Date` datetime DEFAULT NULL,
  `Description` varchar(100) DEFAULT NULL,
  `Type_sequence` int(11) DEFAULT NULL,
  `Lock_capteur` tinyint(1) DEFAULT NULL,
  `Puissance_BO` double DEFAULT NULL,
  `Sens_recherche` int(11) DEFAULT NULL,
  `Limitation_courant` double DEFAULT NULL,
  `Fréquence_hachage` double DEFAULT NULL,
  `ALLER_Puissance_max_moteur` double DEFAULT NULL,
  `ALLER_Offset` double DEFAULT NULL,
  `ALLER_Coefficient_puissance` double DEFAULT NULL,
  `ALLER_Tolérance_asservissement` double DEFAULT NULL,
  `ALLER_Limitation_courant` double DEFAULT NULL,
  `ALLER_Fréquence_hachage` double DEFAULT NULL,
  `ALLER_Consigne` double DEFAULT NULL,
  `ALLER_Consommation_max` double DEFAULT NULL,
  `RETOUR_Puissance_max_moteur` double DEFAULT NULL,
  `RETOUR_Offset` double DEFAULT NULL,
  `RETOUR_Coefficient_puissance` double DEFAULT NULL,
  `RETOUR_Tolérance_asservissement` double DEFAULT NULL,
  `RETOUR_Limitation_courant` double DEFAULT NULL,
  `RETOUR_Fréquence_hachage` double DEFAULT NULL,
  `RETOUR_Consigne` double DEFAULT NULL,
  `RETOUR_Consommation_max` double DEFAULT NULL,
  `LS1_offset` double DEFAULT NULL,
  `LS1_gain` double DEFAULT NULL,
  `LS1_Seuil_min_initial` double DEFAULT NULL,
  `LS1_Seuil_max_initial` double DEFAULT NULL,
  `LS1_Seuil_min_palier` double DEFAULT NULL,
  `LS1_Seuil_max_palier` double DEFAULT NULL,
  `LS2_offset` double DEFAULT NULL,
  `LS2_gain` double DEFAULT NULL,
  `LS2_Seuil_min_initial` double DEFAULT NULL,
  `LS2_Seuil_max_initial` double DEFAULT NULL,
  `LS2_Seuil_min_palier` double DEFAULT NULL,
  `LS2_Seuil_max_palier` double DEFAULT NULL,
  `LS3_offset` double DEFAULT NULL,
  `LS3_gain` double DEFAULT NULL,
  `LS3_Seuil_min_initial` double DEFAULT NULL,
  `LS3_Seuil_max_initial` double DEFAULT NULL,
  `LS3_Seuil_min_palier` double DEFAULT NULL,
  `LS3_Seuil_max_palier` double DEFAULT NULL,
  `Cell_type` int(11) DEFAULT NULL,
  `Position_livraison` double DEFAULT NULL,
  `Liv_Puissance_max_moteur` double DEFAULT NULL,
  `Liv_Offset` double DEFAULT NULL,
  `Liv_Coefficient_puissance` double DEFAULT NULL,
  `Liv_Tolérance_asservissement` double DEFAULT NULL,
  `Courant_consommation_min` double DEFAULT NULL,
  `Courant_consommation_max` double DEFAULT NULL,
  `Tension_min_Haut` double DEFAULT NULL,
  `Tension_max_Bas` double DEFAULT NULL,
  `Fréquence_min` double DEFAULT NULL,
  `Fréquence_max` double DEFAULT NULL,
  `ID_Setup` int(11) DEFAULT NULL,
  `A_Point` double DEFAULT NULL,
  `A_Soupape` double DEFAULT NULL,
  `A_Front` double DEFAULT NULL,
  `A_Position` double DEFAULT NULL,
  `A_PWM` double DEFAULT NULL,
  `A_Tol_Min` double DEFAULT NULL,
  `A_Tol_Max` double DEFAULT NULL,
  `B_Point` double DEFAULT NULL,
  `B_Soupape` double DEFAULT NULL,
  `B_Front` double DEFAULT NULL,
  `B_Position` double DEFAULT NULL,
  `B_PWM` double DEFAULT NULL,
  `B_Tol_Min` double DEFAULT NULL,
  `B_Tol_Max` double DEFAULT NULL,
  `C_Point` double DEFAULT NULL,
  `C_Soupape` double DEFAULT NULL,
  `C_Front` double DEFAULT NULL,
  `C_Position` double DEFAULT NULL,
  `C_PWM` double DEFAULT NULL,
  `C_Tol_Min` double DEFAULT NULL,
  `C_Tol_Max` double DEFAULT NULL,
  `D_Point` double DEFAULT NULL,
  `D_Soupape` double DEFAULT NULL,
  `D_Front` double DEFAULT NULL,
  `D_Position` double DEFAULT NULL,
  `D_PWM` double DEFAULT NULL,
  `D_Tol_Min` double DEFAULT NULL,
  `D_Tol_Max` double DEFAULT NULL,
  `SBB` double DEFAULT NULL,
  `SBH` double DEFAULT NULL,
  `Offset_mecanique` double DEFAULT NULL,
  `PWMBBMin` double DEFAULT NULL,
  `PWMBBMax` double DEFAULT NULL,
  `PWMBHMin` double DEFAULT NULL,
  `PWMBHMax` double DEFAULT NULL,
   KEY (`ID`)
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mlx90365`
--

DROP TABLE IF EXISTS `mlx90365`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mlx90365` (
  `ID_Setup` int(11) NOT NULL,
  `Nom_setup` varchar(100) DEFAULT NULL,
  `Output1mode` int(11) DEFAULT NULL,
  `MapXYZ` int(11) DEFAULT NULL,
  `Clockwise` tinyint(1) DEFAULT NULL,
  `4Points` tinyint(1) DEFAULT NULL,
  `Pullup` tinyint(1) DEFAULT NULL,
  `PullDown` tinyint(1) DEFAULT NULL,
  `EnableDiag` tinyint(1) DEFAULT NULL,
  `ProgramK` tinyint(1) DEFAULT NULL,
  `Fixedgain` tinyint(1) DEFAULT NULL,
  `FilterMode` int(11) DEFAULT NULL,
  `PWMFreq` double DEFAULT NULL,
  `ClampLow` double DEFAULT NULL,
  `ClampHigh` double DEFAULT NULL,
  `K` double DEFAULT NULL,
  `Gainvalue` int(11) DEFAULT NULL,
  `DPsolver` double DEFAULT NULL,
  `WorkingrangeDeg` int(11) DEFAULT NULL,
  `DPByAngle` tinyint(1) DEFAULT NULL,
  `DP` double DEFAULT NULL,
  `PWMPOL` tinyint(1) DEFAULT NULL,
  `Baudrate` int(11) DEFAULT NULL,
  `YO` double DEFAULT NULL,
  `Y1` double DEFAULT NULL,
  `Y2` double DEFAULT NULL,
  `Y3` double DEFAULT NULL,
  `Y4` double DEFAULT NULL,
  `Y5` double DEFAULT NULL,
  `Y6` double DEFAULT NULL,
  `Y7` double DEFAULT NULL,
  `Y8` double DEFAULT NULL,
  `Y9` double DEFAULT NULL,
  `Y10` double DEFAULT NULL,
  `Y11` double DEFAULT NULL,
  `Y12` double DEFAULT NULL,
  `Y13` double DEFAULT NULL,
  `Y14` double DEFAULT NULL,
  `Y15` double DEFAULT NULL,
  `Y16` double DEFAULT NULL,
  `LevelPosition0` double DEFAULT NULL,
  `LevelPositionA` double DEFAULT NULL,
  `LevelPositionB` double DEFAULT NULL,
  `LevelPositionC` double DEFAULT NULL,
  `LevelPositionD` double DEFAULT NULL,
  `LevelPositionE` double DEFAULT NULL,
  `Position0` double DEFAULT NULL,
  `PositionA` double DEFAULT NULL,
  `PositionB` double DEFAULT NULL,
  `PositionC` double DEFAULT NULL,
  `PositionD` double DEFAULT NULL,
  `PositionE` double DEFAULT NULL
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `ID` int(11) NOT NULL DEFAULT '0',
  `server` varchar(8) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `Mail` varchar(50) DEFAULT NULL,
  `Signature` varchar(255) DEFAULT NULL,
  `Administrateur` tinyint(1) DEFAULT '0',
  `Support` tinyint(1) DEFAULT '0',
  `Edit_setup` tinyint(1) NOT NULL DEFAULT '0',
  `Password` varchar(16) NOT NULL,
  `Actif` tinyint(1) DEFAULT '0',
  `manager` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `hyu1309-act-theta3_efi`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hyu1309-act-theta3_efi` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `hyu1309-act-theta3_efi`;

--
-- Table structure for table `Result`
--

DROP TABLE IF EXISTS `Result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Result` (
  `ID_Result` int(11) NOT NULL AUTO_INCREMENT,
  `Numero_piece` varchar(100) DEFAULT NULL,
  `Numero_poste` double DEFAULT NULL,
  `Date` datetime DEFAULT NULL,
  `conforme` varchar(100) DEFAULT NULL,
  `i_aller` double DEFAULT NULL,
  `i_retour` double DEFAULT NULL,
  `ls1ini` double DEFAULT NULL,
  `ls2ini` double DEFAULT NULL,
  `ls3ini` double DEFAULT NULL,
  `Point_A` double DEFAULT NULL,
  `Point_B` double DEFAULT NULL,
  `Point_C` double DEFAULT NULL,
  `Point_D` double DEFAULT NULL,
  `ls1palier` double DEFAULT NULL,
  `LS2palier` double DEFAULT NULL,
  `LS3palier` double DEFAULT NULL,
  `Vminhigh` double DEFAULT NULL,
  `Vmaxlow` double DEFAULT NULL,
  `frequence` double DEFAULT NULL,
  `angle` double DEFAULT NULL,
  `PWM_BB` double DEFAULT NULL,
  `PWM_BH` double DEFAULT NULL,
  `Livraison` double DEFAULT NULL,
  `Num_Actionneur` varchar(12) DEFAULT NULL,
   KEY (`ID_Result`)
) ENGINE=ndbcluster AUTO_INCREMENT=901031 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Setup`
--

DROP TABLE IF EXISTS `Setup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Setup` (
  `ID` double NOT NULL DEFAULT '1',
  `Date` datetime DEFAULT NULL,
  `Description` varchar(100) DEFAULT NULL,
  `Type_sequence` int(11) DEFAULT NULL,
  `Lock_capteur` tinyint(1) DEFAULT NULL,
  `Puissance_BO` double DEFAULT NULL,
  `Sens_recherche` int(11) DEFAULT NULL,
  `Limitation_courant` double DEFAULT NULL,
  `Fréquence_hachage` double DEFAULT NULL,
  `ALLER_Puissance_max_moteur` double DEFAULT NULL,
  `ALLER_Offset` double DEFAULT NULL,
  `ALLER_Coefficient_puissance` double DEFAULT NULL,
  `ALLER_Tolérance_asservissement` double DEFAULT NULL,
  `ALLER_Limitation_courant` double DEFAULT NULL,
  `ALLER_Fréquence_hachage` double DEFAULT NULL,
  `ALLER_Consigne` double DEFAULT NULL,
  `ALLER_Consommation_max` double DEFAULT NULL,
  `RETOUR_Puissance_max_moteur` double DEFAULT NULL,
  `RETOUR_Offset` double DEFAULT NULL,
  `RETOUR_Coefficient_puissance` double DEFAULT NULL,
  `RETOUR_Tolérance_asservissement` double DEFAULT NULL,
  `RETOUR_Limitation_courant` double DEFAULT NULL,
  `RETOUR_Fréquence_hachage` double DEFAULT NULL,
  `RETOUR_Consigne` double DEFAULT NULL,
  `RETOUR_Consommation_max` double DEFAULT NULL,
  `LS1_offset` double DEFAULT NULL,
  `LS1_gain` double DEFAULT NULL,
  `LS1_Seuil_min_initial` double DEFAULT NULL,
  `LS1_Seuil_max_initial` double DEFAULT NULL,
  `LS1_Seuil_min_palier` double DEFAULT NULL,
  `LS1_Seuil_max_palier` double DEFAULT NULL,
  `LS2_offset` double DEFAULT NULL,
  `LS2_gain` double DEFAULT NULL,
  `LS2_Seuil_min_initial` double DEFAULT NULL,
  `LS2_Seuil_max_initial` double DEFAULT NULL,
  `LS2_Seuil_min_palier` double DEFAULT NULL,
  `LS2_Seuil_max_palier` double DEFAULT NULL,
  `LS3_offset` double DEFAULT NULL,
  `LS3_gain` double DEFAULT NULL,
  `LS3_Seuil_min_initial` double DEFAULT NULL,
  `LS3_Seuil_max_initial` double DEFAULT NULL,
  `LS3_Seuil_min_palier` double DEFAULT NULL,
  `LS3_Seuil_max_palier` double DEFAULT NULL,
  `Cell_type` int(11) DEFAULT NULL,
  `Position_livraison` double DEFAULT NULL,
  `Liv_Puissance_max_moteur` double DEFAULT NULL,
  `Liv_Offset` double DEFAULT NULL,
  `Liv_Coefficient_puissance` double DEFAULT NULL,
  `Liv_Tolérance_asservissement` double DEFAULT NULL,
  `Courant_consommation_min` double DEFAULT NULL,
  `Courant_consommation_max` double DEFAULT NULL,
  `Tension_min_Haut` double DEFAULT NULL,
  `Tension_max_Bas` double DEFAULT NULL,
  `Fréquence_min` double DEFAULT NULL,
  `Fréquence_max` double DEFAULT NULL,
  `ID_Setup` int(11) DEFAULT NULL,
  `A_Point` double DEFAULT NULL,
  `A_Soupape` double DEFAULT NULL,
  `A_Front` double DEFAULT NULL,
  `A_Position` double DEFAULT NULL,
  `A_PWM` double DEFAULT NULL,
  `A_Tol_Min` double DEFAULT NULL,
  `A_Tol_Max` double DEFAULT NULL,
  `B_Point` double DEFAULT NULL,
  `B_Soupape` double DEFAULT NULL,
  `B_Front` double DEFAULT NULL,
  `B_Position` double DEFAULT NULL,
  `B_PWM` double DEFAULT NULL,
  `B_Tol_Min` double DEFAULT NULL,
  `B_Tol_Max` double DEFAULT NULL,
  `C_Point` double DEFAULT NULL,
  `C_Soupape` double DEFAULT NULL,
  `C_Front` double DEFAULT NULL,
  `C_Position` double DEFAULT NULL,
  `C_PWM` double DEFAULT NULL,
  `C_Tol_Min` double DEFAULT NULL,
  `C_Tol_Max` double DEFAULT NULL,
  `D_Point` double DEFAULT NULL,
  `D_Soupape` double DEFAULT NULL,
  `D_Front` double DEFAULT NULL,
  `D_Position` double DEFAULT NULL,
  `D_PWM` double DEFAULT NULL,
  `D_Tol_Min` double DEFAULT NULL,
  `D_Tol_Max` double DEFAULT NULL,
  `SBB` double DEFAULT NULL,
  `SBH` double DEFAULT NULL,
  `Offset_mecanique` double DEFAULT NULL,
  `PWMBBMin` double DEFAULT NULL,
  `PWMBBMax` double DEFAULT NULL,
  `PWMBHMin` double DEFAULT NULL,
  `PWMBHMax` double DEFAULT NULL,
   KEY (`ID`)
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mlx90365`
--

DROP TABLE IF EXISTS `mlx90365`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mlx90365` (
  `ID_Setup` int(11) NOT NULL,
  `Nom_setup` varchar(100) DEFAULT NULL,
  `Output1mode` int(11) DEFAULT NULL,
  `MapXYZ` int(11) DEFAULT NULL,
  `Clockwise` tinyint(1) DEFAULT NULL,
  `4Points` tinyint(1) DEFAULT NULL,
  `Pullup` tinyint(1) DEFAULT NULL,
  `PullDown` tinyint(1) DEFAULT NULL,
  `EnableDiag` tinyint(1) DEFAULT NULL,
  `ProgramK` tinyint(1) DEFAULT NULL,
  `Fixedgain` tinyint(1) DEFAULT NULL,
  `FilterMode` int(11) DEFAULT NULL,
  `PWMFreq` double DEFAULT NULL,
  `ClampLow` double DEFAULT NULL,
  `ClampHigh` double DEFAULT NULL,
  `K` double DEFAULT NULL,
  `Gainvalue` int(11) DEFAULT NULL,
  `DPsolver` double DEFAULT NULL,
  `WorkingrangeDeg` int(11) DEFAULT NULL,
  `DPByAngle` tinyint(1) DEFAULT NULL,
  `DP` double DEFAULT NULL,
  `PWMPOL` tinyint(1) DEFAULT NULL,
  `Baudrate` int(11) DEFAULT NULL,
  `YO` double DEFAULT NULL,
  `Y1` double DEFAULT NULL,
  `Y2` double DEFAULT NULL,
  `Y3` double DEFAULT NULL,
  `Y4` double DEFAULT NULL,
  `Y5` double DEFAULT NULL,
  `Y6` double DEFAULT NULL,
  `Y7` double DEFAULT NULL,
  `Y8` double DEFAULT NULL,
  `Y9` double DEFAULT NULL,
  `Y10` double DEFAULT NULL,
  `Y11` double DEFAULT NULL,
  `Y12` double DEFAULT NULL,
  `Y13` double DEFAULT NULL,
  `Y14` double DEFAULT NULL,
  `Y15` double DEFAULT NULL,
  `Y16` double DEFAULT NULL,
  `LevelPosition0` double DEFAULT NULL,
  `LevelPositionA` double DEFAULT NULL,
  `LevelPositionB` double DEFAULT NULL,
  `LevelPositionC` double DEFAULT NULL,
  `LevelPositionD` double DEFAULT NULL,
  `LevelPositionE` double DEFAULT NULL,
  `Position0` double DEFAULT NULL,
  `PositionA` double DEFAULT NULL,
  `PositionB` double DEFAULT NULL,
  `PositionC` double DEFAULT NULL,
  `PositionD` double DEFAULT NULL,
  `PositionE` double DEFAULT NULL
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `ID` int(11) NOT NULL DEFAULT '0',
  `server` varchar(8) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `Mail` varchar(50) DEFAULT NULL,
  `Signature` varchar(255) DEFAULT NULL,
  `Administrateur` tinyint(1) DEFAULT '0',
  `Support` tinyint(1) DEFAULT '0',
  `Edit_setup` tinyint(1) NOT NULL DEFAULT '0',
  `Password` varchar(16) NOT NULL,
  `Actif` tinyint(1) DEFAULT '0',
  `manager` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `hyu1312-act-nu_efi`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hyu1312-act-nu_efi` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `hyu1312-act-nu_efi`;

--
-- Table structure for table `Result`
--

DROP TABLE IF EXISTS `Result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Result` (
  `ID_Result` int(11) NOT NULL AUTO_INCREMENT,
  `Numero_piece` varchar(100) DEFAULT NULL,
  `Numero_poste` double DEFAULT NULL,
  `Date` datetime DEFAULT NULL,
  `conforme` varchar(100) DEFAULT NULL,
  `i_aller` double DEFAULT NULL,
  `i_retour` double DEFAULT NULL,
  `ls1ini` double DEFAULT NULL,
  `ls2ini` double DEFAULT NULL,
  `ls3ini` double DEFAULT NULL,
  `Point_A` double DEFAULT NULL,
  `Point_B` double DEFAULT NULL,
  `Point_C` double DEFAULT NULL,
  `Point_D` double DEFAULT NULL,
  `ls1palier` double DEFAULT NULL,
  `LS2palier` double DEFAULT NULL,
  `LS3palier` double DEFAULT NULL,
  `Vminhigh` double DEFAULT NULL,
  `Vmaxlow` double DEFAULT NULL,
  `frequence` double DEFAULT NULL,
  `angle` double DEFAULT NULL,
  `PWM_BB` double DEFAULT NULL,
  `PWM_BH` double DEFAULT NULL,
  `Livraison` double DEFAULT NULL,
  `Num_Actionneur` varchar(12) DEFAULT NULL,
   KEY (`ID_Result`)
) ENGINE=ndbcluster AUTO_INCREMENT=892552 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Setup`
--

DROP TABLE IF EXISTS `Setup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Setup` (
  `ID` double NOT NULL DEFAULT '1',
  `Date` datetime DEFAULT NULL,
  `Description` varchar(100) DEFAULT NULL,
  `Type_sequence` int(11) DEFAULT NULL,
  `Lock_capteur` tinyint(1) DEFAULT NULL,
  `Puissance_BO` double DEFAULT NULL,
  `Sens_recherche` int(11) DEFAULT NULL,
  `Limitation_courant` double DEFAULT NULL,
  `Fréquence_hachage` double DEFAULT NULL,
  `ALLER_Puissance_max_moteur` double DEFAULT NULL,
  `ALLER_Offset` double DEFAULT NULL,
  `ALLER_Coefficient_puissance` double DEFAULT NULL,
  `ALLER_Tolérance_asservissement` double DEFAULT NULL,
  `ALLER_Limitation_courant` double DEFAULT NULL,
  `ALLER_Fréquence_hachage` double DEFAULT NULL,
  `ALLER_Consigne` double DEFAULT NULL,
  `ALLER_Consommation_max` double DEFAULT NULL,
  `RETOUR_Puissance_max_moteur` double DEFAULT NULL,
  `RETOUR_Offset` double DEFAULT NULL,
  `RETOUR_Coefficient_puissance` double DEFAULT NULL,
  `RETOUR_Tolérance_asservissement` double DEFAULT NULL,
  `RETOUR_Limitation_courant` double DEFAULT NULL,
  `RETOUR_Fréquence_hachage` double DEFAULT NULL,
  `RETOUR_Consigne` double DEFAULT NULL,
  `RETOUR_Consommation_max` double DEFAULT NULL,
  `LS1_offset` double DEFAULT NULL,
  `LS1_gain` double DEFAULT NULL,
  `LS1_Seuil_min_initial` double DEFAULT NULL,
  `LS1_Seuil_max_initial` double DEFAULT NULL,
  `LS1_Seuil_min_palier` double DEFAULT NULL,
  `LS1_Seuil_max_palier` double DEFAULT NULL,
  `LS2_offset` double DEFAULT NULL,
  `LS2_gain` double DEFAULT NULL,
  `LS2_Seuil_min_initial` double DEFAULT NULL,
  `LS2_Seuil_max_initial` double DEFAULT NULL,
  `LS2_Seuil_min_palier` double DEFAULT NULL,
  `LS2_Seuil_max_palier` double DEFAULT NULL,
  `LS3_offset` double DEFAULT NULL,
  `LS3_gain` double DEFAULT NULL,
  `LS3_Seuil_min_initial` double DEFAULT NULL,
  `LS3_Seuil_max_initial` double DEFAULT NULL,
  `LS3_Seuil_min_palier` double DEFAULT NULL,
  `LS3_Seuil_max_palier` double DEFAULT NULL,
  `Cell_type` int(11) DEFAULT NULL,
  `Position_livraison` double DEFAULT NULL,
  `Liv_Puissance_max_moteur` double DEFAULT NULL,
  `Liv_Offset` double DEFAULT NULL,
  `Liv_Coefficient_puissance` double DEFAULT NULL,
  `Liv_Tolérance_asservissement` double DEFAULT NULL,
  `Courant_consommation_min` double DEFAULT NULL,
  `Courant_consommation_max` double DEFAULT NULL,
  `Tension_min_Haut` double DEFAULT NULL,
  `Tension_max_Bas` double DEFAULT NULL,
  `Fréquence_min` double DEFAULT NULL,
  `Fréquence_max` double DEFAULT NULL,
  `ID_Setup` int(11) DEFAULT NULL,
  `A_Point` double DEFAULT NULL,
  `A_Soupape` double DEFAULT NULL,
  `A_Front` double DEFAULT NULL,
  `A_Position` double DEFAULT NULL,
  `A_PWM` double DEFAULT NULL,
  `A_Tol_Min` double DEFAULT NULL,
  `A_Tol_Max` double DEFAULT NULL,
  `B_Point` double DEFAULT NULL,
  `B_Soupape` double DEFAULT NULL,
  `B_Front` double DEFAULT NULL,
  `B_Position` double DEFAULT NULL,
  `B_PWM` double DEFAULT NULL,
  `B_Tol_Min` double DEFAULT NULL,
  `B_Tol_Max` double DEFAULT NULL,
  `C_Point` double DEFAULT NULL,
  `C_Soupape` double DEFAULT NULL,
  `C_Front` double DEFAULT NULL,
  `C_Position` double DEFAULT NULL,
  `C_PWM` double DEFAULT NULL,
  `C_Tol_Min` double DEFAULT NULL,
  `C_Tol_Max` double DEFAULT NULL,
  `D_Point` double DEFAULT NULL,
  `D_Soupape` double DEFAULT NULL,
  `D_Front` double DEFAULT NULL,
  `D_Position` double DEFAULT NULL,
  `D_PWM` double DEFAULT NULL,
  `D_Tol_Min` double DEFAULT NULL,
  `D_Tol_Max` double DEFAULT NULL,
  `SBB` double DEFAULT NULL,
  `SBH` double DEFAULT NULL,
  `Offset_mecanique` double DEFAULT NULL,
  `PWMBBMin` double DEFAULT NULL,
  `PWMBBMax` double DEFAULT NULL,
  `PWMBHMin` double DEFAULT NULL,
  `PWMBHMax` double DEFAULT NULL,
   KEY (`ID`)
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mlx90365`
--

DROP TABLE IF EXISTS `mlx90365`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mlx90365` (
  `ID_Setup` int(11) NOT NULL,
  `Nom_setup` varchar(100) DEFAULT NULL,
  `Output1mode` int(11) DEFAULT NULL,
  `MapXYZ` int(11) DEFAULT NULL,
  `Clockwise` tinyint(1) DEFAULT NULL,
  `4Points` tinyint(1) DEFAULT NULL,
  `Pullup` tinyint(1) DEFAULT NULL,
  `PullDown` tinyint(1) DEFAULT NULL,
  `EnableDiag` tinyint(1) DEFAULT NULL,
  `ProgramK` tinyint(1) DEFAULT NULL,
  `Fixedgain` tinyint(1) DEFAULT NULL,
  `FilterMode` int(11) DEFAULT NULL,
  `PWMFreq` double DEFAULT NULL,
  `ClampLow` double DEFAULT NULL,
  `ClampHigh` double DEFAULT NULL,
  `K` double DEFAULT NULL,
  `Gainvalue` int(11) DEFAULT NULL,
  `DPsolver` double DEFAULT NULL,
  `WorkingrangeDeg` int(11) DEFAULT NULL,
  `DPByAngle` tinyint(1) DEFAULT NULL,
  `DP` double DEFAULT NULL,
  `PWMPOL` tinyint(1) DEFAULT NULL,
  `Baudrate` int(11) DEFAULT NULL,
  `YO` double DEFAULT NULL,
  `Y1` double DEFAULT NULL,
  `Y2` double DEFAULT NULL,
  `Y3` double DEFAULT NULL,
  `Y4` double DEFAULT NULL,
  `Y5` double DEFAULT NULL,
  `Y6` double DEFAULT NULL,
  `Y7` double DEFAULT NULL,
  `Y8` double DEFAULT NULL,
  `Y9` double DEFAULT NULL,
  `Y10` double DEFAULT NULL,
  `Y11` double DEFAULT NULL,
  `Y12` double DEFAULT NULL,
  `Y13` double DEFAULT NULL,
  `Y14` double DEFAULT NULL,
  `Y15` double DEFAULT NULL,
  `Y16` double DEFAULT NULL,
  `LevelPosition0` double DEFAULT NULL,
  `LevelPositionA` double DEFAULT NULL,
  `LevelPositionB` double DEFAULT NULL,
  `LevelPositionC` double DEFAULT NULL,
  `LevelPositionD` double DEFAULT NULL,
  `LevelPositionE` double DEFAULT NULL,
  `Position0` double DEFAULT NULL,
  `PositionA` double DEFAULT NULL,
  `PositionB` double DEFAULT NULL,
  `PositionC` double DEFAULT NULL,
  `PositionD` double DEFAULT NULL,
  `PositionE` double DEFAULT NULL
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `ID` int(11) NOT NULL DEFAULT '0',
  `server` varchar(8) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `Mail` varchar(50) DEFAULT NULL,
  `Signature` varchar(255) DEFAULT NULL,
  `Administrateur` tinyint(1) DEFAULT '0',
  `Support` tinyint(1) DEFAULT '0',
  `Edit_setup` tinyint(1) NOT NULL DEFAULT '0',
  `Password` varchar(16) NOT NULL,
  `Actif` tinyint(1) DEFAULT '0',
  `manager` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=ndbcluster DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `production`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `production` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `production`;

--
-- Table structure for table `Datas_Scan`
--

DROP TABLE IF EXISTS `Datas_Scan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Datas_Scan` (
  `ID` varchar(10) NOT NULL DEFAULT '0',
  `Reference` varchar(10) NOT NULL DEFAULT '',
  `IndicePlan` varchar(2) NOT NULL DEFAULT '01',
  `Designation` varchar(50) NOT NULL DEFAULT '',
  `Type` varchar(20) NOT NULL DEFAULT '',
  `CaB_Detr_Ref` varchar(4) NOT NULL DEFAULT '30S',
  `CaB_Detr_Etiq` varchar(4) NOT NULL DEFAULT 'S',
  `Cpt_NbPie/UC` int(10) unsigned NOT NULL DEFAULT '1',
  `Type_UC` varchar(20) NOT NULL DEFAULT 'Aucun',
   KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Machines`
--

DROP TABLE IF EXISTS `Machines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Machines` (
  `Num_Machine` int(10) NOT NULL DEFAULT '0',
  `Designation` varchar(50) NOT NULL DEFAULT '',
  `Fournisseur` varchar(50) NOT NULL DEFAULT '',
  `Num_Usine` varchar(4) NOT NULL DEFAULT '0900',
  `Num_Ligne` varchar(4) NOT NULL DEFAULT 'LAxx',
   KEY (`Num_Machine`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `hyu1312-act-nu`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `hyu1312-act-nu` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `hyu1312-act-nu`;

--
-- Temporary view structure for view `Ref_Composants`
--

DROP TABLE IF EXISTS `Ref_Composants`;
/*!50001 DROP VIEW IF EXISTS `Ref_Composants`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `Ref_Composants` AS SELECT 
 1 AS `Reference`,
 1 AS `Designation`,
 1 AS `CaB_Detr_Ref`,
 1 AS `CaB_Detr_Etiq`,
 1 AS `Cpt_NbPie/UC`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `st01_vissage_boitier`
--

DROP TABLE IF EXISTS `st01_vissage_boitier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st01_vissage_boitier` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Vissage` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_6` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_6` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_6` float NOT NULL DEFAULT '-9999.99',
  `Galia_Joint_Boitier` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT '',
  `Galia_Distrib_Ass` varchar(10) DEFAULT '',
  `Galia_Corp_Soud` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1312 : Vissage boitier';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st02_vissage_boitier_manuel`
--

DROP TABLE IF EXISTS `st02_vissage_boitier_manuel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st02_vissage_boitier_manuel` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Vis_2` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Num_Prog_Vis_5` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_5` float NOT NULL DEFAULT '-9999.99',
  `Galia_Vis` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1309 : Vissage manuel boitier';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st03_etancheite`
--

DROP TABLE IF EXISTS `st03_etancheite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st03_etancheite` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Posage_Plateau` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Etancheite` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Controle` int(10) unsigned NOT NULL DEFAULT '0',
  `Pression_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_1` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_1` float NOT NULL DEFAULT '0',
  `Pression_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Rejet_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Alarme_Test_2` float NOT NULL DEFAULT '0',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Joint_Culasse` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1312 : Assemblage, étanchéité et orientation came';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st04_vissage_actionneur`
--

DROP TABLE IF EXISTS `st04_vissage_actionneur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st04_vissage_actionneur` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Vissage` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog` int(10) unsigned NOT NULL DEFAULT '0',
  `Couple_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_1` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_2` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_3` float NOT NULL DEFAULT '-9999.99',
  `Couple_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Angle_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Hauteur_Vis_4` float NOT NULL DEFAULT '-9999.99',
  `Galia_Actionneur` varchar(10) DEFAULT '',
  `Galia_Vis` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1312 : Vissage actionneur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st05_calibration`
--

DROP TABLE IF EXISTS `st05_calibration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st05_calibration` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Mode_Prod` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Posage_Plateau` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Poste_Calibr` int(10) unsigned NOT NULL DEFAULT '0',
  `H_Initial_LS1_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS2_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS3_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS1_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS2_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS3_Test_1` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS1_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS2_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Initial_LS3_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS1_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS2_Test_2` float NOT NULL DEFAULT '-9999.99',
  `H_Palier_LS3_Test_2` float NOT NULL DEFAULT '-9999.99',
  `Chang_Param` int(10) NOT NULL DEFAULT '0',
  `Galia_Soupape_1_2` varchar(10) DEFAULT '',
  `Galia_Soupape_3` varchar(10) DEFAULT '',
  `Galia_Ressort_1_2` varchar(10) DEFAULT '',
  `Galia_Ressort_3` varchar(10) DEFAULT '',
  `Galia_Ressort_4` varchar(10) DEFAULT '',
  `Galia_Thermostat` varchar(10) DEFAULT '',
  `Galia_Platine` varchar(10) DEFAULT '',
  `Galia_Conditionnement` varchar(10) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='HYU1312 : Calibration actionneur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st08_soudure_rot_kcc`
--

DROP TABLE IF EXISTS `st08_soudure_rot_kcc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st08_soudure_rot_kcc` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Galia_Axe_Came` varchar(16) DEFAULT '',
  `Galia_Ressort` varchar(16) DEFAULT '',
  `Galia_Came` varchar(16) DEFAULT '',
  `Galia_Aimant` varchar(16) DEFAULT '',
  `Galia_Chapeau` varchar(16) DEFAULT '',
  `Galia_Palier` varchar(16) DEFAULT '',
  `Galia_Joint_Dyn` varchar(16) DEFAULT '',
  `Galia_Rondelle` varchar(16) DEFAULT '',
  `Galia_Distributeur` varchar(16) DEFAULT '',
  `Galia_Rotule` varchar(16) DEFAULT '',
  `Galia_Joint_Rot` varchar(16) DEFAULT '',
  `Galia_Distrib_Ass` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Soudure rotation KCC sur  soudeuse Sonimat';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st11_soudure_rot_pipette_radia`
--

DROP TABLE IF EXISTS `st11_soudure_rot_pipette_radia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st11_soudure_rot_pipette_radia` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Type_Machine` varchar(10) NOT NULL DEFAULT '',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Intensite` float NOT NULL DEFAULT '-9999.99',
  `Fusion` float NOT NULL DEFAULT '-9999.99',
  `Galia_Corp_Nu` varchar(16) DEFAULT '',
  `Galia_Pip_Radia` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure pipette radiateur';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st12_soudure_rot_pipette_heater`
--

DROP TABLE IF EXISTS `st12_soudure_rot_pipette_heater`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st12_soudure_rot_pipette_heater` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Type_Machine` varchar(10) NOT NULL DEFAULT '',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Intensite` float NOT NULL DEFAULT '-9999.99',
  `Fusion` float NOT NULL DEFAULT '-9999.99',
  `Galia_Pip_Heater` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure pipette heater';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `st13_soudure_rot_pipette_atf`
--

DROP TABLE IF EXISTS `st13_soudure_rot_pipette_atf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `st13_soudure_rot_pipette_atf` (
  `Date_Heure` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Num_Piece` varchar(45) NOT NULL DEFAULT '',
  `Etat` int(10) unsigned NOT NULL DEFAULT '0',
  `Horodateur_Jour` varchar(6) NOT NULL DEFAULT '',
  `Horodateur_Heure` varchar(5) NOT NULL DEFAULT '',
  `Code_Marq` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Machine` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Outil` int(10) unsigned NOT NULL DEFAULT '0',
  `Num_Prog_Soud` int(10) unsigned NOT NULL DEFAULT '0',
  `Type_Machine` varchar(10) NOT NULL DEFAULT '',
  `Energie` float NOT NULL DEFAULT '-9999.99',
  `Puissance` float NOT NULL DEFAULT '-9999.99',
  `Temps_Cycle` float NOT NULL DEFAULT '-9999.99',
  `Temps_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Temps_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Enfoncement` float NOT NULL DEFAULT '-9999.99',
  `Effort` float NOT NULL DEFAULT '-9999.99',
  `Cote_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Cote_Soudure` float NOT NULL DEFAULT '-9999.99',
  `Cote_Piece` float NOT NULL DEFAULT '-9999.99',
  `Angle_Arret` float NOT NULL DEFAULT '-9999.99',
  `Angle_Maintien` float NOT NULL DEFAULT '-9999.99',
  `Couple` float NOT NULL DEFAULT '-9999.99',
  `Intensite` float NOT NULL DEFAULT '-9999.99',
  `Fusion` float NOT NULL DEFAULT '-9999.99',
  `Galia_Pip_ATF` varchar(16) DEFAULT '',
  `Galia_Corp_Ass` varchar(16) DEFAULT ''
) ENGINE=ndbcluster DEFAULT CHARSET=latin1 COMMENT='Données de soudure pipette ATF';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Current Database: `hyu1309-act-theta3`
--

USE `hyu1309-act-theta3`;

--
-- Current Database: `hyu1278-act-newu`
--

USE `hyu1278-act-newu`;

--
-- Current Database: `hyu1278-act-newu_efi`
--

USE `hyu1278-act-newu_efi`;

--
-- Current Database: `hyu1309-act-theta3_efi`
--

USE `hyu1309-act-theta3_efi`;

--
-- Current Database: `hyu1312-act-nu_efi`
--

USE `hyu1312-act-nu_efi`;

--
-- Current Database: `production`
--

USE `production`;

--
-- Current Database: `hyu1312-act-nu`
--

USE `hyu1312-act-nu`;

--
-- Final view structure for view `Ref_Composants`
--

/*!50001 DROP VIEW IF EXISTS `Ref_Composants`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `Ref_Composants` AS select `production`.`Datas_Scan`.`Reference` AS `Reference`,`production`.`Datas_Scan`.`Designation` AS `Designation`,`production`.`Datas_Scan`.`CaB_Detr_Ref` AS `CaB_Detr_Ref`,`production`.`Datas_Scan`.`CaB_Detr_Etiq` AS `CaB_Detr_Etiq`,`production`.`Datas_Scan`.`Cpt_NbPie/UC` AS `Cpt_NbPie/UC` from `production`.`Datas_Scan` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-11-25 13:53:52
