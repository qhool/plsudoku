use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sudoku',
    VERSION_FROM      => 'lib/Sudoku/Board.pm', # finds $VERSION
    PREREQ_PM         => { Moose => 2.0200 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Extensible Sudoku Puzzle & Solver', # retrieve abstract from module
       AUTHOR         => 'Josh Burroughs <josh@qhool.com>') : ()),
);
