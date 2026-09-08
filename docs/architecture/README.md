# Architecture de Gate

[Ouvrir le HTML autonome](architecture.html) · [Spécification Archify](architecture.archify.json)

Télécharger le HTML et l'ouvrir localement dans un navigateur : GitHub affiche son code et ne l'exécute pas. Aucun hébergement supplémentaire n'est nécessaire.

Vue compacte des composants du dépôt au commit `4055549df65719d81866804daad62c318ccc2553`. Les flèches représentent les opérations indiquées, pas une preuve de déploiement ni un graphe exhaustif des appels. Les composants secondaires sans flèche complètent l'inventaire ; leurs liens détaillés restent dans les sources ci-dessous.

Vue logique des modules ; fonctionnalités et fournisseurs dépendent de la configuration. Aucun trafic LLM ni validation de déploiement pendant cette documentation.

Le texte du diagramme est en français. Les commandes fixes du Viewer et l'attribut HTML `lang` restent en anglais, langue de repli d'Archify 2.17. Affichage statique initial, thèmes clair et sombre ; aucune animation activée.

![Aperçu de la carte](architecture-preview.png)

## Sources vérifiées

| Composant | Source au commit de référence |
| --- | --- |
| API Axum | [src/server/mod.rs:1–9](https://github.com/murillo-consulting/Gate/blob/4055549df65719d81866804daad62c318ccc2553/src/server/mod.rs#L1-L9) |
| Dispatch | [src/server/mod.rs:10–18](https://github.com/murillo-consulting/Gate/blob/4055549df65719d81866804daad62c318ccc2553/src/server/mod.rs#L10-L18) |
| Fournisseurs | [src/providers/mod.rs:1–9](https://github.com/murillo-consulting/Gate/blob/4055549df65719d81866804daad62c318ccc2553/src/providers/mod.rs#L1-L9) |
| Budget | [src/server/mod.rs:38–46](https://github.com/murillo-consulting/Gate/blob/4055549df65719d81866804daad62c318ccc2553/src/server/mod.rs#L38-L46) |
| Audit | [src/server/mod.rs:3–11](https://github.com/murillo-consulting/Gate/blob/4055549df65719d81866804daad62c318ccc2553/src/server/mod.rs#L3-L11) |
| Authentification | [src/server/mod.rs:57–65](https://github.com/murillo-consulting/Gate/blob/4055549df65719d81866804daad62c318ccc2553/src/server/mod.rs#L57-L65) |

## Reproduction

Prérequis : Node.js et le skill [Archify](https://github.com/tt-a1i/archify), version 2.17 (MIT). Depuis la racine du dépôt, remplacer `<ARCHIFY>` par le répertoire du skill installé :

```text
rtk node <ARCHIFY>/bin/archify.mjs validate architecture docs/architecture/architecture.archify.json --repo-root . --quality showcase --json
rtk node <ARCHIFY>/bin/archify.mjs deliver architecture docs/architecture/architecture.archify.json docs/architecture/architecture.html --repo-root . --quality showcase --json
rtk node <ARCHIFY>/bin/archify.mjs visual-check docs/architecture/architecture.html --json
```

La révision source doit être présente dans le clone pour vérifier les références. Après une modification du JSON, relancer les trois commandes puis inspecter les captures des deux thèmes. Ne pas éditer le HTML généré.

## Vérifications et limites

Validation et livraison : **9/9 contrôles showcase**, zéro erreur et zéro avertissement. Le reçu portable `acceptance.json` lie les octets exacts aux contrôles et distingue la preuve navigateur de la revue des images.

Les tests applicatifs ne sont pas relancés : seuls le JSON, le HTML, les preuves documentaires et le lien du README changent. Cette documentation n'établit pas la santé d'un service, la sécurité d'une installation ni une conformité réglementaire.

Retour arrière : retirer le lien du README et les cinq fichiers de cette documentation, ou révoquer son commit. Aucun changement applicatif ou déploiement n'est associé.
