package interactive;

import controllers.modes.botControllers.BotController;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.WebSocket;
import java.time.Duration;
import java.util.Objects;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Lightweight local WebSocket bridge between the JavaFX game and the Python
 * BRABO7X TikTok LIVE control panel.
 */
public final class TikTokInteractiveBridge implements WebSocket.Listener {
    private static final URI BRIDGE_URI = URI.create(System.getProperty(
            "brabo7x.bridgeUrl", "ws://127.0.0.1:8765/ws/game"));
    private static final ScheduledExecutorService RECONNECTOR = Executors.newSingleThreadScheduledExecutor(r -> {
        Thread t = new Thread(r, "brabo7x-ws-reconnector");
        t.setDaemon(true);
        return t;
    });
    private static final Pattern STRING_FIELD = Pattern.compile("\\\"([a-zA-Z0-9_]+)\\\"\\s*:\\s*\\\"([^\\\"]*)\\\"");
    private static final Pattern INT_FIELD = Pattern.compile("\\\"([a-zA-Z0-9_]+)\\\"\\s*:\\s*(-?\\d+)");
    private static volatile TikTokInteractiveBridge INSTANCE;
    private static volatile BotController controller;

    private final HttpClient client;
    private final StringBuilder partialMessage = new StringBuilder();
    private volatile WebSocket socket;
    private volatile boolean connecting;

    private TikTokInteractiveBridge() {
        this.client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(4))
                .build();
    }

    public static synchronized void startOrAttach(BotController gameController) {
        controller = Objects.requireNonNull(gameController);
        if (INSTANCE == null) {
            INSTANCE = new TikTokInteractiveBridge();
            INSTANCE.connect();
        } else if (INSTANCE.socket == null) {
            INSTANCE.connect();
        } else {
            INSTANCE.send("{\"type\":\"game_ready\",\"message\":\"controller_attached\"}");
        }
    }

    public static boolean isEnabled() {
        return Boolean.getBoolean("brabo7x.tiktok");
    }

    private synchronized void connect() {
        if (!isEnabled() || connecting || socket != null) return;
        connecting = true;
        client.newWebSocketBuilder()
                .connectTimeout(Duration.ofSeconds(4))
                .buildAsync(BRIDGE_URI, this)
                .whenComplete((ws, error) -> {
                    connecting = false;
                    if (error != null) {
                        scheduleReconnect();
                    } else {
                        socket = ws;
                    }
                });
    }

    private void scheduleReconnect() {
        if (!isEnabled()) return;
        RECONNECTOR.schedule(this::connect, 2, TimeUnit.SECONDS);
    }

    public void send(String json) {
        WebSocket ws = socket;
        if (ws != null) {
            ws.sendText(json, true);
        }
    }

    @Override
    public void onOpen(WebSocket webSocket) {
        this.socket = webSocket;
        webSocket.request(1);
        send("{\"type\":\"game_ready\",\"message\":\"BRABO7X Clash LIVE connected\"}");
    }

    @Override
    public CompletionStage<?> onText(WebSocket webSocket, CharSequence data, boolean last) {
        partialMessage.append(data);
        if (last) {
            String payload = partialMessage.toString();
            partialMessage.setLength(0);
            handleMessage(payload);
        }
        webSocket.request(1);
        return null;
    }

    private void handleMessage(String json) {
        String type = stringField(json, "type", "");
        if ("spawn".equalsIgnoreCase(type)) {
            String team = stringField(json, "team", "blue");
            String card = stringField(json, "card", "Archer");
            String lane = stringField(json, "lane", "auto");
            String source = stringField(json, "source", "panel");
            String username = stringField(json, "username", "");
            int count = intField(json, "count", 1);
            BotController current = controller;
            if (current != null) {
                current.queueInteractiveSpawn(team, card, count, lane, source, username);
            }
        }
    }

    private static String stringField(String json, String key, String fallback) {
        Matcher matcher = STRING_FIELD.matcher(json);
        while (matcher.find()) {
            if (key.equals(matcher.group(1))) return matcher.group(2);
        }
        return fallback;
    }

    private static int intField(String json, String key, int fallback) {
        Matcher matcher = INT_FIELD.matcher(json);
        while (matcher.find()) {
            if (key.equals(matcher.group(1))) {
                try {
                    return Integer.parseInt(matcher.group(2));
                } catch (NumberFormatException ignored) {
                    return fallback;
                }
            }
        }
        return fallback;
    }

    @Override
    public CompletionStage<?> onClose(WebSocket webSocket, int statusCode, String reason) {
        socket = null;
        scheduleReconnect();
        return null;
    }

    @Override
    public void onError(WebSocket webSocket, Throwable error) {
        socket = null;
        scheduleReconnect();
    }
}
