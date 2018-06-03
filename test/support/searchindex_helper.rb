require 'rake'

module SearchindexHelper

  def self.included(base)

    base.teardown do
      next if ENV['ES_URL'].blank?

      Rake::Task['searchindex:drop'].execute
    end
  end

  def configure_elasticsearch(required: false)
    if ENV['ES_URL'].blank?
      return if !required
      raise "ERROR: Need ES_URL - hint ES_URL='http://127.0.0.1:9200'"
    end

    Setting.set('es_url', ENV['ES_URL'])

    # Setting.set('es_url', 'http://127.0.0.1:9200')
    # Setting.set('es_index', 'estest.local_zammad')
    # Setting.set('es_user', 'elasticsearch')
    # Setting.set('es_password', 'zammad')

    if ENV['ES_INDEX_RAND'].present?
      ENV['ES_INDEX'] = "es_index_#{rand(999_999_999)}"
    end
    if ENV['ES_INDEX'].blank?
      raise "ERROR: Need ES_INDEX - hint ES_INDEX='estest.local_zammad'"
    end
    Setting.set('es_index', ENV['ES_INDEX'])

    # set max attachment size in mb
    Setting.set('es_attachment_max_size_in_mb', 1)

    yield if block_given?
  end

  def rebuild_searchindex
    # drop/create indexes
    Rake::Task.clear
    Zammad::Application.load_tasks
    #Rake::Task["searchindex:drop"].execute
    #Rake::Task["searchindex:create"].execute
    Rake::Task['searchindex:rebuild'].execute
  end
end
