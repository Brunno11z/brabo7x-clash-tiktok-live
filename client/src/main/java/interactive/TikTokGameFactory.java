package interactive;

import cards.Card;
import controllers.Controller;
import globals.GlobalData;
import javafx.geometry.Point2D;
import javafx.stage.Stage;
import models.BotModeModel;
import towers.Tower;
import user.User;

import java.util.ArrayList;
import java.util.List;

/** Creates a self-contained red-vs-blue match for TikTok LIVE mode. */
public final class TikTokGameFactory {
    private static final List<String> CARD_NAMES = List.of(
            "Archer", "Barbarian", "BabyDragon", "Giant",
            "MiniPekka", "Valkyrie", "Wizard", "Cannon",
            "InfernoTower", "FireBall", "Arrows", "Rage"
    );

    private TikTokGameFactory() {}

    public static void setupAndShow() {
        setupAndShow(null);
    }

    public static void setupAndShow(Stage primaryStage) {
        GlobalData.gameStarted = false;
        GlobalData.playerTeam.clear();
        GlobalData.opponentTeam.clear();

        GlobalData.user = new User("TIME AZUL", "live");
        GlobalData.bot = new User("TIME VERMELHO", "live");
        GlobalData.playerTeam.add(GlobalData.user);
        GlobalData.opponentTeam.add(GlobalData.bot);

        ArrayList<Card> blueCards = createCards(GlobalData.user);
        ArrayList<Card> redCards = createCards(GlobalData.bot);
        ArrayList<Card> blueBattle = new ArrayList<>(blueCards.subList(0, 4));
        ArrayList<Card> redBattle = new ArrayList<>(redCards.subList(0, 4));

        GlobalData.gameModel = new BotModeModel(redCards, redBattle, blueCards, blueBattle);
        setTowerPositions(GlobalData.gameModel.getPlayerTowers());
        setTowerPositions(((BotModeModel) GlobalData.gameModel).getBotTowers());

        Controller.SCENE_CONTROLLER.removeScene("Map/NormalBotMap.fxml");
        Controller.SCENE_CONTROLLER.showScene("Map/NormalBotMap.fxml");

        Stage stageToShow = (primaryStage != null) ? primaryStage : Controller.STAGE;
        if (primaryStage != null && Controller.STAGE.getScene() != null) {
            primaryStage.setScene(Controller.STAGE.getScene());
            primaryStage.setTitle("BRABO7X CLASH LIVE - Azul x Vermelho");
            primaryStage.setResizable(false);
            primaryStage.show();
            primaryStage.toFront();
        } else {
            Controller.STAGE.setTitle("BRABO7X CLASH LIVE - Azul x Vermelho");
            Controller.STAGE.setResizable(false);
            Controller.STAGE.show();
            Controller.STAGE.toFront();
        }
    }

    private static ArrayList<Card> createCards(User owner) {
        ArrayList<Card> cards = new ArrayList<>();
        for (String cardName : CARD_NAMES) {
            cards.add(GlobalData.getCardBasedOnName(cardName, owner));
        }
        return cards;
    }

    private static void setTowerPositions(ArrayList<Tower> towers) {
        towers.get(0).setPosition(new Point2D(6, 29));
        towers.get(1).setPosition(new Point2D(17, 29));
        towers.get(2).setPosition(new Point2D(9, 34));
    }
}
