@ECHO OFF
SETLOCAL

IF NOT EXIST "%1" (
  echo File does not exists: %1
  exit 1
)

FOR /F "delims=" %%i IN ("%1") DO (
  set file_drive=%%~di
  set file_path=%%~pi
  set file_name=%%~ni
  set file_extension=%%~xi
)

set project_file=%file_drive%%file_path%%file_name%.prj
echo Creating project:  %project_file%

(
  echo Project project {
  echo   Generate Simulator {
  echo     simulator {
  echo       product-file "%file_name%%file_extension%"
  echo     }
  echo   }
  echo }
) > "%project_file%"

echo Generating simulator
.\jre\bin\java.exe -jar .\bpmn4s-generator.jar -l "%project_file%"

set simulator_file=%file_drive%%file_path%src-gen\CPNServer.py
echo Starting simulator:  %simulator_file%

python "%simulator_file%"

