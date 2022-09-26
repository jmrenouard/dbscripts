-- MySQL dump 10.13  Distrib 8.0.20, for Win64 (x86_64)
--
-- Host: 192.168.231.3    Database: production
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
-- Current Database: `production`
--
DROP DATABASE IF EXISTS `production`;

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
-- Dumping data for table `Datas_Scan`
--

LOCK TABLES `Datas_Scan` WRITE;
/*!40000 ALTER TABLE `Datas_Scan` DISABLE KEYS */;
INSERT INTO `Datas_Scan` VALUES ('0000000_0','RRRRRRRRRR','00','Test','PF interne','x','ddd',9999,'Bac'),('1062926_A','1062926S01','00','Douille a inserer m6','Composant','P','S',3000,'Carton'),('1071615_A','1071615S01','00','Entretoise Dia:11.4 Lg:18.8mm','Composant','P','H',1500,'Carton'),('1079892_A','1079892S01','00','Ressort de soupape','Composant','P','S',4000,'Carton'),('1079893_A','1079893S01','00','Ressort de came','Composant','P','S',5000,'Carton'),('1079896_A','1079896S01','00','Ressort thermostat','Composant','P','S',650,'Bac'),('1079908_A','1079908S01','00','Axe de came','Composant','P','S',4500,'Carton'),('1079909_A','1079909S05','00','Joint dynamique LJF - 6EP3024','Composant','P','S',3220,'Carton'),('1079915_A','1079915S02','00','Vis autoformeuse actionneur','Composant','P','H',1650,'Bac'),('1102635_A','1102635S49','00','Valve aero bp nue 2-2368','Composant','P','S',1600,'Bac'),('1102635_B','1102635S48','00','Valve aero ass. 2-2368','PSF interne','30S','S',1600,'Bac'),('1102636_A','1102636S49','00','Valve radia nue 2-2368','Composant','P','S',800,'Bac'),('1102636_B','1102636S48','00','Valve radia ass. 2-2368','PSF interne','30S','S',800,'Bac'),('1102637_A','1102637S01','00','Joint aero','Composant','P','S',2500,'Bac'),('1102638_A','1102638S01','00','Joint radia','Composant','P','S',1500,'Bac'),('1104070_A','1104070S01','00','Rotule','Composant','P','S',6000,'Carton'),('1206731_A','1206731S01','00','Corps 2-2426','PSF interne','P','S',24,'Bac'),('1206733_A','1206733S50','00','Soupape radiateur 2-2430','PSF injecte','30S','S',500,'Bac'),('1206733_B','1206733S48','00','Soupape radiateur ass. 2-2430 (1/3)','PSF interne','30S','S',500,'Bac'),('1206733_C','1206733S46','00','Soupape radiateur Ass. 2-2453','PSF injecte','30S','S',500,'Bac'),('1206733_D','1206733S56','00','Soupape radiateur ass.  2-2453 (1/2)','PSF interne','30S','S',500,'Bac'),('1206739_A','1206739S48','00','Valve aero ass. 2-2430 (2/3)','PSF interne','30S','S',1000,'Bac'),('1206739_B','1206739S50','00','Valve aero 2-2430','PSF injecte','30S','S',1000,'Bac'),('1206859_A','1206859S48','00','Distributeur ass. 2-2427 ','PSF interne','30S','S',24,'Bac'),('1206859_B','1206859S01','00','Distributeur nu 2-2427 ','PSF injecte','P','S',32,'Bac'),('1206946_A','1206946S01','00','Chapeau de came 2-2429','Composant','P','S',70,'Bac'),('1206947_A','1206947S01','00','Aimant','Composant','P','S',5700,'Carton'),('1206949_A','1206949S01','00','Came 2-2428','PSF injecte','P','S',160,'Bac'),('1206955_A','1206955S01','00','Actionneur','Composant','P','S',280,'Bac'),('1207024_A','1207024S51','00','ACT NewU COREE','PF interne','30S','S',150,'Caisse_Carton'),('1207024_B','1207024S53','00','Palette NewU SLOVAQUIE','PF interne','BC_','M',150,'Palette'),('1207024_C','1207024S53','00','ACT NewU SLOVAQUIE','PF interne','30S','S',10,'Carton'),('1207516_A','1207516S01','00','Body gasket joint noir','Composant','P','S',150,'Bac'),('1207558_A','1207558S02','00','Platine principale','Composant','P','S',600,'Carton'),('1207563_A','1207563S01','00','Cylinder gasket orange','Composant','P','S',300,'Carton'),('1207722_A','1207722S01','00','Joints petites soupapes (valve)','Composant','P','S',2500,'Bac'),('1207742_A','1207742S01','00','Thermostat','Composant','P','S',350,'Bac'),('1207744_A','1207744S01','00','Temperature sensor inzi 90deg','Composant','P','S',585,'Carton'),('1207745_A','1207745S01','00','Temperature sensor clamp','Composant','P','H',1000,'Bac'),('1212686_A','1212686S02','00','Palier de guidage inox','Composant','P','S',1000,'Bac'),('1219856_A','1219856S91','00','ACT Nu NA1 - 2-2450','PF interne','30S','S',120,'Caisse_Carton'),('1219856_B','1219856V91','00','ACT Nu NA2 - 2-2450','PF interne','30S','S',120,'Caisse_Carton'),('1220024_A','1220024S48','00','Soupape bloc ass - 2-2449 (1/3)','PSF interne','30S','S',1000,'Bac'),('1220024_B','1220024S50','00','Soupape bloc - 2-2449','PSF injecte','30S','S',1000,'Bac'),('1225993_A','1225993S01','00','Cylinder head gasket serie','Composant','P','S',100,'Bac'),('1225994_A','1225994S47','00','Corps ass. 2-2450 - NA1','PSF interne','30S','S',22,'Bac'),('1225994_B','1225994S01','00','Corps 2-2450','PSF injecte','P','S',27,'Bac'),('1225994_C','1225994V47','00','Corps ass. 2-2450 - NA2','PSF interne','30S','S',22,'Bac'),('1225995_A','1225995S03','00','Spring holder Platine','Composant','P','S',250,'Carton'),('1225998_A','1225998S01','00','Distributeur nu 2-2451','PSF injecte','P','S',48,'Bac'),('1225999_A','1225999S01','00','Body gasket serie','Composant','P','S',100,'Bac'),('1226004_A','1226004S02','00','Spigot to radia serie','Composant','P','S',160,'Bac'),('1226005_A','1226005S02','00','Spigot to heater - NA1','Composant','P','S',480,'Bac'),('1226005_B','1226005V02','00','Spigot to heater - NA2','Composant','P','S',480,'Bac'),('1226080_A','1226080S02','00','Corps 2-2446','PSF injecte','P','S',16,'Carton'),('1226081_A','1226081S01','00','Distributeur nu 2-2447 MH','PSF injecte','P','S',48,'Bac'),('1226081_B','1226081S03','00','Distributeur nu 2-2447 Dedienne','PSF injecte','P','S',48,'Bac'),('1226082_A','1226082S02','00','Cylinder head gasket','Composant','P','S',100,'Carton'),('1226083_A','1226083S01','00','Body gasket','Composant','P','S',100,'Bac'),('1226084_A','1226084S04','00','Spring holder','Composant','P','S',350,'Carton'),('1226087_A','1226087S03','00','Spigot to heater - new weld','Composant','P','S',160,'Bac'),('1226089_A','1226089S06','00','Spigot to oil - new weld','Composant','P','S',160,'Bac'),('1226090_A','1226090S04','00','Collector body','Composant','P','S',40,'Carton'),('1229703_A','1229703S92','00','ACT Theta III - GDI','PF interne','30S','S',96,'Caisse_Carton'),('1229703_B','1229703V92','00','ACT Theta III - TGDI','PF interne','30S','S',96,'Caisse_Carton'),('1229712_A','1229712S01','00','Came 2-2452','PSF injecte','P','S',160,'Bac'),('1231459_A','1231459S01','00','Valve block / heater o-ring','Composant','P','S',2500,'Bac'),('1231785_A','1231785S01','00','Rondelle de glissement','Composant','P','H',2100,'Carton'),('1232641_A','1232641S48','00','Corps ass. 2-2446','PSF interne','30S','S',16,'Bac'),('1232642_A','1232642S01','00','Entretoise Dia:11.4 Lg:48mm','Composant','P','S',400,'Carton'),('1239406_A','1239406S01','00','Wax thermostat','Composant','P','S',306,'Carton'),('1242860_A','1242860S03','00','Spigot to radiator- new weld','Composant','P','S',160,'Bac'),('1242959_A','1242959S01','00','Compression Spring Thermostat','Composant','P','S',1000,'Bac'),('1243229_A','1243229S01','00','Came GDI 2-2448','PSF injecte','P','S',160,'Bac'),('1243229_B','1243229V01','00','Came TGDI','PSF injecte','P','S',160,'Bac'),('1244874_A','1244874S02','00','Spigot to ATF warner','Composant','P','S',480,'Bac'),('1245503_A','1245503S48','00','Oil valve ass. 2-2453','PSF interne','30S','S',1000,'Bac'),('1246914_A','1246914S04','00','Spigot from heater mass prod','Composant','P','S',480,'Bac'),('1247983_A','1247983S48','00','Soupape heater ass - 2-2449 (1/3)','PSF interne','30S','S',1000,'Bac'),('1247983_B','1247983S50','00','Soupape heater - 2-2449','PSF injecte','30S','S',1000,'Bac'),('1248546_A','1248546S49','00','Return  pipe collector assy','PSF injecte','30S','S',26,'Bac'),('1252396_A','1252396S48','00','Radiator valve ass - 2-2449 (1/3)','PSF interne','30S','S',500,'Bac'),('1252396_B','1252396S49','00','Radiator valve 2-2449','PSF injecte','30S','S',500,'Bac'),('1253657_A','1253657S01','00','Griffe platine','Composant','P','H',4000,'Carton'),('1256151_A','1256151S01','00','Spring holder bloc','Composant','P','S',2700,'Carton'),('1257677_A','1257677S01','00','Pilot pin','Composant','P','S',10000,'Carton'),('1275342_A','1275342S49','00','Distributeur ass. GDI 2-2447','PSF interne','30S','S',36,'Bac'),('1275342_B','1275342V49','00','Distributeur ass. TGDI 2-2447','PSF interne','30S','S',36,'Bac'),('1275343_A','1275343S49','00','Distributeur ass. GDI 2-2447 OLD','PSF interne','30S','S',36,'Bac'),('1275343_B','1275343V48','00','Distributeur ass. TGDI 2-2447 OLD','PSF interne','30S','S',36,'Bac'),('1275445_A','1275445S48','00','Distributeur ass. 2-2451','PSF interne','30S','S',30,'Bac'),('1289106_A','1289106S02','00','Platine bloc assemblee','Composant','P','S',800,'Carton'),('1291745_A','1291745S01','00','Valve radiator gasket d shape 1','Composant','P','S',1000,'Bac'),('1292724_A','1292724S01','00','Ressort de compression','Composant','P','S',3000,'Bac'),('1310494_A','1310494S01','00','Bearing lip seal','Composant','P','S',15000,'Carton'),('2000026_A','2000026S01','01','Metal Clip','Composant','P','S',40000,'Carton');
/*!40000 ALTER TABLE `Datas_Scan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `Machines`
--

LOCK TABLES `Machines` WRITE;
/*!40000 ALTER TABLE `Machines` DISABLE KEYS */;
INSERT INTO `Machines` VALUES (19001,'BC 800 vissage','Simrad','0900','LA32'),(19002,'BC Etancheite','Simrad','0900','LA17'),(19003,'Soudeuse rotation','Sonimat','0900','LA17'),(19004,'Soudeuse US','Mecasonic','0900','LA17'),(19005,'BC 800 vissage','Simrad','0900','LA21'),(19006,'BC 800 vissage','Simrad','0900','LA31'),(19024,'BC 800 assemblage','Simrad','0900','PROT'),(19025,'Soudeuse rotation','Sonimat','0900','LA10'),(19026,'Soudeuse rotation','Sonimat','0900','LA10'),(19027,'Soudeuse rotation','Sonimat','0900','LA10'),(19028,'BC 800 vissage','Simrad','0900','LA32'),(19048,'Coffret tracabilite','Simrad','0900','LA12'),(19049,'Coffret tracabilite','Simrad','0900','LA13'),(19050,'Coffret tracabilite','Simrad','0900','LA10'),(20011,'Cabine marquage laser','Simrad','0900','LA16'),(51197,'Kitting soupapes','AMU','0900','LA14'),(51575,'Base modulaire robot','Teknics','0900','LA32'),(51576,'Base modulaire robot','Teknics','0900','LA32'),(51577,'Base modulaire 3 axes','AMU','0900','LA32'),(51578,'Base modulaire 3 axes','AMU','0900','LA32'),(51610,'Soudeuse rotation','Mecasonic','0900','LA12'),(51651,'BC 800 assemblage','Simrad','0900','LA16'),(51652,'BC 800 assemblage','Simrad','0900','LA15'),(51653,'BC 800 assemblage','Simrad','0900','LA32'),(51670,'Kitting cames','Tecma','0900','LA15'),(51671,'BC 800 assemblage','Simrad','0900','LA15'),(51672,'BC 800 assemblage','Simrad','0900','LA15'),(51694,'Base modulaire 3 axes','AMU','0900','LA21'),(51695,'Base modulaire 3 axes','AMU','0900','LA21'),(51760,'BC 800 assemblage','Simrad','0900','LA21'),(51761,'BC 800 assemblage','Simrad','0900','LA31'),(51762,'BC 800 vissage','Simrad','0900','LA21'),(51781,'Base modulaire 3 axes','AMU','0900','LA31'),(51782,'Base modulaire 3 axes','AMU','0900','LA31'),(51783,'Base modulaire robot','Teknics','0900','LA31'),(51784,'Base modulaire robot','Teknics','0900','LA31'),(51803,'Soudeuse rotation','Sonimat','0900','LA15'),(51804,'Soudeuse rotation','Mecasonic','0900','LA12'),(51805,'Soudeuse rotation','Mecasonic','0900','LA12'),(51806,'Soudeuse rotation','Mecasonic','0900','LA13'),(51807,'Soudeuse rotation','Mecasonic','0900','LA13'),(51808,'Soudeuse rotation','Mecasonic','0900','LA13'),(51809,'Soudeuse rotation','Sonimat','0900','LA11'),(51811,'Base modulaire robot','Teknics','0900','LA21'),(51812,'Base modulaire robot','Teknics','0900','LA21'),(51822,'Soudeuse US','Mecasonic','0900','LA11'),(51875,'Armoire tracabilite','Simrad','0900','LA32'),(51876,'Armoire tracabilite','Simrad','0900','LA21'),(51877,'Armoire tracabilite','Simrad','0900','LA31'),(51940,'Soudeuse rotation','Sonimat','0900','LA16'),(51993,'BC Etancheite','Simrad','0900','LA11'),(52009,'BC 800 assemblage','Simrad','0900','PROT');
/*!40000 ALTER TABLE `Machines` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-11-25 13:55:56
