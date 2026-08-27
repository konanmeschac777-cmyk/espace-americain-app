import { Controller } from "@hotwired/stimulus"

// Aperçu de la cote de rangement pendant la saisie d'un nouvel ouvrage.
// Chaque <option> de catégorie porte sa cote et son libellé de rayon en
// attributs data-*, calculés côté serveur : ce script ne fait que les
// recopier à l'écran, il n'invente aucun numéro.
export default class extends Controller {
  static targets = ["categorie", "cote", "rayon", "champCache"]

  connect() {
    this.actualiser()
  }

  actualiser() {
    const option = this.categorieTarget.selectedOptions[0]
    const cote = option?.dataset.cote || "—"
    const rayon = option?.dataset.rayon || "Choisis une catégorie"

    this.coteTarget.textContent = cote
    this.rayonTarget.textContent = rayon
    this.champCacheTarget.value = option?.value ? cote : ""
  }
}
