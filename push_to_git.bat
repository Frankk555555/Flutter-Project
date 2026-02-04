@echo off
echo Git Config... > git_push_log.txt 2>&1
git config user.email "flutter_project@example.com" >> git_push_log.txt 2>&1
git config user.name "Flutter Developer" >> git_push_log.txt 2>&1
echo Remote Config... >> git_push_log.txt 2>&1
git remote remove origin >> git_push_log.txt 2>&1
git remote add origin https://github.com/Frankk555555/Flutter-Project.git >> git_push_log.txt 2>&1
echo Adding files... >> git_push_log.txt 2>&1
git add . >> git_push_log.txt 2>&1
echo Committing... >> git_push_log.txt 2>&1
git commit -m "Initial commit of stock management project" >> git_push_log.txt 2>&1
echo Renaming branch... >> git_push_log.txt 2>&1
git branch -M main >> git_push_log.txt 2>&1
echo Pushing... >> git_push_log.txt 2>&1
git push -u origin main >> git_push_log.txt 2>&1
echo DONE >> git_push_log.txt 2>&1
