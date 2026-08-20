import { Controller } from "@hotwired/stimulus"

// Lance la recherche pendant la frappe, sans attendre le bouton.
//
// Deux garde-fous, parce que le bibliothécaire travaille sur un téléphone
// et une connexion mobile :
//
// - un délai après la dernière touche, pour n'envoyer qu'une requête par
//   mot tapé plutôt qu'une par lettre. Taper « Diarra » déclenche une
//   requête, pas six.
// - un minimum de caractères, pour ne pas ramener tout le fichier dès la
//   première lettre.
//
// Le bouton « Chercher » reste en place : si ce script ne se charge pas,
// l'écran continue de fonctionner exactement comme avant.
export default class extends Controller {
  static values = {
    delai: { type: Number, default: 300 },
    minimum: { type: Number, default: 2 }
  }

  connect() {
    this.timer = null
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  chercher(event) {
    clearTimeout(this.timer)

    const saisie = event.target.value.trim()

    // Champ vidé : on relance pour revenir à l'état de départ.
    // Sinon, on attend d'avoir assez de lettres pour que ce soit utile.
    if (saisie.length > 0 && saisie.length < this.minimumValue) return

    this.timer = setTimeout(() => this.element.requestSubmit(), this.delaiValue)
  }
}
