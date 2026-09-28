from __future__ import annotations

import asyncio
import json
import os
import re
import threading
import time
import webbrowser
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

BASE_DIR = Path(__file__).resolve().parent
CONFIG_PATH = BASE_DIR / "config.json"
HTML_PATH = BASE_DIR / "static" / "index.html"
CARDS = [
    "Archer", "Barbarian", "BabyDragon", "Giant", "MiniPekka", "Valkyrie",
    "Wizard", "Cannon", "InfernoTower", "FireBall", "Arrows", "Rage"
]
TEAMS = {"blue", "red"}
LANES = {"auto", "left", "right"}

DEFAULT_CONFIG: dict[str, Any] = {
    "tiktok_username": "",
    "euler_api_key": "",
    "max_spawn_per_event": 20,
    "gift_rules": [
        {"enabled": True, "gift_id": "", "gift_name": "Rose", "team": "blue", "card": "Archer", "count": 1, "lane": "auto"},
        {"enabled": True, "gift_id": "", "gift_name": "TikTok", "team": "red", "card": "Barbarian", "count": 1, "lane": "auto"}
    ],
    "comment_rules": [
        {"enabled": True, "trigger": "azul", "match": "exact", "team": "blue", "card": "Archer", "count": 1, "lane": "auto"},
        {"enabled": True, "trigger": "vermelho", "match": "exact", "team": "red", "card": "Barbarian", "count": 1, "lane": "auto"},
        {"enabled": True, "trigger": "gigante azul", "match": "contains", "team": "blue", "card": "Giant", "count": 1, "lane": "left"},
        {"enabled": True, "trigger": "gigante vermelho", "match": "contains", "team": "red", "card": "Giant", "count": 1, "lane": "right"}
    ]
}


def deep_copy_default() -> dict[str, Any]:
    return json.loads(json.dumps(DEFAULT_CONFIG))


def load_config() -> dict[str, Any]:
    if not CONFIG_PATH.exists():
        cfg = deep_copy_default()
        save_config(cfg)
        return cfg
    try:
        raw = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        cfg = deep_copy_default()
        cfg.update(raw if isinstance(raw, dict) else {})
        cfg.setdefault("gift_rules", [])
        cfg.setdefault("comment_rules", [])
        return cfg
    except Exception:
        cfg = deep_copy_default()
        save_config(cfg)
        return cfg


def save_config(config: dict[str, Any]) -> None:
    CONFIG_PATH.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


class SpawnRequest(BaseModel):
    team: Literal["blue", "red"] = "blue"
    card: str = "Archer"
    count: int = Field(default=1, ge=1, le=50)
    lane: Literal["auto", "left", "right"] = "auto"
    source: str = "panel"
    username: str = "teste"


class CommentTest(BaseModel):
    comment: str
    username: str = "teste"


class ConfigPayload(BaseModel):
    tiktok_username: str = ""
    euler_api_key: str = ""
    max_spawn_per_event: int = Field(default=20, ge=1, le=50)
    gift_rules: list[dict[str, Any]] = []
    comment_rules: list[dict[str, Any]] = []


@dataclass
class LiveState:
    connected: bool = False
    connecting: bool = False
    room_id: str = ""
    username: str = ""
    last_error: str = ""


app = FastAPI(title="BRABO7X TikTok Clash LIVE", docs_url=None, redoc_url=None)
config = load_config()
state = LiveState()
admin_clients: set[WebSocket] = set()
game_clients: set[WebSocket] = set()
logs: list[dict[str, Any]] = []
_tiktok_thread: threading.Thread | None = None
_tiktok_stop_requested = threading.Event()
_tiktok_client: Any = None
_tiktok_loop: asyncio.AbstractEventLoop | None = None
_main_loop: asyncio.AbstractEventLoop | None = None
_gift_streak_counts: dict[str, int] = {}


def public_config() -> dict[str, Any]:
    cfg = dict(config)
    key = str(cfg.pop("euler_api_key", ""))
    cfg["euler_api_key_masked"] = ("•" * max(0, len(key) - 4) + key[-4:]) if key else ""
    return cfg


def status_payload() -> dict[str, Any]:
    return {
        "type": "status",
        "live": {
            "connected": state.connected,
            "connecting": state.connecting,
            "room_id": state.room_id,
            "username": state.username,
            "last_error": state.last_error,
        },
        "game_connected": len(game_clients) > 0,
        "game_clients": len(game_clients),
        "cards": CARDS,
    }


