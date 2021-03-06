module Sidekiq
  module Cron
    module WebExtension

      def self.registered(app)

        app.settings.locales << File.join(File.expand_path("..", __FILE__), "locales")

        #index page of cron jobs
        app.get '/cron' do
          view_path    = File.join(File.expand_path("..", __FILE__), "views")

          @cron_jobs = Sidekiq::Cron::Job.all

          #if Slim renderer exists and sidekiq has layout.slim in views
          if defined?(Slim) && File.exists?(File.join(settings.views,"layout.slim"))
            render(:slim, File.read(File.join(view_path, "cron.slim")))
          else
            render(:erb, File.read(File.join(view_path, "cron.erb")))
          end
        end

        #enque cron job
        app.post '/cron/:name/enque' do |name|
          if job = Sidekiq::Cron::Job.find(name)
            job.enque!
          end
          redirect "#{root_path}cron"
        end

        app.post '/cron/schedule' do
          name = params[:name]
          cron = params[:cron]
          klass = params[:klass]

          if name && cron && klass
            Sidekiq::Cron::Job.create( name: name, cron: cron, klass: klass)
          end
          redirect "#{root_path}cron"
        end

        app.post '/cron/oneoff' do
          at = params[:at]
          klass = params[:klass]
          booking = params[:booking]

          if at && klass && booking
            klass.classify.constantize.perform_at(DateTime.parse(at), booking.to_i)
          end
          redirect "#{root_path}cron"
        end

        #delete schedule
        app.post '/cron/:name/delete' do |name|
          if job = Sidekiq::Cron::Job.find(name)
            job.destroy
          end
          redirect "#{root_path}cron"
        end

        #enable job
        app.post '/cron/:name/enable' do |name|
          if job = Sidekiq::Cron::Job.find(name)
            job.enable!
          end
          redirect "#{root_path}cron"
        end

        #disable job
        app.post '/cron/:name/disable' do |name|
          if job = Sidekiq::Cron::Job.find(name)
            job.disable!
          end
          redirect "#{root_path}cron"
        end
        
      end
    end
  end
end
