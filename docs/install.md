Installation
------------

To install Cukable, do:

    $ gem install cukable

Cukable requires [rubyslim](http://github.com/unclebob/rubyslim) in order to
work; as of this writing, rubyslim is not officially packaged as a gem, making
it slightly more difficult to get Cukable working. For this reason, a makeshift
rubyslim gem is provided in the `vendor/cache` directory of Cukable. Use `gem
list cukable -d` to find out the full installation path for cukable, then
append `/vendor/cache/rubyslim-0.1.1.gem` on the end of that,a nd install like
so:

    $ gem install /path/to/cukable/vendor/cache/rubyslim-0.1.1.gem

Please note that this is an unofficial gem, created without the sanction of the
rubyslim author. Until such time as rubyslim gets an official gem distribution,
please report any issues with it to the
[Cukable issue tracker](http://github.com/wapcaplet/cukable/issues).


Configuration
-------------

FitNesse uses a JSON format for its test reporting, so you must enable the SLIM
JSON output formatter provided by Cukable. To make Cucumber aware of this
formatter, add this line:

    require 'cukable/slim_json_formatter'

to your `features/support/env.rb`, `features/support/custom_env.rb`, or
wherever you're keeping custom initialization for your Cucumber environment.


