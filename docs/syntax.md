Supported syntax
----------------

Most of the standard Cucumber/Gherkin syntax is supported by Cukable, including:

- Background sections
- Scenarios and Scenario Outlines with Examples
- Multiple scenarios per feature
- Multi-line table arguments and table diffing
- Multi-line strings
- Tags for running/skipping scenarios and defining drivers (such as `@selenium`)


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
