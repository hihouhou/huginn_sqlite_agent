require 'sqlite3'

module Agents
  class SqliteAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule 'every_1h'

    description do
      <<-MD
      The huginn Sqlite Agent does queries on sqlite DB and can creates events.

      `debug` is used to verbose mode.

      `path` is the path of the sqlite file.

      `table` is the wanted table we are going to query.

      `query` is the used wanted query.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "type": "top1",
            "game": "cod",
            "classement": {
              "XXXXXXXXXXXXXXXXX": "68",
              "ZZZZZZZZZZZZZZ": "64",
              "WWWWWWWWWWWWWWWW": "59",
              "YYYYYYYYYYYYYYY": "13"
            }
          }
    MD

    def default_options
      {
        'path' => '',
        'table' => '',
        'debug' => 'false',
        'query' => ''
      }
    end
    form_configurable :path, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :table, type: :string
    form_configurable :query, type: :string
    def validate_options
      unless options['path'].present?
        errors.add(:base, "path is a required field")
      end

      unless options['table'].present?
        errors.add(:base, "table is a required field")
      end

      unless options['query'].present?
        errors.add(:base, "query is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end
    end

    def working?
      received_event_without_error? && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          play_query
        end
      end
    end

    def check
      play_query
    end

    private

    def play_query()
#     Open a database
      db = SQLite3::Database.open "#{interpolated['path']}"
      db.results_as_hash = true

      if interpolated['debug'] == 'true'
        log "table : #{interpolated['table']}"
        log "query : #{interpolated['query']}"
      end

      db.execute( "#{interpolated['query']}" ) do |row|
        if interpolated['debug'] == 'true'
          log "row: #{row}"
        end
        if interpolated['query'].start_with?("select")
          create_event payload: row
        end
      end
      rescue SQLite3::Exception => error_output
          log "Exception occurred"
          log error_output
      ensure

      db.close if db
    end
  end
end
