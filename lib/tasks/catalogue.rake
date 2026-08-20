# Cotes de rangement.
#
#   bin/rails catalogue:coter          attribue les cotes manquantes
#   bin/rails catalogue:coter[force]   recalcule toutes les cotes
#   bin/rails catalogue:plan           affiche le plan de rangement
#
# Une cote est l'adresse du livre sur les étagères : COM-01, PRO-04. Elle
# sert surtout au rangement des retours. Sans elle, chacun range à sa
# logique et le fonds se mélange en quelques semaines.
#
# La numérotation suit l'ordre alphabétique des titres dans la catégorie,
# pour que l'étagère se lise de gauche à droite comme une liste.

namespace :catalogue do
  desc "Attribue les cotes de rangement manquantes. [force] recalcule tout."
  task :coter, [ :mode ] => :environment do |_task, args|
    force = args[:mode].to_s.casecmp("force").zero?

    # Deux catégories qui produiraient le même préfixe rendraient les cotes
    # ambiguës. Mieux vaut s'arrêter que créer deux rayons "COM".
    doublons = Category.all.group_by(&:shelf_prefix).select { |_p, cats| cats.size > 1 }
    unless doublons.empty?
      doublons.each { |prefixe, cats| puts "Conflit sur #{prefixe} : #{cats.map(&:name).join(', ')}" }
      abort "Préfixes en conflit, cotes non attribuées."
    end

    attribuees = 0
    conservees = 0

    Category.includes(:books).order(:slug).each do |category|
      category.books.order(:title).each_with_index do |book, index|
        cote = format("%s-%02d", category.shelf_prefix, index + 1)

        if book.shelf_mark.present? && !force
          conservees += 1
          next
        end

        book.update!(shelf_mark: cote)
        attribuees += 1
      end
    end

    puts "Cotes attribuées : #{attribuees}"
    puts "Cotes conservées : #{conservees}" if conservees.positive?
    puts "Sans cote        : #{Book.where(shelf_mark: nil).count}"
  end

  desc "Affiche le plan de rangement des étagères"
  task plan: :environment do
    Category.includes(:books).order(:slug).each do |category|
      livres = category.books.order(:shelf_mark)
      total = livres.sum(:total_copies)

      puts ""
      puts "#{category.shelf_prefix} | #{category.name}"
      puts "     #{livres.count} titre#{'s' if livres.count > 1}, #{total} exemplaires"
      puts "     " + "-" * 60

      livres.each do |book|
        cote = book.shelf_mark || "  ?   "
        puts format("     %-7s %-52s %2d ex.", cote, book.title.truncate(52), book.total_copies)
      end
    end
    puts ""
  end
end
