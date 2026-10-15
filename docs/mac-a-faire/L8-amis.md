# L8 Amis : ce que le Mac doit faire (lot/amis, 574045f, non compilé ; après l'étiquette v1.0-soumise)
1. Capacité iCloud + CloudKit, conteneur iCloud.ai.mwm.build.challenge.team.01 (ne pas toucher l'identifiant de l'app).
2. Clé Info CKSharingSupported = YES (Info.plist de compléments si GENERATE_INFOPLIST_FILE).
3. BuildChallengeApp.swift : @UIApplicationDelegateAdaptor(AdaptateurPartage.self) var adaptateur.
4. RootView / Mon club : GestionAmis(ServiceAmisCloudKit(configuration: ConfigurationAmis(contact: <e-mail du Club>)), FileEnvoi(dossier: FileEnvoi.dossierParDefaut()), CacheAmis(conteneur: try CacheAmis.creerConteneur(), dossierImages: CacheAmis.dossierParDefaut()), CollectionCartes de L4, ServiceEspeces) ; afficher AmisView(gestion:) ; appeler gestion.synchroniserMesCartes() après chaque nouvelle carte.
5. À compiler d'abord (écrit de mémoire) : CKAllowedSharingOptions (.readOnly, .specifiedRecipientsOnly), CKShareTransferRepresentation .prepareShare dans AmisView.swift, RelaisInvitations.swift (adaptateur de scène), @Model nonisolated final class, quitterPartage.
6. JetonAmis (palette en dur) à remplacer par Palette.* une fois D0 fusionné.
7. Avant TestFlight : Deploy Schema Changes vers Production. Test sur deux iPhones, deux comptes iCloud.
