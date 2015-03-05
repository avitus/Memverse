
module TreasureData
module Command

  def sample_apache(op)
    fname = op.cmd_parse

    require 'json'

    t = Time.now.to_i
    i = 0
    last_time = nil

    data = File.join(File.dirname(__FILE__), '../../../data/sample_apache.json')
    File.open(data) {|df|
      File.open(fname, 'w') {|of|
        df.each_line {|line|
          record = JSON.parse(line)
          record['time'] = last_time = (t - (i**1.3)).to_i
          of.puts record.to_json
          i += 1
        }
      }
    }

    $stderr.puts "Create #{fname} with #{i} records whose time is"
    $stderr.puts "from #{Time.at(last_time)} to #{Time.at(t)}."
    $stderr.puts "Use '#{$prog} table:import <db> <table> --json #{fname}' to import this file."
  end

end
end

