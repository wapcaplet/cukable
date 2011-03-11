#!/usr/bin/env ruby

# Script to convert Cucumber features into FitNesse wiki pages

# Desired behavior:
#
# - Recursively search for .feature files in a directory
# - Create a FitNesse wiki hierarchy that mirrors the .feature hierarchy, with
#   one wiki page for each .feature file
# - Fill those wiki pages with a table - essentially just the text of the
#   .feature file with |...| wrapping each line. Empty lines should be skipped.
#

# The "main" function, only executed when this script is
# run standalone (not when it's imported from elsewhere)
if __FILE__ == $PROGRAM_NAME
  if ARGV.count == 0
    puts "Usage: cuke2fit.rb <features_path> <fitnesse_path>"
  else
    convert_features_to_fitnesse(ARGV[0], ARGV[1])
  end
end


