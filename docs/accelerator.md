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


