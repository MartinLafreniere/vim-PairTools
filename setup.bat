@ECHO OFF
REM setup.bat
REM Setup PairTools plugin for Windows
REM Copyright (C) 2011 Martin Lafreniere

SET VIMFILESPATH=%USERPROFILE%\vimfiles

REM Use default path?
IF "%~1"=="" (GOTO PASS)

REM User provided, verify folder exists
IF EXIST %1 (GOTO USERPATH)

ECHO ERROR: CANNOT FIND VIMFILES PATH %1.
GOTO END

:USERPATH
SET VIMFILESPATH=%1

REM Copy plugin files into user vimfiles
:PASS
ECHO COPYING plugin\pairtools.vim into %VIMFILESPATH%\plugin\
COPY /A plugin\pairtools.vim %VIMFILESPATH%\plugin\ /Y

ECHO COPYING plugin\pairtools.txt into %VIMFILESPATH%\doc\
COPY /A doc\pairtools.txt %VIMFILESPATH%\doc\ /Y

REM Make sure to install ithe help file
ECHO OPENING Vim session to install help file (pairtools.txt)
vim --servername INSTALL_PAIRTOOLS --cmd "helptags %VIMFILESPATH%\doc | quit" 
:END

