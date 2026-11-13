import os
from flask import Flask, jsonify, request
import redis

app = Flask(__name__)

redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    decode_responses=True
)


@app.route("/health", methods=["GET"])
def health():
    try:
        redis_client.ping()
        return jsonify({
            "status": "ok",
            "service": "cache-api",
            "redis": "connected"
        })
    except redis.RedisError:
        return jsonify({
            "status": "error",
            "redis": "disconnected"
        }), 503


@app.route("/consultas", methods=["POST"])
def guardar_consulta():
    data = request.get_json(silent=True) or {}
    consulta = data.get("consulta")

    if not isinstance(consulta, str) or not consulta.strip():
        return jsonify({"error": "La consulta es obligatoria"}), 400

    try:
        total = redis_client.incr("wikijs:consultas:total")
        redis_client.lpush("wikijs:consultas:recientes", consulta.strip())
        redis_client.ltrim("wikijs:consultas:recientes", 0, 9)

        return jsonify({
            "mensaje": "Consulta registrada correctamente",
            "total": total
        }), 201
    except redis.RedisError:
        return jsonify({"error": "Redis no disponible"}), 503


@app.route("/consultas", methods=["GET"])
def listar_consultas():
    try:
        consultas = redis_client.lrange(
            "wikijs:consultas:recientes", 0, 9
        )
        total = int(redis_client.get("wikijs:consultas:total") or 0)

        return jsonify({
            "total": total,
            "consultas_recientes": consultas
        })
    except redis.RedisError:
        return jsonify({"error": "Redis no disponible"}), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)