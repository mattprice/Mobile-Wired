desc 'Run the tests'
task :build do
  buildAndLogScheme("Mobile Wired")
end

task :default => :build

class String
  def self.colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def red
    self.class.colorize(self, 31)
  end

  def green
    self.class.colorize(self, 32)
  end
end

def buildAndLogScheme(scheme)
  result = compile(scheme)
  log(scheme, result)
end

def log(scheme, result)
  scheme = "Default" if scheme == ""
  puts "#{scheme}: #{result == 0 ? 'PASSED'.green : 'FAILED'.red}"
end

def compile(scheme)
  command = "xcodebuild -scheme \"#{scheme}\" -configuration Release -sdk iphonesimulator -verbose build OBJROOT=\"$PWD/build\" SYMROOT=\"$PWD/build\""
  IO.popen(command) do |io|
    while line = io.gets do
      puts line
      if line == "** BUILD SUCCEEDED **\n"
        return 0
      elsif line == "** BUILD FAILED **\n"
        return 1
      end
    end
  end
end