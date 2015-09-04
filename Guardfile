guard :rake, :task => 'assets:css' do
  watch %r{^app/css/.+$}
end

guard :rake, :task => 'assets:javascript' do
  watch %r{^app/js/.+$}
end

guard :bundler do
  watch 'Gemfile'
end

guard :foreman do
  watch %r{^.+\.rb$}
end
