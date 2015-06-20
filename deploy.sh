git pull;
npm install;
cd public;
bower install;
cd ..;
grunt coffee;
grunt uglify;
forever restart -l listify.log -o out.log -e err.log -a bin/www;