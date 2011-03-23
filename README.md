Cukable
=======

Cukable allows you to write and execute [Cucumber](http://cukes.info) tests
from [FitNesse](http://fitnesse.org).

It consists of a [rubyslim](http://github.com/unclebob/rubyslim) fixture that
invokes Cucumber, and a custom Cucumber output formatter that returns
SliM-formatted test results to FitNesse.


Supported syntax
----------------

Most of the standard Cucumber/Gherkin syntax is supported by Cukable, including:

- Background sections
- Scenarios and Scenario Outlines with Examples
- Multiple scenarios per feature
- Multi-line table arguments and table diffing
- Multi-line strings
- Tags for running/skipping scenarios and defining drivers (such as `@selenium`)


Installation
------------

To install Cukable, do:

    $ gem install cukable

Cukable requires [rubyslim](http://github.com/unclebob/rubyslim) in order to
work; as of this writing, rubyslim is not officially packaged as a gem, making
it slightly more difficult to get Cukable working. For this reason, a makeshift
rubyslim gem is provided in the `vendor/cache` directory of Cukable. Install
this into whatever environment you plan to run Cukable under, like so:

    $ gem install /path/to/cukable/vendor/cache/rubyslim-0.1.1.gem

Please note that this is an unofficial gem, created without the sanction of the
rubyslim author. Until such time as rubyslim gets an official gem distribution,
please report any issues with it to the
[Cukable issue tracker](http://github.com/wapcaplet/cukable/issues).


Converting existing features
----------------------------

Cukable comes with an executable script to convert existing Cucumber features
to FitNesse wiki format. You must have an existing FitNesse page; features will
be imported under that page.

Usage:

    cuke2fit <features_path> <fitnesse_path>

For example, if your existing features are in `features/`, and the FitNesse
wiki page you want to import them to is in `FitNesseRoot/MyTests`, do:

    $ cuke2fit features FitNesseRoot/MyTests

The hierarchy of your `features/` folder will be preserved as a hierarchy of
FitNesse wiki pages. Each `.feature` file becomes a separate wiki page.


Writing new features
--------------------

You can write new Cucumber features from scratch, directly in FitNesse, and run
them from FitNesse with only minimal configuration.

Here's what a simple hierarchy might look like:

- FitNesseRoot
  - CukableTests (suite)
    - SetUp
    - FeedKitty (test)
    - CleanLitterbox (test)

Put these variable definitions in `CukableTests`:

    !define TEST_SYSTEM {slim}
    !define TEST_RUNNER {rubyslim}
    !define COMMAND_PATTERN {rubyslim}

This is the essential configuration to tell FitNesse how to invoke `rubyslim`
for tests in the suite. Then put this in `CukableTests.SetUp`:

    !| import |
    | Cukable |

This tells `rubyslim` to load the `Cukable` module, so it'll know how to run
tests in `Cuke` tables. Now create a `Cuke` table in `CukableTests.FeedKitty`:

    !| Table: Cuke                       |
    | Feature: Feed kitty                |
    |   Scenario: Canned food            |
    |     Given I have a can of cat food |
    |     When I feed it to my cat       |
    |     Then the cat should purr       |

The `!` that precedes the table ensures that all text within will be treated
literally, and will not be marked up as FitNesse wiki-text. This is especially
important if you have CamelCase words, email addresses, or URLs in your table.

Also, note that all your steps must be defined in the usual way, such as `.rb`
files in `features/step_definitions`. That's outside Cukable's scope.

Finally, you can run the `FeedKitty` test by itself, or run the entire
`CukableTests` suite.


Test syntax
-----------

FitNesse uses wikitext tables delimited with a pipe `|` to format the
executable statements of a test scenario; these are rendered as HTML tables in
a FitNesse wiki page. When a test is run from FitNesse, the results of the test
are rendered into the same table, with green- or red-highlighted cells indicating
pass/fail status.

Cucumber tests written in a FitNesse wiki page closely resemble the
[Gherkin](http://github.com/aslakhellesoy/cucumber/wiki/gherkin) syntax that
Cucumber understands, with some changes in formatting to accommodate FitNesse.

If this is your `.feature` file:

    Feature: Hello
      Scenario: Hello world
        Given I am on the hello page
        Then I should see "Hello world"

Then here is what your FitNesse wikitext would be:

    !| Table: Cuke                        |
    | Feature: Hello                      |
    |   Scenario: Hello world             |
    |     Given I am on the hello page    |
    |     Then I should see "Hello world" |

Each row of the FitNesse table contains one step or other directive. Whitespace
before and/or after steps is not significant, so you can use it to aid
readability if you're into that sort of thing.

Your table must contain exactly one row with `Feature: ...`, and you must have
at least one `Scenario: ...` or `Scenario Outline: ...`.


Tables
------

Cucumber supports multiline step arguments in the form of tables; in a
`.feature` file, these might look like:

    Feature: Tables
      Scenario: Fill in fields
        Given I am on the contact page
        When I fill in the following:
          | Name | Email                 | Message |
          | Eric | wapcaplet88@gmail.com | Howdy   |

In a FitNesse wiki page, this would translate to:

    !| Table: Cuke                                   |
    | Feature: Tables                                |
    |   Scenario: Fill in fields                     |
    |     Given I am on the contact page             |
    |     When I fill in the following:              |
    |       | Name | Email                 | Message |
    |       | Eric | wapcaplet88@gmail.com | Howdy   |

That is, each row in an embedded table begins with an empty cell. The same
applies to the "Examples" portion of a
[Scenario Outline](https://github.com/aslakhellesoy/cucumber/wiki/scenario-outlines):

    | When I look at paint samples |
    | Then I should see "<color>"  |
    | Examples:                    |
    |   | color                    |
    |   | Taupe                    |
    |   | Vermilion                |
    |   | Fuscia                   |


Multi-line strings
------------------

To pass a multi-line string to one of your steps, just enter it as you normally
would in a .feature file, with triple-double-quotes delimiting the string:

    | When I fill in "Message" with: |
    |   """                          |
    |   So long, and                 |
    |   thanks for all the fish!     |
    |   """                          |


Tags
----

You can include Cucumber tags, as long as you only include one tag per row in
the table:

    | @tag_a                      |
    | @tag_b                      |
    | Feature: Tagged feature     |
    |   @tag_c                    |
    |   @tag_d                    |
    |   Scenario: Tagged scenario |
    |     When I have some tags   |

The inclusion of tags is useful for defining which driver to use (for example
the `@selenium` tag supported by Capybara), as well as for controlling which
tests are run via cucumber command-line arguments, described below.


Acceleration
------------

Normally, FitNesse runs tests one-by-one. That is, under normal circumstances,
each `Cuke` table will result in its own standalone execution of `cucumber`.
This means that when you run a suite of tests, Cucumber will be running
multiple times (once per feature) when it should really be running all features
at once.

This may be fine if your test environment is simple, and Cucumber runs quickly.
But if your application has a lot of dependencies to load, there may be too much
overhead to run a suite of tests in this way.

Cukable provides a workaround to this in the form of something called `AaaAccelerator`.
If you have a suite of three features:

- MyFeatures (suite)
    - FirstFeature (test)
    - SecondFeature (test)
    - ThirdFeature (test)

and you want to be able to run the entire suite without invoking a separate
Cucumber instance each time, simply create a new child page of `MyFeatures` called
`AaaAccelerator` (named this way so it will be executed first in the suite):

- MyFeatures (suite)
    - AaaAccelerator (test)
    - FirstFeature (test)
    - SecondFeature (test)
    - ThirdFeature (test)

The `AaaAccelerator` page does not need to have any content; you can leave it
empty if you like. Its existence alone will cause acceleration to take effect
for the suite that it's in. To make this magic happen, you must add this to your
`SetUp` page for the suite:

    | script | Cuke |
    | accelerate; | ${PAGE_PATH}.${PAGE_NAME} | ${CUCUMBER_ARGS} |

Include this exactly as it appears; the variables will be expanded to the
name of your `AaaAccelerator` page when the suite runs. The `CUCUMBER_ARGS`
piece is an optional argument that passes any defined command-line arguments
to Cucumber (see below).

You can nest suites inside each other, and each suite can have its own
`AaaAccelerator` page. Whenever you execute a suite, the highest-level
accelerator will be executed (thus running as many features as possible
together).


Cucumber args
-------------

There are two ways to pass command-line arguments to Cucumber when running
features. The first is by passing an argument directly to the `Cuke`
constructor in a feature table; just include an extra cell in the first row:

    !| Table: Cuke | --tags @run_me    |
    | Feature: Arguments               |
    |   @run_me                        |
    |   Scenario: This will be run     |
    |   @dont_run_me                   |
    |   Scenario: This will be skipped |

This is the approach you'd use if you wanted to run a single test with
specific command-line arguments. If you want to run an entire suite using
the `AaaAccelerator` technique described above, you can define command-line
arguments as a FitNesse variable, like this:

    !define CUCUMBER_ARGS {--tags @run_me}

Put this at the top of any suite page, and any `AaaAccelerator` in that suite
will pass those additional arguments to Cucumber. Note that these will override
any arguments passed to individual tables, because Cucumber is only executed
once for the entire suite.


Support
-------

This README, along with API documentation on Cukable, are available on
[rdoc.info](http://rdoc.info/github/wapcaplet/cukable/master/frames).

Please report any bugs, complaints, and feature requests to the
[issue tracker](http://github.com/wapcaplet/cukable/issues).


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


Copyright
---------

The MIT License

Copyright (c) 2011 Automation Excellence

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

