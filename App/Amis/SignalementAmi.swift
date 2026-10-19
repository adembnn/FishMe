import SwiftUI

/// Ce que la personne signale depuis la page Amis : un ami, ou une carte d'ami.
enum CibleAmi: Identifiable {
    case ami(Ami)
    case carte(Ami, CartePartagee)

    var id: String {
        switch self {
        case .ami(let ami): "ami-\(ami.id)"
        case .carte(_, let carte): "carte-\(carte.id.uuidString)"
        }
    }

    var ami: Ami {
        switch self {
        case .ami(let ami), .carte(let ami, _): ami
        }
    }
}

extension View {
    /// Signaler un ami ou une carte d'ami : mêmes motifs (`MotifSignalement`), même honnêteté que pour un profil.
    /// « Signalé » seulement si l'enregistrement est en base ; l'ami est masqué chez moi tout de suite ; l'e-mail n'est qu'un complément si Mail est prêt.
    func signalerDansAmis(cible: Binding<CibleAmi?>, gestion: GestionAmis, profil: GestionProfil) -> some View {
        signalerAvecMotifs(
            cible: cible,
            question: { c in
                switch c {
                case .ami(let ami): "Pourquoi signaler \(ami.nom) ?"
                case .carte: "Pourquoi signaler cette carte ?"
                }
            },
            masque: { c in
                if case .ami = c { return true }
                return false
            },
            envoyer: { c, motif in
                switch c {
                case .ami(let ami):
                    // Masquage immédiat et local, comme pour un profil ; la relation de partage n'est pas coupée (ce n'est pas un blocage).
                    gestion.masquerApresSignalement(ami)
                    return await profil.signaler(cible: GestionAmis.cleDeBlocage(ami), type: .ami, motif: motif, masquer: false)
                case .carte(_, let carte):
                    return await profil.signaler(cible: carte.id.uuidString, type: .carte, motif: motif, masquer: false)
                }
            },
            courriel: { c, motif in
                switch c {
                case .ami(let ami): gestion.urlDeSignalement(ami: ami, motif: motif)
                case .carte(let ami, let carte): gestion.urlDeSignalement(ami: ami, carte: carte, motif: motif)
                }
            })
    }
}