async def broadcast_admin(payload: dict[str, Any]) -> None:
    dead: list[WebSocket] = []
    for ws in list(admin_clients):
        try:
            await ws.send_json(payload)
        except Exception:
            dead.append(ws)
    for ws in dead:
        admin_clients.discard(ws)


async def add_log(kind: str, message: str, **extra: Any) -> None:
    item = {"ts": time.strftime("%H:%M:%S"), "kind": kind, "message": message, **extra}
    logs.append(item)
    if len(logs) > 250:
        del logs[:-250]
    await broadcast_admin({"type": "log", "item": item})


async def broadcast_status() -> None:
    await broadcast_admin(status_payload())


async def send_spawn(spawn: SpawnRequest) -> int:
    safe_count = min(int(spawn.count), int(config.get("max_spawn_per_event", 20)))
    payload = {
        "type": "spawn",
        "team": spawn.team,
        "card": spawn.card,
        "count": safe_count,
        "lane": spawn.lane,
        "source": spawn.source,
        "username": spawn.username,
    }
    dead: list[WebSocket] = []
    delivered = 0
    for ws in list(game_clients):
        try:
            await ws.send_json(payload)
            delivered += 1
        except Exception:
            dead.append(ws)
    for ws in dead:
        game_clients.discard(ws)
    await add_log("spawn", f"{spawn.team.upper()} +{safe_count} {spawn.card} ({spawn.source})", username=spawn.username)
    await broadcast_status()
    return delivered


def normalize_text(value: str) -> str:
    return " ".join(str(value or "").strip().lower().split())


async def process_comment(comment: str, username: str) -> int:
    text = normalize_text(comment)
    triggered = 0
    for rule in config.get("comment_rules", []):
        if not rule.get("enabled", True):
            continue
        trigger = normalize_text(rule.get("trigger", ""))
        if not trigger:
            continue
        mode = str(rule.get("match", "exact"))
        matched = text == trigger if mode == "exact" else trigger in text
        if mode == "regex":
            try:
                matched = re.search(str(rule.get("trigger", "")), comment, re.IGNORECASE) is not None
            except re.error:
                matched = False
        if matched:
            await send_spawn(SpawnRequest(
                team=rule.get("team", "blue"),
                card=rule.get("card", "Archer"),
                count=max(1, min(int(rule.get("count", 1)), 50)),
                lane=rule.get("lane", "auto"),
                source=f"comment:{comment}",
                username=username,
            ))
            triggered += 1
    await add_log("comment", f"@{username}: {comment}" + (f" → {triggered} regra(s)" if triggered else ""))
    return triggered


def extract_gift_id(event: Any) -> str:
    gift = getattr(event, "gift", None)
    for obj in (gift, getattr(gift, "info", None), event):
        if obj is None:
            continue
        for attr in ("id", "gift_id", "giftId"):
            value = getattr(obj, attr, None)
            if value not in (None, ""):
                return str(value)
    return ""


def extract_gift_name(event: Any) -> str:
    gift = getattr(event, "gift", None)
    for obj in (gift, getattr(gift, "info", None), event):
        if obj is None:
            continue
        for attr in ("name", "gift_name", "giftName"):
            value = getattr(obj, attr, None)
            if value:
                return str(value)
    return "Unknown Gift"


def extract_repeat_count(event: Any) -> int:
    candidates = [
        getattr(event, "repeat_count", None),
        getattr(getattr(event, "gift", None), "repeat_count", None),
        getattr(getattr(event, "gift", None), "count", None),
    ]
    for value in candidates:
        try:
            if value is not None:
                return max(1, int(value))
        except Exception:
            pass
    return 1


def extract_user(event: Any) -> str:
    user = getattr(event, "user", None)
    return str(getattr(user, "unique_id", None) or getattr(user, "nickname", None) or "viewer")


