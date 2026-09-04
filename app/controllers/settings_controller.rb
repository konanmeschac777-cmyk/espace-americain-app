# Les règles du comptoir : durée d'un prêt, renouvellements, quota, durée
# d'adhésion, préfixe des cartes.
#
# Elles vivaient en base depuis le début mais ne se changeaient qu'en
# console, donc en pratique seulement depuis le poste serveur. Le
# responsable de l'Espace peut maintenant les régler depuis le comptoir.
#
# Aucun réglage ne touche aux prêts déjà enregistrés : une échéance est
# écrite dans le prêt au moment de l'emprunt. Passer de 14 à 21 jours ne
# rallonge pas les prêts en cours, cela vaut pour les suivants.
class SettingsController < ApplicationController
  def show
    @reglages = Setting.modifiables
  end

  def update
    @reglages = Setting.enregistrer(valeurs_saisies)

    if @reglages.all? { |reglage| reglage.errors.empty? }
      redirect_to reglages_path, notice: t("app.flash.reglages_enregistres")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  # On ne lit que les clés connues du modèle : une clé inventée dans la
  # requête ne doit pas pouvoir créer une ligne dans la table.
  def valeurs_saisies
    params.fetch(:reglages, {}).permit(*Setting::REGLAGES.keys).to_h
  end
end
