import { Controller } from "@hotwired/stimulus"

// Tiroir de navigation (écran 24). Un seul tiroir existe dans la page,
// posé sur <body> : n'importe quel bouton menu, où qu'il soit dans le
// DOM, peut l'ouvrir via data-action="click->tiroir#ouvrir".
export default class extends Controller {
  ouvrir() {
    this.element.classList.add("tiroir-ouvert")
  }

  fermer() {
    this.element.classList.remove("tiroir-ouvert")
  }

  // Un clic sur le voile ferme, un clic dans le panneau ne doit pas
  // remonter jusqu'au voile.
  arreter(event) {
    event.stopPropagation()
  }
}
