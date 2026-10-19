import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

/// L'app Mail (ou un compte de courrier) est-elle prête à écrire un message ? Sert à décider si on ouvre le `mailto:` du signalement.
/// ⚠ à vérifier sur iPhone : `MFMailComposeViewController.canSendMail()` est faux sans compte Mail configuré, même si un autre client de courrier
/// est installé. Repli volontaire : sans Mail, on n'ouvre rien (le signalement en base reste le circuit principal), jamais d'erreur affichée.
enum CourrielDisponible {
    static var estPret: Bool {
        #if canImport(MessageUI)
        return MFMailComposeViewController.canSendMail()
        #else
        return false
        #endif
    }
}

/// L'écran de signalement, commun à tous (profil, ami, carte d'ami) : choisir un motif parmi `MotifSignalement`, puis dire la VÉRITÉ.
/// - « Merci, c'est signalé » seulement si l'enregistrement `Signalement` est bien en base (`ResultatSignalement.enregistre`) ;
/// - sinon « Pas enregistré, réessaie » avec un bouton « Réessayer » ;
/// - le brouillon d'e-mail (`mailto:`) ne s'ouvre que si Mail est prêt, et rien ne dit jamais qu'il est parti.
struct SignalerAvecMotifs<Cible: Identifiable>: ViewModifier {
    @Binding var cible: Cible?
    let question: (Cible) -> String
    /// Vrai si le signalement masque aussi la cible chez moi (un profil, un ami) ; faux pour une carte.
    let masque: (Cible) -> Bool
    let envoyer: (Cible, MotifSignalement) async -> ResultatSignalement
    let courriel: (Cible, MotifSignalement) -> URL?
    var apres: (Cible, ResultatSignalement) -> Void = { _, _ in }

    @Environment(\.openURL) private var ouvrirURL
    @State private var retour: Retour?

    private struct Retour {
        let cible: Cible
        let motif: MotifSignalement
        let resultat: ResultatSignalement
    }

    func body(content: Content) -> some View {
        content
            .confirmationDialog(cible.map(question) ?? "", isPresented: motifsAffiches, titleVisibility: .visible, presenting: cible) { choisie in
                ForEach(MotifSignalement.allCases) { motif in
                    Button(motif.titre) { lancer(choisie, motif) }
                }
                Button("Annuler", role: .cancel) {}
            }
            .alert(retour?.resultat.titre ?? "", isPresented: alerteAffichee) {
                if let retour, retour.resultat == .nonEnregistre {
                    Button("Réessayer") { lancer(retour.cible, retour.motif) }
                }
                Button("OK", role: .cancel) {}
            } message: {
                if let retour { Text(retour.resultat.message(masque: masque(retour.cible))) }
            }
    }

    private var motifsAffiches: Binding<Bool> {
        Binding(get: { cible != nil }, set: { if !$0 { cible = nil } })
    }

    private var alerteAffichee: Binding<Bool> {
        Binding(get: { retour != nil }, set: { if !$0 { retour = nil } })
    }

    private func lancer(_ choisie: Cible, _ motif: MotifSignalement) {
        Task {
            let resultat = await envoyer(choisie, motif)
            retour = Retour(cible: choisie, motif: motif, resultat: resultat)
            apres(choisie, resultat)
            // Le brouillon d'e-mail est un complément : seulement si Mail est prêt, et sans rien affirmer sur son envoi.
            if CourrielDisponible.estPret, let url = courriel(choisie, motif) { ouvrirURL(url) }
        }
    }
}

extension View {
    func signalerAvecMotifs<Cible: Identifiable>(
        cible: Binding<Cible?>, question: @escaping (Cible) -> String, masque: @escaping (Cible) -> Bool,
        envoyer: @escaping (Cible, MotifSignalement) async -> ResultatSignalement,
        courriel: @escaping (Cible, MotifSignalement) -> URL?,
        apres: @escaping (Cible, ResultatSignalement) -> Void = { _, _ in }
    ) -> some View {
        modifier(SignalerAvecMotifs(cible: cible, question: question, masque: masque, envoyer: envoyer, courriel: courriel, apres: apres))
    }
}
