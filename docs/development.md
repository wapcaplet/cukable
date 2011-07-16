Development
-----------

To hack on Cukable's code, first fork the
[repository](http://github.com/wapcaplet/cukable),
then clone your fork locally:

    $ git clone git://github.com/your_username/cukable.git

Install [bundler](http://gembundler.com/):

    $ gem install bundler

Then install Cukable's dependencies:

    $ cd /path/to/cukable
    $ bundle install

It's a good idea to use [RVM](http://rvm.beginrescueend.com/)
with a new gemset to keep things tidy.

If you make changes that you'd like to share, push them into your fork,
then [submit a pull request](http://github.com/wapcaplet/cukable/pulls).


Testing
-------

Cukable includes a suite of self-tests, executed using RSpec and Cucumber.
These are in the `spec` and `features` directories, respectively. To run the
full suite of tests, simply run:

    $ rake

This will generate output showing the status of each test, and will also use
[rcov](http://eigenclass.org/hiki.rb?rcov) to write a code coverage report to
`coverage/index.html`.


