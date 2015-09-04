require 'dotenv/tasks'
Rake::Task['dotenv'].execute
devel   = ENV['RACK_ENV'] != 'production'
assets  = ENV['WEB_ASSETS']

namespace :assets do
  desc 'Compile all assets'
  task :all => [:css, :javascript]

  desc 'Compile CSS assets'
  task :css do
    puts 'Processing CSS assets...'

    if devel
      require 'fileutils'
      minify = false
    else
      require 'cssminify'
      minify = true
    end

    FileList['app/css/*.css'].each do |css|
      tgt = assets + 'css/' + File.basename(css)
      puts "#{css} -> #{tgt}"
      if minify
        File.open(tgt, 'wb') {|out| out.write CSSminify.compress(File.read(css)) }
      else
        FileUtils.cp css, tgt
      end
    end
  end

  desc 'Compile JavaScript assets'
  task :javascript do
    puts 'Processing JavaScript assets...'

    if devel
      require 'fileutils'
      uglify = false
    else
      require 'uglifier'
      uglify = true
    end

    FileList['app/js/*.js'].each do |js|
      tgt = assets + 'js/' + File.basename(js)
      puts "#{js} -> #{tgt}"
      if uglify
        File.open(tgt, 'wb') {|out| out.write Uglifier.compile(File.read(js)) }
      else
        FileUtils.cp js, tgt
      end
    end
  end
end
