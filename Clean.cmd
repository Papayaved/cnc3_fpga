@echo off
rem Clear Quartus project
del *.bak
del *.txt
del *.rpt
del Testbench\\*.bak

rd /s /q db
rd /s /q incremental_db
rd /s /q simulation
rd /s /q greybox_tmp

for /R "output_files" %%f in (*) do (if not "%%~xf"==".sof" if not "%%~xf"==".pof" del "%%~f")
