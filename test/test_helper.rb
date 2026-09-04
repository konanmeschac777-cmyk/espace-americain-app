ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/library_test_helper"

module ActiveSupport
  class TestCase
    # Là où Ruby sait dupliquer un processus (Linux, donc le CI), chaque
    # worker reçoit sa propre base de test et les tests se répartissent.
    #
    # Sous Windows, Process.fork n'existe pas : Rails retombe alors sur des
    # threads qui se partagent une seule base SQLite, et les fixtures
    # transactionnelles finissent par ouvrir une transaction dans une autre
    # ("cannot start a transaction within a transaction"). La suite échouait
    # alors au hasard, sur des tests pourtant justes. Elle tourne en quelques
    # secondes : mieux vaut la passer en séquentiel que la rendre douteuse.
    parallelize(workers: Process.respond_to?(:fork) ? :number_of_processors : 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Fabrique les prêts, qui ne peuvent pas vivre en fixtures : ils se
    # définissent toujours par rapport à aujourd'hui.
    include LibraryTestHelper
  end
end
