# Atlart

Application mobile Flutter pour découvrir les œuvres et l’artisanat du Maghreb.

## Mode aperçu front-end (par défaut)

L’authentification Laravel est désactivée par défaut pour permettre de
continuer le développement front-end sans serveur. La connexion accepte les
identifiants saisis comme compte de démonstration ; l’inscription crée une
session locale et permet de prévisualiser le rôle choisi. Ces sessions ne sont
pas des comptes réels. En particulier, seul le serveur pourra confirmer un
changement de rôle après une candidature.

## Connexion à l’API Laravel (à réactiver plus tard)

L’application utilise les routes Laravel suivantes :

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`

L’intégration Flutter ci-dessous est conservée, mais ne fait aucun appel réseau
tant que le backend n’est pas disponible. Pour la réactiver, lancez avec
`ATLART_USE_BACKEND=true` et configurez l’URL. Par défaut, l’URL est
`http://10.0.2.2:8000/api`, l’adresse de la machine hôte vue depuis un
émulateur Android :

```powershell
flutter run --dart-define=ATLART_USE_BACKEND=true --dart-define=API_URL=http://10.0.2.2:8000/api
```

Depuis un appareil physique, remplacez `10.0.2.2` par l’adresse IP locale de
l’ordinateur exécutant l’API. Utilisez HTTPS en production. Le trafic HTTP en
clair est autorisé uniquement dans la configuration Android de debug.

Les inscriptions envoient le rôle choisi comme `role_souhaite` ; le compte créé
par le serveur reste `visiteur` jusqu’à une éventuelle candidature acceptée.
Quand le backend sera prêt, les appels register/login/me/logout et la session
sécurisée seront réactivés avec cette option. Sans elle, aucune requête
Laravel, notamment `/auth/me` au démarrage, n’est envoyée.
