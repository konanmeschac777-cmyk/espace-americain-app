import { Controller } from "@hotwired/stimulus"

// Bascule l'affichage du mot de passe en clair. Sans ce script, le champ
// reste un simple input password : on perd juste le bouton "Afficher".
// Les deux libellés viennent de la vue (data-afficher/data-masquer,
// traduits) plutôt que d'être codés en dur ici.
export default class extends Controller {
  static targets = [ "champ", "bouton" ]

  basculer() {
    const masque = this.champTarget.type === "password"
    this.champTarget.type = masque ? "text" : "password"
    this.boutonTarget.textContent = masque
      ? this.boutonTarget.dataset.masquer
      : this.boutonTarget.dataset.afficher
  }
}
