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

    !| Table: Cuke                         |
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

    !| Table: Cuke                                    |
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
tests are run via the `CUCUMBER_ARGS` variable supported by the accelerator,
described below.


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

The new page does not need to have any content; you can leave it empty if you
like. Its existence alone will cause acceleration to take effect for the suite
that it's in.

You can nest suites inside each other, and each suite can have its own
accelerator page. Whenever you execute a suite, the highest-level accelerator
will be executed (thus running as many features as possible together).


Cucumber args
-------------

Whenever you run a suite with an `AaaAccelerator` page, you can define
additional command-line arguments to pass to Cucumber by using the
`CUCUMBER_ARGS` variable. This is most useful for specifying the `--tags`
argument to control which tests are executed or skipped. Simply define the
variable like this:

    !define CUCUMBER_ARGS {--tags @run_me}

Put this at the top of any suite page, and any `AaaAccelerator` in that suite
will pass those additional arguments to Cucumber. When tags are passed that
prevent certain scenarios in a feature to be skipped, those skipped scenarios
will be colored grey (ignored).

At present the `CUCUMBER_ARGS` variable only takes effect when an
`AaaAccelerator` page is called, and there is no way to pass additional
arguments to individual tests.



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

