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