async def process_gift(event: Any) -> int:
    gift_id = extract_gift_id(event)
    gift_name = extract_gift_name(event)
    repeat_count = extract_repeat_count(event)
    username = extract_user(event)

    # TikTokLive emits updates during a streak. Spawn only the delta so a 10x streak = 10 units, not 1+2+...+10.
    streak_key = f"{username}:{gift_id or gift_name}"
    previous = _gift_streak_counts.get(streak_key, 0)
    delta = repeat_count - previous if repeat_count >= previous else repeat_count
    if delta <= 0:
        delta = 0
    _gift_streak_counts[streak_key] = repeat_count

    gift = getattr(event, "gift", None)
    is_repeating = getattr(gift, "is_repeating", None)
    streaking = getattr(event, "streaking", None)
    repeat_end = getattr(event, "repeat_end", None)
    if streaking is False or repeat_end == 1 or is_repeating == 0:
        # Keep the current count through this final packet; the next fresh streak can start from 1.
        async def clear_later() -> None:
            await asyncio.sleep(1.2)
            _gift_streak_counts.pop(streak_key, None)
        asyncio.create_task(clear_later())

    triggered = 0
    if delta > 0:
        for rule in config.get("gift_rules", []):
            if not rule.get("enabled", True):
                continue
            rule_id = str(rule.get("gift_id", "")).strip()
            rule_name = normalize_text(rule.get("gift_name", ""))
            id_match = bool(rule_id) and rule_id == gift_id
            name_match = bool(rule_name) and rule_name == normalize_text(gift_name)
            if id_match or name_match:
                base_count = max(1, min(int(rule.get("count", 1)), 50))
                total = min(base_count * delta, int(config.get("max_spawn_per_event", 20)))
                await send_spawn(SpawnRequest(
                    team=rule.get("team", "blue"),
                    card=rule.get("card", "Archer"),
                    count=total,
                    lane=rule.get("lane", "auto"),
                    source=f"gift:{gift_name}",
                    username=username,
                ))
                triggered += 1

    await add_log("gift", f"@{username}: {gift_name} x{repeat_count}" + (f" (+{delta})" if delta else ""))
    return triggered


def schedule_on_main(coro: Any) -> None:
    if _main_loop and _main_loop.is_running():
        asyncio.run_coroutine_threadsafe(coro, _main_loop)


def run_tiktok_client(username: str, api_key: str) -> None:
    global _tiktok_client, _tiktok_loop
    loop = asyncio.new_event_loop()
    _tiktok_loop = loop
    asyncio.set_event_loop(loop)
    try:
        from TikTokLive import TikTokLiveClient
        from TikTokLive.client.web.web_settings import WebDefaults
        from TikTokLive.events import CommentEvent, ConnectEvent, DisconnectEvent, GiftEvent

        if api_key:
            WebDefaults.tiktok_sign_api_key = api_key

        unique_id = username if username.startswith("@") else f"@{username}"
        client = TikTokLiveClient(unique_id=unique_id)
        _tiktok_client = client

        @client.on(ConnectEvent)
        async def on_connect(event: Any) -> None:
            state.connected = True
            state.connecting = False
            state.username = username.lstrip("@")
            state.room_id = str(getattr(event, "room_id", "") or getattr(client, "room_id", "") or "")
            state.last_error = ""
            schedule_on_main(add_log("system", f"LIVE conectada: @{state.username} | Room {state.room_id or '-'}"))
            schedule_on_main(broadcast_status())

        @client.on(CommentEvent)
        async def on_comment(event: Any) -> None:
            schedule_on_main(process_comment(str(getattr(event, "comment", "")), extract_user(event)))

        @client.on(GiftEvent)
        async def on_gift(event: Any) -> None:
            schedule_on_main(process_gift(event))

        @client.on(DisconnectEvent)
        async def on_disconnect(event: Any) -> None:
            state.connected = False
            state.connecting = False
            schedule_on_main(add_log("system", "TikTok LIVE desconectada"))
            schedule_on_main(broadcast_status())

        loop.run_until_complete(client.connect(fetch_gift_info=True))
    except Exception as exc:
        state.connected = False
        state.connecting = False
        state.last_error = f"{type(exc).__name__}: {exc}"
        schedule_on_main(add_log("error", f"Falha ao conectar TikTok: {state.last_error}"))
        schedule_on_main(broadcast_status())
    finally:
        try:
            if _tiktok_client is not None:
                loop.run_until_complete(_tiktok_client.close())
        except Exception:
            pass
        _tiktok_client = None
        _tiktok_loop = None
        try:
            loop.close()
        except Exception:
            pass


import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

@app.on_event("startup")
async def on_startup() -> None:
    global _main_loop
    _main_loop = asyncio.get_running_loop()
    await add_log("system", "Painel BRABO7X iniciado em http://127.0.0.1:8765")
    print("[BRABO7X] Servidor online! Abra http://127.0.0.1:8765 no navegador.")


