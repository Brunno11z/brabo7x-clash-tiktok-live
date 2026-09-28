package controllers.modes.botControllers;

import controllers.modes.runnables.*;
import globals.GlobalData;
import interactive.TikTokInteractiveBridge;
import javafx.application.Platform;

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * The type Normal bot mode controller.
 */
public class NormalBotModeController extends BotController {
    private final ExecutorService frameWorkers = Executors.newFixedThreadPool(6, runnable -> {
        Thread thread = new Thread(runnable, "brabo7x-game-worker");
        thread.setDaemon(true);
        return thread;
    });

    /**
     * Instantiates a new Bot controller.
     */
    public NormalBotModeController() {
        super();
        GlobalData.gameController = this;
        if (TikTokInteractiveBridge.isEnabled()) {
            TikTokInteractiveBridge.startOrAttach(this);
        }
        this.setTimer();
    }

    public void shutdownWorkers() {
        frameWorkers.shutdownNow();
    }

    private void executeFrameTask(Runnable runnable, CountDownLatch latch) {
        frameWorkers.execute(() -> {
            try {
                runnable.run();
            } finally {
                latch.countDown();
            }
        });
    }

        @Override
    protected void setTimer() {
        Timer timer = new Timer("brabo7x-game-timer", true);
        TimerTask timerTask = new TimerTask() {
            @Override
            public void run() {
                Platform.runLater(() -> {
                    if (!GlobalData.gameStarted) return;

                    NormalBotModeController.this.processInteractiveSpawns();
                    boolean interactive = TikTokInteractiveBridge.isEnabled();

                    try {
                        new HandleTowersRunnable(
                                NormalBotModeController.super.model,
                                NormalBotModeController.this,
                                timer
                        ).run();

                        new HandleTroopsRunnable(
                                NormalBotModeController.super.model,
                                NormalBotModeController.this
                        ).run();

                        new HandleSpellsRunnable(
                                NormalBotModeController.super.model,
                                NormalBotModeController.this
                        ).run();

                        new HandleBuildingRunnable(
                                NormalBotModeController.super.model,
                                NormalBotModeController.this
                        ).run();

                        new HandleElixirsCountRunnable(
                                NormalBotModeController.super.model,
                                NormalBotModeController.this
                        ).run();

                        if (!interactive) {
                            new HandleNormalBotMoveRunnable(
                                    NormalBotModeController.super.model,
                                    NormalBotModeController.this
                            ).run();
                        }
                    } catch (Exception ignored) {
                    }

                    NormalBotModeController.super.render();
                    NormalBotModeController.this.reduceFrameRemainingCount();
                });
            }
        };

        timer.scheduleAtFixedRate(timerTask, 0, this.eachFrameDuration);
    }
}
