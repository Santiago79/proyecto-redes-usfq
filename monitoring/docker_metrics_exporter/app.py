import datetime as dt
import os
import subprocess
import threading
import time
from typing import Dict, Tuple

import docker
from docker.errors import DockerException
from flask import Flask, Response
from prometheus_client import Gauge, generate_latest

app = Flask(__name__)

PROJECT_NAME = os.getenv("COMPOSE_PROJECT", "infra")
SCRAPE_PACKET_STATS = os.getenv("SCRAPE_PACKET_STATS", "true").lower() == "true"
REFRESH_INTERVAL_SECONDS = max(int(os.getenv("REFRESH_INTERVAL_SECONDS", "5")), 2)

client = docker.DockerClient(base_url="unix://var/run/docker.sock", version="auto", timeout=15)
refresh_lock = threading.Lock()
last_refresh_timestamp = 0.0
previous_cpu_samples: Dict[str, Tuple[int, int, int, float]] = {}

LABELS = ["service", "container"]
SCRAPED_SERVICES = {"web", "router", "atacante", "db", "panel_control"}
CONTAINER_UP = Gauge("lab_container_up", "Estado del contenedor Docker", LABELS)
CONTAINER_CPU = Gauge("lab_container_cpu_percent", "Uso de CPU por contenedor", LABELS)
CONTAINER_MEMORY_USAGE = Gauge(
    "lab_container_memory_usage_bytes",
    "Uso de memoria por contenedor",
    LABELS,
)
CONTAINER_MEMORY_LIMIT = Gauge(
    "lab_container_memory_limit_bytes",
    "Limite de memoria reportado por Docker",
    LABELS,
)
CONTAINER_NETWORK_RX_BYTES = Gauge(
    "lab_container_network_rx_bytes_total",
    "Bytes recibidos por contenedor",
    LABELS,
)
CONTAINER_NETWORK_TX_BYTES = Gauge(
    "lab_container_network_tx_bytes_total",
    "Bytes transmitidos por contenedor",
    LABELS,
)
CONTAINER_NETWORK_RX_PACKETS = Gauge(
    "lab_container_network_rx_packets_total",
    "Paquetes recibidos por contenedor",
    LABELS,
)
CONTAINER_NETWORK_TX_PACKETS = Gauge(
    "lab_container_network_tx_packets_total",
    "Paquetes transmitidos por contenedor",
    LABELS,
)
CONTAINER_NETWORK_RX_ERRORS = Gauge(
    "lab_container_network_rx_errors_total",
    "Errores RX por contenedor",
    LABELS,
)
CONTAINER_NETWORK_TX_ERRORS = Gauge(
    "lab_container_network_tx_errors_total",
    "Errores TX por contenedor",
    LABELS,
)
CONTAINER_NETWORK_RX_DROPPED = Gauge(
    "lab_container_network_rx_dropped_total",
    "Drops RX por contenedor",
    LABELS,
)
CONTAINER_NETWORK_TX_DROPPED = Gauge(
    "lab_container_network_tx_dropped_total",
    "Drops TX por contenedor",
    LABELS,
)
CONTAINER_TCP_SYN_RECV = Gauge(
    "lab_container_tcp_syn_recv_connections",
    "Conexiones TCP del contenedor en estado SYN_RECV",
    LABELS,
)
CONTAINER_UPTIME = Gauge(
    "lab_container_uptime_seconds",
    "Uptime aproximado del contenedor en segundos",
    LABELS,
)
CONTAINER_SCRAPE_OK = Gauge(
    "lab_container_scrape_success",
    "Indica si la ultima lectura del contenedor fue exitosa",
    LABELS,
)
EXPORTER_LAST_REFRESH = Gauge(
    "lab_container_refresh_timestamp_seconds",
    "Marca de tiempo de la ultima actualizacion del exportador Docker",
)


def label_values(container) -> Dict[str, str]:
    labels = container.labels or {}
    service = labels.get("com.docker.compose.service", container.name)
    return {"service": service, "container": container.name}


def parse_started_at(value: str) -> float:
    if not value:
        return 0.0
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def calculate_cpu_percent(cpu_total: int, system_total: int, previous_cpu_total: int, previous_system_total: int, cpu_count: int) -> float:
    cpu_delta = cpu_total - previous_cpu_total
    system_delta = system_total - previous_system_total
    if system_delta <= 0 or cpu_delta < 0:
        return 0.0
    return (cpu_delta / system_delta) * max(cpu_count, 1) * 100.0


def live_cpu_percent(container) -> float:
    stream = None
    try:
        stream = container.stats(stream=True, decode=True)
        first = next(stream)
        second = next(stream)

        second_cpu_stats = second.get("cpu_stats", {})
        second_precpu_stats = second.get("precpu_stats", {}) or first.get("cpu_stats", {})
        cpu_count = second_cpu_stats.get("online_cpus") or len(
            second_cpu_stats.get("cpu_usage", {}).get("percpu_usage", [])
        )

        return calculate_cpu_percent(
            int(second_cpu_stats.get("cpu_usage", {}).get("total_usage", 0) or 0),
            int(second_cpu_stats.get("system_cpu_usage", 0) or 0),
            int(second_precpu_stats.get("cpu_usage", {}).get("total_usage", 0) or 0),
            int(second_precpu_stats.get("system_cpu_usage", 0) or 0),
            max(cpu_count, 1),
        )
    except Exception:
        return 0.0
    finally:
        if stream is not None:
            try:
                stream.close()
            except Exception:
                pass


