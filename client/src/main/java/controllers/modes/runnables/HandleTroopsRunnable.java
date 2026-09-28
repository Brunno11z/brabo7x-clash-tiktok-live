package controllers.modes.runnables;

import cards.Card;
import cards.CardStatusEnum;
import cards.troops.Troop;
import cards.utils.AttackAble;
import cards.utils.TypeEnum;
import controllers.modes.BaseController;
import exceptions.InvalidAttackTargetException;
import globals.GlobalData;
import javafx.geometry.Point2D;
import models.BotModeModel;
import models.GameModel;
import models.OnlineModeModel;
import towers.KingTower;

import java.util.ArrayList;
import java.util.Objects;

/**
 * Enhanced troop movement, combat targeting, and attack animation handler.
 */
public record HandleTroopsRunnable(GameModel model, BaseController controller) implements Runnable {
    @Override
    public void run() {
        this.handleDeadTroops();
        this.handleEachTroopTargetSelection();
        this.handleTroopAttacks();
        this.handleTroopsMove();
    }

    private void handleTroopAttacks() {
        if (this.model instanceof BotModeModel) {
            this.doTroopsAttack(this.model.getPlayerInMapTroops());
            this.doTroopsAttack(((BotModeModel) this.model).getBotInMapTroops());
        }

        if (this.model instanceof OnlineModeModel) {
            this.doTroopsAttack(this.model.getPlayerInMapTroops());
            this.doTroopsAttack(((OnlineModeModel) this.model).getOpponentInMapTroops());
        }
    }

    private void doTroopsAttack(ArrayList<Troop> troops) {
        for (Troop troop : new ArrayList<>(troops)) {
            AttackAble target = troop.getTarget();
            if (target != null && !target.isDead()) {
                if (this.isInRange(troop, target)) {
                    troop.setStatus(CardStatusEnum.FIGHT);
                    if (this.isTimeForAttack(troop)) {
                        troop.attack();
                    }
                    if (target.isDead()) {
                        troop.setStatus(CardStatusEnum.WALK);
                        troop.clearTarget();
                    }
                } else {
                    // Out of range, keep walking towards target
                    troop.setStatus(CardStatusEnum.WALK);
                }
            } else {
                troop.setStatus(CardStatusEnum.WALK);
                troop.clearTarget();
            }
        }
    }

    private boolean isTimeForAttack(Troop troop) {
        int fps = Math.max(1, controller.getFRAME_PER_SECOND());
        long interval = Math.max(1, (long) (troop.getHitSpeed() * fps));
        return controller.getFrameRemainingCount() % interval == 0;
    }

    private void handleTroopsMove() {
        this.moveTroops(this.model.getPlayerInMapTroops(), true);

        if (this.model instanceof BotModeModel) {
            this.moveTroops(((BotModeModel) this.model).getBotInMapTroops(), false);
        }

        if (this.model instanceof OnlineModeModel) {
            this.moveTroops(((OnlineModeModel) this.model).getOpponentInMapTroops(), false);
        }
    }

    private void moveTroops(ArrayList<Troop> troops, boolean isPlayerTeam) {
        for (Troop troop : new ArrayList<>(troops)) {
            // Do not move while engaged in attack range
            if (troop.getTarget() != null && !troop.getTarget().isDead() && this.isInRange(troop, troop.getTarget())) {
                troop.setStatus(CardStatusEnum.FIGHT);
                continue;
            }

            troop.setStatus(CardStatusEnum.WALK);
            if (!this.isTimeForMove(troop)) {
                continue;
            }

            Point2D currentPos = troop.getPosition();
            Point2D goal;

            if (troop.getTarget() != null && !troop.getTarget().isDead()) {
                // Walk toward active target
                goal = isPlayerTeam ? troop.getTarget().getPosition() : controller.transferPosition(troop.getTarget().getPosition());
            } else {
                // Head down bridge/tower lane toward opponent territory
                int targetX = currentPos.getX() < 12 ? 6 : 17;
                int targetY = isPlayerTeam ? 6 : 32;
                goal = new Point2D(targetX, targetY);
            }

            int currentX = (int) currentPos.getX();
            int currentY = (int) currentPos.getY();

            int nextX = currentX;
            int nextY = currentY;

            // Move along X towards lane/target if not aligned
            if (Math.abs(goal.getX() - currentX) >= 1) {
                nextX += (goal.getX() > currentX) ? 1 : -1;
            }

            // Move along Y towards goal
            if (Math.abs(goal.getY() - currentY) >= 1) {
                nextY += (goal.getY() > currentY) ? 1 : -1;
            }

            nextX = Math.max(1, Math.min(22, nextX));
            nextY = Math.max(1, Math.min(37, nextY));

            this.moveTo(troop, nextX, nextY);
        }
    }

