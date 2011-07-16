Cucumber arguments
------------------

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

Next: [Multiple Projects](multiple_projects.md)

