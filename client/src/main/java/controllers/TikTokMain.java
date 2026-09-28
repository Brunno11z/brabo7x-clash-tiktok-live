package controllers;

import interactive.TikTokGameFactory;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.stage.Stage;

/** Dedicated launcher for BRABO7X TikTok interactive mode. */
public class TikTokMain extends Application {
    @Override
    public void start(Stage primaryStage) {
        try {
            System.setProperty("brabo7x.tiktok", "true");
            Platform.setImplicitExit(true);

            Controller.SCENE_CONTROLLER.loadAllCardsUrls();
            Controller.SCENE_CONTROLLER.loadGifs();
            Controller.SCENE_CONTROLLER.loadCardBoxImages();

            TikTokGameFactory.setupAndShow(primaryStage);
        } catch (Exception e) {
            System.err.println("[BRABO7X] Falha na inicializacao do jogo:");
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        System.setProperty("brabo7x.tiktok", "true");
        setUserAgentStylesheet(STYLESHEET_MODENA);
        launch(args);
    }
}