def cpu_percent(container, container_name: str, service_name: str, stats: Dict, started_at: float) -> float:
    if service_name == "web":
        live_value = live_cpu_percent(container)
        if live_value > 0:
            return live_value

    cpu_stats = stats.get("cpu_stats", {})
    precpu_stats = stats.get("precpu_stats", {})
    cpu_total = int(cpu_stats.get("cpu_usage", {}).get("total_usage", 0) or 0)
    system_total = int(cpu_stats.get("system_cpu_usage", 0) or 0)
    cpu_count = cpu_stats.get("online_cpus") or len(
        cpu_stats.get("cpu_usage", {}).get("percpu_usage", [])
    )
    effective_cpu_count = max(cpu_count, 1)

    payload_cpu_percent = calculate_cpu_percent(
        cpu_total,
        system_total,
        int(precpu_stats.get("cpu_usage", {}).get("total_usage", 0) or 0),
        int(precpu_stats.get("system_cpu_usage", 0) or 0),
        effective_cpu_count,
    )

    previous = previous_cpu_samples.get(container_name)
    previous_cpu_samples[container_name] = (cpu_total, system_total, effective_cpu_count, started_at)

    if not previous:
        return payload_cpu_percent

    previous_cpu_total, previous_system_total, previous_cpu_count, previous_started_at = previous
    if previous_started_at != started_at:
        return payload_cpu_percent

    sampled_cpu_percent = calculate_cpu_percent(
        cpu_total,
        system_total,
        previous_cpu_total,
        previous_system_total,
        max(cpu_count or previous_cpu_count, 1),
    )

    if payload_cpu_percent > 0:
        return payload_cpu_percent
    return sampled_cpu_percent


def network_bytes(stats: Dict) -> Dict[str, float]:
    rx_bytes = 0.0
    tx_bytes = 0.0
    for values in stats.get("networks", {}).values():
        rx_bytes += float(values.get("rx_bytes", 0))
        tx_bytes += float(values.get("tx_bytes", 0))
    return {"rx_bytes": rx_bytes, "tx_bytes": tx_bytes}


def network_packets(container) -> Dict[str, float]:
    if not SCRAPE_PACKET_STATS:
        return {
            "rx_packets": 0.0,
            "tx_packets": 0.0,
            "rx_errors": 0.0,
            "tx_errors": 0.0,
            "rx_dropped": 0.0,
            "tx_dropped": 0.0,
        }

    command = (
        "for iface in /sys/class/net/*; do "
        "name=$(basename \"$iface\"); "
        "[ \"$name\" = \"lo\" ] && continue; "
        "for metric in rx_packets tx_packets rx_errors tx_errors rx_dropped tx_dropped; do "
        "printf \"%s,%s,%s\\n\" \"$name\" \"$metric\" \"$(cat \"$iface/statistics/$metric\" 2>/dev/null || echo 0)\"; "
        "done; "
        "done"
    )
    result = container.exec_run(["sh", "-lc", command], demux=False)
    totals = {
        "rx_packets": 0.0,
        "tx_packets": 0.0,
        "rx_errors": 0.0,
        "tx_errors": 0.0,
        "rx_dropped": 0.0,
        "tx_dropped": 0.0,
    }
    if result.exit_code != 0:
        return totals

    for raw_line in result.output.decode("utf-8", errors="ignore").splitlines():
        parts = raw_line.strip().split(",")
        if len(parts) != 3:
            continue
        _, metric, value = parts
        if metric in totals:
            try:
                totals[metric] += float(value)
            except ValueError:
                continue
    return totals


def tcp_syn_recv_connections(container) -> float:
    command = (
        "command -v ss >/dev/null 2>&1 || { echo 0; exit 0; }; "
        "ss -tan state syn-recv 2>/dev/null | tail -n +2 | wc -l | tr -d ' '"
    )
    result = container.exec_run(["sh", "-lc", command], demux=False)
    if result.exit_code != 0:
        return 0.0

    output = result.output.decode("utf-8", errors="ignore").strip() or "0"
    try:
        return float(output)
    except ValueError:
        return 0.0