@app.get("/", response_class=HTMLResponse)
async def index() -> HTMLResponse:
    return HTMLResponse(HTML_PATH.read_text(encoding="utf-8"))


@app.get("/api/status")
async def get_status() -> dict[str, Any]:
    return {**status_payload(), "config": public_config(), "logs": logs[-80:]}


@app.get("/api/config")
async def get_config() -> dict[str, Any]:
    return public_config()


@app.post("/api/config")
async def set_config(payload: ConfigPayload) -> dict[str, Any]:
    global config
    cfg = payload.model_dump()
    submitted_key = str(cfg.get("euler_api_key", "")).strip()
    cfg["euler_api_key"] = submitted_key or str(config.get("euler_api_key", ""))
    for rule in cfg.get("gift_rules", []) + cfg.get("comment_rules", []):
        if rule.get("card") not in CARDS:
            raise HTTPException(400, f"Carta inválida: {rule.get('card')}")
        if rule.get("team") not in TEAMS:
            raise HTTPException(400, "Time inválido")
        if rule.get("lane", "auto") not in LANES:
            raise HTTPException(400, "Lane inválida")
    config = cfg
    save_config(config)
    await add_log("system", "Configurações salvas")
    return {"ok": True, "config": public_config()}


@app.post("/api/live/connect")
async def connect_live() -> dict[str, Any]:
    global _tiktok_thread
    if state.connected or state.connecting:
        return {"ok": True, "message": "Conexão já ativa"}
    username = str(config.get("tiktok_username", "")).strip().lstrip("@")
    if not username:
        raise HTTPException(400, "Informe o @ do TikTok e salve as configurações.")
    state.connecting = True
    state.last_error = ""
    _tiktok_stop_requested.clear()
    _tiktok_thread = threading.Thread(
        target=run_tiktok_client,
        args=(username, str(config.get("euler_api_key", "")).strip()),
        daemon=True,
        name="brabo7x-tiktoklive",
    )
    _tiktok_thread.start()
    await add_log("system", f"Conectando à LIVE @{username}...")
    await broadcast_status()
    return {"ok": True}


@app.post("/api/live/disconnect")
async def disconnect_live() -> dict[str, Any]:
    global _tiktok_client
    client = _tiktok_client
    loop = _tiktok_loop
    if client is not None and loop is not None and loop.is_running():
        try:
            future = asyncio.run_coroutine_threadsafe(client.disconnect(close_client=True), loop)
            future.result(timeout=5)
        except Exception:
            pass
    state.connected = False
    state.connecting = False
    await add_log("system", "Desconexão solicitada")
    await broadcast_status()
    return {"ok": True}


@app.post("/api/test/spawn")
async def test_spawn(payload: SpawnRequest) -> dict[str, Any]:
    if payload.card not in CARDS:
        raise HTTPException(400, "Carta inválida")
    delivered = await send_spawn(payload)
    return {"ok": True, "delivered_to_game": delivered}


@app.post("/api/test/comment")
async def test_comment(payload: CommentTest) -> dict[str, Any]:
    triggered = await process_comment(payload.comment, payload.username)
    return {"ok": True, "triggered": triggered}


@app.websocket("/ws/admin")
async def ws_admin(ws: WebSocket) -> None:
    await ws.accept()
    admin_clients.add(ws)
    await ws.send_json(status_payload())
    await ws.send_json({"type": "logs", "items": logs[-80:]})
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        admin_clients.discard(ws)


@app.websocket("/ws/game")
async def ws_game(ws: WebSocket) -> None:
    await ws.accept()
    game_clients.add(ws)
    await add_log("system", "Jogo Java conectado ao WebSocket")
    await broadcast_status()
    try:
        while True:
            raw = await ws.receive_text()
            try:
                msg = json.loads(raw)
            except Exception:
                msg = {"type": "game_message", "message": raw}
            if msg.get("type") == "game_ready":
                await add_log("system", f"Jogo pronto: {msg.get('message', 'OK')}")
    except WebSocketDisconnect:
        pass
    finally:
        game_clients.discard(ws)
        await add_log("system", "Jogo Java desconectado")
        await broadcast_status()


def main() -> None:
    import uvicorn
    threading.Timer(1.2, lambda: webbrowser.open("http://127.0.0.1:8765")).start()
    uvicorn.run(app, host="127.0.0.1", port=8765, log_level="warning")


if __name__ == "__main__":
    main()
