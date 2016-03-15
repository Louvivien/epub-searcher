require 'epub-searcher/remote-database'

class TestRemoteDatabase < Test::Unit::TestCase
  def setup
    db_options = {
      host: EPUBSearcher::App.settings.droonga_host,
      port: EPUBSearcher::App.settings.droonga_port
    }
    @database = EPUBSearcher::RemoteDatabase.new(db_options)
  end

  def teardown
    super
    @database.close
  end

  class TestSetup < self
    def test_setup_database
      expected_table_create_params = [
        {:name=>:Books, :flags=>'TABLE_NO_KEY'},
        {:name=>:Terms, :flags=>'TABLE_PAT_KEY', :key_type=>:ShortText, :default_tokenizer=>:TokenBigram, :normalizer=>:NormalizerAuto},
      ]

      expected_column_create_params = [
        {:table=>:Books, :name=>'author', :flags=>'COLUMN_SCALAR', :type=>:ShortText},
        {:table=>:Books, :name=>'file_path', :flags=>'COLUMN_SCALAR', :type=>:ShortText},
        {:table=>:Books, :name=>'title', :flags=>'COLUMN_SCALAR', :type=>:ShortText},
        {:table=>:Books, :name=>'main_text', :flags=>'COLUMN_SCALAR', :type=>:LongText},
        {:table=>:Books, :name=>'unique_identifier', :flags=>'COLUMN_SCALAR', :type=>:ShortText},
        {:table=>:Books, :name=>'modified', :flags=>'COLUMN_SCALAR', :type=>:Time},
        {:table=>:Terms, :name=>'entries_author_index', :flags=>'COLUMN_INDEX|WITH_POSITION', :type=>:Books, :source=>'author'},
        {:table=>:Terms, :name=>'entries_main_text_index', :flags=>'COLUMN_INDEX|WITH_POSITION', :type=>:Books, :source=>'main_text'},
        {:table=>:Terms, :name=>'entries_title_index', :flags=>'COLUMN_INDEX|WITH_POSITION', :type=>:Books, :source=>'title'},
      ]

      expected_table_create_params.each do |params|
        @database.client.expects(:table_create).with(params)
      end

      expected_column_create_params.each do |params|
        @database.client.expects(:column_create).with(params)
      end

      @database.setup_database
    end
  end

  class TestRecords < self
    def test_load_records
      epub_paths = [
        'empty_contributors_single_spine.epub',
        'single_contributors_multi_spine.epub',
        'multi_contributors_multi_spine.epub',
      ]

      documents = epub_paths.map do |path|
        document = EPUBSearcher::EPUBDocument.open(fixture_path(path))
        document
      end

      expected_values = File.read(fixture_path('load_records_params_values_expected.txt'))
      expected = {
        :table => :Books,
        :values => normalize_newline_literal(expected_values),
      }
      @database.client.expects(:load).with do |actual_params|
        actual_params[:values].gsub!(%r|"file_path":"/.+?/test/epub-searcher/fixtures/|) do
          "\"file_path\":\"${PREFIX}/test/epub-searcher/fixtures/"
        end
        actual_params[:values] = normalize_newline_literal(actual_params[:values])
        expected == actual_params
      end

      @database.load_records(documents)
    end
  end

  def test_select_records
    select_params = {
      :table => :Books,
      :query => 'query words',
      :match_columns => 'author,title,main_text',
      :output_columns => 'author,title,snippet_html(main_text)',
      :command_version => 2
    }
    @database.client.expects(:select).with(select_params).returns(search_result)

    @database.select(
      :table => :Books,
      :query => 'query words',
      :match_columns => 'author,title,main_text',
      :output_columns => 'author,title,snippet_html(main_text)'
    )
  end

  def test_delete_record
    delete_params = {
      :table => :Books,
      :id => 1,
      :command_version => 2
    }
    @database.client.expects(:delete).with(delete_params)

    @database.delete(
      :table => :Books,
      :id => 1
    )
  end

  private
  def fixture_path(basename)
    File.join(__dir__, 'fixtures', basename)
  end

  def search_result
    result = Object.new
    result.stubs(:records)
    result
  end
end
