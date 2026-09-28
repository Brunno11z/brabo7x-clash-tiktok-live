package controllers.menus;

import controllers.Controller;
import javafx.fxml.FXMLLoader;
import javafx.scene.Cursor;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.effect.ColorAdjust;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Objects;

/**
 * The type Scene controller.
 */
public class SceneController {
    private final HashMap<String, Scene> menus;
    private final ArrayList<String> cardsUrls;
    private final HashMap<String, Image> gifs;
    private final HashMap<String, Image> battleCardsBoxImages;
    private final HashMap<String, Image> comingCardsBoxImages;
    private final HashMap<String, Image> nextCardImages;

    /**
     * Instantiates a new Scene controller.
     */
    public SceneController() {
        this.menus = new HashMap<>();
        this.cardsUrls = new ArrayList<>();
        this.gifs = new HashMap<>();
        this.battleCardsBoxImages = new HashMap<>();
        this.comingCardsBoxImages = new HashMap<>();
        this.nextCardImages = new HashMap<>();
    }

    /**
     * Remove scene.
     *
     * @param sceneName the scene name
     */
    public void removeScene(String sceneName) {
        this.menus.remove(sceneName);
    }

    /**
     * Show scene.
     *
     * @param sceneName the scene name
     */
    public void showScene(String sceneName) {
        try {
            Scene scene;
            if (menus.containsKey(sceneName)) {
                scene = menus.get(sceneName);
            } else {
                URL url = resolveViewUrl(sceneName);
                if (url == null) {
                    throw new IOException("Arquivo de visualização não encontrado: " + sceneName);
                }
                Parent root = FXMLLoader.load(url);
                scene = new Scene(root, 528, 946);
                this.menus.put(sceneName, scene);
            }

            Controller.STAGE.setTitle("BRABO7X CLASH LIVE - Azul x Vermelho");
            Controller.STAGE.setScene(scene);
            Controller.STAGE.show();
        } catch (Exception e) {
            System.err.println("[BRABO7X] Erro ao carregar cena: " + sceneName);
            e.printStackTrace();
        }
    }

