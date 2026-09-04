# Fabrique les prêts dont les tests ont besoin.
#
# Les prêts ne sont pas en fixtures parce qu'ils n'existent qu'en relation
# à aujourd'hui : un prêt sert à vérifier un retard de six jours, une
# échéance à deux jours, un oubli de deux mois. Une fixture figée dirait
# autre chose chaque semaine.
module LibraryTestHelper
  # Un prêt en cours. `en_retard_de` et `du_dans` posent l'échéance sans
  # attendre : ce sont les deux situations que le comptoir traite.
  def pret_en_cours(book:, member:, en_retard_de: nil, du_dans: nil, borrowed_on: nil)
    due_on =
      if en_retard_de then Date.current - en_retard_de
      elsif du_dans   then Date.current + du_dans
      end

    borrowed_on ||= (due_on || Date.current) - Setting.loan_days

    Loan.create!(
      book: book,
      member: member,
      borrowed_on: borrowed_on,
      due_on: due_on || borrowed_on + Setting.loan_days
    )
  end

  # Un prêt déjà rendu, pour les historiques et les compteurs.
  def pret_rendu(book:, member:, rendu_le: Date.current, en_retard_de: 0)
    Loan.create!(
      book: book,
      member: member,
      borrowed_on: rendu_le - Setting.loan_days - en_retard_de,
      due_on: rendu_le - en_retard_de,
      returned_on: rendu_le
    )
  end
end
