import { Controller } from "@hotwired/stimulus"

// Le champ libre « Autre » du formulaire d'abonné : masqué tant que le
// bibliothécaire n'a pas choisi « Autre » dans la liste.
//
// Rien ne dépend de ce script pour que la saisie aboutisse : le serveur
// n'enregistre jamais la valeur sentinelle « autre » toute seule, il la
// remplace par le texte saisi à côté, ou par rien.
export default class extends Controller {
  static targets = ["choix", "autre", "champAutre"]
  static values = { sentinelle: String }

  connect() {
    this.afficher()
  }

  // Sur changement de la liste : on montre ou cache, et on place le
  // curseur dans le champ qui vient d'apparaître pour éviter un tap de
  // plus au comptoir.
  basculer() {
    this.afficher()

    if (!this.autreTarget.hidden) this.champAutreTarget.focus()
  }

  afficher() {
    this.autreTarget.hidden = this.choixTarget.value !== this.sentinelleValue
  }
}
