module Cartographer
  module Routes extend self
    class Break < StandardError; end

    module Helpers
      TIME_FMT = '%Y-%m-%d %H:%M:%S %Z'

      def log(level, msg)
        request.logger.send(level, msg)
      end

      def ready
        Models::Map.all(:state => :ready, :order => [:created_at.desc],
                        :limit => 32)
      end

      def queue
        Models::Map.all(:state.not => :ready, :order => [:created_at.desc])
      end

      def get_state_class(map)
        case map.state
        when :waiting
          'text-warning'
        when :processing
          'text-success'
        when :error
          'text-danger'
        else
          ''
        end
      end

      def stats
        settings.stats
      end
    end

    def registered(app)
      app.helpers Helpers

      stats = Models::Stats.first(:order => [:created_at.desc])
      unless stats
        stats = Models::Stats.create
        unless stats.save
          log :error, 'Couldn\'t save new stats'
          log :error, stats.errors
        end
      end
      app.set :stats, stats

      app.before do
        @login  = session[:login]
        @errors = session[:errors] || Hash.new
        @msgs   = session[:msgs] || Hash.new # for stuff done and dandy
        session.delete(:errors)
        session.delete(:msgs)
      end

      app.after do
        stats.hits += 1
        stats.save
      end

      app.get '/' do
        haml :layout
      end

      app.get '/map/:id' do
        unless map = Models::Map.get(params[:id])
          @errors[:ready] = "Map ID #{params[:id]} not found."
          session[:errors] = @errors
          redirect '/'
        end

        map.downloads += 1
        map.save

        stats.downloads += 1
        redirect map.link
      end

      app.post '/logreg' do
        begin
          unless params[:login] && params[:pass] && \
            !params[:login].empty? && !params[:pass].empty?
            @errors[:logreg] = 'You need to specify both login and password.'
            raise Break
          end

          if user = Models::User.get(params[:login])
            if user.pass == params[:pass]
              session[:login] = user.login
              redirect '/'
            end
            @errors[:logreg] = 'Login already taken. Either make another up or give the right password.'
            raise Break
          end

          user = Models::User.new(login: params[:login], pass: params[:pass])
          unless user.save
            @errors[:logreg] = 'Something went wrong, sorry!'
            log :error, "Couldn't save user '#{params[:login]}'"
            log :error, user.errors
            stats.failed += 1
            raise Break
          end

          session[:login] = user.login
          stats.users += 1
          redirect '/'
        rescue Break
          # just a dandy exit
        end
        haml :layout
      end

      app.get '/logout' do
        session.delete(:login)
        redirect '/'
      end

      app.post '/upload' do
        begin
          user = nil
          user = Models::User.get(session[:login]) if session[:login]
          unless user
            @errors[:upload] = 'Are you logged in? Otherwise something went wrong...'
            raise Break
          end

          map = Models::Map.new(user: user, comment: params[:comment])
          unless map.save
            @errors[:upload] = 'Something went wrong, sorry. Will investigate!'
            log :error, 'Couldn\'t save map @ /upload'
            log :error, map.errors
            stats.failed += 1
            raise Break
          end

          upload_dir = ENV['WEB_UPLOADS'] + map.id.to_s
          begin
            Dir.mkdir(upload_dir)
          rescue SystemCallError => e
            @errors[:upload] = 'Something went wrong, sorry. Will investigate!'
            log :error, "Couldn't create upload dir for #{map.id}"
            log :error, e.to_s
            log :debug, e.backtrace.join("\n")
            stats.failed += 1
            raise Break
          end

          files_count = 0
          params['files'].each do |f|
            begin
              File.rename(f[:tempfile].path, "#{upload_dir}/#{f[:filename]}")
              files_count += 1
            rescue Exception => e
              @errors[:upload] = 'Something went wrong, sorry. Will investigate!'
              log :error, "Couldn't create upload file #{f[:filename]} for #{map.id}"
              log :error, e.to_s
              log :debug, e.backtrace.join("\n")
              stats.failed += 1
              raise Break
            end
          end

          stats.maps += 1
          enqueue('ctg-process', {id: map.id, path: upload_dir})
          @msgs[:upload] = "Received #{files_count} file(s) for your map <b>#{map.id}</b>."
        rescue Break
          # something might have gone wrong
          if map
            map.state = :error
            unless map.save
              log :error, 'Couldn\'t save map @ /upload/error'
              log :error, map.errors
              stats.failed += 1
            end
            enqueue('ctg-clean', {id: map.id, path: upload_dir},
                    ENV['KEEP_BROKEN'].to_i)
            haml :layout
          end
        else
          session[:msgs] = @msgs
          redirect '/'
        end
      end
    end
  end
end
