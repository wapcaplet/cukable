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