    private URL resolveViewUrl(String sceneName) {
        try {
            File direct = new File(Controller.VIEW_PATH, sceneName);
            if (direct.exists()) {
                return direct.toURI().toURL();
            }
            File fallback = new File("client/src/main/java/views", sceneName);
            if (fallback.exists()) {
                return fallback.toURI().toURL();
            }
            File fallbackCore = new File("src/main/java/views", sceneName);
            if (fallbackCore.exists()) {
                return fallbackCore.toURI().toURL();
            }
            return getClass().getResource("/views/" + sceneName);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Load all menu scenes.
     */
    public void loadAllMenuScenes() {
        try {
            Path dirPath = resolveDirPath(Controller.VIEW_PATH + "Menu", "client/src/main/java/views/Menu");
            if (dirPath == null || !Files.exists(dirPath)) return;
            try (DirectoryStream<Path> directoryStream = Files.newDirectoryStream(dirPath)) {
                for (Path path : directoryStream) {
                    URL url = path.toUri().toURL();
                    Parent menuRoot = FXMLLoader.load(Objects.requireNonNull(url));
                    menus.put("Menu/" + path.getFileName(), new Scene(menuRoot, 528, 946));
                }
            }
        } catch (Exception e) {
            System.err.println("[BRABO7X] Aviso ao carregar menus: " + e.getMessage());
        }
    }

    /**
     * Load all cards urls.
     */
    public void loadAllCardsUrls() {
        try {
            Path dirPath = resolveDirPath(Controller.RESOURCE_PATH + "photos", "client/src/main/resources/photos");
            if (dirPath == null || !Files.exists(dirPath)) {
                System.err.println("[BRABO7X] Pasta de fotos não encontrada");
                return;
            }
            try (DirectoryStream<Path> directoryStream = Files.newDirectoryStream(dirPath)) {
                for (Path path : directoryStream) {
                    if (path.toString().contains("Card")) {
                        this.cardsUrls.add(path.toUri().toURL().toString());
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("[BRABO7X] Aviso ao carregar cartas: " + e.getMessage());
        }
    }

    /**
     * Load card box images.
     */
    public void loadCardBoxImages() {
        for (String url : this.cardsUrls) {
            String className = getClassName(url);
            Image battleBoxImage = new Image(url, 59, 73, true, true);
            Image comingBoxImage = new Image(url, 34, 41, true, true);
            Image nextCardImage = new Image(url, 50, 62, true, true);

            this.battleCardsBoxImages.put(className, battleBoxImage);
            this.comingCardsBoxImages.put(className, comingBoxImage);
            this.nextCardImages.put(className, nextCardImage);
        }
    }

    private String getClassName(String url) {
        String[] parts = url.split("/");
        int lastIndex = parts.length - 1;
        String className = parts[lastIndex].replace("Card.png", "");
        return switch (className) {
            case "Archers" -> "Archer";
            case "Barbarians" -> "Barbarian";
            case "MiniPEKKA" -> "MiniPekka";
            case "Fireball" -> "FireBall";
            default -> className;
        };
    }

    /**
     * Load gifs.
     */
    public void loadGifs() {
        try {
            Path dirPath = resolveDirPath(Controller.RESOURCE_PATH + "gifs", "client/src/main/resources/gifs");
            if (dirPath == null || !Files.exists(dirPath)) {
                System.err.println("[BRABO7X] Pasta de GIFs não encontrada");
                return;
            }
            try (DirectoryStream<Path> directoryStream = Files.newDirectoryStream(dirPath)) {
                for (Path path : directoryStream) {
                    String name = path.getFileName().toString().replace(".gif", "");
                    if (name.equals("splash_screen_time_line")) continue;

                    ArrayList<Integer> size = getSizeFromName(name);
                    Image gif = new Image(path.toUri().toURL().toString(), size.get(0), size.get(1), true, true);
                    String key = getKeyFromName(name);
                    this.gifs.put(key, gif);
                }
            }
        } catch (Exception e) {
            System.err.println("[BRABO7X] Aviso ao carregar GIFs: " + e.getMessage());
        }
    }

    private Path resolveDirPath(String preferredPath, String fallbackRel) {
        try {
            Path p = Paths.get(preferredPath);
            if (Files.exists(p)) return p;
        } catch (Exception ignored) {}
        try {
            Path p = Paths.get(fallbackRel);
            if (Files.exists(p)) return p;
        } catch (Exception ignored) {}
        try {
            Path p = Paths.get("..", fallbackRel);
            if (Files.exists(p)) return p;
        } catch (Exception ignored) {}
        return null;
    }

    private ArrayList<Integer> getSizeFromName(String name) {
        ArrayList<Integer> size = new ArrayList<>();
        String[] elements = name.split("_");
        String sizePart = elements[3];
        String[] widthHeight = sizePart.split("-");
        size.add(Integer.parseInt(widthHeight[0]));
        size.add(Integer.parseInt(widthHeight[1]));
        return size;
    }

    private String getKeyFromName(String name) {
        String[] elements = name.split("_");
        return elements[0] + "_" + elements[1] + "_" + elements[2];
    }

    /**
     * Convert to black and white.
     */
    public void convertToBlackAndWhite(ImageView imageView) {
        ColorAdjust colorAdjust = new ColorAdjust();
        colorAdjust.setSaturation(-1);
        colorAdjust.setBrightness(-0.2);
        imageView.setEffect(colorAdjust);
        imageView.setCursor(Cursor.DEFAULT);
    }

    /**
     * Convert to colorful.
     */
    public void convertToColorful(ImageView imageView) {
        imageView.setEffect(null);
        imageView.setCursor(Cursor.HAND);
    }

    public ArrayList<String> getCardsUrls() {
        return cardsUrls;
    }

    public Image getGif(String key) {
        if (!gifs.containsKey(key)) {
            key = key.replace("walk", "fight");
        }
        return gifs.get(key);
    }

    public Image getBattleBoxImg(String className) {
        return this.battleCardsBoxImages.get(className);
    }

    public Image getComingBoxImg(String className) {
        return this.comingCardsBoxImages.get(className);
    }

    public Image getNextCardImg(String className) {
        return this.nextCardImages.get(className);
    }
}
