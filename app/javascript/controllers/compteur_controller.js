import { Controller } from "@hotwired/stimulus"

// Boutons - / + d'un champ nombre. Le champ reste modifiable au clavier,
// ces boutons ne sont qu'un raccourci pour le comptoir.
export default class extends Controller {
  static targets = ["champ"]

  incrementer() {
    this.changer(1)
  }

  decrementer() {
    this.changer(-1)
  }

  changer(delta) {
    const min = parseInt(this.champTarget.min || "1", 10)
    const valeur = parseInt(this.champTarget.value, 10) || min
    this.champTarget.value = Math.max(min, valeur + delta)
  }
}
