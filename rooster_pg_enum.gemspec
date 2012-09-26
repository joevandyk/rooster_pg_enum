Gem::Specification.new do |s|
  s.name = 'rooster_pg_enum'
  s.files         = ['rooster_pg_enum.rb']
  s.require_path  = '.'
  s.version = "0.0.1"
  s.date = %q{2012-09-25}
  s.summary = %q{automatically validate pg enums in activerecord}
  s.author = "Joe Van Dyk <joe@tanga.com>"
  s.add_dependency('activerecord', '>= 3')
  s.add_dependency('pg') # for enum monkeypatch
end
