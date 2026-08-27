# Gestion du catalogue par le personnel.
#
# Le fonds a été importé depuis un fichier qui ne contenait que le titre et
# la quantité : une bonne partie des fiches n'a donc ni auteur confirmé ni
# cote de rangement. La file "à compléter" existe pour rattraper ça, fiche
# après fiche, sans revenir à la liste entre chacune.
class BooksController < ApplicationController
  RESULTS_LIMIT = 60

  def index
    @categories = Category.order(:name)
    @filtre = params[:categorie].presence || "toutes"
    @query = params[:q].to_s

    @compteur_completer = Book.active.needing_completion.count

    @books = case @filtre
    when "completer" then Book.active.needing_completion
    else current_category&.books&.active || Book.active
    end

    @books = @books.search(@query).by_title.includes(:category).limit(RESULTS_LIMIT)

    # Groupé par catégorie seulement dans la vue d'ensemble : dès qu'on
    # filtre ou qu'on cherche, une liste simple suffit et évite des
    # en-têtes de catégorie répétés pour un seul résultat.
    @groupes = @books.group_by(&:category).sort_by { |categorie, _| categorie.name } if @filtre == "toutes" && @query.blank?

    @total_titres = Book.active.count
    @total_copies = Book.active.sum(:total_copies)
  end

  # Fiche de l'ouvrage : ce qu'on voit avant de décider de la modifier.
  # Le catalogue mène ici, pas directement au formulaire, pour la même
  # raison que la fiche abonné existe déjà : consulter et modifier sont
  # deux gestes différents.
  def show
    @book = Book.find(params[:id])
  end

  def new
    # Ouvrage qui vient d'être ajouté : l'écran de succès (16) prend la
    # place, avec la cote et le total du fonds mis à jour.
    @confirmed_book = Book.find_by(id: params[:confirmed_book_id])
    return if @confirmed_book

    @categories = Category.order(:name)
    @book = Book.new(
      language: "fr",
      collection: "Nouveaux Horizons",
      received_on: Date.current,
      total_copies: 1,
      category_id: params[:category_id]
    )
  end

  def create
    @book = Book.new(book_params)
    @book.site = current_site
    @book.shelf_mark = @book.category.next_shelf_mark if @book.category

    if @book.save
      redirect_to new_book_path(confirmed_book_id: @book.id)
    else
      @categories = Category.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @book = Book.find(params[:id])
    @categories = Category.order(:name)
    @completer = queue_mode?

    if @completer
      @queue = Book.active.needing_completion.by_title.to_a
      @position = @queue.index(@book)
    end
  end

  def update
    @book = Book.find(params[:id])
    @completer = queue_mode?

    if @book.update(book_params)
      redirect_to next_destination
    else
      @categories = Category.order(:name)
      if @completer
        @queue = Book.active.needing_completion.by_title.to_a
        @position = @queue.index(@book)
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def archive
    book = Book.find(params[:id])
    book.update!(active: false)
    redirect_to books_path, notice: t("app.flash.livre_archive", titre: book.title)
  end

  private

  def current_category
    @categories.find { |c| c.slug == @filtre }
  end

  def queue_mode? = ActiveModel::Type::Boolean.new.cast(params[:completer])

  # Après un enregistrement en mode file : direction la fiche suivante à
  # compléter, ou la liste si la file est vide. Hors mode file, retour
  # simple à la liste.
  def next_destination
    return books_path unless @completer

    restantes = Book.active.needing_completion.by_title.to_a
    if restantes.any?
      cle = restantes.size > 1 ? "app.flash.fiche_completee_restantes_plusieurs" : "app.flash.fiche_completee_restantes_un"
      flash[:notice] = t(cle, titre: @book.title, n: restantes.size)
      edit_book_path(restantes.first, completer: true)
    else
      flash[:notice] = t("app.flash.fiche_completee_terminee", titre: @book.title)
      books_path
    end
  end

  def book_params
    attrs = params.expect(book: [ :title, :author, :category_id, :language, :total_copies,
                                   :shelf_mark, :collection, :received_on, :summary, :cover ])
    # Un auteur saisi à l'écran est par définition confirmé : seul l'import
    # d'origine laisse un auteur deviné et non confirmé.
    attrs[:author_confirmed] = attrs[:author].present?
    attrs
  end

  # Le MVP ne sert que Tiassalé. Le jour où une autre antenne ouvre, c'est
  # ici que le site viendra de la session du bibliothécaire.
  def current_site
    @current_site ||= Site.active.first || Site.first
  end
end
