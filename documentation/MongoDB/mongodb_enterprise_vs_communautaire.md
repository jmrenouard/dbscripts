Voici le document complété avec les informations supplémentaires fournies :

---

## MongoDB Community vs Enterprise Comparison

### Introduction
MongoDB offre deux éditions principales : Community et Enterprise. Bien que les deux éditions fournissent des fonctionnalités robustes, elles s'adressent à des besoins et des cas d'utilisation différents.

### Fonctionnalités de Base

#### MongoDB Community Edition
- **Version gratuite et open-source** de MongoDB.
- **Pas de limitations artificielles** en termes de mémoire, de stockage ou d'évolutivité.
- **Capacités de failover et de réplication**.
- **Sécurité de base** comme le contrôle d'accès basé sur les rôles.

#### MongoDB Enterprise Edition
- **Version payante** qui inclut des fonctionnalités supplémentaires pour les entreprises.
- **MongoDB Management Service (MMS)** : Solution de sauvegarde et de surveillance.
- **Surveillance SNMP** : Pour la gestion réseau.
- **Sécurité avancée** : Options comme Kerberos ou LDAP pour l'authentification.
- **Licence de développement commerciale** : Permet de modifier MongoDB sans respecter les termes AGPL.
- **BI Connector** : Ajoute une compatibilité limitée avec SQL pour l'intégration avec des outils de Business Intelligence basés sur SQL.
- **MongoDB Compass** : Outil GUI pour la visualisation des données, gratuit depuis avril 2020.
- **Moteur de stockage en mémoire** : Pour un accès plus rapide aux données (encore en bêta en version 3.2).
- **Moteur de stockage chiffré** : Pour protéger les données au repos.
- **Support et formation** : Accès aux services de support et de formation de MongoDB.

### Fonctionnalités Avancées

#### MongoDB Enterprise Server
- **Visibilité opérationnelle et contrôle** : Fonctionnalités supplémentaires pour une meilleure visibilité et contrôle opérationnel.
- **Sécurité des données et conformité** : Fonctionnalités de sécurité avancées construites sur une infrastructure de sécurité complète, incluant le contrôle d'accès basé sur les rôles, les certificats x.509, TLS, etc.
- **Configuration FIPS 140-2** : MongoDB peut être configuré pour fonctionner avec une bibliothèque OpenSSL certifiée FIPS 140-2 par défaut ou via la ligne de commande.
- **Moteur de stockage chiffré** : Fournit un chiffrement natif des données au repos dans le stockage et les sauvegardes, éliminant la complexité et le surcoût d'intégrer des options de chiffrement.
- **Authentification Kerberos et LDAP** : Permet de défendre, détecter et contrôler l'accès aux données.
- **Audit granulaire** : Permet aux administrateurs de suivre l'activité système pour des déploiements avec plusieurs utilisateurs et applications, avec des capacités d'audit pour les schémas, les ensembles de réplication et les clusters fragmentés, les accès et les opérations CRUD.
- **Chiffrement automatique au niveau des champs côté client** : Fournit les contrôles de confidentialité et de sécurité les plus forts. Les pilotes MongoDB chiffrent les champs sensibles dans les documents avant qu'ils ne quittent l'application.

#### Support Entreprise
- **Support de niveau entreprise** : Accès à des experts proactifs et consultatifs de la phase de développement à la production.
- **Ingénieurs Techniques** : Fournissent plus que des solutions de dépannage. Ils peuvent vous guider sur les mises à jour, les plans de déploiement, la configuration et l'optimisation, les nouvelles fonctionnalités, etc.
- **Questions illimitées** : Votre équipe peut poser un nombre illimité de questions, 24h/24, 7j/7, globalement, avec un SLA de réponse de 1 heure.
- **Patches d'urgence** : Inclut des patches d'urgence pour MongoDB.
- **Succès client** : Fournit un processus d'intégration initiale, ainsi que des vérifications périodiques tout au long de l'année pour vous assurer que vous êtes informé des dernières fonctionnalités, mises à jour, événements et ressources nécessaires pour réussir avec MongoDB.
- **MongoDB University** : Bibliothèque de formation à la demande. Les équipes de développement et d'exploitation peuvent améliorer leurs compétences MongoDB et apprendre les nouvelles fonctionnalités et produits à leur convenance.

### Cas d'Utilisation

#### MongoDB Community Edition
- **Développement et tests** : Idéal pour les développeurs ayant besoin d'une base de données gratuite et open-source pour construire et tester des applications.
- **Petits à moyens projets** : Projets qui n'ont pas besoin de fonctionnalités de sécurité avancées, de surveillance ou de support.

#### MongoDB Enterprise Edition
- **Environnements de production** : Particulièrement lorsque la sécurité des données, la conformité et le support sont critiques.
- **Déploiements à grande échelle** : Entreprises ayant besoin de fonctionnalités avancées comme le stockage chiffré, le stockage en mémoire et une surveillance complète.
- **Business Intelligence** : Organisations nécessitant une intégration avec des outils BI basés sur SQL.

### Licences

- **MongoDB Community Edition** : Sous licence GNU AGPL v3.0. Toute modification du code source de MongoDB doit être open-source si la base de données est accédée sur un réseau.
- **MongoDB Enterprise Edition** : Offre une licence commerciale permettant des modifications propriétaires sans obligation de divulguer le code source.

### Conclusion

Bien que l'édition Community fournisse toutes les fonctionnalités essentielles pour exécuter une base de données MongoDB, l'édition Enterprise offre des outils et services supplémentaires bénéfiques pour les applications de niveau entreprise et les environnements de production. Le choix entre les deux dépend des besoins spécifiques et de l'échelle de votre projet.

---

**Contact Information:**
- **Email:** info@mongodb.com
- **© 2021 MongoDB, Inc. All rights reserved.**