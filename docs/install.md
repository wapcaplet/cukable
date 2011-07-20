Installation
------------

To install Cukable, simply do:

    $ gem install cukable


Configuration
-------------

FitNesse uses a JSON format for its test reporting, so you must enable the SLIM
JSON output formatter provided by Cukable. To make Cucumber aware of this
formatter, add this line:

    require 'cukable/slim_json_formatter'

to your `features/support/env.rb`, `features/support/custom_env.rb`, or
wherever you're keeping custom initialization for your Cucumber environment.


Next: [Converting Existing Features](converting.md)
