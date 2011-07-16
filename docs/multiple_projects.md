Multiple projects
-----------------

As of Cukable version 0.1.2, you can run tests in multiple project directories.
For example, you may have two applications that you want to test with Cukable:

- `/home/eric/projects/A`: First application you want to test
- `/home/eric/projects/B`: Second application you want to test
- `/home/eric/projects/FitNesseRoot`: Where your wiki is stored

Projects `A` and `B` may have different dependencies, and you want Cukable to
mimic the process of running `cucumber` within each of those directories. If
`A` and `B` are Rails applications, and you know what's good for you, you're
already using [bundler](http://gembundler.com/) to manage each application's
gem dependencies, and [RVM](http://rvm.beginrescueend.com/) with two distinct
gemsets to keep the projects' dependencies from interfering with one another.
This is what Cukable expects that you are doing.

In your wiki pages (either in a `Cuke` table, or in the `accelerate` function
call), you can pass a third argument (after `CUCUMBER_ARGS`) that indicates the
directory where that test should be executed. For instance, you could have a
wiki page with two tests--one for each project:

    !| Table: Cuke | | /home/eric/projects/A |
    | When I run a test on project A         |
    | Then the test should pass              |

    !| Table: Cuke | | /home/eric/projects/B   |
    | When I run a different test on project B |
    | Then the test should pass                |

These two tests will be executed in their respective directories. If the two
applications have differing gem dependencies, you should put an `.rvmrc` file
in both the `A` and `B` directories, containing the correct `rvm` command to
switch gemsets; if Cukable finds an `.rvmrc` in a project directory, it will be
sourced so that Cucumber runs within the context of that gemset.

Next: [Development & Testing](development.md)

