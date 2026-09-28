package cards.utils;

import javafx.geometry.Point2D;

/**
 * The interface Attack able.
 */
public interface AttackAble {
    void reduceHealthBy(double damage);
    TypeEnum getSelfType();
    Point2D getPosition();
    void setPosition(Point2D position);
    boolean isDead();

    default double getHP() {
        return 100.0;
    }

    default double getMaxHP() {
        return 100.0;
    }
}
