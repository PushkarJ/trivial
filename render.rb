require_relative './models/vulnerability.rb'
require_relative './models/vuln_aggregator.rb'
require 'JSON'
#PARSE
scan_results_directory = ARGV[0]
relative_filenames = Dir[File.join(scan_results_directory, "*")]
scan_results_by_target = {}
relative_filenames.each do |relative_filename|
  #whole file goes in memory, may not scale but easy
  result_json = File.read(relative_filename)
  if result_json == "null" || result_json == ""
    puts "Skipping #{relative_filename}, content was '#{result_json}'"
    next
  end
  begin
  results = JSON.parse(result_json)
  rescue JSON::ParserError => e
    puts "Error #{e} while parsing #{relative_filename}"
  end

  if (!results.empty?)
    results.each do |result|
      target = result["Target"]
      target_results = scan_results_by_target[target] ||= VulnAggregator.new()
      target_vuln_data = result["Vulnerabilities"] || []
      target_vuln_data.each do |vuln_data|
        vuln = Vulnerability.new(vuln_data)
        target_results.add(vuln)
      end
    end
  end
end
#RENDER
puts "\n\n"
summary = []
overall_catastrophic = 0
overall_critical = 0
overall_high = 0
overall_medium = 0
overall_low = 0
overall_unknown = 0
scan_results_by_target.each do |target, target_results|
  if target_results.total_vuln_count == 0
    summary.push("#{target}: No vulnerabilities found")
  else
    string = "#{target}: Catastrophic: #{target_results.catastrophic_count}, "
    string += "Critical: #{target_results.critical_count}, "
    string += "High: #{target_results.high_count}, "
    string += "Medium: #{target_results.medium_count}, "
    string += "Low: #{target_results.low_count}, "
    string += "Unknown: #{target_results.unknown_count}"
    summary.push(string)
    overall_catastrophic += target_results.catastrophic_count
    overall_critical += target_results.critical_count
    overall_high += target_results.high_count
    overall_medium += target_results.medium_count
    overall_low += target_results.low_count
    overall_unknown += target_results.unknown_count
  end
end
puts summary.join("\n")
puts "\n\n"
string = "OVERALL: Catastrophic: #{overall_catastrophic}, "
string += "Critical: #{overall_critical}, "
string += "High: #{overall_high}, "
string += "Medium: #{overall_medium}, "
string += "Low: #{overall_low}, "
string += "Unknown: #{overall_unknown}"
puts string
