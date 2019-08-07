echo "# Building the game in html format"
/mnt/c/Program\ Files\ \(x86\)/PICO-8/pico8.exe dom.p8 -export "dom.html -p ub"

echo""
echo "# Copying the game client and server to the server"
scp dom.html p8server:/var/www/html/dom/.
scp dom.js p8server:/var/www/html/dom/.
scp server/server.js p8server:./pico8-server/.

echo ""
ssh p8server ./pico8-server/bounce.sh
