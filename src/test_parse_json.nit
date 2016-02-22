import json

var toto = new FileReader.open("pep8.json")

var data = toto.read_all
var titi = data.parse_json
print titi or else "khfsgisdkhfa"
