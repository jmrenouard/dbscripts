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
