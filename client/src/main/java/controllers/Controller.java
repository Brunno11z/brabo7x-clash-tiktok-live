package controllers;

import controllers.menus.SceneController;
import database.queryBuilders.CardQueryBuilder;
import database.queryBuilders.HistoryQueryBuilder;
import javafx.stage.Stage;

import java.io.File;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

/**
 * The interface Controller.
 */
public interface Controller {
    static String getBasePath() {
        try {
            String path = Controller.class.getProtectionDomain().getCodeSource().getLocation().toURI().getPath();
            if (path == null) {
                path = Controller.class.getProtectionDomain().getCodeSource().getLocation().getPath();
                path = URLDecoder.decode(path, StandardCharsets.UTF_8);
            }
            if (System.getProperty("os.name", "").toLowerCase().contains("win") && path.startsWith("/") && path.length() > 2 && path.charAt(2) == ':') {
                path = path.substring(1);
            }
            return path;
        } catch (Exception e) {
            String fallback = new File(".").getAbsolutePath();
            if (fallback.endsWith(".")) {
                fallback = fallback.substring(0, fallback.length() - 1);
            }
            return fallback;
        }
    }

    /**
     * The constant VIEW_PATH.
     */
    String VIEW_PATH = getBasePath().replace("target/classes/", "src/main/java/views/").replace("target/classes", "src/main/java/views/");
    /**
     * The constant RESOURCE_PATH.
     */
    String RESOURCE_PATH = getBasePath().replace("target/classes/", "src/main/resources/").replace("target/classes", "src/main/resources/");
    /**
     * The constant STAGE.
     */
    Stage STAGE = new Stage();
    /**
     * The constant SCENE_CONTROLLER.
     */
    SceneController SCENE_CONTROLLER = new SceneController();
    /**
     * The constant CARD_QUERY_BUILDER.
     */
    CardQueryBuilder CARD_QUERY_BUILDER = CardQueryBuilder.getSingletonInstance();
    /**
     * The constant HISTORY_QUERY_BUILDER.
     */
    HistoryQueryBuilder HISTORY_QUERY_BUILDER = HistoryQueryBuilder.getInstance();
}