    private void moveTo(Troop troop, int x, int y) {
        troop.setStatus(CardStatusEnum.WALK);
        troop.setPosition(new Point2D(x, y));
    }

    private boolean isTimeForMove(Troop troop) {
        return switch (troop.getMovementSpeed()) {
            case FAST -> this.controller.getFrameRemainingCount() % 4 == 0;
            case MEDIUM -> this.controller.getFrameRemainingCount() % 7 == 0;
            case SLOW -> this.controller.getFrameRemainingCount() % 11 == 0;
        };
    }

    private void handleEachTroopTargetSelection() {
        if (this.model instanceof BotModeModel) {
            this.handleTargetSelection(this.model.getPlayerInMapTroops(), ((BotModeModel) this.model).getBotInMapAttackAbles(), true);
            this.handleTargetSelection(((BotModeModel) this.model).getBotInMapTroops(), this.model.getPlayerInMapAttackAbles(), false);
        }

        if (this.model instanceof OnlineModeModel) {
            this.handleTargetSelection(this.model.getPlayerInMapTroops(), ((OnlineModeModel) this.model).getOpponentInMapAttackAbles(), true);
            this.handleTargetSelection(((OnlineModeModel) this.model).getOpponentInMapTroops(), this.model.getPlayerInMapAttackAbles(), false);
        }
    }

    private void handleTargetSelection(ArrayList<Troop> troops, ArrayList<AttackAble> possibleTargets, boolean isPlayer) {
        if (possibleTargets == null || possibleTargets.isEmpty()) return;

        for (Troop troop : new ArrayList<>(troops)) {
            if (troop.getTarget() == null || troop.getTarget().isDead()) {
                AttackAble nearestTarget = this.findNearestTarget(troop.getPosition(), possibleTargets);
                if (nearestTarget != null && this.haveCompatibleTypes(troop, nearestTarget)) {
                    try {
                        troop.setTarget(nearestTarget);
                    } catch (InvalidAttackTargetException ignored) {}
                }
            }
        }
    }

    private boolean haveCompatibleTypes(Troop troop, AttackAble nearestTarget) {
        return switch (troop.getAttackType()) {
            case AIR -> nearestTarget.getSelfType().equals(TypeEnum.AIR);
            case GROUND -> nearestTarget.getSelfType().equals(TypeEnum.GROUND);
            case AIR_GROUND -> true;
        };
    }

    private boolean isInRange(Troop troop, AttackAble nearestTarget) {
        if (nearestTarget == null) return false;
        Point2D targetPos = nearestTarget.getPosition();
        double dist = troop.getPosition().distance(targetPos);
        return dist <= Math.max(1.8, (double) troop.getRange());
    }

    private void handleDeadTroops() {
        for (AttackAble attackAble : this.model.getPlayerInMapAttackAblesCards()) {
            if (attackAble.isDead()) {
                this.model.getPlayerInMapCards().remove((Card) attackAble);
            }
        }

        ArrayList<AttackAble> opponentAttackAbleCards = new ArrayList<>();
        ArrayList<Card> opponentInMapCards = new ArrayList<>();

        if (this.model instanceof BotModeModel) {
            opponentAttackAbleCards = ((BotModeModel) this.model).getBotInMapAttackAblesCards();
            opponentInMapCards = ((BotModeModel) this.model).getBotInMapCards();
            ((BotModeModel) this.model).getBotInMapAttackAblesCards().removeIf(AttackAble::isDead);
        }

        if (this.model instanceof OnlineModeModel) {
            opponentAttackAbleCards = ((OnlineModeModel) this.model).getOpponentInMapAttackAblesCards();
            opponentInMapCards = ((OnlineModeModel) this.model).getOpponentInMapCards();
            ((OnlineModeModel) this.model).getOpponentInMapAttackAblesCards().removeIf(AttackAble::isDead);
        }

        for (AttackAble attackAble : opponentAttackAbleCards) {
            if (attackAble.isDead()) {
                opponentInMapCards.remove((Card) attackAble);
            }
        }
    }

    private AttackAble findNearestTarget(Point2D troopPosition, ArrayList<AttackAble> targets) {
        AttackAble nearest = null;
        double minDistance = Double.MAX_VALUE;

        for (AttackAble target : targets) {
            if (target != null && !target.isDead() && target.getPosition() != null) {
                double d = troopPosition.distance(target.getPosition());
                if (d < minDistance) {
                    minDistance = d;
                    nearest = target;
                }
            }
        }
        return nearest;
    }
}