def docker_cli_cpu_percent_map() -> Dict[str, float]:
    try:
        result = subprocess.run(
            ["docker", "stats", "--no-stream", "--format", "{{.Name}},{{.CPUPerc}}"],
            check=True,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except Exception:
        return {}

    cpu_by_container: Dict[str, float] = {}
    for raw_line in result.stdout.splitlines():
        line = raw_line.strip()
        if not line or "," not in line:
            continue
        container_name, cpu_value = line.rsplit(",", 1)
        normalized = cpu_value.strip().rstrip("%").replace(",", ".")
        try:
            cpu_by_container[container_name.strip()] = float(normalized)
        except ValueError:
            continue
    return cpu_by_container


def should_scrape_packet_stats(service_name: str) -> bool:
    return service_name in {"atacante", "router", "web"}


def should_scrape_syn_recv(service_name: str) -> bool:
    return service_name == "web"


def refresh_metrics():
    global last_refresh_timestamp

    containers = client.containers.list(
        all=True,
        filters={"label": f"com.docker.compose.project={PROJECT_NAME}"},
    )
    now = dt.datetime.now(dt.timezone.utc).timestamp()
    active_container_names = set()
    cli_cpu_by_container = docker_cli_cpu_percent_map()

    for container in containers:
        labels = label_values(container)
        if labels["service"] not in SCRAPED_SERVICES:
            continue

        active_container_names.add(container.name)
        label_tuple = [labels["service"], labels["container"]]
        state = container.attrs.get("State", {})
        started_at = parse_started_at(state.get("StartedAt", ""))
        is_running = state.get("Status") == "running"

        CONTAINER_UP.labels(*label_tuple).set(1 if is_running else 0)
        CONTAINER_UPTIME.labels(*label_tuple).set(max(now - started_at, 0) if started_at else 0)

        if not is_running:
            previous_cpu_samples.pop(container.name, None)
            CONTAINER_CPU.labels(*label_tuple).set(0)
            CONTAINER_MEMORY_USAGE.labels(*label_tuple).set(0)
            CONTAINER_MEMORY_LIMIT.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_RX_BYTES.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_TX_BYTES.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_RX_PACKETS.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_TX_PACKETS.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_RX_ERRORS.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_TX_ERRORS.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_RX_DROPPED.labels(*label_tuple).set(0)
            CONTAINER_NETWORK_TX_DROPPED.labels(*label_tuple).set(0)
            CONTAINER_TCP_SYN_RECV.labels(*label_tuple).set(0)
            CONTAINER_SCRAPE_OK.labels(*label_tuple).set(0)
            continue

        try:
            stats = container.stats(stream=False)
            packets = network_packets(container) if should_scrape_packet_stats(labels["service"]) else {
                "rx_packets": 0.0,
                "tx_packets": 0.0,
                "rx_errors": 0.0,
                "tx_errors": 0.0,
                "rx_dropped": 0.0,
                "tx_dropped": 0.0,
            }
            network = network_bytes(stats)
            syn_recv = tcp_syn_recv_connections(container) if should_scrape_syn_recv(labels["service"]) else 0.0
            memory = stats.get("memory_stats", {})

            cli_cpu_percent = cli_cpu_by_container.get(container.name)
            cpu_value = (
                cli_cpu_percent
                if cli_cpu_percent is not None
                else cpu_percent(container, container.name, labels["service"], stats, started_at)
            )

            CONTAINER_CPU.labels(*label_tuple).set(cpu_value)
            CONTAINER_MEMORY_USAGE.labels(*label_tuple).set(float(memory.get("usage", 0)))
            CONTAINER_MEMORY_LIMIT.labels(*label_tuple).set(float(memory.get("limit", 0)))
            CONTAINER_NETWORK_RX_BYTES.labels(*label_tuple).set(network["rx_bytes"])
            CONTAINER_NETWORK_TX_BYTES.labels(*label_tuple).set(network["tx_bytes"])
            CONTAINER_NETWORK_RX_PACKETS.labels(*label_tuple).set(packets["rx_packets"])
            CONTAINER_NETWORK_TX_PACKETS.labels(*label_tuple).set(packets["tx_packets"])
            CONTAINER_NETWORK_RX_ERRORS.labels(*label_tuple).set(packets["rx_errors"])
            CONTAINER_NETWORK_TX_ERRORS.labels(*label_tuple).set(packets["tx_errors"])
            CONTAINER_NETWORK_RX_DROPPED.labels(*label_tuple).set(packets["rx_dropped"])
            CONTAINER_NETWORK_TX_DROPPED.labels(*label_tuple).set(packets["tx_dropped"])
            CONTAINER_TCP_SYN_RECV.labels(*label_tuple).set(syn_recv)
            CONTAINER_SCRAPE_OK.labels(*label_tuple).set(1)
        except Exception:
            previous_cpu_samples.pop(container.name, None)
            app.logger.exception("No se pudo refrescar metricas del contenedor %s", container.name)
            CONTAINER_TCP_SYN_RECV.labels(*label_tuple).set(0)
            CONTAINER_SCRAPE_OK.labels(*label_tuple).set(0)

    stale_containers = set(previous_cpu_samples.keys()) - active_container_names
    for container_name in stale_containers:
        previous_cpu_samples.pop(container_name, None)

    last_refresh_timestamp = now
    EXPORTER_LAST_REFRESH.set(now)


def refresh_loop():
    while True:
        try:
            with refresh_lock:
                refresh_metrics()
        except Exception:
            app.logger.exception("Fallo el ciclo de actualizacion del exporter Docker")
        time.sleep(REFRESH_INTERVAL_SECONDS)


@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype="text/plain; version=0.0.4")


if __name__ == "__main__":
    threading.Thread(target=refresh_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=9151)
