sudo apt-get update && sudo apt-get install -y cowsay
cowsay -f dragon "Run for cover, I am a dragon!" >> dragon_artwork.txt
grep -i "dragon" dragon_artwork.txt
cat dragon_artwork.txt
ls -ltar